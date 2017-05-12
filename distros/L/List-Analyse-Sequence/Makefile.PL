use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'List::Analyse::Sequence',
    AUTHOR              => 'Alastair Douglas <altreus@perl.org>',
    VERSION_FROM        => 'lib/List/Analyse/Sequence.pm',
    ABSTRACT_FROM       => 'lib/List/Analyse/Sequence.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'Roman'             => 0,
        'List::MoreUtils'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'List-Analyse-Sequence-*' },
);
