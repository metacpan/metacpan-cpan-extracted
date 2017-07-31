use 5.006_001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME           => 'Mail::DKIM',
	VERSION        => "0.42",
	PREREQ_PM      => {
			Crypt::OpenSSL::RSA => 0.24,
			Digest::SHA => 0,
			Mail::Address => 0,
			MIME::Base64 => 0,
			Net::DNS => 0,
			Test::Simple => 0,  # only needed for `make test'
		},
	ABSTRACT_FROM  => 'lib/Mail/DKIM.pm', # retrieve abstract from module
	AUTHOR         => 'Jason Long <jason@long.name>',
);
