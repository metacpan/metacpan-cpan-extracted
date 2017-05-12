
use strict;
use Test;

plan tests => 5;

use Games::RolePlay::MapGen;

$Games::RolePlay::MapGen::known_opts{test_arg}   = undef; # this is a hack to allow the test options for the tests
$Games::RolePlay::MapGen::known_opts{test_arg_2} = undef;

START_WITH_HREF: {
    my $map = new Games::RolePlay::MapGen({ test_arg => 2 });

    $map->set_test_arg_2(3);

    ok( $map->{test_arg},   2 );
    ok( $map->{test_arg_2}, 3 );
}

START_WITH_ARRAY: {
    my $map = new Games::RolePlay::MapGen( test_arg => 2 );

    $map->set_test_arg_2(3);

    ok( $map->{test_arg},   2 );
    ok( $map->{test_arg_2}, 3 );
}

BORKED: {
    my $map = new Games::RolePlay::MapGen;

    eval '$map->set_stupid_borked_arg( 9 )';
    ok($@ ne "");
}
