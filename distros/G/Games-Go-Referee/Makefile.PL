use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Games::Go::Referee',
    VERSION_FROM      => 'lib/Games/Go/Referee.pm', # finds $VERSION
    PREREQ_PM         => {
			 Games::Go::SGF => 0,
       Test::More   => 0,
			 IO::File 	=> 0,
			 English	=> 0,
			 Carp		=> 0,
},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Games/Go/Referee.pm', # retrieve abstract from module
       AUTHOR         => 'DG <deg@cpan.org>') : ()),
);

