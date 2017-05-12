package FBP::Children;

=pod

=head1 NAME

FBP::Children - Role for objects which can contain other objects

=head1 METHODS

=cut

use Mouse::Role;

our $VERSION = '0.41';

has children => (
	is      => 'ro',
	isa     => "ArrayRef[FBP::Object]",
	default => sub { [ ] },
);

sub find {
	my $self  = shift;
	my @where = @_;
	my @queue = @{ $self->children };
	my @found = ( );
	while ( @queue ) {
		my $object = shift @queue;

		# First add any children to the queue so that we
		# will process the model in depth first order.
		if ( $object->does('FBP::Children') ) {
			unshift @queue, @{ $object->children };
		}

		# Filter to see if we want it
		my $i = 0;
		while ( my $method = $where[$i] ) {
			if ( $method eq 'isa' ) {
				last unless $object->isa($where[$i + 1]);
			} else {
				last unless $object->can($method);
				my $value = $object->$method();
				unless ( defined $value and $value eq $where[$i + 1] ) {
					last;
				}
			}
			$i += 2;
		}

		# If we hit the final $i += 2 we have found a match
		unless ( defined $where[$i] ) {
			push @found, $object;
		}
	}

	return @found;
}

=pod

=head2 find_first

  my $dialog = $object->find_first(
      isa  => 'FBP::Dialog',
      name => 'MyDialog1',
  );

The C<find_first> method implements a generic depth-first search of the object
model. It takes a series of condition pairs that are used in the provided order
(allowing the caller to tune the way in which the filter is done).

Each pair is treated as a method + value set. First, the object is checked to
ensure it has that method, and then the method output is string-matched to the
output of the method via C<$object-E<gt>$method() eq $value>.

The special condition "isa" is applied as C<$object-E<gt>isa($value)> instead.

Returns the first object located that matches the provided criteria,
or C<undef> if nothing in the object model matches the conditions.

=cut

sub find_first {
	my $self  = shift;
	my @where = @_;
	my @queue = ( $self );
	while ( @queue ) {
		my $object = shift @queue;

		# First add any children to the queue so that we
		# will process the model in depth first order.
		if ( $object->does('FBP::Children') ) {
			unshift @queue, @{ $object->children };
		}

		# Filter to see if we want it
		my $i = 0;
		while ( my $method = $where[$i] ) {
			if ( $method eq 'isa' ) {
				last unless $object->isa($where[$i + 1]);
			} else {
				last unless $object->can($method);
				my $value = $object->$method();
				last unless defined $value;
				last unless $value eq $where[$i + 1];
			}
			$i += 2;
		}

		# If we hit the final $i += 2 we have found a match
		unless ( defined $where[$i] ) {
			return $object;
		}
	}

	return undef;
}

no Mouse::Role;

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FBP>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
