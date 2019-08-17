use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Relation

=abstract

Doodle Relation Class

=synopsis

  use Doodle::Relation;

  my $self = Doodle::Relation->new(%args);

=description

Table relation representation.

=cut

use_ok "Doodle::Relation";

ok 1 and done_testing;
