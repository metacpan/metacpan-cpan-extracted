use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME             => 'Ham::WorldMap',
    AUTHOR           => q{Matt Gumbley <devzendo@cpan.org>},
    VERSION_FROM     => 'lib/Ham/WorldMap.pm',
    ABSTRACT_FROM    => 'lib/Ham/WorldMap.pm',
    LICENSE          => 'apache_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Imager' => '1.005',
        'Ham::Locator' => '0.1000',
        'File::ShareDir' => '1.102',
        'DateTime' => '1.28',
        'POSIX' => '1.30',
        'Math::Trig' => '1.23',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Ham-WorldMap-*' },
);

package MY;
use File::ShareDir::Install 'postamble';
