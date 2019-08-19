use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

if_not_exists

=usage

  $self->if_not_exists;

=description

Used with the C<create> method to denote that the table should be created only
if it doesn't already exist.

=signature

if_not_exists() : Table

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Table::Helpers;

can_ok "Doodle::Table::Helpers", "if_not_exists";

my $d = Doodle->new;
my $t = $d->table('users');

$t->if_not_exists;

is $t->data->{if_not_exists}, 1;

ok 1 and done_testing;
