use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Getopt::CommandLineExports',
    AUTHOR              => q{Robert Haxton <robert.haxton@gmail.com>},
    VERSION_FROM        => 'lib/Getopt/CommandLineExports.pm',
    ABSTRACT_FROM       => 'lib/Getopt/CommandLineExports.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'CGI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Getopt-CommandLineExports-*' },
);
