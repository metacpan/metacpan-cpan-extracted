use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Column

=abstract

Doodle Column Class

=synopsis

  use Doodle::Column;

  my $self = Doodle::Column->new(%args);

=description

Table column representation.

=cut

use_ok "Doodle::Column";

ok 1 and done_testing;
