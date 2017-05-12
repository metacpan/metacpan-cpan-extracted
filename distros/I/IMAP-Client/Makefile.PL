use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IMAP::Client',
    'VERSION_FROM' => 'lib/IMAP/Client.pm', # finds $VERSION
    'PREREQ_PM'  => {'IO::Socket::SSL' => '0',
		     'IO::Socket::INET' => '0',
		     'MIME::Base64' => '0',
		     'URI::imap' => '0',
		     'URI::Escape' => '0',
		 },
);
