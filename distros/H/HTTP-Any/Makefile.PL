use strict;
use warnings;
use ExtUtils::MakeMaker;

my %pm = map { $_ => "\$(INST_LIB)/$_" } "HTTP/Any.pm", map { "HTTP/Any/$_.pm" } qw(Curl AnyEvent LWP);

WriteMakefile(
	NAME         => "HTTP::Any",
	ABSTRACT     => 'HTTP::Any - a common interface for HTTP clients (LWP, AnyEvent::HTTP, Curl)',
	AUTHOR       => '<kni@cpan.org>',
	LICENSE      => "perl",
	VERSION_FROM => "HTTP/Any.pm",
	PM           => \%pm,
);
