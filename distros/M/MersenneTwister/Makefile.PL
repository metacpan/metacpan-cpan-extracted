require 5.004 ;
use ExtUtils::MakeMaker 5.16 ;
use Config ;

WriteMakefile(
	NAME		=> 'Rand::MersenneTwister',
	VERSION_FROM	=> 'MersenneTwister.pm',
	);
