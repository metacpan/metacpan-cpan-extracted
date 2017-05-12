use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
use Test::MockObject;

use Game::TextPacMonster::J;

my $ID    = 2;
my $X     = 10;
my $Y     = 10;
my $POINT = Game::TextPacMonster::Point->new( $X, $Y );

my %r_rules = ();

# R will face to move right, front, left
$r_rules{left_to_right} = [ 'move_down',  'move_right', 'move_up' ];
$r_rules{right_to_left} = [ 'move_up',    'move_left',  'move_down' ];
$r_rules{up_to_down}    = [ 'move_left',  'move_down',  'move_right' ];
$r_rules{down_to_up}    = [ 'move_right', 'move_up',    'move_left' ];

my %l_rules = ();

# L will face to move left, front, right
$l_rules{left_to_right} = [ 'move_up',    'move_right', 'move_down' ];
$l_rules{right_to_left} = [ 'move_down',  'move_left',  'move_up' ];
$l_rules{up_to_down}    = [ 'move_right', 'move_down',  'move_left' ];
$l_rules{down_to_up}    = [ 'move_left',  'move_up',    'move_right' ];



&test_new;
&test__get_delta_point;
&test__get_rules;
&test__get_rule;
#&test_move_free;


sub test_new {
    my $map = Test::MockObject->new();
    my $creature = Game::TextPacMonster::J->new( $ID, $POINT, $map );

    isa_ok( $creature, 'Game::TextPacMonster::J' );
    isa_ok( $creature, 'Game::TextPacMonster::Creature' );
    is( $creature->{_enter_crossing_count}, 0);
}

sub test__get_delta_point {
    my $map = Test::MockObject->new();
    $map->set_true('can_move');
    my $creature = Game::TextPacMonster::J->new( $ID, $POINT, $map );

    $creature->move_right;
    is($creature->_get_delta_point->x_coord, 1);
    $creature->move_left;
    is($creature->_get_delta_point->x_coord, -1);
    $creature->move_up;
    is($creature->_get_delta_point->y_coord, -1);
    $creature->move_down;
    is($creature->_get_delta_point->y_coord, 1);
}


sub test__get_rules {
    my $map = Test::MockObject->new();
    my $creature = Game::TextPacMonster::J->new( $ID, $POINT, $map );



    my %r_rules_from_creature = $creature->_get_rules(1);

    for my $key ( keys(%r_rules_from_creature) ) {
        is( @{ $r_rules{$key} }, @{ $r_rules_from_creature{$key} } );
    }

    my %l_rules_from_creature = $creature->_get_rules(0);

    for my $key ( keys(%l_rules_from_creature) ) {
        is( @{ $l_rules{$key} }, @{ $l_rules_from_creature{$key} } );
    }

}


sub test__get_rule {
   my $map = Test::MockObject->new();
    $map->set_true('can_move');
    my $creature = Game::TextPacMonster::J->new( $ID, $POINT, $map );

   $creature->move_right;
   my @rule_r_left_to_right = $creature->_get_rule(1); # r behavior
   is(@{$r_rules{'left_to_right'}}, @rule_r_left_to_right, '_get_rule');

   my @rule_l_left_to_right = $creature->_get_rule(0); # l behavior
   is(@{$l_rules{'left_to_right'}}, @rule_l_left_to_right, '_get_rule');


   $creature->move_left;
   my @rule_r_right_to_left = $creature->_get_rule(1); # r behavior
   is(@{$r_rules{'right_to_left'}}, @rule_r_right_to_left, '_get_rule');

   my @rule_l_right_to_left = $creature->_get_rule(0); # l behavior
   is(@{$l_rules{'right_to_left'}}, @rule_l_right_to_left, '_get_rule');


   $creature->move_down;
   my @rule_r_up_to_down = $creature->_get_rule(1); # r behavior
   is(@{$r_rules{'up_to_down'}}, @rule_r_up_to_down, '_get_rule');

   my @rule_l_up_to_down = $creature->_get_rule(0); # l behavior
   is(@{$l_rules{'up_to_down'}}, @rule_l_up_to_down, '_get_rule');


   $creature->move_up;
   my @rule_r_down_to_up = $creature->_get_rule(1); # r behavior
   is(@{$r_rules{'down_to_up'}}, @rule_r_down_to_up, '_get_rule');

   my @rule_l_down_to_up = $creature->_get_rule(0); # l behavior
   is(@{$l_rules{'down_to_up'}}, @rule_l_down_to_up, '_get_rule');
}


#test_false_move_free
 {
    my $map = Test::MockObject->new();
    $map->set_series('can_move', [1, 0, 0, 0, 0]);
    my $creature = Game::TextPacMonster::J->new( $ID, $POINT, $map );

    $creature->move_right;
    ok(!$creature->move_free, 'move_free');
    is($creature->{_enter_crossing_count}, 0, 'move_free');
}

#test_true_move_free
{
    my $map = Test::MockObject->new();
    $map->set_true('can_move');
    my $creature = Game::TextPacMonster::J->new( $ID, $POINT, $map );

    $creature->move_right;
    is($creature->{_enter_crossing_count}, 0, 'move_free');
    ok($creature->move_free, 'move_free'); # set L behavior
    is($creature->point->x_coord, $X + 1, 'move_free'); # move_right
    is($creature->point->y_coord, $Y - 1, 'move_free'); # left to right of L behavior
    is($creature->{_enter_crossing_count}, 1, 'move_free'); # counted
    ok($creature->move_free, 'move_free'); # set R behavior
    is($creature->point->x_coord, $X + 2, 'move_free'); # down to up of R behavior
    is($creature->point->y_coord, $Y - 1, 'move_free');
}

