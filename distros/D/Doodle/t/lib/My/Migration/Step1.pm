package My::Migration::Step1;

use parent 'Doodle::Migration';

sub up {
  my ($self, $doodle) = @_;

  my $users = $doodle->table('users');
  $users->primary('id');
  $users->string('email');
  $users->create;
  $users->index(columns => ['email'])->unique->create;

  return $doodle;
}

sub down {
  my ($self, $doodle) = @_;

  my $users = $doodle->table('users');
  $users->delete;

  return $doodle;
}

1;
