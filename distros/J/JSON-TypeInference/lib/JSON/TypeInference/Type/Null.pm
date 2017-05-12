package JSON::TypeInference::Type::Null;
use strict;
use warnings;
use parent qw(JSON::TypeInference::Type::Atom);

sub name {
  my ($class) = @_;
  return 'null';
}

sub accepts {
  my ($class, $data) = @_;
  return !defined($data);
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::TypeInference::Type::Null - JSON null type

=head1 DESCRIPTION

C< JSON::TypeInference::Type::Null > represents JSON null type.

It is a value type, and so has no parameters.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

