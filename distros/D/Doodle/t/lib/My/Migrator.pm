package My::Migrator;

use parent 'Doodle::Migrator';

sub namespace {
  return 'My::Migration';
}

1;
