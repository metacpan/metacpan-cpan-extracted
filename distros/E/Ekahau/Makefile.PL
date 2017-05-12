use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'Ekahau',
	      VERSION_FROM    => 'Ekahau.pm',
	      EXE_FILES       => ['examples/ekahau-example.pl','examples/ekahau-events-example.pl'],
	      PREREQ_PM       => {
		XML::Simple            => 0,
		Digest::MD5            => 0,
		Socket                 => 0,
		IO::Socket::INET       => 0,
		IO::Select             => 0,
		Symbol                 => 0,
		bytes                  => 0,
 	        warnings               => 0,
		strict                 => 0,
		constant               => 0,
	      },
	    );
