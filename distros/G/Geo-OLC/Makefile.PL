use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Geo::OLC',
    AUTHOR           => q{J Greely <jgreely@cpan.org>},
    VERSION_FROM     => 'lib/Geo/OLC.pm',
    ABSTRACT_FROM    => 'lib/Geo/OLC.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
	EXE_FILES        => [ qw( ./bin/olc ) ],
    MIN_PERL_VERSION => 'v5.10.1',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'List::Util' => 1,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-OLC-*' },
);
