use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Table::Helpers

=abstract

Doodle Table Helpers

=synopsis

  use Doodle::Table;

  my $self = Doodle::Table->new(
    name => 'users'
  );

=description

Helpers for configuring Table classes.

=cut

use_ok "Doodle::Table::Helpers";

ok 1 and done_testing;
