require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
	'AUTHOR'        => 'FOOLFISH', 
	'NAME'          => 'EasyDBAccess',
	'VERSION_FROM'	=>	'EasyDBAccess.pm',
    	'PREREQ_PM'     => {
		'DBD::mysql'=> '0',
    		'DBI'=>'0',
    		'Encode'=>'0',
    		'FileHandle'=>'0'
    	},
	dist		=>	{ COMPRESS => 'gzip -9f', SUFFIX => '.gz'}
);

