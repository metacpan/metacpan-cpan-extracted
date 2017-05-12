require 5.004 ;
use ExtUtils::MakeMaker 5.16 ;
use Config ;

WriteMakefile(
	NAME            => 'Logger::Fq',
	VERSION_FROM    => 'Fq.pm',
	OBJECT          => 'logger-fq.o',
	LIBS            => "$ENV{LDFLAGS} -lfq",
	OPTIMIZE        => $ENV{'OPTIMIZE'},
	PREREQ_PM       => {},
);

