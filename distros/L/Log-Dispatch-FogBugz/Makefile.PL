use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Log::Dispatch::FogBugz',
    AUTHOR              => 'DIMARTINO <chris.dimartino@gmail.com>',
    VERSION_FROM        => 'lib/Log/Dispatch/FogBugz.pm',
    ABSTRACT_FROM       => 'lib/Log/Dispatch/FogBugz.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE' => 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'Log::Dispatch::Output' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Dispatch-FogBugz-*' },
);
