require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'File::CounterFile',
    VERSION_FROM => 'CounterFile.pm',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
