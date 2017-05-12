use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::VersionDump',
    AUTHOR              => q{Rob Hoelz <rob@hoelz.ro>},
    VERSION_FROM        => 'lib/Devel/VersionDump.pm',
    ABSTRACT_FROM       => 'lib/Devel/VersionDump.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-VersionDump-*' },
);
