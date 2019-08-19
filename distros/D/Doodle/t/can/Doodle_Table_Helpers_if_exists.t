use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

if_exists

=usage

  $self->if_exists;

=description

Used with the C<delete> method to denote that the table should be deleted only
if it already exists.

=signature

if_exists() : Table

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Table::Helpers;

can_ok "Doodle::Table::Helpers", "if_exists";

my $d = Doodle->new;
my $t = $d->table('users');

$t->if_exists;

is $t->data->{if_exists}, 1;

ok 1 and done_testing;
