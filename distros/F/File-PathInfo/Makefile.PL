if( $^O=~/mswin32|cygwin/i ){ die("Unsupported OS."); }

use ExtUtils::MakeMaker;
WriteMakefile(
	NAME				=> "File::PathInfo",
	VERSION_FROM	=> 'lib/File/PathInfo.pm',
   ABSTRACT_FROM  => 'lib/File/PathInfo.pod',

	PREREQ_PM 		=> {
		'Time::Format' => '0.01',
      'Smart::Comments' => '0',
		'Cwd'	=> '0.1',
	},
   LICENSE => 'perl',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',
);
