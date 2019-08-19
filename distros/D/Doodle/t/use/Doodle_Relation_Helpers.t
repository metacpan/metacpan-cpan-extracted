use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Relation::Helpers

=abstract

Doodle Relation Helpers

=synopsis

  use Doodle::Relation;

  my $self = Doodle::Relation->new(
    column => 'profile_id',
    ftable => 'profiles',
    fcolumn => 'id'
  );

=description

Helpers for configuring Relation classes.

=cut

use_ok "Doodle::Relation::Helpers";

ok 1 and done_testing;
