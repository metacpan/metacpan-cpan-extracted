use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

use Config;
use Cwd qw(abs_path getcwd);

# In-repo development helper: if in git repo, ensure local Alien-libhisto is built and in @INC
BEGIN {
    my $alien_dir = File::Spec->rel2abs(File::Spec->catdir(File::Spec->curdir, '..', 'Alien-libhisto'));
    my $alien_file = File::Spec->catfile($alien_dir, 'alienfile');
    my $alien_blib = File::Spec->catdir($alien_dir, 'blib', 'lib');
    my $alien_arch = File::Spec->catdir($alien_dir, 'blib', 'arch');

    if (-f $alien_file) {
        # Check if local Alien-libhisto blib exists, if not build it automatically
        if (! -d $alien_blib || ! -f File::Spec->catfile($alien_blib, 'Alien', 'libhisto.pm')) {
            print "In-tree build: building Alien-libhisto in $alien_dir...\n";
            my $orig = getcwd();
            chdir $alien_dir or die "Cannot chdir to $alien_dir: $!";
            system($^X, 'Makefile.PL') == 0 or die "Failed to execute Makefile.PL in $alien_dir: $?";
            my $make = $Config{make} || 'make';
            system($make) == 0 or die "Failed to execute $make in $alien_dir: $?";
            chdir $orig or die "Cannot chdir back to $orig: $!";
        }
        unshift @INC, $alien_blib, $alien_arch;
        require ExtUtils::Manifest;
        ExtUtils::Manifest::mkmanifest();
    }
}


use Alien::Base::Wrapper qw( Alien::libhisto !export );


my %args = Alien::Base::Wrapper->mm_args2(
    NAME          => 'Math::Histo',
    DISTNAME      => 'Math-Histo',
    VERSION_FROM  => 'lib/Math/Histo.pm',
    ABSTRACT_FROM => 'lib/Math/Histo.pm',
    AUTHOR        => 'Steffen Mueller <cpan@steffen-mueller.net>',
    LICENSE       => 'mit',
    MIN_PERL_VERSION => '5.008001',
    EXE_FILES     => ['script/phisto'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'  => '6.52',
        'Alien::Base::Wrapper' => '0',
        'Alien::libhisto'      => '0.1.0',
    },
    PREREQ_PM => {
        'Alien::libhisto'      => '0.1.0',
        'Exporter'             => '5.57',
        'XSLoader'             => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0'            => '0.000060',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    OBJECT        => '$(O_FILES)',

    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/tsee/libhisto.git',
                web  => 'https://github.com/tsee/libhisto',
            },
            bugtracker => {
                web => 'https://github.com/tsee/libhisto/issues',
            },
        },
    },
);

my $alien_libs = Alien::libhisto->libs;
$alien_libs =~ s/-lhisto/-lhistocli -lhisto/;
$args{LIBS} = [ $alien_libs ];

WriteMakefile(%args);

sub MY::postamble {
    return "\ndistdir : manifest\n\n";
}



