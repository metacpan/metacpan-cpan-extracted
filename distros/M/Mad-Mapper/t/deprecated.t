use Mojo::Base -strict;
use Test::More;

plan skip_all => 'Mojo::Pg is required' unless eval 'require Mojo::Pg;1';

eval <<'CODE' or die "package user failed: $@";
package MyApp::Model::User;
use Mad::Mapper -base;
pk 'id';
col name  => 'Bruce';
col email => 'bruce@wayneenterprise.com';
1;
CODE

package main;
my $user = MyApp::Model::User->new(db => Mojo::Pg::Database->new, id => 42);
is($user->table, 'users', 'table');

is_deeply([$user->columns], [qw( name email )], 'columns');

is_deeply([$user->_find_sst], ['SELECT id,name,email FROM users WHERE id=?', qw( 42 )], 'find');

is_deeply([$user->expand_sst('%t \\\%t')], ['users \%t'],     'escaped');
is_deeply([$user->expand_sst('%pc')],      ['id,name,email'], 'pc');

is_deeply([$user->expand_sst('%c.x from %t.x')],  ['x.name,x.email from users x'],      'alias x');
is_deeply([$user->expand_sst('%pc.x from %t.x')], ['x.id,x.name,x.email from users x'], 'alias x');

is_deeply([$user->_insert_sst],
  ['INSERT INTO users (name,email) VALUES (?,?) RETURNING id', qw( Bruce bruce@wayneenterprise.com )], 'insert');

is_deeply([$user->_update_sst],
  ['UPDATE users SET name=?,email=? WHERE id=?', qw( Bruce bruce@wayneenterprise.com 42 )], 'update');

done_testing;
