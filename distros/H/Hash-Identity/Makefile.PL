use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hash::Identity',
    AUTHOR              => q{Cindy Wang (CindyLinz)},
    VERSION_FROM        => 'lib/Hash/Identity.pm',
    ABSTRACT_FROM       => 'lib/Hash/Identity.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Tie::Hash::Identity' => 0.01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hash-Identity-*' },
);
