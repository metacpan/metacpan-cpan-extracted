use Test::More tests => 48;
use FLAT;

my $fa = FLAT::FA->new;

is( ref $fa,
    "FLAT::FA",
    "blessed reference returned" );

is_deeply(
    [ $fa->get_states ],
    [],
    "initially no states" );

is( $fa->num_states,
    0,
    "initially no states" );

ok( ! $fa->is_state(0),
    "initially no states" );

my @s = $fa->add_states(5);
is( scalar(@s),
    5,
    "add_states returns list" );

is( $fa->num_states,
    5,
    "add_states adds states" );

is_deeply(
    [ sort $fa->get_states ],
    [ sort @s ],
    "add_states add states" );

for (@s) {
    ok( $fa->is_state($_),
        "add_states returns valid states" );
}

my $del = pop @s;
$fa->delete_states($del);

is( $fa->num_states,
    4,
    "delete_states deletes states" );

is_deeply(
    [ sort $fa->get_states ],
    [ sort @s ],
    "delete_states deletes states" );

ok( ! $fa->is_state($del),
    "delete_states delete states" );

is_deeply(
    [ $fa->get_accepting ],
    [],
    "initially no accepting states" );

is_deeply(
    [ $fa->get_starting ],
    [],
    "initially no starting states" );


$fa->set_accepting(@s[0,1,2]);
$fa->set_starting(@s[2,3]);

is_deeply(
    [ sort $fa->get_accepting ],
    [ sort @s[0,1,2] ],
    "set_accepting sets accepting" );

is_deeply(
    [ sort $fa->get_starting ],
    [ sort @s[2,3] ],
    "set_starting sets starting" );

ok( $fa->is_starting( $s[2] ),
    "set_starting sets starting" );
ok( ! $fa->is_starting( $s[1] ),
    "set_starting leaves others" );

ok( $fa->is_accepting( $s[2] ),
    "set_accepting sets accepting" );
ok( ! $fa->is_accepting( $s[3] ),
    "set_accepting leaves others" );

#############
#
#      | a   b
# -----+------
#  F 0 | 0,2 1
#  F 1 | 3   1
# SF 2 | 1   -
# S  3 | 2   2,1

use FLAT::Transition;
$fa->{TRANS_CLASS} = "FLAT::Transition";

my @trans = (
    [$s[0], $s[0], "a"],
    [$s[0], $s[1], "b"],
    [$s[0], $s[2], "a"],
    [$s[1], $s[1], "b"],
    [$s[1], $s[3], "a"],
    [$s[2], $s[1], "a"],
    [$s[3], $s[1], "b"],
    [$s[3], $s[2], "a", "b"]
);

$fa->add_transition( @$_ ) for @trans;

is_deeply(
    [ sort $fa->get_transition( @$_[0,1] )->alphabet ],
    [ sort @$_[2 .. $#$_] ],
    "transitions added correctly" ) for @trans;

is( $fa->get_transition( $s[2], $s[0] ),
    undef,
    "transitions added correctly" );

is_deeply(
    [ sort $fa->alphabet ],
    [ "a", "b" ],
    "alphabet correct" );

my @succ = (
    [ [@s[0,1]]                     => [@s[0,1,2,3]] ],
    [ []                            => []            ],
    [ [$s[2]]                       => [$s[1]]       ],
    [ $s[0]                         => [@s[0,1,2]]   ],

    [ [@s[0,1]],        "b"         => [$s[1]]       ],
    [ [$s[2]],          "b"         => []            ],
    [ [@s[2,3]],        "a"         => [@s[1,2]]     ],
    
    [ $s[0],            "a"         => [@s[0,2]]     ],
    [ $s[0],            "c"         => []            ],
    [ $s[3],            "b"         => [@s[1,2]]     ],
    
    [ [@s[0,1]],        ["a","b"]   => [@s[0,1,2,3]] ],
    [ [@s[0,1,2,3]],    []          => [@s[0,1,2,3]] ],
    [ $s[0],            ["a","b"]   => [@s[0,1,2]]   ],
);

for (@succ) {
    my @args = @$_;
    my $expected = pop @args;
    is_deeply(
        [ sort $fa->successors(@args) ],
        [ sort @$expected ],
        "successors" );
}

$fa->remove_transition( $s[0], $s[1] );

is( $fa->get_transition( $s[0], $s[1] ),
    undef,
    "remove_transition" );


$fa->prune;

is( $fa->num_states,
    3,
    "prune" );
