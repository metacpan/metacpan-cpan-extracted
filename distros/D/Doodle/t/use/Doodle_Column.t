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

  my $self = Doodle::Column->new(
    name => 'id'
  );

=description

Table column representation. This class consumes the L<Doodle::Column::Helpers>
role.

=cut

use_ok "Doodle::Column";

ok 1 and done_testing;
