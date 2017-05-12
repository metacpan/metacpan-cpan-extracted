use ExtUtils::MakeMaker;
require 5.6.0;
WriteMakefile(
	'NAME' => 'Log::Dispatch::FileShared',
	($[ >= 5.005) ?
		(	'AUTHOR'   => 'Craig Manley',
			'ABSTRACT' => 'Object for logging to file.'
		) : (),
	'VERSION_FROM' => 'lib/Log/Dispatch/FileShared.pm',
	'PREREQ_PM' =>	{
						'Log::Dispatch'		=> '2.11',
						'Scalar::Util'		=> 0,
						'Time::HiRes'		=> 0,
						'Params::Validate'	=> 0,
					},
	'dist' => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
