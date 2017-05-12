package JSON::TypeInference::Type::Union;
use strict;
use warnings;

sub new {
  my ($class, @types) = @_;
  return bless { _types => \@types }, $class;
}

sub name {
  my ($class) = @_;
  return 'union';
}

sub types {
  my ($self) = @_;
  return $self->{_types};
}

sub accepts {
  my ($class, $data) = @_;
  return 0;
}

sub signature {
  my ($self) = @_;
  my @signatures = map { $_->signature } @{$self->types};
  return join '|', sort @signatures;
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::TypeInference::Type::Union - union type

=head1 DESCRIPTION

C< JSON::TypeInference::Type::Union > consists of one or more value types.

C< JSON::TypeInference::Type::Union > represents a possibility of actual types from inference.

It is a container type, and has some type parameters.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

