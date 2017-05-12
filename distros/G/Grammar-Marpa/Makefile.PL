use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Grammar::Marpa',
    AUTHOR              => q{Paul Bennett <paul.w.bennett@gmail.com>},
    VERSION_FROM        => 'lib/Grammar/Marpa.pm',
    ABSTRACT_FROM       => 'lib/Grammar/Marpa.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Marpa::R2' => '2.074000',
        'utf8' => '0',
        'overload' => '0',
    },
    TEST_REQUIRES => { 'Test::More' => 0, },
    MIN_PERL_VERSION => '5.018000',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Grammar-Marpa-*' },
);
