use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Games::Quake::Stats',
    VERSION_FROM      => 'lib/Games/Quake/Stats.pm', # finds $VERSION
    PREREQ_PM         => {Test::More => 0,
			  GD::Graph::hbars => 0,
			  GD::Graph::colour => 0,}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Games/Quake/Stats.pm', # retrieve abstract from module
       AUTHOR         => 'Matthias Beebe <matthiasbeebe@gmail.com>') : ()),
);
