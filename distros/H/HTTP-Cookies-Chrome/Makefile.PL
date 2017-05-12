use ExtUtils::MakeMaker 6.65;

require 5.010;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'HTTP::Cookies::Chrome',
	'ABSTRACT'     => 'A subclass of HTTP::Cookies to handle Chrome',
	'VERSION_FROM' => 'lib/HTTP/Cookies/Chrome.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'DBI'           => '0',
		'DBD::SQLite'   => '1.32',
		'POSIX'         => '0',
		'HTTP::Cookies' => '0',
		},

	'TEST_REQUIRES' => {
		'Test::More'  => '0.95',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
			resources => {
				repository => {
					type => 'git',
					url  => 'https://github.com/briandfoy/HTTP-Cookies-Chrome.git',
					web  => 'https://github.com/briandfoy/HTTP-Cookies-Chrome',
				},
			},
		},

	clean  => { FILES    => q|HTTP-Cookies-Chrome-*| },

	);
