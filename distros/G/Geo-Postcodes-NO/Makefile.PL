use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Geo::Postcodes::NO',
    VERSION_FROM  => 'lib/Geo/Postcodes/NO.pm',
    ABSTRACT_FROM => 'lib/Geo/Postcodes/NO.pm',
    AUTHOR        => 'Arne Sommer <perl@bbop.org>',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.008',
    PREREQ_PM => {},
    EXE_FILES => [ 'script/check-postcodes-no' ],
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    PM => {
        'lib/Geo/Postcodes/NO.pm' => '$(INST_LIB)/Geo/Postcodes/NO.pm',
        'lib/Geo/Postcodes/NO/Check.pm' => '$(INST_LIB)/Geo/Postcodes/NO/Check.pm',
        'lib/Geo/Postcodes/NO/Selection.pm' => '$(INST_LIB)/Geo/Postcodes/NO/Selection.pm',
        'lib/Geo/Postcodes/NO/Tutorial.pm' => '$(INST_LIB)/Geo/Postcodes/NO/Tutorial.pm',
        'lib/Geo/Postcodes/NO/postnummerregister-ansi.txt' => '$(INST_LIB)/Geo/Postcodes/NO/postnummerregister-ansi.txt',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/arnesom/perl-geo-postcodes-no.git',
                web  => 'https://github.com/arnesom/perl-geo-postcodes-no',
            },
            homepage => 'https://www.bring.no/tjenester/adressetjenester/postnummer',
        },
    },
);
