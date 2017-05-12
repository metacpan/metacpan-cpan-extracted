package JSON::TypeInference::Type::Maybe;
use strict;
use warnings;

use List::Util qw(any);

# ArrayRef[JSON::TypeInference::Type] => Bool
sub looks_like_maybe {
  my ($class, $candidate_types) = @_;
  return (scalar(@$candidate_types) == 2) && any { $_->isa('JSON::TypeInference::Type::Null') } @$candidate_types;
}

sub new {
  my ($class, $type) = @_;
  return bless { type => $type }, $class;
}

sub name {
  my ($class) = @_;
  return 'maybe';
}

sub type {
  my ($self) = @_;
  return $self->{type};
}

sub signature {
  my ($self) = @_;
  return sprintf 'maybe[%s]', $self->type->signature;
}

sub accepts {
  my ($class, $data) = @_;
  return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::TypeInference::Type::Maybe - maybe type

=head1 DESCRIPTION

C< JSON::TypeInference::Type::Maybe > represents a possibility whether a value type exists or not.

The type consists of a value type and C<< JSON::TypeInference::Type::Null >>.

It is a container type, and has a type parameter.

=head1 METHODS

=over 4

=item C<< looks_like_maybe($candidate_types: ArrayRef[JSON::TypeInference::Type]); # => Bool >>

Returns whether the given types conform to C< JSON::TypeInference::Type::Maybe > structure.

=back

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=head1 SEE ALSO

L<JSON::TypeInference::Type::Null>

=cut

