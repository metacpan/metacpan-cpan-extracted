use 5.010;
use v5.10;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME				=> 'JSONP',
	AUTHOR				=> 'Anselmo Canfora <acanfora@cpan.org>',
	LICENSE				=> 'perl_5',
	MIN_PERL_VERSION	=> 5.016,
	VERSION_FROM		=> 'lib/JSONP.pm',
	ABSTRACT_FROM		=> 'lib/JSONP.pm',
	PREREQ_PM			=> {
		CGI					=> 0,
		JSON				=> 0,
		Want				=> 0,
		'Time::HiRes'		=> 0,
		'Digest::SHA'		=> 0,
		'Scalar::Util'		=> 0,
	},
	META_MERGE			=> {
		"meta-spec"			=> { version => 2 },
		resources			=> {
			repository			=> {
				type => 'git',
				url => 'https://github.com/ANSI-C/JSONP.git',
				web => 'https://github.com/ANSI-C/JSONP',
			},
		},

	},
);
