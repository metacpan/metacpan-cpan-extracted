# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Roguelike-Caves.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Games::Roguelike::Caves') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $map = generate_cave(50,20);
is(ref $map, 'ARRAY', 'returns array');
is (scalar @$map, 20, '20 rows');
is (scalar @{$map->[10]}, 50, '50 cols');

outline_walls ($map);
is (scalar @$map, 20, 'still 20 rows');
is (scalar @{$map->[10]}, 50, 'still 50 cols');
