use 5.6.0;
use strict;
use warnings;
use ExtUtils::MakeMaker qw( WriteMakefile prompt );

my(%config) = (
	NAME		=> 'EAFDSS',
	VERSION_FROM	=> 'lib/EAFDSS.pm',
	LICENSE		=> 'lgpl',
	ABSTRACT_FROM	=> 'lib/EAFDSS.pm',
	AUTHOR		=> 'Hasiotis Nikos (hasiotis@gmail.com)',
	PREREQ_PM	=> {
		"Carp"              => 1.04,
		"Class::Base"       => 0.03,
		"Config::IniFiles"  => 2.38,
		"Digest::SHA1"      => 2.11,
		"IO::Socket::INET"  => 1.31,
		"Socket"            => 1.78,
		"Switch"            => 2.10,
	}
);

WriteMakefile(%config);

