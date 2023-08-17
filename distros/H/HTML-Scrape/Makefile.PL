use 5.10.1;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

my %WriteMakefileArgs = (
    NAME             => 'HTML::Scrape',
    AUTHOR           => q{Andy Lester <andy@petdance.com>},
    VERSION_FROM     => 'lib/HTML/Scrape.pm',
    ABSTRACT_FROM    => 'lib/HTML/Scrape.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.10.1',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Test::More'     => '0.98', # To get subtest()
        'Test::Warnings' => '0',
    },
    PREREQ_PM => {
        'HTML::Parser' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTML-Scrape-*' },
);

WriteMakefile(%WriteMakefileArgs);
