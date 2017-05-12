use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Games::DungeonMaker',
    'VERSION_FROM'	=> 'lib/Games/DungeonMaker.pm', # finds $VERSION
    'PREREQ_PM'		=> {Test::More => 0.11},
    'INC'		=> '-I/usr/local/include',
    'LIBS'		=> ['-ldungeonmaker -lstdc++'],
    'OBJECT'		=> 'DungeonMaker_wrap.o',
	'CC'	=> 'g++',
    ($] >= 5.005 ?
		(ABSTRACT_FROM	=> 'lib/Games/DungeonMaker.pod',
		AUTHOR		=> 'Aaron Dalton <aaron@daltons.ca>') : ()),
);

