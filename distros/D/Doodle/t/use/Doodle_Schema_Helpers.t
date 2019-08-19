use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Schema::Helpers

=abstract

Doodle Schema Helpers

=synopsis

  use Doodle::Schema;

  my $self = Doodle::Schema->new(
    name => 'app'
  );

=description

Helpers for configuring Schema classes.

=cut

use_ok "Doodle::Schema::Helpers";

ok 1 and done_testing;
