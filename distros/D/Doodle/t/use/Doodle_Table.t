use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Table

=abstract

Doodle Table Class

=synopsis

  use Doodle::Table;

  my $self = Doodle::Table->new(
    name => 'users'
  );

=description

Database table representation. This class consumes the
L<Doodle::Table::Helpers> role.

=cut

use_ok "Doodle::Table";

ok 1 and done_testing;
