use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::EternalLands::Loader',
    AUTHOR              => q{Cole Minor <coleminor@hush.ai>},
    VERSION_FROM        => 'lib/Games/EternalLands/Loader.pm',
    ABSTRACT_FROM       => 'lib/Games/EternalLands/Loader.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'Convert::Binary::C' => 0,
        'Digest::MD5' => 0,
        'IO::Uncompress::AnyUncompress' => 0,
        'IO::File' => 0,
        'File::Basename' => 0,
        'File::Spec::Functions' => 0,
        'Games::EternalLands::Binary::Float16' => 0,
        'Games::EternalLands::Binary::Unitvec16' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-EternalLands-Loader-*' },
);
