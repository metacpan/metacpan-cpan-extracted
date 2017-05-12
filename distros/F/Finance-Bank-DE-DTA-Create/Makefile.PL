use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Bank::DE::DTA::Create',
    AUTHOR              => q{Ben Schnopp <bsnoop@cpan.org>},
    VERSION_FROM        => 'lib/Finance/Bank/DE/DTA/Create.pm',
    ABSTRACT_FROM       => 'lib/Finance/Bank/DE/DTA/Create.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Bank-DE-DTA-Create-*' },
);
