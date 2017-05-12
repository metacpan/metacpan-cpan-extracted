use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => 'Device::WxM2',
	      AUTHOR => 'Mark Mabry (mmabry@cpan.org)',
	      VERSION_FROM => 'WxM2.pm',
	      PREREQ_PM => { Device::SerialPort => 0.09},
	      'dist' => { CI => 'cvs commit',
			  RCS_LABEL => 'cvs tag rel-$(VERSION_SYM)',
			  COMPRESS => 'gzip',
			  SUFFIX => 'gz'
			  },
	      );
