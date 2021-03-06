use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hash::ConsistentHash',
    AUTHOR              => q{Luben Karavelov <<karavelov@gmail.com>>},
    VERSION_FROM        => 'lib/Hash/ConsistentHash.pm',
    ABSTRACT_FROM       => 'lib/Hash/ConsistentHash.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hash-ConsistentHash-*' },
);
