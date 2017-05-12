package JSON::TypeInference::Type::Array;
use strict;
use warnings;

sub new {
  my ($class, $element_type) = @_;
  return bless { element_type => $element_type }, $class;
}

sub name {
  my ($class) = @_;
  return 'array';
}

# => Type
sub element_type {
  my ($self) = @_;
  return $self->{element_type};
}

sub signature {
  my ($self) = @_;
  return sprintf 'array[%s]', $self->element_type->signature;
}

sub accepts {
  my ($class, $data) = @_;
  return ref($data) eq 'ARRAY';
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::TypeInference::Type::Array - JSON array type

=head1 DESCRIPTION

JSON::TypeInference::Type::Array represents JSON array type.

It is a container type, and has a type parameter that called C<< element_type >>.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

