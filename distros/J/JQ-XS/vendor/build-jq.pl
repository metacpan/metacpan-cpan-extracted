#!/usr/bin/perl
#
# Build the vendored jq into a private staging prefix, statically and with PIC,
# so that Makefile.PL can link libjq.a and its oniguruma straight into XS.so.
# The installed module then has no libjq dependency at all, and the jq it uses
# is the one shipped here rather than whatever the OS happens to package.
#
# Normally run by the generated Makefile, but standalone-runnable for debugging:
#
#   perl vendor/build-jq.pl --tarball vendor/jq-1.8.2.tar.gz \
#        --builddir .jq-build --prefix .jq-build/stage \
#        --cc gcc --cflags '-O2 -fPIC'
#
# Everything it creates lives under --builddir, which "make realclean" and
# "make jq_clean" remove.

use strict;
use warnings;

use Cwd qw(abs_path getcwd);
use File::Basename qw(basename);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long qw(GetOptions);

my %opt = (
    tarball  => undef,
    builddir => '.jq-build',
    prefix   => undef,
    cc       => $ENV{CC} || 'cc',
    cflags   => '-O2 -fPIC',
    make     => $ENV{MAKE} || 'make',
    jobs     => $ENV{JQ_XS_JOBS} || 0,
);

GetOptions(
    \%opt,
    'tarball=s', 'builddir=s', 'prefix=s',
    'cc=s', 'cflags=s', 'make=s', 'jobs=i',
) or die "usage: $0 --tarball FILE [--builddir DIR] [--prefix DIR] " .
         "[--cc CC] [--cflags FLAGS] [--make MAKE] [--jobs N]\n";

defined $opt{tarball} or die "$0: --tarball is required\n";
-f $opt{tarball}      or die "$0: no such tarball: $opt{tarball}\n";

# The tarball name is the single source of truth for the jq version: there is
# deliberately no second place to keep in sync.
my $tarball = abs_path($opt{tarball});
my $base    = basename($tarball);
my ($jq_version) = $base =~ /^jq-(.+)\.tar\.gz\z/
    or die "$0: cannot read a jq version out of '$base'; " .
           "expected something like jq-1.8.2.tar.gz\n";

make_path($opt{builddir}) unless -d $opt{builddir};
my $builddir = abs_path($opt{builddir});
# configure and libtool both need an absolute prefix.
my $prefix = abs_path_maybe($opt{prefix} // File::Spec->catdir($builddir, 'stage'));
my $src    = File::Spec->catdir($builddir, "jq-$jq_version");

my $jq_lib   = File::Spec->catfile($prefix, 'lib', 'libjq.a');
my $onig_lib = File::Spec->catfile($prefix, 'lib', 'libonig.a');

# Already built and newer than the tarball?  Nothing to do.  Keeps the make
# rule cheap to re-enter and makes a hand re-run a no-op.
if (-f $jq_lib && -f $onig_lib && -M $jq_lib <= -M $tarball) {
    print "jq $jq_version already built in $prefix\n";
    exit 0;
}

print "=== building jq $jq_version for JQ::XS ===\n";

verify_checksum($tarball);
extract($tarball, $builddir, $src);

-x File::Spec->catfile($src, 'configure')
    or die "$0: $src/configure is missing or not executable; " .
           "the tarball did not extract correctly\n";

my $cwd = getcwd();
chdir $src or die "$0: cannot chdir to $src: $!\n";

# --disable-shared      we only ever link the static archive into XS.so
# --with-pic            ... and libtool skips its PIC objects for a static-only
#                       build unless asked, which would make XS.so unlinkable
# --with-oniguruma=builtin  build the oniguruma vendored in the tarball, so the
#                       regex builtins (test/match/capture/sub/gsub/scan/splits)
#                       work without an OS libonig
# --disable-docs        the manual needs python/pipenv; jq.1 ships prebuilt
# --disable-dependency-tracking   we build once and throw the tree away
run('./configure',
    '--disable-shared',
    '--enable-static',
    '--with-pic',
    '--with-oniguruma=builtin',
    '--disable-docs',
    '--disable-dependency-tracking',
    "--prefix=$prefix",
    "CC=$opt{cc}",
    "CFLAGS=$opt{cflags}",
);

# Plain "all", not "libjq.la": the oniguruma archive libjq links against is
# produced by the SUBDIRS recursion, which has no top-level rule of its own.
my $jobs = $opt{jobs} || cpu_count();
run($opt{make}, "-j$jobs");
run($opt{make}, 'install');

chdir $cwd or die "$0: cannot chdir back to $cwd: $!\n";

for my $lib ($jq_lib, $onig_lib) {
    -f $lib or die "$0: $lib was not created.\n" .
        "The jq build reported success but did not leave the static archives\n" .
        "where they were expected.  Try 'make jq_clean' and build again.\n";
}

# jq's "make install" does not install version.h, but reporting the version of
# the jq that actually got built (rather than one Makefile.PL believes in) is
# worth one file copy.
my $version_h = File::Spec->catfile($src, 'src', 'version.h');
my $staged_h  = File::Spec->catfile($prefix, 'include', 'jq_version.h');
if (-f $version_h) {
    copy($version_h, $staged_h)
        or die "$0: cannot copy $version_h to $staged_h: $!\n";
}
else {
    # Shipped pre-generated in every release tarball, so this should not happen.
    open my $fh, '>', $staged_h
        or die "$0: cannot write $staged_h: $!\n";
    print {$fh} qq{#define JQ_VERSION "$jq_version"\n};
    close $fh or die "$0: cannot close $staged_h: $!\n";
}

printf "=== jq %s built: %s (%.1f MiB), %s (%.1f MiB) ===\n",
    $jq_version,
    $jq_lib,   (-s $jq_lib)   / (1024 * 1024),
    $onig_lib, (-s $onig_lib) / (1024 * 1024);

exit 0;

# --------------------------------------------------------------------------

# Check the tarball against the checksum committed next to it.  A jq compromise
# now ships inside our binary instead of arriving through an OS update, so this
# is worth the two seconds.  Digest::SHA is a separate package on some distros;
# warn rather than fail if it is missing, so the check can never be the reason a
# build cannot run.
sub verify_checksum {
    my ($file) = @_;

    my $sumfile = "$file.sha256";
    unless (-f $sumfile) {
        warn "$0: no $sumfile; skipping checksum verification\n";
        return;
    }

    unless (eval { require Digest::SHA; 1 }) {
        warn "$0: Digest::SHA is not available; " .
             "skipping checksum verification of $file\n";
        return;
    }

    open my $fh, '<', $sumfile or die "$0: cannot open $sumfile: $!\n";
    my $line = <$fh>;
    close $fh;
    my ($want) = ($line // '') =~ /\A([0-9a-fA-F]{64})\b/
        or die "$0: cannot read a sha256 out of $sumfile\n";

    my $got = Digest::SHA->new(256)->addfile($file, 'b')->hexdigest;
    lc $got eq lc $want or die
        "$0: checksum mismatch for $file\n" .
        "  expected $want\n" .
        "  got      $got\n" .
        "Refusing to build.  Replace the tarball with the upstream release, or\n" .
        "update $sumfile if the vendored jq was deliberately changed.\n";

    print "checksum ok: $base\n";
}

# Unpack with Archive::Tar so no external tar is needed.  Fall back to tar(1)
# where Archive::Tar is not installed -- some distros package the core modules
# separately -- and also where it is installed but cannot manage the archive,
# so that an Archive::Tar of any vintage cannot be what stops the build.
sub extract {
    my ($file, $into, $expect) = @_;

    if (-d $expect) {
        print "reusing extracted $expect\n";
        return;
    }

    print "extracting $base\n";

    my $err = eval { require Archive::Tar; 1 }
        ? extract_with_archive_tar($file, $into)
        : 'Archive::Tar is not installed';

    if (defined $err) {
        warn "$0: $err; falling back to tar\n";
        run('tar', 'xzf', $file, '-C', $into);
    }

    -d $expect or die "$0: $file did not contain $expect\n";
}

# Returns undef once the archive is unpacked into $into, or the reason it
# could not be, for extract() to fall back on.
sub extract_with_archive_tar {
    my ($file, $into) = @_;

    # Read the whole archive rather than using extract_archive(), which
    # extracts as it streams and so keeps no entry in memory -- which the
    # dereferencing below needs, and which Archive::Tar itself needs to
    # resolve a hard link.  The jq tarball is ~9M unpacked; next to compiling
    # it that is not a cost worth optimising.
    my $tar = Archive::Tar->new;
    $tar->read($file)
        or return "Archive::Tar cannot read $base: " . (Archive::Tar->error || '?');

    deref_hardlinks($tar);

    my $cwd = getcwd();
    chdir $into or die "$0: cannot chdir to $into: $!\n";
    my $ok  = eval { $tar->extract };
    my $err = $@ || $tar->error || '?';
    chdir $cwd or die "$0: cannot chdir back to $cwd: $!\n";

    return $ok ? undef : "Archive::Tar cannot extract $base: $err";
}

# Replace every hard link in the archive with a plain copy of what it points
# at, before anything reaches the disk.
#
# tar anchors a hard link's target at the root of the archive.  Archive::Tar
# agreed as long as it called link(), but it now defaults $EXTRACT_HARDLINK to
# 0 -- extracting a hard link chmods the inode it shares, which a hostile
# archive can aim at a file that is already there -- and instead re-extracts
# the target as a plain file, resolving its name relative to the link's own
# directory.  jq's tarball holds exactly one hard link,
# docs/content/manual/v1.8/manual.yml -> docs/content/manual/manual.yml, so
# that lookup goes hunting for
#
#   jq-1.8.2/docs/content/manual/v1.8/jq-1.8.2/docs/content/manual/manual.yml
#
# and one entry it cannot place fails the whole extraction.
#
# Dereferencing here rather than repacking vendor/jq-1.8.2.tar.gz keeps it
# byte-for-byte the upstream release, which is what makes the sha256 beside it
# jq's own and worth checking.  Nothing in the build cares that the two files
# no longer share an inode: --disable-docs means neither is so much as read.
sub deref_hardlinks {
    my ($tar) = @_;

    my @entries = $tar->get_files;
    my %by_path = map { $_->full_path => $_ } @entries;

    for my $link (grep { $_->is_hardlink } @entries) {
        # Leave anything we cannot resolve to a plain file exactly as it is,
        # for Archive::Tar to report and the tar(1) fallback to deal with:
        # a target that is missing, or is itself a link -- tar names the first
        # member it archived, so links should never chain, and guessing at one
        # that did would be worse than handing the job to tar.
        my $target = $by_path{ $link->linkname };
        next unless $target && !$target->is_hardlink;

        $link->replace_content($target->get_content);
        $link->type($target->type);
        $link->linkname('');
    }
}

sub run {
    my (@cmd) = @_;
    print "+ @cmd\n";
    my $rc = system @cmd;
    return if $rc == 0;

    my $why = $rc == -1 ? "failed to run ($!)"
            : $rc & 127 ? sprintf('died with signal %d', $rc & 127)
            :             sprintf('exited with status %d', $rc >> 8);
    die "$0: '@cmd' $why.\n" .
        "The vendored jq did not build.  All it needs is a C compiler, make and\n" .
        "a POSIX shell; the compiler used was '$opt{cc}'.\n";
}

sub cpu_count {
    my $n = 0;
    if (open my $fh, '<', '/proc/cpuinfo') {
        $n = grep { /^processor\s*:/ } <$fh>;
        close $fh;
    }
    $n ||= do {
        my $out = `getconf _NPROCESSORS_ONLN 2>/dev/null` || '';
        $out =~ /(\d+)/ ? $1 : 1;
    };
    $n = 1 if $n < 1;
    $n = 8 if $n > 8;    # jq is small; more workers stop helping
    return $n;
}

sub abs_path_maybe {
    my ($path) = @_;
    return abs_path($path) if -e $path;
    make_path($path);
    return abs_path($path);
}
