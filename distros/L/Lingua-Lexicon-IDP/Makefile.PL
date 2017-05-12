use CPAN::MakeMaker;
WriteMakefile(
	      'NAME'	     => 'Lingua::Lexicon::IDP',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => 'OOP interface for parsing translation files from the Internet Dictionary Project') : (),
	      'VERSION_FROM' => 'lib/Lingua/Lexicon/IDP.pm',
	      'PREREQ_PM'    => {
				 File::Spec::Functions => '1.1',
				 IO::File              => '0',
				 Memoize               => '0',
				 Carp                  => '0',

				 # For testing
				 Test::More            => '0',
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
	     );
