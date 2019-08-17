use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create_relation

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $r = $t->relation('profile_id', 'profiles', 'id');

  my $command = $r->create;

  $self->create_relation($command);

  # alter table [users] add constraint fkey_users_profile_id_profiles_id
  # foreign key (profile_id) references profiles (id)

=description

Returns the SQL statement for the create relation command.

=signature

create_relation(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Mssql;

use_ok 'Doodle::Grammar::Mssql', 'create_relation';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mssql->new;
my $t = $d->table('users');
my $r = $t->relation('profile_id', 'profiles', 'id');

my $command = $r->create;

my $sql = $g->create_relation($command);

isa_ok $g, 'Doodle::Grammar::Mssql';
isa_ok $command, 'Doodle::Command';

is $sql, qq{alter table [users] add constraint fkey_users_profile_id_profiles_id foreign key (profile_id) references profiles (id)};

ok 1 and done_testing;
