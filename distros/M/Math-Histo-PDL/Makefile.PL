use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;
use Config;
use Cwd qw(abs_path getcwd);

# In-repo development helper: if in git repo, ensure local Alien-libhisto and Math-Histo are built and in @INC
BEGIN {
    my $alien_dir = File::Spec->rel2abs(File::Spec->catdir(File::Spec->curdir, '..', 'Alien-libhisto'));
    my $alien_blib_lib  = File::Spec->catdir($alien_dir, 'blib', 'lib');
    my $alien_blib_arch = File::Spec->catdir($alien_dir, 'blib', 'arch');

    my $math_dir = File::Spec->rel2abs(File::Spec->catdir(File::Spec->curdir, '..', 'Math-Histo'));
    my $math_blib_lib  = File::Spec->catdir($math_dir, 'blib', 'lib');
    my $math_blib_arch = File::Spec->catdir($math_dir, 'blib', 'arch');

    if (-d $alien_dir && -d $math_dir) {
        # Check if local Alien-libhisto blib exists, if not build it automatically
        if (! -d $alien_blib_lib || ! -f File::Spec->catfile($alien_blib_lib, 'Alien', 'libhisto.pm')) {
            print "In-tree build: building Alien-libhisto in $alien_dir...\n";
            my $orig = getcwd();
            chdir $alien_dir or die "Cannot chdir to $alien_dir: $!";
            system($^X, 'Makefile.PL') == 0 or die "Failed to execute Makefile.PL in $alien_dir: $?";
            my $make = $Config{make} || 'make';
            system($make) == 0 or die "Failed to execute $make in $alien_dir: $?";
            chdir $orig or die "Cannot chdir back to $orig: $!";
        }

        # Check if local Math-Histo blib exists, if not build it automatically
        if (! -d $math_blib_lib || ! -f File::Spec->catfile($math_blib_lib, 'Math', 'Histo.pm')) {
            print "In-tree build: building Math-Histo in $math_dir...\n";
            my $orig = getcwd();
            chdir $math_dir or die "Cannot chdir to $math_dir: $!";
            system($^X, 'Makefile.PL') == 0 or die "Failed to execute Makefile.PL in $math_dir: $?";
            my $make = $Config{make} || 'make';
            system($make) == 0 or die "Failed to execute $make in $math_dir: $?";
            chdir $orig or die "Cannot chdir back to $orig: $!";
        }

        unshift @INC, $alien_blib_lib, $alien_blib_arch, $math_blib_lib, $math_blib_arch;
        require ExtUtils::Manifest;
        ExtUtils::Manifest::mkmanifest();
    }
}

WriteMakefile(
    NAME             => 'Math::Histo::PDL',
    DISTNAME         => 'Math-Histo-PDL',
    VERSION_FROM     => 'lib/Math/Histo/PDL.pm',
    ABSTRACT_FROM    => 'lib/Math/Histo/PDL.pm',
    AUTHOR           => 'Steffen Mueller <cpan@steffen-mueller.net>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.010000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.52',
    },
    PREREQ_PM => {
        'Math::Histo' => '0.1.1',
        'PDL'         => '2.000',
        'Exporter'    => '5.57',
        'Carp'        => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0'   => '0.000060',
        'Math::Histo' => '0.1.1',
        'PDL'         => '2.000',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/tsee/libhisto.git',
                web  => 'https://github.com/tsee/libhisto',
            },
            bugtracker => {
                web => 'https://github.com/tsee/libhisto/issues',
            },
        },
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {
        FILES => 'Math-Histo-PDL-*',
    },
);
