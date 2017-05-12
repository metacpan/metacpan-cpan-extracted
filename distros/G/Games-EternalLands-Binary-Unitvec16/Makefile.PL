use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::EternalLands::Binary::Unitvec16',
    AUTHOR              => q{Cole Minor <coleminor@hush.ai>},
    VERSION_FROM        => 'lib/Games/EternalLands/Binary/Unitvec16.pm',
    ABSTRACT_FROM       => 'lib/Games/EternalLands/Binary/Unitvec16.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-EternalLands-Binary-Unitvec16-*' },
    OBJECT              => 'convert.o Unitvec16.o',
);
