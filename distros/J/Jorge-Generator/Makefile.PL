use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Jorge::Generator',
    AUTHOR              => 'Julián Porta <julian.porta@gmail.com>',
    VERSION_FROM        => 'lib/Jorge/Generator.pm',
    ABSTRACT_FROM       => 'lib/Jorge/Generator.pm',
    EXE_FILES           => ['bin/jorge-generate'],
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Jorge-Generator-*' },
);
