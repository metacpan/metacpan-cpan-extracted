use ExtUtils::MakeMaker;
my @opt=(
	 PREREQ_PM => { Test => 1, Event => '0.61', Ioctl => '0.8' },
	 VERSION_FROM => 'lib/Event/tcpsession.pm',
	 NAME => 'Event::tcp'
	);

WriteMakefile(@opt);
