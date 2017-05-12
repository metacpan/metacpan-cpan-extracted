use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTML::Content::Extractor',
    VERSION_FROM     => 'Extractor.pm',
    ABSTRACT_FROM    => 'Extractor.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => 5.008,
    AUTHOR           => 'Alexander Borisov <lex.borisov@gmail.com>',
    PREREQ_PM        => {}
);
