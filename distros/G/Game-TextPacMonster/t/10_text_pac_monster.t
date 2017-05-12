use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
use Test::MockObject;

use Game::TextPacMonster;

my $ID    = 2;
my $X     = 10;
my $Y     = 10;
my $POINT = Game::TextPacMonster::Point->new( $X, $Y );



#test_new_no_timelimit
{
    my $message = q/^An input param 'timelimit' has not been set./;
    eval { my $game = Game::TextPacMonster->new(); };
    like( $@, qr/$message/ );
}

#test_new_timelimit_is_too_small
{
   my $message =  q/^An input param 'timelimit' should be lager than 0./;

    eval { my $game = Game::TextPacMonster->new({map_string=>'#', timelimit=>0}); };
    like( $@, qr/$message/ );

    eval { my $game = Game::TextPacMonster->new({map_string=>'#', timelimit=>-1}); };
    like( $@, qr/$message/ );
}


#test_new_no_map_string
{
   my $message = q/^An input param 'map_string' has not been set./;

    eval { my $game = Game::TextPacMonster->new({ timelimit=>1}); };
    like( $@, qr/$message/ );
}


#test_new_is_no_dot
{
    my $message =  q/^An input param 'map_string' should include '.' ./;

    my $map = <<'EOF';
###########
# V  #  H #
# ##   ## #
#L#  #  R #
# # ### # #
#    @    #
###########
EOF

    eval { my $game = Game::TextPacMonster->new( {map_string => $map, timelimit => 1 } ); };
    like( $@, qr/$message/ );
}

#test_new_no_required_char
{
    my $message =
      q/^An input param 'map_string' should be char set '#VHLRJ@.' and 'SPACE' ./;

    my $map = <<'EOF';
###########
#.V  #  H #
# ## J ## #
#L#  #  R #
# # ### # #
#    @ U  #
###########
EOF

    eval {
        my $game =
          Game::TextPacMonster->new( { map_string => $map, timelimit => 1 } );
    };
    like( $@, qr/$message/ );
}


# test_new_no_atmark_or_many_atmarks
{
    my $message =
        q/^An input param 'map_string' should inculde just only one '@' ./;

    my $map_no_atmark = <<'EOF';
###########
#.V  #  H #
# ## J ## #
#L#  #  R #
# # ### # #
#         #
###########
EOF

    eval {
        my $game =
          Game::TextPacMonster->new( { map_string => $map_no_atmark, timelimit => 1 } );
    };
    like( $@, qr/$message/ );

    undef($@);

    my $map = <<'EOF';
###########
#.V  #  H #
# ## J ## #
#L#  #  R #
# # ### # #
#    @ @  #
###########
EOF

    eval {
        my $game =
          Game::TextPacMonster->new( { map_string => $map, timelimit => 1 } );
    };
    like( $@, qr/$message/ );
}


# test_new_square
{
    my $message =
        q/^An input param 'map_string' should shape square' ./;

    my $map_no_square = <<'EOF';
##########
#.V  #  H #
# ## J ## #
#L#  #  R #
# # ### # #
#    @    #
###########
EOF

    eval {
        my $game =
          Game::TextPacMonster->new( { map_string => $map_no_square, timelimit => 1 } );
    };
    like( $@, qr/$message/ );
}


# test_new_surface_not_valid
{
    my $message =
        q/^An input param 'map_string' s 4 sides should be all '#'  ./;

    my $map_no_square = <<'EOF';
######### #
#.V  #  H #
# ## J ## #
#L#  #  R #
# # ### # #
#    @    #
###########
EOF

    eval {
        my $game =
          Game::TextPacMonster->new( { map_string => $map_no_square, timelimit => 1 } );
    };
    like( $@, qr/$message/ );
}





# test_level1 
{
    my $level1 = Game::TextPacMonster->level1;
    isa_ok( $level1, 'Game::TextPacMonster' );
}

# test_level2
{
    my $level2 = Game::TextPacMonster->level2;
    isa_ok( $level2, 'Game::TextPacMonster' );
}

# test_level3
{
    my $level2 = Game::TextPacMonster->level2;
    isa_ok( $level2, 'Game::TextPacMonster' );
}








