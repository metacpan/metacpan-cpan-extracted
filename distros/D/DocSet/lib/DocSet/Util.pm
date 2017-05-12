package DocSet::Util;

use strict;
use warnings;

use Symbol ();
use File::Basename ();
use File::Copy ();
use File::Path ();
use File::Find ();
use Data::Dumper;
use Carp;
use Template;
use File::Spec;
use File::Spec::Functions;

require DocSet::RunTime; # interdependency with DocSet::Util

use constant IS_WIN32 => $^O eq 'MSWin32';
use constant PERL_LT_580 => $] < 5.008;

use vars qw(@ISA @EXPORT);
@ISA    = qw(Exporter);
@EXPORT = qw(read_file read_file_paras copy_file gzip_file write_file
             create_dir filename filename_ext require_package dumper
             sub_trace note get_date get_timestamp proc_tmpl
             build_matchmany_sub banner confess cluck carp
             format_bytes expand_dir which path2uri);

# copy_file($src_path, $dst_path);
# copy a file at $src_path to $dst_path, 
# if one of the directories of the $dst_path doesn't exist -- it'll
# be created.
###############
sub copy_file {
    my ($src, $dst) = @_;

    die "$src doesn't exist" unless -e $src;
    my $mode = (stat _)[2];

    # make sure that the directory exist or create one
    my $base_dir = File::Basename::dirname $dst;
    create_dir($base_dir) unless (-d $base_dir);

    # File::Copy::syscopy doesn't preserve the mode :(
    File::Copy::syscopy($src, $dst);
    chmod $mode, $dst;
}

# gzip_file($src_path);
# gzip a file at $src_path
###############
sub gzip_file {
    my ($src) = @_;
    system "gzip -f $src";
}


# write_file($filename, $ref_to_array||scalar);
# content will be written to the file from the passed array of
# paragraphs
###############
sub write_file {
    my ($filename, $content) = @_;

    # make sure that the directory exist or create one
    my $dir = File::Basename::dirname $filename;
    create_dir($dir) unless -d $dir;

    my $fh = Symbol::gensym;
    open $fh, ">$filename" or croak "Can't open $filename for writing: $!";
    print $fh ref $content ? @$content : defined $content ? $content : '';
    close $fh;
}


# recursively creates a multi-layer directory
###############
sub create_dir {
    my $path = shift;
    return if !defined($path) || -e $path;
    # META: mode could be made configurable
    File::Path::mkpath($path, 0, 0755) or croak "Couldn't create $path: $!";
}

# read_file($filename, $ref);
# assign to a ref to a scalar
###############
sub read_file {
    my ($filename, $r_content) = @_;

    my $fh = Symbol::gensym;
    open $fh, $filename  or croak "Can't open $filename for reading: $!";
    local $/;
    $$r_content = <$fh>;
    close $fh;

}

# read_file_paras($filename, $ref_to_array);
# read by paragraph
# content will be set into a ref to an array
###############
sub read_file_paras {
    my ($filename, $ra_content) = @_;

    my $fh = Symbol::gensym;
    open $fh, $filename  or croak "Can't open $filename for reading: $!";
    local $/ = "";
    @$ra_content = <$fh>;
    close $fh;

}

# return the filename part of the path
sub filename {
    my ($path) = @_;
    return File::Basename::basename($path);
}

# return the passed file's extension or '' if there is no one
# note: that '/foo/bar.conf.in' returns an extension: 'conf.in';
# note: a hidden file .foo will be recognized as an extension 'foo'
sub filename_ext {
    my ($filename) = @_;
    my $ext = (File::Basename::fileparse($filename, '\.[^\.]*'))[2] || '';
    $ext =~ s/^\.(.*)/lc $1/e;
    $ext;
}


# since on non-Unix platforms the fs path's separator don't match the
# URI separator ('/'), we need to rewrite those paths
# accept a relative native path 
# return relative URI
sub path2uri {
    return unless defined $_[0];
    return join '/', File::Spec->splitdir(shift);
}

# File::Spec->abs2rel doesn't strip the volume (e.g. /^c:/) before
# Perl v5.8.0 on Win32. This function fixes this bug.
#
# Make sure to call this function as DocSet::Util::abs2rel, especially
# in the code that already uses File::Spec functions.
sub abs2rel {
    my $res = File::Spec->abs2rel(@_);
    $res =~ s/^[a-zA-Z]:// if IS_WIN32 && PERL_LT_580 && defined $res;
    $res;
}


sub get_date {
    sprintf "%s %d, %d", (split /\s+/, scalar localtime)[1,2,4];
}

sub get_timestamp {
    my ($mon,$day,$year) = (localtime ( time ) )[4,3,5];
    return scalar gmtime() . ' GMT';
}

my %require_seen = ();
# convert Foo::Bar into Foo/Bar.pm and require
sub require_package {
    my $package = shift;
    die "no package passed" unless $package;
    return if $require_seen{$package};
    $require_seen{$package} = 1;
    $package =~ s|::|/|g;
    $package .= '.pm';
    require $package;
}

# convert the template into the release version
# $tmpl_root: a ref to an array of tmpl base dirs
# tmpl_file: which template file to process
# mode     : in what mode (html, ps, ...)
# vars     : ref to a hash with vars to path to the template
#
# returns the processed template
###################
sub proc_tmpl {
    my ($tmpl_root, $tmpl_file, $mode, $vars) = @_;

    # append the specific rendering mode, so the correct template will
    # be picked (e.g. in 'ps' mode, the ps sub-dir(s) will be searched
    # first)
    my $search_path = join ':',
        map { ("$_/$mode", "$_/common", "$_") }
            (ref $tmpl_root ? @$tmpl_root : $tmpl_root);

    my $template = Template->new
        ({
          INCLUDE_PATH => $search_path,
          RECURSION => 1,
          PLUGINS => {
              cnavigator => 'DocSet::Template::Plugin::NavigateCache',
          },
         }) || die $Template::ERROR, "\n";

    #  use Data::Dumper;
    #  print Dumper \@search_path;

    my $output;
    $template->process($tmpl_file, $vars, \$output)
        || die "error: ", $template->error(), "\n";

    return $output;

}


sub banner {
    my ($string) = @_;

    my $len = length($string) + 8;
    note(
         "#" x $len,
         "### $string ###",
         "#" x $len,
        );

}

# see DocSet::Config::files_to_copy() for usage
#########################
sub build_matchmany_sub {
    my $ra_regex = shift;
    my $expr = join '||', map { "\$_[0] =~ m/$_/o" } @$ra_regex;
    # note $expr;
    my $matchsub = eval "sub { ($expr) ? 1 : 0}";
    die "Failed in building regex [@$ra_regex]: $@" if $@;
    $matchsub;
}

use constant KBYTE =>       1024;
use constant MBYTE =>    1048576;
use constant GBYTE => 1073741824;

# compacts numbers like 1200234 => 1.2M, so they always fit into 4 chars.
#################
sub format_bytes {
  my $bytes = shift || 0;

  if ($bytes < KBYTE) {
      return sprintf "%5dB", $bytes;
  }
  elsif (KBYTE <= $bytes  and $bytes < MBYTE) {
      return sprintf "%4.@{[int($bytes/KBYTE) < 10 ? 1 : 0]}fKiB", $bytes/KBYTE;
  }
  elsif (MBYTE <= $bytes  and $bytes < GBYTE) {
      return sprintf "%4.@{[int($bytes/MBYTE) < 10 ? 1 : 0]}fMiB", $bytes/MBYTE;
  }
  elsif (GBYTE <= $bytes) {
      return sprintf "%4.@{[int($bytes/GBYTE) < 10 ? 1 : 0]}fGiB", $bytes/GBYTE;
  }
  else {
      # shouldn't happen
      die "cannot handle formatting of $bytes"
  }
}


sub expand_dir {
    my @files = ();
    if ($] >= 5.006) {
       File::Find::find(sub {push @files, $File::Find::name}, $_[0]);
    }
    else {
        # perl 5.005_03 on FreeBSD doesn't set the dir it chdir'ed to
        # need to move this to compat level?
        require Cwd;
        File::Find::find(sub {push @files, catfile(Cwd::cwd(), $_)}, $_[0]);
    }

    return \@files;
}

my @path_ext = ('');
if (IS_WIN32) {
    if ($ENV{PATHEXT}) {
        push @path_ext, split ';', $ENV{PATHEXT};
    }
    else {
        push @path_ext, map { ".$_" } qw(com exe bat); # Win9X
    }
}
sub which {
    for my $base (map { catfile $_, $_[0] } File::Spec->path()) {
        for my $ext (@path_ext) {
            return $base.$ext if -x $base.$ext;
        }
    }
    return '';
}

sub dumper {
    print Dumper @_;
}


#sub sub_trace {
##    my ($package) = (caller(0))[0];
#    my ($sub) = (caller(1))[3];
#    print "=> $sub: @_\n";
#}

*confess = \*Carp::confess;
*cluck   = \*Carp::cluck;
*carp    = \*Carp::carp;

sub note {
    return unless DocSet::RunTime::get_opts('verbose');
    print join("\n", @_), "\n";
}


#sub error {
#    return unless DocSet::RunTime::get_opts('verbose');
#    cluck(join("\n", @_), "\n");
#}


1;
__END__

=head1 NAME

C<DocSet::Util> - Commonly used functions

=head1 SYNOPSIS

  use DocSet::Util;

  copy_file($src, $dst);
  write_file($filename, $content);
  create_dir($path);

  read_file($filename, $r_content);
  read_file_paras($filename, $ra_content);

  my $ext = filename_ext($filename);
  my $date = get_date();
  my $timestamp = get_timestamp();
  my $uri = path2uri($os_path);

  require_package($package);
  my $output = proc_tmpl($tmpl_root, $tmpl_file, $mode, $vars);

  banner($string);

  my $sub_ref = build_matchmany_sub($ra_regex);
  dumper($ref);
  confess($string);
  note($string);

  my $exec_path = which('perldoc');

=head1 DESCRIPTION

All the functions are exported by default.

=head2 METHODS

META: to be completed (see SYNOPSIS meanwhile)

=over

=item * copy_file

=item * write_file

=item * create_dir

=item * read_file

=item * read_file_paras

=item * filename_ext

=item * path2uri

=item * get_date

=item * get_timestamp

=item * require_package

=item * proc_tmpl

=item * banner

=item * build_matchmany_sub

Since the patterns are compiled by insertion into m//, make sure that
any C</> are escaped. Be careful with using quotemeta() for this,
since you don't want to espace special regex char, e.g. C<^>, C<$>,
etc.

=item * which

  my $exec_path = which('perldoc');

a portable function to search for executables on the system.

Accepts a single argument which is the name of the executable to
search for. Returns the full path to the executable if found, an empty
string otherwise.

Parts of the implementation are borrowed from
I<modperl-2.0/lib/Apache/Build.pm> and modified to take into an
account Win32's C<PATHEXT> environment variable or the hardcoded list
of known executable extensions for Win9x which doesn't have this
variable.

=item * dumper

=item * confess

=item * cluck

=item * carp

=item * note


=back

=head1 AUTHORS

Stas Bekman E<lt>stas (at) stason.orgE<gt>


=cut

