# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::String;

use Moose;
with 'Erlang::Parser::Node';

has 'string' => (is => 'rw', required => 1, isa => 'Str');

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	my $string = $self->string;
	$string =~ s/\\/\\\\/g;
	$string =~ s/"/\\"/g;

	print $fh "\"$string\"";
}

sub _append {
	my ($self, $str) = @_;
	$self->string($self->string . $str);
	$self;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::String - a string

=head1 DESCRIPTION

Just a string literal.

=head2 Accessors

=over 4

=item C<string>

The string.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	"I ain't buyin' the Hone Avenue one for like, above 580."

=cut

1;

# vim: set sw=4 ts=4:
