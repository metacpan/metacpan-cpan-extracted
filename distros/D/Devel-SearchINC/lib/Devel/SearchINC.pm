use 5.008;
use strict;
use warnings;

package Devel::SearchINC;
BEGIN {
  $Devel::SearchINC::VERSION = '2.103460';
}
# ABSTRACT: Loading Perl modules from their development directories
use Data::Dumper;
use File::Find;

sub build_cache {
    our %cache = ();
    our @PATHS;
    return unless @PATHS;
    our $DEBUG;

    # Programs run with -T cause a "Insecure dependency in chdir while running
    # with -T switch" warning, so untaint directory names.
    find(
        {   untaint         => 1,
            untaint_pattern => qr|^(.+)$|,  # File::Find gets this wrong on OS X
            untaint_skip    => 1,
            follow          => 1,
            wanted          => sub {
                warn "dir [$File::Find::name]\n" if $DEBUG && -d;
                if (-d && /^(t|CVS|\.svn|\.git|skel|_build)$/) {
                    warn "$File::Find::name dir will be pruned\n" if $DEBUG;
                    $File::Find::prune = 1;
                    return;
                }
                if (-d && -e "$File::Find::name/INC.SKIP") {
                    warn "$File::Find::name dir contains INC.SKIP; pruned\n"
                      if $DEBUG;
                    $File::Find::prune = 1;
                    return;
                }
                if (-d && $_ eq 'lib') {
                    push our @inc => $File::Find::name;
                    return;
                }
                return unless -f && /\.pm$/;
                if ($File::Find::name =~ m!.*/(?:lib|blib/(?:lib|arch))/(.*)!) {
                    $cache{$1} ||= $File::Find::name;
                }
              }
        },
        @PATHS
    );
    warn "cache:\n", Dumper \%cache if $DEBUG;
}

BEGIN {
    unshift @INC, sub {
        my ($self, $file) = @_;
        our %cache;
        our $DEBUG;
        unless (exists $cache{$file}) {
            printf "%s: cache miss <%s>\n", __PACKAGE__, $file
              if $DEBUG;
            return;
        }
        printf "%s: found <%s>\n", __PACKAGE__, $cache{$file} if $DEBUG;
        if (open(my $fh, '<', $cache{$file})) {
            $INC{$file} = $cache{$file};
            return $fh;
        }
        printf "%s: can't open <%s>, declining\n", __PACKAGE__, $cache{$file}
          if $DEBUG;
        return;
      }
}

sub import {
    shift;    # we don't need the package name
    our $DEBUG = 0;
    my @p =
      map { s/^~/$ENV{HOME}/; $_ }
      map { split /\s*[,;:]\s*/ } @_;
    our @PATHS;
    for my $path (@p) {
        if ($path eq '-debug') {
            $DEBUG = 1;
            next;
        }
        if ($path eq '-clear') {
            @PATHS = ();
            next;
        }
        push @PATHS => $path;
    }

    # Build the module cache anew after each import; this is so that if you
    # use PERL5OPT=-MDevel::SearchINC=... and then a program loads it
    # separately with "use Devel::SearchINC '...'" paths from both occasions
    # get respected.
    build_cache();
    warn "paths:\n", Dumper \@PATHS if $DEBUG;
}
1;


__END__
=pod

=head1 NAME

Devel::SearchINC - Loading Perl modules from their development directories

=head1 VERSION

version 2.103460

=head1 SYNOPSIS

  # export PERL5OPT=-MDevel::SearchINC=/my/dev/dir
  # now use your new modules

=head1 DESCRIPTION

When developing a new module, I always start with a standard skeleton
distribution directory. The directory structure is such, however, that you
have to install the module first (with C<make install>) before you can use it
in another program or module. For example, bringing in a module like so:

    use My::Module;

requires the module to be somewhere in a path listed in C<@INC>, and
the relative path is expected to be C<My/Module.pm>. However, C<h2xs>
creates a structure where the module ends up in C<My/Module/Module.pm>.

This module tries to compensate for that. The idea is that you C<use()>
it right at the beginning of your program so it can modify C<@INC> to look
for modules in relative paths of the special structure mentioned above,
starting with directories specified along with the C<use()> statement
(i.e. the arguments passed to this module's C<import()>).

This is useful because with this module you can test your programs using
your newly developed modules without having to install them just so you
can use them. This is especially advantageous when you consider working
on many new modules at the same time.

To automatically make your development modules available to all
your scripts, you can place the following in your C<.bashrc> (or
your shell initialization file of choice):

  export PERL5OPT=-MDevel::SearchINC=/my/dev/dir

Tilde expansion is also performed.

When this module is first run, that is, when perl first consults C<@INC>, all
candidate files are remembered in a cache (see C<build_cache()>). A candidate
file is one whose name ends in C<.pm>, is not within a directory called C<t>,
C<CVS>, C<.svn>, C<.git>, C<skel> or C<_build>, and is within a directory
called C<lib>, C<blib/lib> or C<blib/arch>. This is a long-winded way of
saying that it tries to find your perl module files within standard
development directories.

If a directory contains a file named C<INC.SKIP>, this directory will be
skipped.

Note that there is a small limitation for the C<PERL5OPT> approach:
development modules can't be loaded via C<-M> on the perl command
line.  So the following won't work:

  $ export PERL5OPT=-MDevel::SearchINC=/my/dev/dir
  $ perl -MMy::Brand::New::Module -e'print "hello world\n"'

This is because C<PERL5OPT> options are processed after the actual command
line options.

Also, the C<PERL5OPT> variable is ignored when Taint checks are
enabled.

=head1 FUNCTIONS

=head2 build_cache

Called during C<import()>, this subroutine builds a cache of the modules it
finds. This way every time a module is C<use()>d, we can just look at the
cache. This does mean that if you add, change or delete a module during the
run-time of a script that uses C<Devel::SearchINC>, that script won't notice
these changes. If necessary, you could re-run C<build_cache()>.

=head1 MULTIPLE DEVELOPMENT DIRECTORIES

You can have multiple development directories. Just list them when using
this module:

  use Devel::SearchINC qw(/my/first/dir my/second/dir);

or

  perl -MDevel::SearchINC=/my/first/dir,/my/second/dir

You can also use semicolons or colons instead of commas as delimiters for
directories.

C<perlrun> details the syntax for specifying multiple arguments for
modules brought in with the C<-M> switch.

=head1 SPECIAL OPTIONS

In addition to development directories, there are special options that can be
passed to this module:

=over 4

=item C<-debug>

This turns on debugging; see below.

=item C<-clear>

This option clears all paths that were previously set. This is useful when you
have a C<PERL5OPT> environment variable but want to use this module from
within your code as well and want to override the environment setting. For
example:

    export PERL5OPT=-MDevel::SearchINC=/path/to/dev

then:

    #!/usr/bin/env perl

    use warnings;
    use strict;
    use Devel::SearchINC qw(-clear /path/to/other/dir);
    ...

=back

=head1 DEBUGGING THIS MODULE

By using C<-debug> as one of the development directories, you can turn
on debugging. Note that despite the leading colon, this has nothing to
do with C<Exporter> semantics. With debugging activated, this module
will print detailed information while trying to find the requested file.

For example

  use Devel::SearchINC qw(/my/first/dir my/second/dir -debug);

or

  perl -MDevel::SearchINC=/my/first/dir,-debug,/my/second/dir

The C<-debug> option can be specified anywhere in the list of development
directories.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Devel-SearchINC>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Devel-SearchINC/>.

The development version lives at L<http://github.com/hanekomu/Devel-SearchINC.git>
and may be cloned from L<git://github.com/hanekomu/Devel-SearchINC.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

