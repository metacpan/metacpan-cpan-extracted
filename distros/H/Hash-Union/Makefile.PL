use strict;
use warnings;
use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hash::Union',
    AUTHOR              => 'Oleg A. Mamontov <oleg@mamontov.net>',
    VERSION_FROM        => 'lib/Hash/Union.pm',
    ABSTRACT_FROM       => 'lib/Hash/Union.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'       => 0,
        'Storable'   => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hash-Union-*' },
);
