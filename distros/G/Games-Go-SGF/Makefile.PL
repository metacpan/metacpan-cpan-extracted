use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::Go::SGF',
    AUTHOR              => 'Daniel Gilder <degatcpan@ntlworld.com>',
    VERSION_FROM        => 'lib/Games/Go/SGF.pm',
    ABSTRACT_FROM       => 'lib/Games/Go/SGF.pm',
    PREREQ_PM => {
	    Parse::RecDescent => 0,
      Test::More 	      => 0,
      IO::File          => 0,
      English           => 0,
      Carp              => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-Go-SGF-*' },
);
