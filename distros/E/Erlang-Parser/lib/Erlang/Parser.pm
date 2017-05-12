# Copyright 2011-2016 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser;

use strict;
use warnings;

use Erlang::Parser::Lexer;
use Erlang::Parser::Parser;

sub parse {
	my $class = shift;

	my $parser = new Erlang::Parser::Parser;
	my $lexerfn = Erlang::Parser::Lexer->lex(@_);
	@{$parser->YYParse(yylex => $lexerfn, yyerror => \&error)};
}

sub error {
	print STDERR "Parse error!\n";

	if ($_ && $_[0] && ref($_[0]) eq 'ARRAY') {
		print STDERR "Failed token was ", $_[0]->YYCurtok;
		print STDERR ", value ", $_[0]->YYCurval;
		print STDERR ", expected ", join(',', $_[0]->YYExpect);
		print STDERR ".\n";
	} else {
		print STDERR "Empty object tree!\n";
		die("Can not continue w/o object tree!\n");
	}
}

=head1 NAME

Erlang::Parser - Erlang source code parser

=head1 VERSION

This document describes version 0.6 of Erlang::Parser released 2016-06-20.

=cut

our $VERSION = '0.6';

=head1 SYNOPSIS

	use Erlang::Parser;

	# Parse the code found in DATA; return all root-level nodes.
	my @nodes = Erlang::Parser->parse(\*DATA);

	# Each object in @nodes implements the Erlang::Parser::Node role, which
	# is the function 'print'. It takes one argument, the filehandle to
	# pretty-print to.
	$_->print(*STDOUT) for @nodes;

	# Use the accessors of each node type to get at the innards:
	my ($directive, $def) = Erlang::Parser->parse(<<ERL);
		-export([my_fun/2]).
		my_fun(X, Y) -> X + Y.
	ERL

	# Have fun!

=head1 DESCRIPTION

L<Erlang::Parser> is an Erlang source code parser.	You can feed C<parse()> any
fragment of code which would be acceptable at the top-level of a C<.erl> file,
including a full file.

=head2 Methods

=over 4

=item C<parse>

Parses an top-level Erlang declarations from a string, list of lines of code,
or filehandle.	Returns a list of top-level nodes.

	my @nodes = Erlang::Parser->parse(
		'myfun(X) -> X + X.',
		'myfun(X, Y) -> X + Y.',
	);

=item C<error>

Called when an error occurs. Reports based on the parser given as the first
argument.

=back

=head1 AUTHOR

Yuki Izumi (anneli@cpan.org)

=head1 SUPPORT

You can find documentation for L<Erlang::Parser> with the perldoc command.

	perldoc Erlang::Parser

Other places of interest:

=over 4

=item * GitHub: source code repository

L<http://github.com/kivikakk/Erlang--Parser>

=item * GitHub: open an issue

L<http://github.com/kivikakk/Erlang--Parser/issues>

=item * Twitter: the author

L<http://twitter.com/kivikakk>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2016, Yuki Izumi C<< <ANNELI@CPAN.org> >>. All rights
reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;

# vim: set sw=4 ts=4:
