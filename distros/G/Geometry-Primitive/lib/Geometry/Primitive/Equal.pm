package Geometry::Primitive::Equal;
use Moose::Role;

requires 'equal_to';

sub not_equal_to {
    my ($self, $other) = @_;
    not $self->equal_to($other);
}

no Moose;
1;
__END__
=head1 NAME

Geometry::Primitive::Equal - Equality Role

=head1 DESCRIPTION

Geometry::Primitive::Equal is a Moose role for equality.

=head1 SYNOPSIS

  with 'Geometry::Primitive::Equal';

  sub equal_to {
      my ($self, $other) = @_;
      
      # compare and return!
  }

=head1 METHODS

=head2 equal_to

Implement this.

=head2 not_equal_to

Provided you implement C<equal_to>, this will be implemented for you!

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.