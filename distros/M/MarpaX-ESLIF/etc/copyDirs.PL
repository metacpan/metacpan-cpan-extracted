#!env perl
use strict;
use diagnostics;
use Cwd;
use Fcntl ':mode';
use File::Basename;
use File::Copy qw/copy/;
use File::Find qw/find/;
use File::Path qw/rmtree/;
use File::Spec;
use POSIX qw/EXIT_SUCCESS/;

my $updir = File::Spec->updir;
my $curdir = File::Spec->curdir;
#
# Move to upper dir of this script
#
my $okupdir = File::Spec->catdir(dirname($0), $updir);

chdir($okupdir) || die "Cannot move to $okupdir, $!";
#
# Copy everything needed
#
if (-d 'src') {
    print "... Removing src\n";
    rmtree('src');
}

my ($src, $dst);

print "... Creating directory src\n";
mkdir('src') || die "Failed to create src directory, $!";

print "... Creating directory src/src\n";
$src = File::Spec->catdir('src', 'src');
mkdir($src) || die "Failed to create $src directory, $!";

$src = File::Spec->catdir(($updir) x 3, '3rdparty');
$dst = File::Spec->catdir('src', '3rdparty');
print "... Copying directory $src to $dst\n",
_dircopy($src, $dst);

#
# 3rd party copy is likely to contain garbage. This can happen only in the ALL_IN_ONE case, and in such
# a case we know that every directory named CMakeFiles or output can be removed
# There are all eventual left over CTestTestfile.cmake files
#
my @toremove = ();
find({
      wanted => sub {
        if (-d $_) {
          my $b = basename($_);
          if (($b eq 'CMakeFiles') || ($b eq 'output')) {
            push(@toremove, File::Spec->canonpath($_));
          }
        } elsif (-f $_) {
          my $b = basename($_);
          if (grep { $b eq $_ } qw/CTestTestfile.cmake .gitignore .gitattributes/) {
            push(@toremove, File::Spec->canonpath($_));
          }
        }
      },
      no_chdir => 1
     }, 'src');
foreach (@toremove) {
  if (-d $_) {
    print "... Removing $_\n";
    rmtree($_);
  } elsif (-f $_) {
    print "... Removing $_\n";
    unlink($_);
  }
}

$src = File::Spec->catdir(($updir) x 3, 'include');
$dst = File::Spec->catdir('src', 'include');
print "... Copying directory $src to $dst\n",
_dircopy($src, $dst);

$src = File::Spec->catdir(($updir) x 3, 'cmake');
$dst = File::Spec->catdir('src', 'cmake');
print "... Copying directory $src to $dst\n",
_dircopy($src, $dst);

$src = File::Spec->catfile(($updir) x 3, 'CMakeObjects.PL');
$dst = File::Spec->catfile('src', 'CMakeObjects.PL');
print "... Copying file $src to $dst\n";
copy($src, $dst)|| die "$!";

$src = File::Spec->catfile(($updir) x 3, 'config_autoconf.ini');
$dst = File::Spec->catfile('src', 'config_autoconf.ini');
print "... Copying file $src to $dst\n";
copy($src, $dst)|| die "$!";

$src = File::Spec->catfile(($updir) x 3, 'CMakeLists.txt');
$dst = File::Spec->catfile('src', 'CMakeLists.txt');
print "... Copying file $src to $dst\n";
copy($src, $dst)|| die "$!";

foreach (qw/bootstrap_actions.c marpaESLIF.c/) {
  $src = File::Spec->catfile(($updir) x 3, 'src', $_);
  $dst = File::Spec->catfile('src', 'src', $_);
  print "... Copying file $src to $dst\n";
  copy($src, $dst)|| die "$!";
}

#
# We tweak doc/BNF/README.pod
#
$src = File::Spec->catfile(($updir) x 3, 'doc', 'BNF', 'README.pod');
$dst = File::Spec->catfile('lib', 'MarpaX', 'ESLIF', 'BNF.pod');
print "... Copying file $src to $dst\n";
copy($src, $dst)|| die "$!";
print "... Adapting $dst to perl\n";
open(BNF, '<', $dst) || die "Cannot open $dst, $!";
my $BNF = do { local $/; <BNF>; };
close(BNF) || warn "Cannot close $dst, $!";
$BNF =~ s/^=for html.*?$//sm;
$BNF =~ s/^marpaESLIF_BNF.*?$//sxmg;
$BNF =~ s/marpaESLIF_/MarpaX::ESLIF::/g;
$BNF =~ s/marpaESLIF /MarpaX::ESLIF /g;
open(BNF, '>', $dst) || die "Cannot open $dst, $!";
print BNF "# PODNAME: MarpaX::ESLIF::BNF\n\n";
print BNF "# ABSTRACT: MarpaX::ESLIF's BNF\n\n";
print BNF $BNF;
close(BNF) || warn "Cannot close $dst, $!";

#
# Idem for README.pod
#
$src = File::Spec->catfile(($updir) x 3, 'README.pod');
$dst = File::Spec->catfile('lib', 'MarpaX', 'ESLIF', 'Introduction.pod');
print "... Copying file $src to $dst\n";
copy($src, $dst)|| die "$!";
print "... Adapting $dst to perl\n";
open(INTRO, '<', $dst) || die "Cannot open $dst, $!";
my $INTRO = do { local $/; <INTRO>; };
close(INTRO) || warn "Cannot close $dst, $!";
$INTRO =~ s/^=for html.*?$//sm;
$INTRO =~ s/^=encoding.*?$//sm;
$INTRO =~ s/=head1 NAME.*=head1 DESCRIPTION/=head1 DESCRIPTION/sg;
$INTRO =~ s/=head1 ARCHITECTURE/=head1 EXAMPLE\n\nPlease look at L<MarpaX::ESLIF::Tutorial::Calculator>.\n\n=head1 ARCHITECTURE/;
$INTRO =~ s/marpaESLIF BNF\|https:\/\/github.com\/jddurand\/c\-marpaESLIF\/tree\/master\/doc\/BNF/MarpaX::ESLIF::BNF/g;
$INTRO =~ s/marpaESLIF_/MarpaX::ESLIF::/g;
$INTRO =~ s/marpaESLIF/MarpaX::ESLIF/g;
$INTRO =~ s/^=head1 LOGGING.*?$//sm;
$INTRO =~ s/^All the logging.*?$//sm;
$INTRO =~ s/=head1 SEE ALSO.*//s;
open(INTRO, '>', $dst) || die "Cannot open $dst, $!";
print INTRO "# PODNAME: MarpaX::ESLIF::Introduction\n\n";
print INTRO "# ABSTRACT: MarpaX::ESLIF's Introduction\n\n";
print INTRO $INTRO;
print INTRO <<TRAILER;

=head1 SEE ALSO

L<MarpaX::ESLIF::BNF>, L<MarpaX::ESLIF::Tutorial::Calculator>, L<PCRE2|http://www.pcre.org/>, L<jpcre2|https://github.com/jpcre2/jpcre2>.

=head1 NOTES

The perl interface is using an I<all-in-one> version of the underlying L<marpaESLIF C library|https://github.com/jddurand/c-marpaESLIF>. This mean that character conversion relies on I<iconv> (or native API on Windows) to do character translation if needed.
TRAILER
close(INTRO) || warn "Cannot close $dst, $!";

exit(EXIT_SUCCESS);

#
# Well, I have a problem on Windows because path is greater than MAX_PATH...!
# This private implementation of _dircopy is doing the job...
# Even if I would use Win32::LongPath, dzil would fail afterwards -;
#
sub _dircopy {
    my ($srcdir, $dstdir) = @_;

    if (! -d $srcdir) {
        die "$srcdir is not a directory";
    }
    if (! -d $dstdir) {
        print "... Creating directory $dstdir\n",
        die "Failed to create $dstdir directory, $!" unless mkdir $dstdir;
    }

    my $workdir = cwd;

    my $basedir = basename($srcdir);
    my $reducedLength = 0;
  
    my $stats = _readdir($srcdir);
    foreach (sort keys %{$stats}) {
        next if $_ eq $updir;
        next if $_ eq $curdir;
        #
        # Do not copy known garbage
        #
        next if $_ eq 'cmake_install.cmake';
        next if $_ eq 'Makefile';
        next if $_ eq 'CMakeFiles';
        next if $_ eq 'output';
        next if $_ eq 'CTestTestfile.cmake';
        next if $_ eq '.gitignore';
        next if $_ eq '.gitattributes';
        #
        # Do not copy known stuff we can skip
        #
        next if $_ eq 'Makefile';
        next if $_ eq 'cmake';
        next if $_ eq 'cmake-utils';
        next if $_ eq 'test';
        next if $_ eq 'blog';
        next if $_ eq 't';
        next if $_ eq 'html';
        next if $_ eq 'inc';
        next if $_ eq 'lib';
        next if $_ eq 'm4';
        next if $_ eq 'pod';
        next if $_ eq 'etc';
        next if $_ eq 'xs';
        next if $_ eq 'author.t';
        next if $_ eq '.travis.yml';
        next if $_ eq 'visual-studio';
        next if $_ =~ /\..?sh$/;
        next if $_ =~ /\.3$/;
        next if $_ =~ /\.3\.gz$/;
        next if $_ =~ /\.o(?:bj)?$/;
        next if $_ =~ /\.pdb$/;
        next if $_ =~ /\.tlog$/;
        next if $_ =~ /\.vcxproj$/;
        next if $_ =~ /\.vcxproj\.filters$/;
        next if $_ =~ /\.vcxproj\.user$/;
        next if $_ =~ /\.opensdf$/;
        next if $_ =~ /\.sln$/;
        next if $_ =~ /\.suo$/;
        next if $_ =~ /\.sdf$/;
        next if $_ =~ /\.dir$/;
        next if $_ =~ /\.psess$/;
        next if $_ =~ /\.vsp$/;
        next if $_ eq 'Testing';
        next if $_ eq 'Win32';
        next if $_ eq 'ipch';
        next if $_ eq 'patchit';
        next if $_ eq 'pcre2-10.22';
        next if $_ eq 'pcre2-10.22.tar.gz';
        next if $_ eq 'pcre2-10.23';
        next if $_ eq 'pcre2-10.23.patchdir';
        next if $_ eq 'pcre2-10.23.tar.gz';
        next if $_ =~ /~$/;

        my $mode = $stats->{$_}->[2];

        if (S_ISDIR($mode)) {
            # if ($basedir eq 'github') {
            #     _dircopy(File::Spec->catdir($srcdir, $_), File::Spec->catdir($dstdir, $reducedLength++));
            # } else {
                _dircopy(File::Spec->catdir($srcdir, $_), File::Spec->catdir($dstdir, $_));
            # }
        } else {
            my $file = File::Spec->catfile($srcdir, $_);
            print "... Copying file $file to $dstdir\n";
            _copy($srcdir, $dstdir, $_);
        }
    }
}

sub _chdir {
    my ($dir) = @_;

    my ($volume, $directories, $file) = File::Spec->splitpath($dir, 1);
    my @dirs = File::Spec->splitdir($directories);
    my @donedirs = ();
    my $donedirs = '';
    foreach (@dirs) {
        push(@donedirs, $_);
        $donedirs = File::Spec->catdir(@donedirs);
        chdir($_) || die "Cannot chdir to $donedirs, $!";
    }
}

sub _readdir {
    my ($dir) = @_;

    my $workdir = cwd;

    _chdir($dir);

    my $dh;
    opendir($dh, $curdir) || die "Failed to opendir $dir, $!";
    my %stats = ();
    while (readdir($dh)) {
        my @stat = stat($_);
        if (! @stat) {
            warn "Failed to stat entry in $dir: $_";
        } else {
            $stats{$_} = \@stat;
        }
    }
    closedir($dh) || warn "Failed to closedir $dir, $!";

    chdir($workdir) || die "Failed to chdir to $workdir, $!";
    return \%stats;
}

sub _copy {
    my ($srcdir, $dstdir, $entry) = @_;

    my $srcfile = File::Spec->catfile($srcdir, $entry);
    my $dstfile = File::Spec->catfile($dstdir, $entry);

    #
    # All files I copy are short -;
    #
    my $workdir = cwd;
    _chdir($srcdir);
    open(my $in, '<', $entry) || die "Cannot open $srcfile, $!";
    binmode($in) || die "Failed to set binary mode on $srcfile, $!";

    chdir($workdir) || die "Failed to chdir to $workdir, $!";
    _chdir($dstdir);

    open(my $out, '>', $entry) || die "Cannot open $dstfile, $!";
    binmode($out) || die "Failed to set binary mode on $dstfile, $!";
    chdir($workdir) || die "Failed to chdir to $workdir, $!";

    #
    #
    my $data = do { local $/; <$in> };
    print $out $data;
    close($in) || warn "Failed to close $srcfile, $!";
    close($out) || warn "Failed to close $dstfile, $!";
}
