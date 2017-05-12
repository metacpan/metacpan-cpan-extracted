use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	        => 'HyperWave::CSP',
    VERSION_FROM => 'lib/HyperWave/CSP.pm',
    'dist'       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
