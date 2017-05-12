use 5.008000;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME              => 'HTTP::Cookies::PhantomJS',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/HTTP/Cookies/PhantomJS.pm',
	PREREQ_PM         => { 
		'HTTP::Cookies'       => 0,
		'HTTP::Headers::Util' => 0,
		'HTTP::Request'       => 0,
		'HTTP::Response'      => 0,
		'HTTP::Date'          => 0,
	},
	BUILD_REQUIRES    => {
		'Test::More' => 0.88,
		'File::Temp' => 0,
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => { 
		resources => {repository => 'https://github.com/olegwtf/p5-HTTP-Cookies-PhantomJS'},
	},
	($] >= 5.005 ?
	(ABSTRACT_FROM  => 'lib/HTTP/Cookies/PhantomJS.pm',
	AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
