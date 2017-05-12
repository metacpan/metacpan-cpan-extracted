# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node;

use Moose::Role;

requires qw/print/;

=head1 NAME

Erlang::Parser::Node - performed by all AST nodes

=head1 SYNOPSIS

    package Erlang::Parser::Node::Quux;

    use Moose;
    with 'Erlang::Parser::Node';

=head1 DESCRIPTION

L<Erlang::Parser::Node> is the L<Moose::Role> performed by all L<Erlang::Parser> AST nodes.  So far, it requires one definition to be provided by the class performing it; C<print>, which takes a filehandle, and pretty-prints the node contents (in Erlang) to it.

It provides no (!) function of its own, other than ensuring all AST nodes know how to pretty-print themselves, and providing a type-name in the Moose type hierarchy; see L<Moose::Util::TypeConstraints>.

=cut

1;

# vim: set sw=4 ts=4:
