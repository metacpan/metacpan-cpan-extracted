use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'List::Analyse::Sequence::Analyser::OL::RomanNumerals',
    AUTHOR              => 'Alastair Douglas <altreus@perl.com>',
    VERSION_FROM        => 'lib/List/Analyse/Sequence/Analyser/OL/RomanNumerals.pm',
    ABSTRACT_FROM       => 'lib/List/Analyse/Sequence/Analyser/OL/RomanNumerals.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Roman'      => 0,
        'List::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'List-Analyse-Sequence-Analyser-OL-RomanNumerals-*' },
);
