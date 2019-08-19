use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Helpers

=abstract

Doodle Command Helpers

=synopsis

  use Doodle;

  my $self = Doodle->new;

  my $command = $self->create_schema(%args);

=description

Helpers for configuring Commands (command objects).

=cut

use_ok "Doodle::Table::Helpers";

ok 1 and done_testing;
