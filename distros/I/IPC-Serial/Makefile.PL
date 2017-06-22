use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'IPC::Serial',
	      AUTHOR              => q{Ashish Gulhati <ipc-serial at hash.neo.tc>},
	      VERSION_FROM        => 'lib/IPC/Serial.pm',
	      ABSTRACT_FROM       => 'lib/IPC/Serial.pm',
	      ($ExtUtils::MakeMaker::VERSION >= 6.64
	       ? ('LICENSE'=> 'artistic_2')
	       : ()),
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM => {
			    'Device::SerialPort' => 0,
			    'Digest::MD5' => 0
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'IPC-Serial-*' },
	     );
