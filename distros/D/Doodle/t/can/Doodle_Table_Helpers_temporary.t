use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

temporary

=usage

  my $temporary = $self->temporary;

=description

Denotes that the table created should be a temporary one.

=signature

temporary() : Table

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Table::Helpers;

can_ok "Doodle::Table::Helpers", "temporary";

my $d = Doodle->new;
my $t = $d->table('users');

$t->temporary;

is $t->data->{temporary}, 1;

ok 1 and done_testing;
