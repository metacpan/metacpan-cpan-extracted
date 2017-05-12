package JSON::TypeInference::Type::Boolean;
use strict;
use warnings;
use parent qw(JSON::TypeInference::Type::Atom);

use Types::Serialiser;

sub name {
  my ($class) = @_;
  return 'boolean';
}

sub accepts {
  my ($class, $data) = @_;
  return Types::Serialiser::is_bool($data);
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::TypeInference::Type::Boolean - JSON boolean type

=head1 DESCRIPTION

C< JSON::TypeInference::Type::Boolean > represents JSON boolean type.

It is a value type, and so has no parameters.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

