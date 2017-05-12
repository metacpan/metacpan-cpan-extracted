# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MetaStore.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 20;
use Data::Dumper;
BEGIN { use_ok('MetaStore::Links') }
my %record =
  ( 0 => [ 1 .. 5 ], 1 => [ 10 .. 15 ], 2 => [ 20 .. 25 ], 3 => [ 1, 10, 20 ] );
ok( my $lnk1 = ( new MetaStore::Links:: { id => 12, attr => \%record } ),
    "create link obj" );
is_deeply(
    [ sort { $a <=> $b } @{ $lnk1->types } ],
    [ sort { $a <=> $b } keys %record ],
    "get types"
);
is_deeply( $lnk1->attr, \%record, "check attr struct" );
is_deeply( $lnk1->by_type(1), [ 10, 11, 12, 13, 14, 15 ], "test by_type(1)" );
is_deeply( $lnk1->by_type(0), [ 1, 2, 3, 4, 5 ], "test by_type(0)" );
is_deeply(
    $lnk1->by_type(),
    [ 1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15, 20, 21, 22, 23, 24, 25 ],
    "test by_type()"
);
ok( !defined( $lnk1->add_by_type() ), "test empty args add_by_type" );
is_deeply(
    $lnk1->add_by_type( 0, 1, 2, 3, 4, 5, 6, 10 ),
    [ 1, 2, 3, 4, 5, 6, 10 ],
    "add by type 0"
);
is_deeply( $lnk1->by_type(0), [ 1, 2, 3, 4, 5, 6, 10 ], "get by type 0" );

is_deeply( $lnk1->by_type(),
    [ 1, 2, 3, 4, 5, 6, 10, 11, 12, 13, 14, 15, 20, 21, 22, 23, 24, 25 ],
    , "test by_type()" );
##print Dumper($lnk1->attr());
is_deeply( $lnk1->by_type(3), $record{3}, "by_type(3)" );
is_deeply( $lnk1->set_by_type(),  [], 'set_by_type() with  empty list' );
is_deeply( $lnk1->set_by_type(3), [], 'set_by_type(3) with  empty list' );
is_deeply(
    $lnk1->set_by_type( 0, 1, 3, 4, 5, 8 ),
    [ 1, 3, 4, 5, 8 ],
    "check set_by_type(0)"
);

is_deeply(
    $lnk1->delete_by_type(0),
    [ 1, 3, 4, 5, 8 ],
    "delete_by_type(0) with empty list"
);
is_deeply( $lnk1->delete_by_type( 0, 5 .. 11 ), [ 1, 3, 4 ], "Check delete" );
is_deeply( $lnk1->empty,   [], "check empty call" );
is_deeply( $lnk1->by_type, [], "check by_type after empty" );
is_deeply(
    [ sort { $a <=> $b } @{ $lnk1->types } ],
    [],
    "types after empty"
);

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

