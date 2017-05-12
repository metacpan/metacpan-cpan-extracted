use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Finance::Bank::Natwest',
    'NO_META'      => 1,
    'VERSION_FROM' => 'lib/Finance/Bank/Natwest.pm', # finds $VERSION
    'PREREQ_PM'    => { 'Test::Exception' => 0,
                        'HTML::TokeParser' => 0,
		        'Carp' => 0,
		        'LWP::UserAgent' => 0,
		        'Digest::MD5' => 0,
		        'Test::More' => 0,
		        'URI' => 0,
		        'Test::MockObject' => 0,
		        'Exporter' => 0,
		      },
);
