use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete_relation

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $r = $t->relation('profile_id', 'profiles', 'id');

  my $command = $r->delete;

  $self->delete_relation($command);

  # alter table `users` drop constraint `fkey_users_profile_id_profiles_id`

=description

Returns the SQL statement for the delete relation command.

=signature

delete_relation(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Mysql;

use_ok 'Doodle::Grammar::Mysql', 'delete_relation';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $r = $t->relation('profile_id', 'profiles', 'id');

my $command = $r->delete;

my $sql = $g->delete_relation($command);

isa_ok $g, 'Doodle::Grammar::Mysql';
isa_ok $command, 'Doodle::Command';

is $sql, qq{alter table `users` drop constraint `fkey_users_profile_id_profiles_id`};

ok 1 and done_testing;
