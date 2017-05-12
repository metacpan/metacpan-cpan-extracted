# Copyright 2011-2012 Yuki Izumi. ( anneli AT cpan DOT org )
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Erlang::Parser::Node::WhenList;

use Moose;
with 'Erlang::Parser::Node';

has 'groups' => (is => 'rw', default => sub {[]}, isa => 'ArrayRef[ArrayRef[Erlang::Parser::Node]]');
has 'exprs'  => (is => 'rw', default => sub {[]}, isa => 'ArrayRef[Erlang::Parser::Node]');

sub _append {
	my ($self, $expr) = @_;
	push @{$self->exprs}, $expr;
	$self;
}

sub _group () {
	my $self = shift;
	push @{$self->groups}, $self->exprs if @{$self->exprs};
	$self->exprs([]);
	$self;
}

sub print {
	my ($self, $fh, $depth) = @_;
	$depth ||= 0;

	if (@{$self->groups}) {
		print $fh 'when ';
		my $first = 1;
		foreach (@{$self->groups}) {
			if ($first) { $first = 0 } else { print $fh '; ' }

			my $infirst = 1;
			foreach (@$_) {
				if ($infirst) { $infirst = 0 } else { print $fh ', ' }
				$_->print($fh, $depth);
			}
		}
		print $fh ' ';
	}
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Erlang::Parser::Node::WhenList - a guard sequence

=head1 DESCRIPTION

Used to restrict the circumstances under which a pattern match will match;
comprised of guards separated by semi-colons, each which is comprised of
several guard expressions separated by commas. The guard sequence as a whole
passes if all guard expressions in any guard pass.

=head2 Accessors

=over 4

=item C<groups>

A list of a list of L<Erlang::Parser::Node>s; each individual list of nodes is
a guard (and each node a guard expression).

=item C<exprs>

Used only during construction of the guard sequence; should be empty after
parsing is complete.

=back

=head2 Methods

=over 4

=item C<print>

Pretty-prints the node to its filehandle argument.

=back

=head1 EXAMPLE

	when is_bool(X), is_bool(Y); X < Y

=cut

1;

# vim: set sw=4 ts=4:
