use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

unique

=usage

  my $unique = $self->unique;

=description

Denotes that the index should be created and enforced as unique and returns
itself.

=signature

unique() : Index

=type

method

=cut

# TESTING

use Doodle::Index;

can_ok "Doodle::Index", "unique";

ok 1 and done_testing;
