package My::Migration::Step2;

use parent 'Doodle::Migration';

sub up {
  my ($self, $doodle) = @_;

  my $users = $doodle->table('users');
  $users->string('first_name')->create;
  $users->string('last_name')->create;

  return $doodle;
}

sub down {
  my ($self, $doodle) = @_;

  my $users = $doodle->table('users');
  $users->string('first_name')->delete;
  $users->string('last_name')->delete;

  return $doodle;
}

1;
