use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MW::ssNA',
    AUTHOR              => q{SHANKAR M <msinfopl@gmail.com>},
    VERSION_FROM        => 'lib/MW/ssNA.pm',
    ABSTRACT_FROM       => 'lib/MW/ssNA.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MW-ssNA-*' },
);
