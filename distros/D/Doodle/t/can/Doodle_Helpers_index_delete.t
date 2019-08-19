use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

index_delete

=usage

  my $command = $self->index_delete(%args);

=description

Register and return an index_delete command.

=signature

index_delete(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Helpers;

can_ok "Doodle::Helpers", "index_delete";

my $d = Doodle->new;

my $t = $d->table('users');
my $i = $t->index(columns => ['profile_id']);
my $c = $d->index_delete(table => $t, indices => [$i]);

is $c->name, 'delete_index';
is $c->indices->first, $i;
is $c->indices->first->table->name, 'users';

ok 1 and done_testing;
