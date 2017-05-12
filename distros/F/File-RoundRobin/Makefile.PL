use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::RoundRobin',
    AUTHOR              => q{Gligan Calin Horea <gliganh@gmail.com>},
    VERSION_FROM        => 'lib/File/RoundRobin.pm',
    ABSTRACT_FROM       => 'lib/File/RoundRobin.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
	EXE_FILES			=> ['bin/rrcat','bin/rrtail'],
    PREREQ_PM => {
        'Test::More' => 0,
        'Getopt::Long' => 0,
        'Time::HiRes' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-RoundRobin-*' },
);
