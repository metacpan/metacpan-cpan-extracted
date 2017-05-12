use Test::More;
use strict;
use warnings;

use Test::DBIx::Class qw(:resultsets);

fixtures_ok 'basic'
  => 'installed the basic fixtures from configuration files';

my $user;
ok $user = User->create({ name => 'herp', password => 'derp' }), "found our user " . $user->name;
ok $user->password('ass');
ok $user->update, "updated pass";
ok ! $user->check_password('derp'), "old pass doesn't work";
ok $user->check_password('ass'), "password checks out";
ok $user->has_role('user'), $user->name . " has role user";
ok !$user->has_role('admin'), $user->name . " does NOT have the admin role";

done_testing;
