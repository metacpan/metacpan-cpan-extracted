package JSON::TypeInference::Type::Object;
use strict;
use warnings;

sub new {
  my ($class, $properties) = @_;
  return bless { properties => $properties }, $class;
}

sub name {
  my ($class) = @_;
  return 'object';
}

sub properties {
  my ($self) = @_;
  return $self->{properties};
}

sub accepts {
  my ($class, $data) = @_;
  return ref($data) eq 'HASH';
}

sub signature {
  my ($self) = @_;
  my @sorted_keys = sort keys %{$self->properties};
  my @prop_signatures = map { join ':', $_, $self->properties->{$_}->signature } @sorted_keys;
  return sprintf 'object[%s]', join ', ', @prop_signatures;
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::TypeInference::Type::Object - JSON object type

=head1 DESCRIPTION

C< JSON::TypeInference::Type::Object > represents JSON object type.

It is a container type, and has some type parameters on each properties.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

