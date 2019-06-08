# -*- Perl -*-
#
# this is a terminal-based game, run the `pperil` command that should be
# installed with this module to start the game
#
# some details for the unwary, or brave, regarding the code:
#
# this implementation uses arrays heavily so instead of a more typical
# Player object there is an array with various slots that are used for
# various purposes. these slots are indexed using constant subs, and
# there is some overlap of these slots for animates, items, and terrain.
# the %Animates hash (where the player, monsters, and items reside) and
# $LMap (level map, which has every ROW and COL and then an array (LMC)
# for what is in that cell) is where most of the game data resides.
# there can be only one terrain (GROUND), one ITEM, and one animate
# (ANI) per level map cell; any new interactions will need to support
# this. there are also four graphs per level map; these graphs dictate
# what moves are possible for animates (double benefit of providing both
# legal next moves and for pathfinding across the map). gravity pulls
# things down at the beginning of a turn (bottom up), and the player
# always moves first in the turn (low id to high), see the game_loop.
# level maps are ASCII text, and only one thing can be present in a cell
# in the map (with FLOOR being assumed present below any item or
# animate). there are some complications around killing things off; dead
# things must not interact with anything, but may still be looped to
# after their death in the apply_gravity or game_loop UPDATE calls.
# hence the BLACK_SPOT

package Game::PlatformsOfPeril;

our $VERSION = '0.03';

use 5.24.0;
use warnings;
use File::Spec          ();
use List::PriorityQueue ();
use List::Util qw(first);
use List::UtilsBy 0.06 qw(nsort_by rev_nsort_by);
use Scalar::Util qw(weaken);
use Term::ReadKey qw(GetTerminalSize ReadKey ReadMode);
use Time::HiRes qw(gettimeofday sleep tv_interval);
use POSIX qw(STDIN_FILENO TCIFLUSH tcflush);

# XTerm control sequences
sub at              { "\e[" . $_[1] . ';' . $_[0] . 'H' }
sub clear_screen () { "\e[1;1H\e[2J" }
sub clear_right ()  { "\e[K" }
sub hide_cursor ()  { "\e[?25l" }
sub hide_pointer () { "\e[>3p" }
sub show_cursor ()  { "\e[?25h" }
sub term_norm ()    { "\e[m" }

# WHAT Animates and such can be
sub HERO ()   { 0 }
sub MONST ()  { 1 }
sub BOMB ()   { 2 }
sub GEM ()    { 3 }
sub FLOOR ()  { 4 }
sub WALL ()   { 5 }
sub LADDER () { 6 }
sub STAIR ()  { 7 }
sub STATUE () { 8 }

sub BOMB_COST () { 2 }
sub GEM_VALUE () { 1 }

# for the Level Map Cell (LMC)
sub WHERE ()  { 0 }
sub GROUND () { 1 }
sub ITEM ()   { 2 }
sub ANI ()    { 3 }

sub MOVE_FAILED () { 0 }
sub MOVE_OK ()     { 1 }
sub MOVE_NEWLVL () { 2 }

# for the level map
sub COLS ()         { 23 }
sub ROWS ()         { 23 }
sub MAP_DISP_OFF () { 1 }

# level map is row, col while points are [ col, row ]
sub PROW () { 1 }
sub PCOL () { 0 }

sub MSG_ROW () { 1 }
sub MSG_COL () { 25 }
# these also used to determine the minimum size for the terminal
sub MSG_MAX ()      { 24 }
sub MSG_COLS_MAX () { 70 }

# for Animates (and also some Things for the first few slots)
sub WHAT ()       { 0 }
sub DISP ()       { 1 }
# NOTE that GROUND use TYPE to distinguish between different types of
# those (FLOOR, STAIR, STATUE) which makes the graph code simpler as
# that only needs to look at WHAT for whether motion is possible in that
# cell; ANI and ITEM instead use TYPE to tell ANI apart from ITEM
sub TYPE ()       { 2 }
sub STASH ()      { 3 }
sub UPDATE ()     { 4 }
sub ANI_ID ()     { 5 }
sub LMC ()        { 6 }
sub BLACK_SPOT () { 7 }

sub GEM_STASH ()  { 0 }
sub BOMB_STASH () { 1 }
sub GEM_ODDS ()   { 1 }

sub GEM_ODDS_ADJUST () { 0.05 }

sub START_GEMS ()  { 0 }
sub START_BOMBS () { 1 }

sub GRAPH_NODE ()   { 0 }
sub GRAPH_WEIGHT () { 1 }
sub GRAPH_POINT ()  { 2 }

our $AnimateID = 1;

our %CharMap = (
    'o' => BOMB,
    '.' => FLOOR,
    '*' => GEM,
    '@' => HERO,
    '=' => LADDER,
    'P' => MONST,
    '%' => STAIR,
    '&' => STATUE,
    '#' => WALL,
);

our (
    @Death_Row, @Graphs, $LMap,  $Monst_Name, @RedrawA,
    @RedrawB,   $Hero,   $TCols, $TRows
);

our %Examine_Offsets = (
    'h' => [ -1, +0 ],    # left
    'j' => [ +0, +1 ],    # down
    'k' => [ +0, -1 ],    # up
    'l' => [ +1, +0 ],    # right
    'y' => [ -1, -1 ],
    'u' => [ +1, -1 ],
    'b' => [ -1, +1 ],
    'n' => [ +1, +1 ],
);

our $Level = 0;
our $Level_Path;

# plosive practice. these must pluralize properly (or please patch)
our @Menagerie = (
    'Palace Peacock',
    'Peckish Packrat',
    'Peevish Penguin',
    'Piratical Parakeet',
    'Placid Piranha',
    'Pleasant Porcupine',
    'Priggish Python',
    'Prurient Pachyderm',
    'Purposeful Plant',
);
$Monst_Name = $Menagerie[ rand @Menagerie ];

our $Redraw_Delay = 0.05;
our $Rotate_Delay = 0.20;
our $Rotation     = 0;

our @Scientists = qw(Eigen Maxwell Newton);
our $Scientist  = $Scientists[ rand @Scientists ];

our $Seed;

our @Styles =
  qw(Abstract Art-Deco Brutalist Egyptian Greek Impressionist Post-Modern Roman Romantic);
our $Style = $Styles[ rand @Styles ];

our %Things = (
    BOMB,   [ BOMB,   "\e[31mo\e[0m",   ITEM ],
    FLOOR,  [ FLOOR,  "\e[33m.\e[0m",   FLOOR ],
    GEM,    [ GEM,    "\e[32m*\e[0m",   ITEM ],
    LADDER, [ LADDER, "\e[37m=\e[0m",   LADDER ],
    STAIR,  [ FLOOR,  "\e[37m%\e[0m",   STAIR ],
    STATUE, [ FLOOR,  "\e[1;33m&\e[0m", STATUE ],
    WALL,   [ WALL,   "\e[35m#\e[0m",   WALL ],
);

our %Descriptions = (
    BOMB,   'Bomb. Avoid.',
    FLOOR,  'Empty cell.',
    GEM,    'A gem. Get these.',
    HERO,   'The much suffering hero.',
    LADDER, 'A ladder.',
    MONST,  $Monst_Name . '. Wants to kill you.',
    STAIR,  'A way out of this mess.',
    STATUE, 'Empty cell with decorative statue.',
    WALL,   'A wall.',
);

our %Animates = (
    HERO,
    [   HERO,                 # WHAT
        "\e[1;33m\@\e[0m",    # DISP
        ANI,                  # TYPE
        [ START_GEMS, START_BOMBS ],    # STASH
        \&update_hero,                  # UPDATE
        HERO,                           # ANI_ID
        undef,                          # LMC
    ],
);

our %Interact_With = (
    HERO,                               # the target of the mover
    sub {
        my ( $mover, $target ) = @_;
        game_over_monster() if $mover->[WHAT] == MONST;
        game_over_bomb()    if $mover->[WHAT] == BOMB;
        grab_gem( $target, $mover );
    },
    MONST,
    sub {
        my ( $mover, $target ) = @_;
        game_over_monster() if $mover->[WHAT] == HERO;
        if ( $mover->[WHAT] == BOMB ) {
            explode( $mover, $target );
        } elsif ( $mover->[WHAT] == GEM ) {
            grab_gem( $target, $mover );
        }
    },
    BOMB,
    sub {
        my ( $mover, $target ) = @_;
        game_over_bomb() if $mover->[WHAT] == HERO;
        if ( $mover->[WHAT] == MONST ) {
            explode( $mover, $target );
        }
    },
    GEM,
    sub {
        my ( $mover, $target ) = @_;
        if ( $mover->[TYPE] == ANI ) {
            relocate( $mover, $target->[LMC][WHERE] );
            grab_gem( $mover, $target );
        }
    },
);

our %Key_Commands = (
    'h' => move_player( -1, +0 ),    # left
    'j' => move_player( +0, +1 ),    # down
    'k' => move_player( +0, -1 ),    # up
    'l' => move_player( +1, +0 ),    # right
    '.' => \&move_nop,               # rest
    ' ' => \&move_nop,               # also rest
    'x' => \&move_examine,
    '<' => sub {
        post_message( $Scientist . q{'s magic wonder left boot, activate!} );
        rotate_left();
        print draw_level();
        sleep($Rotate_Delay);
        return MOVE_OK;
    },
    '>' => sub {
        post_message( $Scientist . q{'s magic wonder right boot, activate!} );
        rotate_right();
        print draw_level();
        sleep($Rotate_Delay);
        return MOVE_OK;
    },
    '?' => sub {
        post_help();
        return MOVE_FAILED;
    },
    # for debugging, probably shouldn't be included as it shows exactly
    # where the monsters are trying to move to which may or may not be
    # where the player is
    'T' => sub {
        local $" = ',';
        post_message("T $Hero->@* R $Rotation");
        return MOVE_FAILED;
    },
    '@' => sub {
        local $" = ',';
        post_message("\@ $Animates{HERO,}[LMC][WHERE]->@* R $Rotation");
        return MOVE_FAILED;
    },
    '$' => sub {
        post_message( 'You have '
              . $Animates{ HERO, }[STASH][BOMB_STASH]
              . ' bombs and '
              . $Animates{ HERO, }[STASH][GEM_STASH]
              . ' gems.' );
        return MOVE_FAILED;
    },
    # by way of history '%' is what rogue (version 3.6) uses for stairs,
    # except the '>' (or very rarely '<') keys are used to interact with
    # that symbol
    '%' => sub {
        if ( $Animates{ HERO, }[LMC][GROUND][TYPE] == STAIR ) {
            load_level();
            print clear_screen(), draw_level();
            post_message( 'Level '
                  . $Level
                  . ' (You have '
                  . $Animates{ HERO, }[STASH][BOMB_STASH]
                  . ' bombs and '
                  . $Animates{ HERO, }[STASH][GEM_STASH]
                  . ' gems.)' );
            return MOVE_NEWLVL;
        } else {
            post_message('There are no stairs here?');
            return MOVE_FAILED;
        }
    },
    'B' => sub {
        my $lmc = $Animates{ HERO, }[LMC];
        return MOVE_FAILED, 'You have no bombs (make them from gems).'
          if $Animates{ HERO, }[STASH][BOMB_STASH] < 1;
        return MOVE_FAILED, 'There is already an item in this cell.'
          if defined $lmc->[ITEM];
        $Animates{ HERO, }[STASH][BOMB_STASH]--;
        make_item( $lmc->[WHERE], BOMB, 0 );
        return MOVE_OK;
    },
    'M' => sub {
        return MOVE_FAILED, 'You need more gems.'
          if $Animates{ HERO, }[STASH][GEM_STASH] < BOMB_COST;
        $Animates{ HERO, }[STASH][GEM_STASH] -= BOMB_COST;
        post_message(
            'You now have ' . ++$Animates{ HERO, }[STASH][BOMB_STASH] . ' bombs' );
        return MOVE_OK;
    },
    'q'    => sub { game_over('Be seeing you...') },
    "\003" => sub {                                    # <C-c>
        post_message('Enough with these silly interruptions!');
        return MOVE_FAILED;
    },
    "\014" => sub {                                    # <C-l>
        redraw_level();
        return MOVE_FAILED;
    },
    "\032" => sub {                                    # <C-z>
        post_message('You hear a strange noise in the background.');
        return MOVE_FAILED;
    },
    "\033" => sub {
        post_message('You cannot escape quite so easily.');
        return MOVE_FAILED;
    },
);

sub apply_gravity {
    for my $ent ( rev_nsort_by { $_->[LMC][WHERE][PROW] } values %Animates ) {
        next if $ent->[BLACK_SPOT];
        my $here = $ent->[LMC][WHERE];
        next
          if $here->[PROW] == ROWS - 1
          or (  $ent->[TYPE] == ANI
            and $LMap->[ $here->[PROW] ][ $here->[PCOL] ][GROUND][WHAT] == LADDER )
          or $LMap->[ $here->[PROW] + 1 ][ $here->[PCOL] ][GROUND][WHAT] == WALL;
        my $dest = [ $here->[PCOL], $here->[PROW] + 1 ];
        relocate( $ent, $dest ) unless interact( $ent, $dest );
        if ( $ent->[WHAT] == HERO ) {
            if ( $ent->[LMC][GROUND][WHAT] == LADDER ) {
                post_message('You fall, but grab onto a ladder.');
            } else {
                post_message('You fall!');
            }
        }
    }
}

sub bad_terminal {
    ( $TCols, $TRows ) = (GetTerminalSize)[ 0, 1 ];
    return ( not defined $TCols or $TCols < MSG_COLS_MAX or $TRows < MSG_MAX );
}

sub bail_out {
    ReadMode 'restore';
    warn $_[0] if @_;
    game_over("Suddenly, the platforms collapse about you.");
}

sub between {
    my ( $min, $max, $value ) = @_;
    if ( $value < $min ) {
        $value = $min;
    } elsif ( $value > $max ) {
        $value = $max;
    }
    return $value;
}

sub draw_level {
    my $s = '';
    for my $rownum ( 0 .. ROWS - 1 ) {
        $s .= at( MAP_DISP_OFF, MAP_DISP_OFF + $rownum );
        for my $lmc ( $LMap->[$rownum]->@* ) {
            if ( defined $lmc->[ANI] ) {
                $s .= $lmc->[ANI][DISP];
            } elsif ( defined $lmc->[ITEM] ) {
                $s .= $lmc->[ITEM][DISP];
            } else {
                $s .= $lmc->[GROUND][DISP];
            }
        }
    }
    $s .= at( 1, ROWS + 1 ) . $Things{ WALL, }[DISP] x COLS;
    return $s;
}

sub explode {
    post_message('ka-boom!');
    for my $ent (@_) {
        # HEROIC DESTRUCTION
        $ent->[LMC][GROUND] = $Things{ FLOOR, } if $ent->[LMC][GROUND][TYPE] == STATUE;
        kill_animate($ent);
    }
}

# cribbed from some A* article on https://www.redblobgames.com/
sub find_hero {
    my ( $ent, $mcol, $mrow ) = @_;

    my $start = $mcol . ',' . $mrow;
    my $pcol  = $Hero->[PCOL];
    my $prow  = $Hero->[PROW];
    my $end   = $pcol . ',' . $prow;

    # already waiting where the player is going to fall to
    return if $start eq $end;

    my %costs = ( $start => 0 );
    my %seen  = ( $start => undef );
    my $q     = List::PriorityQueue->new;
    $q->insert( $start, 0 );

    my $linked = 0;
    while ( my $node = $q->pop ) {
        if ( $node eq $end ) {
            $linked = 1;
            last;
        }
        for my $peer ( $Graphs[$Rotation]{$node}->@* ) {
            my $new  = $peer->[GRAPH_NODE];
            my $cost = $costs{$node} + $peer->[GRAPH_WEIGHT];
            if ( not exists $seen{$new} or $cost < $costs{$new} ) {
                $costs{$new} = $cost;
                # perhaps they drove taxicabs in Manhattan in a former life?
                my $priority =
                  $cost +
                  abs( $pcol - $peer->[GRAPH_POINT][PCOL] ) +
                  abs( $prow - $peer->[GRAPH_POINT][PROW] );
                $q->insert( $new, $priority );
                $seen{$new} = $node;
            }
        }
    }
    return unless $linked;

    my @path;
    my $node = $end;
    while ( $node ne $start ) {
        unshift @path, $node;
        $node = $seen{$node};
    }
    return [ split ',', $path[0] ];
}

sub game_loop {
    game_over( 'Terminal must be at least ' . MSG_COLS_MAX . 'x' . MSG_MAX )
      if bad_terminal();
    ( $Level_Path, $Level, $Seed ) = @_;
    $SIG{$_} = \&bail_out for qw(INT HUP TERM PIPE QUIT USR1 USR2 __DIE__);
    STDOUT->autoflush(1);
    load_level();
    ReadMode 'raw';
    print term_norm, hide_cursor, hide_pointer, clear_screen, draw_level;
    post_message('The Platforms of Peril');
    post_message('');
    post_message( 'Your constant foes, the ' . $Monst_Name . 's' );
    post_message('seek to destroy your way of life!');
    post_help();
    post_message('');
    post_message( 'Seed ' . $Seed . ' of version ' . $VERSION );
    $SIG{CONT}  = \&redraw_level;
    $SIG{WINCH} = sub {
        post_message('The terminal is too small!') if bad_terminal();
        redraw_level();
    };

    while (1) {
        apply_gravity();
        while ( my $id = pop @Death_Row ) { delete $Animates{$id} }
        redraw_movers() if @RedrawA;
        my @actors = nsort_by { $_->[ANI_ID] } values %Animates;
        next if shift(@actors)->[UPDATE]->() == MOVE_NEWLVL;
        track_hero();
        for my $ent (@actors) {
            $ent->[UPDATE]->($ent) if !$ent->[BLACK_SPOT] and defined $ent->[UPDATE];
        }
        while ( my $id = pop @Death_Row ) { delete $Animates{$id} }
        redraw_movers();
    }
}

sub game_over {
    my ( $msg, $code ) = @_;
    $code //= 1;
    ReadMode 'restore';
    print at( 1, ROWS + 1 ), term_norm, "\n", clear_right, show_cursor, $msg, ' (',
      $Animates{ HERO, }[STASH][GEM_STASH], " gems)\n",
      clear_right;
    exit $code;
}

sub game_over_bomb { game_over('You gone done blowed yourself up.') }

sub game_over_monster {
    game_over( 'The ' . $Monst_Name . ' polished you off.' );
}

sub grab_gem {
    my ( $ent, $gem ) = @_;
    $ent->[STASH][GEM_STASH] += $gem->[STASH];
    kill_animate($gem);
    if ( $ent->[WHAT] == MONST ) {
        post_message( 'The ' . $Monst_Name . ' grabs a gem.' );
    } else {
        post_message( 'You now have ' . $ent->[STASH][GEM_STASH] . ' gems.' );
    }
}

sub graph_bilink {
    my ( $g, $c1, $r1, $c2, $r2 ) = @_;
    my $from = $c1 . ',' . $r1;
    my $to   = $c2 . ',' . $r2;
    push $g->{$from}->@*, [ $to,   1, [ $c2, $r2 ] ];
    push $g->{$to}->@*,   [ $from, 1, [ $c1, $r1 ] ];
}

sub graph_setup {
    my $g = {};
    for my $r ( 0 .. ROWS - 2 ) {
        for my $c ( 0 .. COLS - 1 ) {
            next if $LMap->[$r][$c][GROUND][WHAT] == WALL;
            # allow left/right, if ladder or wall below permits it
            if ($c != COLS - 1
                and (  $LMap->[$r][$c][GROUND][WHAT] == LADDER
                    or $LMap->[ $r + 1 ][$c][GROUND][WHAT] == WALL )
                and (
                    $LMap->[$r][ $c + 1 ][GROUND][WHAT] == LADDER
                    or (    $LMap->[$r][ $c + 1 ][GROUND][WHAT] != WALL
                        and $LMap->[ $r + 1 ][ $c + 1 ][GROUND][WHAT] == WALL )
                )
            ) {
                graph_bilink( $g, $c, $r, $c + 1, $r );
            }
            if ( $r > 0 ) {
                # allow motion up/down ladders
                if (    $LMap->[$r][$c][GROUND][WHAT] == LADDER
                    and $LMap->[ $r - 1 ][$c][GROUND][WHAT] == LADDER ) {
                    graph_bilink( $g, $c, $r, $c, $r - 1 );
                } elsif (
                    $LMap->[$r][$c][GROUND][WHAT] == LADDER
                    or (    $LMap->[$r][$c][GROUND][WHAT] == FLOOR
                        and $LMap->[ $r + 1 ][$c][GROUND][WHAT] == WALL )
                ) {
                    # can we fall into this cell from above?
                    graph_shaft( $g, $c, $r );
                }
            }
        }
    }
    for my $c ( 0 .. COLS - 1 ) {
        next if $LMap->[ ROWS - 1 ][$c][GROUND][WHAT] == WALL;
        if (    $LMap->[ ROWS - 1 ][$c][GROUND][WHAT] == LADDER
            and $LMap->[ ROWS - 2 ][$c][GROUND][WHAT] == LADDER ) {
            graph_bilink( $g, $c, ROWS - 1, $c, ROWS - 2 );
        } else {
            graph_shaft( $g, $c, ROWS - 1 );
        }
        if ( $c != COLS - 1 ) {
            graph_bilink( $g, $c, ROWS - 1, $c + 1, ROWS - 1 );
        }
    }
    return $g;
}

sub graph_shaft {
    my ( $g, $c, $r ) = @_;
    for my $x ( reverse 0 .. $r - 1 ) {
        last if $LMap->[$x][$c][GROUND][WHAT] == WALL;
        my $weight = $r - $x;
        if ( $LMap->[$x][$c][GROUND][WHAT] == LADDER ) {
            if ( $weight == 1 ) {
                graph_udlink( $g, $c, $x, $c, $r, 1, [ $c, $x ] );
            } else {
                graph_udlink( $g, $c, $x,     $c, $x + 1, 1,           [ $c, $x ] );
                graph_udlink( $g, $c, $x + 1, $c, $r,     $weight - 2, [ $c, $r ] );
            }
            last;
        }
        # can fall into this shaft from the left or right?
        if ($c != 0
            and (
                $LMap->[$x][ $c - 1 ][GROUND][WHAT] == LADDER
                or (    $LMap->[$x][ $c - 1 ][GROUND][WHAT] == FLOOR
                    and $LMap->[ $x + 1 ][ $c - 1 ][GROUND][WHAT] == WALL )
            )
        ) {
            graph_udlink( $g, $c - 1, $x, $c, $x, 1,           [ $c, $x ] );
            graph_udlink( $g, $c,     $x, $c, $r, $weight - 1, [ $c, $r ] );
        }
        if ($c != COLS - 1
            and (
                $LMap->[$x][ $c + 1 ][GROUND][WHAT] == LADDER
                or (    $LMap->[$x][ $c + 1 ][GROUND][WHAT] == FLOOR
                    and $LMap->[ $x + 1 ][ $c + 1 ][GROUND][WHAT] == WALL )
            )
        ) {
            graph_udlink( $g, $c + 1, $x, $c, $x, $weight,     [ $c, $x ] );
            graph_udlink( $g, $c,     $x, $c, $r, $weight - 1, [ $c, $r ] );
        }
    }
}

sub graph_udlink {
    my ( $g, $c1, $r1, $c2, $r2, $weight, $point ) = @_;
    my $from = $c1 . ',' . $r1;
    my $to   = $c2 . ',' . $r2;
    push $g->{$from}->@*, [ $to, $weight, $point ];
}

sub interact {
    my ( $mover, $dest ) = @_;
    for my $i ( ANI, ITEM ) {
        my $target = $LMap->[ $dest->[PROW] ][ $dest->[PCOL] ][$i];
        if ( defined $target ) {
            # this code is assumed to take care of everything and be the
            # final say on the interaction
            $Interact_With{ $target->[WHAT] }->( $mover, $target );
            return 1;
        }
    }
    return 0;
}

sub kill_animate {
    my ($ent) = @_;
    push @RedrawA, $ent->[LMC][WHERE];
    $ent->[BLACK_SPOT] = 1;
    push @Death_Row, $ent->[ANI_ID];
    # NOTE this only works for TYPE of ANI or ITEM, may need to rethink
    # how STATUE and STAIRS are handled if there are GROUND checks on
    # TYPE as those abuse the TYPE field for other things (see %Things)
    undef $ent->[LMC][ $ent->[TYPE] ];
}

sub load_level {
    my $file = File::Spec->catfile( $Level_Path, 'level' . $Level++ );
    game_over( 'No more levels.', 0 ) unless -e $file;

    open( my $fh, '<', $file ) or game_over("Failed to open '$file': $!");

    $AnimateID = 1;
    for my $key ( grep { $_ != HERO } keys %Animates ) {
        delete $Animates{$key};
    }
    undef $Animates{ HERO, }[LMC];
    $LMap = [];

    my $rownum = 0;
    while ( my $line = readline $fh ) {
        chomp $line;
        game_over("Wrong number of columns at $file:$.") if length $line != COLS;
        my $colnum = 0;
        for my $v ( split //, $line ) {
            my $c = $CharMap{$v} // game_over("Unknown character $v at $file:$.");
            my $point = [ $colnum++, $rownum ];    # PCOL, PROW (x, y)
            if ( exists $Things{$c} ) {
                if ( $c eq BOMB ) {
                    push $LMap->[$rownum]->@*, [ $point, $Things{ FLOOR, } ];
                    make_item( $point, BOMB, 0 );
                } elsif ( $c eq GEM ) {
                    push $LMap->[$rownum]->@*, [ $point, $Things{ FLOOR, } ];
                    make_item( $point, GEM, GEM_VALUE );
                } else {
                    push $LMap->[$rownum]->@*, [ $point, $Things{$c} ];
                }
            } else {
                if ( $c eq HERO ) {
                    game_over("Player placed twice in $file")
                      if defined $Animates{ HERO, }[LMC];
                    push $LMap->[$rownum]->@*,
                      [ $point, $Things{ FLOOR, }, undef, $Animates{ HERO, } ];
                    $Animates{ HERO, }[LMC] = $LMap->[$rownum][-1];
                    $Hero = $point;
                    weaken( $Animates{ HERO, }[LMC] );
                } elsif ( $c eq MONST ) {
                    push $LMap->[$rownum]->@*, [ $point, $Things{ FLOOR, } ];
                    make_monster($point);
                } else {
                    game_over("Unknown object '$v' at $file:$.");
                }
            }
        }
        last if ++$rownum == ROWS;
    }
    game_over("Too few rows in $file") if $rownum < ROWS;
    game_over("No player in $file") unless defined $Animates{ HERO, }[LMC];

    $Rotation = 0;
    for my $rot ( 1 .. 4 ) {
        $Graphs[$Rotation] = graph_setup();
        rotate_left();
    }
}

sub make_item {
    my ( $point, $thingy, $stash, $update ) = @_;
    my $id   = $AnimateID++;
    my $item = [ $Things{$thingy}->@*, $stash, $update, $id ];
    $Animates{$id} = $item;
    $LMap->[ $point->[PROW] ][ $point->[PCOL] ][ITEM] = $item;
    $Animates{$id}[LMC] = $LMap->[ $point->[PROW] ][ $point->[PCOL] ];
    weaken( $Animates{$id}[LMC] );
}

sub make_monster {
    my ($point) = @_;
    my $id = $AnimateID++;
    # STASH replicates that of the HERO for simpler GEM handling code
    # though the BOMB_STASH is instead used for GEM_ODDS
    my $monst = [ MONST, "\e[1;33mP\e[0m", ANI, [ 0, 0.0 ], \&update_monst, $id ];
    $Animates{$id} = $monst;
    $LMap->[ $point->[PROW] ][ $point->[PCOL] ][ANI] = $monst;
    $Animates{$id}[LMC] = $LMap->[ $point->[PROW] ][ $point->[PCOL] ];
    weaken( $Animates{$id}[LMC] );
}

sub move_animate {
    my ( $ent, $cols, $rows ) = @_;
    my $lmc = $ent->[LMC];

    my $from = $lmc->[WHERE][PCOL] . ',' . $lmc->[WHERE][PROW];
    my $to =
      ( $lmc->[WHERE][PCOL] + $cols ) . ',' . ( $lmc->[WHERE][PROW] + $rows );

    return MOVE_FAILED
      unless first { $_->[GRAPH_NODE] eq $to } $Graphs[$Rotation]{$from}->@*;

    my $dest = [ $lmc->[WHERE][PCOL] + $cols, $lmc->[WHERE][PROW] + $rows ];

    relocate( $ent, $dest ) unless interact( $ent, $dest );
    return MOVE_OK;
}

# so the player can see if there is a ladder under something; this is an
# important consideration on some levels
sub move_examine {
    my $key;
    my $row = $Animates{ HERO, }[LMC][WHERE][PROW];
    my $col = $Animates{ HERO, }[LMC][WHERE][PCOL];
    print at( MSG_COL, MSG_ROW + $_ ), clear_right for 1 .. MSG_MAX;
    print at( MSG_COL, MSG_ROW ), clear_right,
      'Move cursor to view a cell. Esc exits', show_cursor;
    while (1) {
        print at( MSG_COL, MSG_ROW + $_ ), clear_right for 3 .. 5;
        my $disp_row = 2;
        for my $i ( ANI, ITEM ) {
            my $x = $LMap->[$row][$col][$i];
            if ( defined $x ) {
                print at( MSG_COL, MSG_ROW + $disp_row++ ), clear_right, $x->[DISP],
                  ' - ', $Descriptions{ $x->[WHAT] };
            }
        }
        my $g = $LMap->[$row][$col][GROUND];
        print at( MSG_COL, MSG_ROW + $disp_row ), clear_right, $g->[DISP],
          ' - ', $Descriptions{ $g->[TYPE] },
          at( MAP_DISP_OFF + $col, MAP_DISP_OFF + $row );
        $key = ReadKey(0);
        last if $key eq "\033";
        my $distance = 1;
        if ( ord $key < 97 ) {    # SHIFT moves faster
            $key      = lc $key;
            $distance = 5;
        }
        my $dir = $Examine_Offsets{$key} // next;
        $row = between( 0, ROWS - 1, $row + $dir->[PROW] * $distance );
        $col = between( 0, COLS - 1, $col + $dir->[PCOL] * $distance );
    }
    print hide_cursor;
    show_messages();
    return MOVE_FAILED;
}

sub move_nop { return MOVE_OK }

sub move_player {
    my ( $cols, $rows ) = @_;
    return sub {
        my ( $status, $msg ) = move_animate( $Animates{ HERO, }, $cols, $rows );
        post_message($msg) if $msg;
        return $status;
    };
}

sub post_help {
    post_message('');
    post_message(
        ' ' . $Animates{ HERO, }[DISP] . ' - You   P - a ' . $Monst_Name );
    post_message(
        ' ' . $Things{ STATUE, }[DISP] . ' - a large granite statue done in the' );
    post_message( '     ' . $Style . ' style' );
    post_message( ' '
          . $Things{ BOMB, }[DISP]
          . ' - Bomb  '
          . $Things{ GEM, }[DISP]
          . ' - Gem (get these)' );
    post_message('');
    post_message(' h j k l - move');
    post_message(' < >     - activate left or right boot');
    post_message(' B       - drop a Bomb');
    post_message( ' M       - make a Bomb (consumes ' . BOMB_COST . ' Gems)' );
    post_message(
        ' %       - when on ' . $Things{ STAIR, }[DISP] . ' goes to the next level' );
    post_message(' . space - pass a turn (handy when falling)');
    post_message('');
    post_message(' q       - quit the game (no save)');
    post_message(' $       - display Bomb and Gem counts');
    post_message(' ?       - post these help messages');
    post_message('');
    post_message( 'You have '
          . $Animates{ HERO, }[STASH][BOMB_STASH]
          . ' bombs and '
          . $Animates{ HERO, }[STASH][GEM_STASH]
          . ' gems.' );
}

{
    my @log;

    sub post_message {
        my ($msg) = @_;
        while ( @log >= MSG_MAX ) { shift @log }
        push @log, $msg;
        show_messages();
    }
    sub clear_messages { @log = () }

    sub show_messages {
        for my $i ( 0 .. $#log ) {
            print at( MSG_COL, MSG_ROW + $i ), clear_right, $log[$i];
        }
    }
}

sub redraw_level { print clear_screen, draw_level; show_messages() }

sub redraw_movers {
    redraw_ref( \@RedrawA );
    sleep($Redraw_Delay);
    redraw_ref( \@RedrawB );
    @RedrawA = ();
    @RedrawB = ();
}

sub redraw_ref {
  CELL: for my $point ( $_[0]->@* ) {
        for my $i ( ANI, ITEM ) {
            my $target = $LMap->[ $point->[PROW] ][ $point->[PCOL] ][$i];
            if ( defined $target ) {
                print at( map { MAP_DISP_OFF + $_ } $point->@* ), $target->[DISP];
                next CELL;
            }
        }
        print at( map { MAP_DISP_OFF + $_ } $point->@* ),
          $LMap->[ $point->[PROW] ][ $point->[PCOL] ][GROUND][DISP];
    }
}

sub relocate {
    my ( $ent, $dest ) = @_;
    my $src = $ent->[LMC][WHERE];
    push @RedrawA, $src;
    push @RedrawB, $dest;
    my $lmc = $LMap->[ $dest->[PROW] ][ $dest->[PCOL] ];
    $lmc->[ $ent->[TYPE] ] = $ent;
    undef $LMap->[ $src->[PROW] ][ $src->[PCOL] ][ $ent->[TYPE] ];
    $ent->[LMC] = $lmc;
    weaken( $ent->[LMC] );
}

sub rotate_left {
    my $lm;
    for my $r ( 0 .. ROWS - 1 ) {
        for my $c ( 0 .. COLS - 1 ) {
            my $newr = COLS - 1 - $c;
            $lm->[$newr][$r] = $LMap->[$r][$c];
            $lm->[$newr][$r][WHERE] = [ $r, $newr ];
        }
    }
    $LMap     = $lm;
    $Rotation = ( $Rotation + 1 ) % 4;
}

sub rotate_right {
    my $lm;
    for my $r ( 0 .. ROWS - 1 ) {
        for my $c ( 0 .. COLS - 1 ) {
            my $newc = ROWS - 1 - $r;
            $lm->[$c][$newc] = $LMap->[$r][$c];
            $lm->[$c][$newc][WHERE] = [ $newc, $c ];
        }
    }
    $LMap     = $lm;
    $Rotation = ( $Rotation - 1 ) % 4;
}

sub track_hero {
    $Hero = $Animates{ HERO, }[LMC][WHERE];

    # route monsters to where the player will fall to as otherwise they
    # tend to freeze or head in the wrong direction
    my $row = $Animates{ HERO, }[LMC][WHERE][PROW];
    my $col = $Animates{ HERO, }[LMC][WHERE][PCOL];
    return if $row == ROWS - 1 or $LMap->[$row][$col][GROUND][WHAT] == LADDER;

    my $goal = $row;
    for my $r ( $row + 1 .. ROWS - 1 ) {
        last if $LMap->[$r][$col][GROUND][WHAT] == WALL;
        if ($LMap->[$r][$col][GROUND][WHAT] == LADDER
            or (    $r < ROWS - 2
                and $LMap->[$r][$col][GROUND][WHAT] == FLOOR
                and $LMap->[ $r + 1 ][$col][GROUND][WHAT] == WALL )
            or (    $r == ROWS - 1
                and $LMap->[$r][$col][GROUND][WHAT] == FLOOR )
        ) {
            $goal = $r;
            last;
        }
    }
    $Hero = [ $col, $goal ];
}

sub update_hero {
    my ( $key, $ret );
    tcflush( STDIN_FILENO, TCIFLUSH );
    while (1) {
        while (1) {
            $key = ReadKey(0);
            last if exists $Key_Commands{$key};
            post_message( sprintf "Illegal command \\%03o", ord $key );
        }
        ( $ret, my $msg ) = $Key_Commands{$key}->();
        post_message($msg) if defined $msg;
        last if $ret == MOVE_OK or $ret == MOVE_NEWLVL;
    }
    return $ret;
}

sub update_monst {
    my ($ent) = @_;
    my $mcol  = $ent->[LMC][WHERE][PCOL];
    my $mrow  = $ent->[LMC][WHERE][PROW];

    # prevent monster move where only gravity should apply
    # NOTE one may have the clever idea that monsters can run across the
    # heads of other monsters though that would require changes to how
    # the graph is setup to permit such moves, and additional checks to
    # see if something to tread upon is available (and then to let the
    # hero do that (like in Lode Runner) or to prevent them from such
    # head-running...)
    if (    $mrow != ROWS - 1
        and $ent->[LMC][GROUND][WHAT] == FLOOR
        and $LMap->[ $mrow + 1 ][$mcol][GROUND][WHAT] != WALL ) {
        return;
    }

    my $dest = find_hero( $ent, $mcol, $mrow );
    return unless defined $dest;

    relocate( $ent, $dest ) unless interact( $ent, $dest );

    if ( $ent->[STASH][GEM_STASH] > 0
        and !defined $ent->[LMC][ITEM] ) {
        if ( rand() < $ent->[STASH][GEM_ODDS] ) {
            post_message( 'The ' . $Monst_Name . ' drops a gem!' );
            $ent->[STASH][GEM_STASH]--;
            make_item( $ent->[LMC][WHERE], GEM, GEM_VALUE );
            $ent->[STASH][GEM_ODDS] = 0.0 - GEM_ODDS_ADJUST;
        }
        $ent->[STASH][GEM_ODDS] += GEM_ODDS_ADJUST;
    }
}

1;
__END__

=head1 NAME

Game::PlatformsOfPeril - the platforms of peril

=head1 SYNOPSIS

Platforms of Peril is a terminal-based game. Assuming App::cpanminus
(and possibly also local::lib) is installed and setup, in a suitable
terminal (possibly one with a square font such as White Rabbit and a
black background) install and run the game via:

    cpanm Game::PlatformsOfPeril
    pperil

Help text should be printed when the game starts. Use the C<?> key in
game to show the help text again.

=head1 DESCRIPTION

You are the only spawn (son, daughter, etc.) of a Xorbian Ranger and as
such are duty bound not to peruse pointless background material such as
this. You have long hair, green eyes, and start the game with a bomb,
and need to collect gems all the while avoiding the enemies. The enemies
have been blessed with pretty much bog standard A* pathfinding yet do
know a thing or two about gravity. Gems can be made into bombs (the
details as to how are not entirely clear) and bombs in turn will explode
on contact with things that move. You also have two magic boots, one on
each foot. These do something when activated.

P.S. Do not drop a bomb while falling, as it will fall with you and
then explode.

P.P.S. You can make bombs while falling. This is perhaps a more
productive use of that time than mashing space or the C<.> key.

=head2 Customizing the Game

C<pperil> accepts a number of options that do not do very much:

    Usage: pperil [--err=file] [--level=N] [--prefix=path] [--seed=N]

      --err    - send STDERR to this file if not already redirected
      --level  - level integer to start on
      --prefix - path to the levels directory (containing the files
                 level0, level1, ...)
      --seed   - PRNG uses the given integer as the seed

Otherwise customizing the game will involve hacking directly at the
module code or level maps, see L</"Known Issues">.

=head2 Terminal Setup

This game may benefit from the use of a square font; C<~/.Xdefaults>
might contain something like:

    # "White Rabbit" square font (the name is "New" in the
    # "whitrabt.ttf" file that I downloaded from who knows where)
    wrterm*background:black
    wrterm*colorMode:true
    wrterm*cursorBlink:false
    wrterm*cursorColor:white
    wrterm*dynamicColors:true
    wrterm*faceName:New
    wrterm*faceSize:24
    wrterm*foreground:gold
    wrterm*geometry:70x24
    wrterm*termName:xterm-256color

And with that loaded by X11 an C<xterm> could be launched via:

    xterm -class wrterm

to play the game in.

=head1 BUGS

Probably lots.

Please report any bugs or feature requests to
C<bug-game-platformsofperil at rt.cpan.org>, or through the web
interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-PlatformsOfPeril>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

Patches might best be applied towards:

L<https://github.com/thrig/Game-PlatformsOfPeril>

=head2 Known Issues

The most glorious lack of tests, the unconvincing and ham-fisted attempt
at documentation, etc.

More B<weaken> calls may be necessary due to the cross linkages between
the C<%Animates> (which need to know things about the level map) and the
C<$LMap> (which needs to know things about the animates). In other
words, this game may leak memory.

Some may be desirous of non-hjkl movement keys and so forth. Fiddle with
the code (C<our> variables can be clobbered from outside the module), or
abstract things to use MOVE_LEFT etc and then map keys to those symbols.
At that point one might add a configuration file or in-game editor of
the key commands, but that sounds like work.

Automatic level generation might be nice? Or more levels made by hand...

Need to research how gems are made into bombs.

The game is not very perilous. And probably needs much tuning.

=head1 SEE ALSO

Lode Runner, but this game evolved off in some other direction. The
bombs are from Bomberman but behave more like animate-sensing landmines.
One idea is that a gem plus a bomb could make a smartbomb which, being
smart, tracks the player. However bombs lack limbs so have trouble with
the ladders, and that idea is otherwise presently tied up in committee.

L<Game::TextPatterns> may help draw candidate level maps:

    use Game::TextPatterns;

    my $pat = Game::TextPatterns->new( pattern => <<'EOP' );
    .==P..
    o#===.
    ####=.
    =====.
    .=*#..
    .=###.
    EOP

    print $pat->four_up->flip_four(1)->string;

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
