use ExtUtils::MakeMaker;
use Config;

require 5.006001;

WriteMakefile(
	      NAME		=> 'Devel::CallStack',
	      VERSION_FROM	=> 'lib/Devel/CallStack.pm',
	      PREREQ_PM		=>
	      	{
		    'Test::More'	=> 0,
		},
	      PL_FILES		=> {},
	      dist		=> {
		  COMPRESS => 'gzip',
		  SUFFIX   => 'gz' },
	      );
