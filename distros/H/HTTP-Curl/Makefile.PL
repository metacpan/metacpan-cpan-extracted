use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
	NAME         => "HTTP::Curl",
	ABSTRACT     => 'HTTP interface for Net::Curl (clone of HTTP::Any::Curl)',
	AUTHOR       => '<kni@cpan.org>',
	LICENSE      => "perl",
	VERSION_FROM => "HTTP/Curl.pm",
	PREREQ_PM    => { 'Net::Curl' => 0.29 },
	PM           => { 'HTTP/Curl.pm' => '$(INST_LIB)/HTTP/Curl.pm' },
);
