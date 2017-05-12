use 5.010;
use v5.10;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'JSONP',
	VERSION_FROM	=> 'lib/JSONP.pm',
	LICENSE		=> 'perl_5',
	ABSTRACT_FROM		=> 'lib/JSONP.pm',
	AUTHOR			=> 'Anselmo Canfora <acanfora@cpan.org>',
	MIN_PERL_VERSION	=> 5.010,
	PREREQ_PM		=> {
		CGI		=> 0,
		JSON		=> 0,
		Want		=> 0,
		Time::HiRes	=> 0,
		Digest::SHA	=> 0,
		Scalar::Util	=> 0,
	},
);
