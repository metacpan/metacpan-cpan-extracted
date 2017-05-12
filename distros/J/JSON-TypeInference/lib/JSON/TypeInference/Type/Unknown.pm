package JSON::TypeInference::Type::Unknown;
use strict;
use warnings;
use parent qw(JSON::TypeInference::Type::Atom);

sub name {
  my ($class) = @_;
  return 'unknown';
}

sub accepts {
  my ($class, $data) = @_;
  return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::TypeInference::Type::Unknown - unknown type

=head1 DESCRIPTION

C< JSON::TypeInference::Type::Unknown > is retuned if C<< JSON::TypeInference >> encountered a value that does not match any JSON types.

It looks like a value type, and so has no parameters.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

