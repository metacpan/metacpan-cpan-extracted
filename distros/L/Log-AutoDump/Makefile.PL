use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Log::AutoDump',
    AUTHOR              => q{Rob Brown <rob@intelcompute.com>},
    VERSION_FROM        => 'lib/Log/AutoDump.pm',
    ABSTRACT_FROM       => 'lib/Log/AutoDump.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-AutoDump-*' },
);
