use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	      NAME                => 'IPC::Queue::Duplex',
	      AUTHOR              => q{Ashish Gulhati <ipc-qd at hash.neo.tc>},
	      VERSION_FROM        => 'lib/IPC/Queue/Duplex.pm',
	      ABSTRACT_FROM       => 'lib/IPC/Queue/Duplex.pm',
              LICENSE             => 'Artistic_2_0',
	      PL_FILES            => {},
	      TEST_REQUIRES       => {
				      'Test::More' => 0,
				     },
	      PREREQ_PM           => {
				      'File::Temp', => 0,
				      'File::Copy', => 0
				     },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'IPC-Queue-Duplex-*' },
	     );
