package JSON::TypeInference::Type::Atom;
use strict;
use warnings;

sub new {
  my ($class) = @_;
  return bless {}, $class;
}

sub signature {
  my ($self) = @_;
  return ref($self)->name;
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::TypeInference::Type::Atom - Base class for JSON value types

=head1 DESCRIPTION

C< JSON::TypeInference::Type::Atom > is a base class for JSON value type and provides some default implementations.

It also introduces a convention that the inherited type's signature is its name.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

