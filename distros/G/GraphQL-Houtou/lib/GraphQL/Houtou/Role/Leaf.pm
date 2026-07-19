package GraphQL::Houtou::Role::Leaf;

use 5.014;
use strict;
use warnings;

use Role::Tiny;

use GraphQL::Houtou::Error ();

# Runtime completion helpers for scalar-like leaf values.

sub _complete_value {
  my ($self, $context, $nodes, $info, $path, $result) = @_;
  my $serialised = eval { $self->perl_to_graphql($result) };
  my $error = $@;

  die GraphQL::Houtou::Error->new(
    message => "Expected a value of type '@{[$self->to_string]}' but received: '$result'.\n$error"
  ) if $error;

  return +{ data => $serialised };
}

1;
