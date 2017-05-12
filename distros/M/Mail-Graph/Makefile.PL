use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Mail-Graph',
    'VERSION_FROM'	=> 'lib/Mail/Graph.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Math::BigInt		=> 1.68,
	GD::Graph		=> 1.33, 
	GD			=> 1.38, 
	GD::Text		=> 0.82, 
	Date::Calc		=> 5.0,
	Time::HiRes		=> 1.2,
	Compress::Zlib		=> 1.32,
	Test::Simple		=> 0.47, 
	}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
