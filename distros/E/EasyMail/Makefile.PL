require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'EasyMail',
	'VERSION_FROM'	=>	'EasyMail.pm',
	'PREREQ_PM'     => {
		'File::Basename' =>'0',
		'MIME::Base64'=>'0',
		'Time::Local'=>'0',
		'IO::Socket::INET'=>'0',
		'FileHandle'=>'0',
		'Encode'=>'0'
 	},
	dist		=>	{ COMPRESS => 'gzip -9f', SUFFIX => '.gz'}
);

