use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	     => 'Finance::Bank::Cahoot',
              'AUTHOR'       => 'Jon Connell <cpan@figsandfudge.com>',
	      'VERSION_FROM' => 'lib/Finance/Bank/Cahoot.pm', # finds $VERSION
	      'PREREQ_PM'    => { 'Carp' => 0,
				  'Class::Accessor' => 0,
				  'Crypt::CBC' => 0,
				  'Crypt::DES_PP' => 0,
                                  'Date::Parse' => 0,
                                  'Digest::MD5' => 0,
                                  'English' => 0,
                                  'ExtUtils::MakeMaker' => 0,
                                  'File::Slurp' => 0,
                                  'File::Spec' => 0,
                                  'HTML::Form' => 0,
                                  'HTML::TableExtract' => 0,
                                  'IO::File' => 0,
                                  'Term::ReadLine' => 0,
                                  'Test::Deep' => 0,
                                  'Test::Exception' => 0,
                                  'Test::MockObject' => 0,
                                  'Test::More' => 0,
                                  'URI' => 0,
                                  'WWW::Mechanize' => 0
                                }
	     );
