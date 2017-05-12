# Copyright 2011-2016 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

use strict;
use warnings;

use ExtUtils::MakeMaker;

my $YAPP_COMMAND = "(yapp -v -m 'Erlang::Parser::Parser' -o lib/Erlang/Parser/Parser.pm lib/Erlang/Parser/Parser.yp)";
`$YAPP_COMMAND`;

WriteMakefile(
	NAME          => 'Erlang::Parser',
	AUTHOR        => q{Yuki Izumi <anneli@cpan.org>},
	ABSTRACT_FROM => 'lib/Erlang/Parser.pm',
	VERSION_FROM  => 'lib/Erlang/Parser.pm',
	PL_FILES      => {},
	LICENSE       => 'perl',
	PREREQ_PM     => {qw(
	                     Parse::Lex   2.20
	                     Parse::Yapp  0
	                     Test::Simple 0
	                     Test::More   0
	                     Moose        0
	                 )},
	dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	clean         => { FILES => 'Erlang-Parser-*' },
);

sub MY::postamble {
	return <<"MAKE_FRAG";
lib/Erlang/Parser/Parser.pm: lib/Erlang/Parser/Parser.yp
	$YAPP_COMMAND
MAKE_FRAG
}

# vim: set sw=4 ts=4:
