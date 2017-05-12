use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Bank::NetBranch',
    AUTHOR              => 'Darren Kulp <darren@kulp.ch>',
    VERSION_FROM        => 'lib/Finance/Bank/NetBranch.pm',
    ABSTRACT_FROM       => 'lib/Finance/Bank/NetBranch.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Alias' => 0,
        'Carp' => 0,
        'Date::Parse' => 0,
        'DateTime' => 0,
        'HTML::Entities' => 0,
        'HTML::TreeBuilder' => 0,
        'Test::More' => 0,
        'WWW::Mechanize' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Bank-NetBranch-*' },
);
