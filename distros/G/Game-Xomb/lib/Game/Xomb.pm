# -*- Perl -*-
#
# Game::Xomb - this is a terminal-based roguelike. run the xomb(1)
# command that is installed with this module to start a game

package Game::Xomb;

our $VERSION = '1.05';

use 5.24.0;
use warnings;
use List::Util qw(min max);
use List::UtilsBy qw(min_by nsort_by);
use POSIX qw(STDIN_FILENO TCIFLUSH tcflush);
use Term::ReadKey qw(GetTerminalSize ReadKey ReadMode);
use Time::HiRes qw(sleep);
require XSLoader;
XSLoader::load('Game::Xomb', $VERSION);    # distance, line drawing, RNG

########################################################################
#
# CONSTANTS

sub NEED_ROWS () { 24 }
sub NEED_COLS () { 80 }

# ANSI or XTerm Control Sequences - https://invisible-island.net/xterm/
sub ALT_SCREEN ()   { "\e[?1049h" }
sub CLEAR_LINE ()   { "\e[2K" }
sub CLEAR_RIGHT ()  { "\e[K" }
sub CLEAR_SCREEN () { "\e[1;1H\e[2J" }
sub HIDE_CURSOR ()  { "\e[?25l" }        # this gets toggled on/off
sub HIDE_POINTER () { "\e[>2p" }         # hide screen gnat
sub SHOW_CURSOR ()  { "\e[?25h" }
sub TERM_NORM ()    { "\e[m" }
sub UNALT_SCREEN () { "\e[?1049l" }

# these not-CONSTANTs move the cursor around. points are col,row (x,y)
# while terminal uses row,col hence the reverse argument order here.
# some at(...) calls have been made into AT_* constants for frequently
# used locations
sub at     { "\e[" . $_[1] . ';' . $_[0] . 'H' }
sub at_row { "\e[" . $_[0] . ';1H' }
sub at_col { "\e[" . $_[0] . 'G' }

# where the message (top) and status (bottom) lines are
sub MSG_ROW ()       { 1 }
sub AT_MSG_ROW ()    { "\e[1;1H" }
sub MSG_MAX ()       { NEED_ROWS - 2 }
sub STATUS_ROW ()    { 24 }
sub AT_STATUS_ROW () { "\e[24;1H" }
sub AT_ECOST ()      { "\e[24;10H" }
sub AT_HPBAR ()      { "\e[24;14H" }
sub AT_CELLOBJS ()   { "\e[24;68H" }
sub AT_SHIELDUP ()   { "\e[24;72H" }
sub AT_PKC_CODE ()   { "\e[24;76H" }

# NOTE also set in Xomb.xs for map-aware functions
sub MAP_COLS () { 78 }
sub MAP_ROWS () { 22 }
sub MAP_SIZE () { MAP_COLS * MAP_ROWS }
sub MAP_DOFF () { 2 }                     # display offset for map on screen

# NOTE level map is row, col while points are [ col, row ]
sub PROW () { 1 }
sub PCOL () { 0 }

# a point in the LMC so Animates can find where they are at
sub WHERE () { 0 }
# GENUS is involved with interactions between thingies and where the
# thing is slotted under the LMC
sub MINERAL () { 1 }    # floor, walls, etc
sub VEGGIE ()  { 2 }    # amulet, gems, etc
sub ANIMAL ()  { 3 }    # Animates

# SPECIES
sub HERO ()    { 0 }    # NOTE also used for @Animates slot
sub FUNGI ()   { 1 }
sub GHAST ()   { 2 }
sub MIMIC ()   { 3 }
sub STALKER () { 4 }
sub TROLL ()   { 5 }
sub AMULET ()  { 6 }
sub GEM ()     { 7 }
sub HOLE ()    { 8 }
sub FLOOR ()   { 9 }
sub GATE ()    { 10 }
sub ACID ()    { 11 }
sub RUBBLE ()  { 12 }
sub WALL ()    { 13 }

sub AMULET_NAME ()  { 'Dragonstone' }
sub AMULET_REGEN () { 6 }               # slow so less likely to burn out
sub AMULET_VALUE () { 1000 }

# for ANIMALS (shared with VEGGIES and MINERALS for the first few slots)
sub GENUS ()      { 0 }
sub SPECIES ()    { 1 }
sub DISPLAY ()    { 2 }                 # how to show 'em on the screen
sub UPDATE ()     { 3 }                 # what happens when their turn comes up
sub STASH ()      { 4 }                 # kitchen drawer
sub LMC ()        { 5 }                 # link back to the level map
sub ENERGY ()     { 6 }                 # how long until their next update call
sub BLACK_SPOT () { 7 }                 # marked for death

# Animates stash slots
sub HITPOINTS () { 0 }                  # player, monsters
sub ECOST ()     { 1 }                  # cost of previous move
sub WEAPON ()    { 2 }                  # mostly only for monsters
sub LOOT ()      { 3 }                  # player inventory
sub SHIELDUP ()  { 4 }                  # player shield recharge gem
# GEM stash slots
sub GEM_NAME ()  { 0 }
sub GEM_VALUE () { 1 }
sub GEM_REGEN () { 2 }

sub START_HP () { 100 }                 # player start (and max) HP
sub LOOT_MAX () { NEED_ROWS - 2 }       # avoids scrolling, status bar wipeout

sub WEAP_DMG () { 0 }    # for WEAPON stash slot (mostly for monsters)
sub W_RANGE ()  { 1 }    # max shooting range
sub W_COST ()   { 2 }    # recharge time after shot
sub W_TOHIT ()  { 3 }    # to-hit values ...

sub MOVE_LVLUP ()   { -1 }    # NOTE tied to level change math
sub MOVE_FAILED ()  { 0 }     # for zero-cost player moves
sub MOVE_LVLDOWN () { 1 }     # NOTE tied to level change math
sub MOVE_OKAY ()    { 2 }     # non-level-change costly moves

# energy constants, see game_loop for the system
sub CAN_MOVE ()     { 0 }
sub DEFAULT_COST () { 10 }
sub DIAG_COST ()    { 14 }
sub NLVL_COST ()    { 15 }    # time to gate to next level

sub RUN_MAX () { 4 }

########################################################################
#
# VARIABLES

our $Violent_Sleep_Of_Reason = 0;

our @Animates;    # things with energy, HERO always in first slot
our @LMap;        # level map. array of array of array of ...

our $Draw_Delay   = 0.15;
our $Energy_Spent = 0;
our $Level        = 1;      # current level
our $Level_Max    = 1;
our $RKFN;                  # function handling key reads
our $Replay_Delay = 0.2;
our $Replay_FH;
our $Save_FH;
our $Seed;                  # cached value, jsf.c internalizes this
our $Sticky;                # for runner/running support
our $Sticky_Max = 0;
our $Turn_Count = 0;
our %Visible_Cell;          # x,y => [x,y] of cells visible in FOV
our @Visible_Monst;         # [x,y] of visible monsters
our %Warned_About;          # limit annoying messages

our %Damage_From = (
    acidburn => sub {
        my ($src, $duration) = @_;
        my $max    = $duration >> 1;
        my $damage = 0;
        for (1 .. $duration) {
            $damage += coinflip();
            $damage-- if onein(3);
            if ($damage > $max) {
                $damage = $max;
                last;
            }
        }
        return max(1, $damage);
    },

    # monster damages (by species, below) get routed through here
    attackby => sub {
        my ($ani) = @_;
        goto $ani->[STASH][WEAPON][WEAP_DMG]->&*;
    },

    falling => sub {
        my $dice   = 1;
        my $damage = 0;
        while (1) {
            my $roll = roll($dice, 4);
            $damage += $roll;
            last if $roll <= 2 or $dice >= 4;
            $dice++;
        }
        return $damage;
    },

    # custom FUNGI damage is based on range (ideal attack pattern for
    # the player is probably similar to using a rapier in Brogue)
    plburn => sub {
        my (undef, $range) = @_;
        return coinflip() if $range > 3;
        my $dice = 4 - $range;
        my $damage;
        do { $damage = roll($dice, 6) } until ($damage <= 18);
        return $damage;
    },
    # pretty sure this is only fungus friendly fire
    plsplash => sub { roll(2, 8) },

    # listed here for reference but get called to through 'attackby'.
    GHAST,
    sub { roll(3, 2) - 1 },
    HERO,
    sub { roll(4, 3) + 2 },
    MIMIC,
    sub { roll(2, 4) },
    STALKER,
    sub { roll(4, 2) },
    TROLL,
    sub { roll(3, 6) + 2 },
);

our %Hit_Points = (FUNGI, 42, GHAST, 28, MIMIC, 24, STALKER, 36, TROLL, 48,);

# NOTE these MUST be kept in sync with the W_RANGE max
our %To_Hit = (
    FUNGI, [ 100, 100, 100, 50 ],
    GHAST, [ 65, 50, 35, 25, 10 ],
    MIMIC, [ 10, 20, 35, 50, 50, 35, 20, 10 ],
    STALKER, [ 80, 75, 70, 65, 60, 55, 50, 45, 45, 30, 25, 10 ],
    TROLL,   [ 70, 60, 50, 40, 25, 15, 5 ],
);
# W_RANGE how far the monster will shoot; W_COST is how long the weapon
# takes to recharge after a successful shot
#
#   W_RANGE  W_COST
our %Weap_Stats = (
    FUNGI,   [ 4,  31 ], GHAST, [ 5, 6 ], MIMIC, [ 8, 13 ],
    STALKER, [ 12, 21 ], TROLL, [ 7, 29 ],
);

# these are "class objects"; see reify and the make_* routines
#              GENUS    SPECIES DISPLAY UPDATE (passive effects)
our %Thingy = (
    FUNGI,   [ ANIMAL,  FUNGI,   'F', \&update_fungi ],
    GHAST,   [ ANIMAL,  GHAST,   'G', \&update_ghast ],
    HERO,    [ ANIMAL,  HERO,    '@', \&update_player ],
    MIMIC,   [ ANIMAL,  MIMIC,   'M', \&update_mimic ],
    STALKER, [ ANIMAL,  STALKER, 'Q', \&update_stalker ],
    TROLL,   [ ANIMAL,  TROLL,   'T', \&update_troll ],
    AMULET,  [ VEGGIE,  AMULET,  "\e[1m," . TERM_NORM ],
    GEM,     [ VEGGIE,  GEM,     '*' ],
    ACID,    [ MINERAL, ACID,    '~', \&passive_burn ],
    FLOOR,   [ MINERAL, FLOOR,   '.' ],
    GATE,   [ MINERAL, GATE,   '%' ],    # stair, rogue 3.6 style
    HOLE,   [ MINERAL, HOLE,   ' ' ],    # shaft
    RUBBLE, [ MINERAL, RUBBLE, '^' ],
    WALL,   [ MINERAL, WALL,   '#' ],
);

# NOTE these may need to be fairly short, see move_examine
our %Descript = (
    ACID,   'Acid pool',       AMULET,  AMULET_NAME,
    FLOOR,  'Floor',           FUNGI,   'Plasma Tower',
    GATE,   'Gate',            GEM,     'gemstone',
    GHAST,  'Gatling Gun',     HERO,    'Hero',
    HOLE,   'Crevasse',        MIMIC,   'Mortar',
    RUBBLE, 'bunch of rubble', STALKER, 'Quad-laser Array',
    TROLL,  'Railgun Tower',   WALL,    'wall',
);

# for looking around with, see move_examine
our %Examine_Offsets = (
    'h' => [ -1, +0 ],
    'j' => [ +0, +1 ],
    'k' => [ +0, -1 ],
    'l' => [ +1, +0 ],
    'y' => [ -1, -1 ],
    'u' => [ +1, -1 ],
    'b' => [ -1, +1 ],
    'n' => [ +1, +1 ],
);

# these define what happens when various keys are mashed
our %Key_Commands = (
    'h' => move_player_maker(-1, +0, DEFAULT_COST),
    'j' => move_player_maker(+0, +1, DEFAULT_COST),
    'k' => move_player_maker(+0, -1, DEFAULT_COST),
    'l' => move_player_maker(+1, +0, DEFAULT_COST),
    'y' => move_player_maker(-1, -1, DIAG_COST),
    'u' => move_player_maker(+1, -1, DIAG_COST),
    'b' => move_player_maker(-1, +1, DIAG_COST),
    'n' => move_player_maker(+1, +1, DIAG_COST),
    ' ' => \&move_nop,
    ',' => \&move_pickup,
    '.' => \&move_nop,
    '<' => \&move_gate_up,
    '>' => \&move_gate_down,
    '?'    => sub { help_screen(); return MOVE_FAILED, 0 },
    '@'    => \&report_position,
    'E'    => \&move_equip,
    'G'    => sub { hide_screen(); return MOVE_FAILED, 0 },
    'M'    => sub { show_messages(); return MOVE_FAILED, 0 },
    'Q'    => \&move_quit,
    'R'    => \&move_remove,
    'd'    => \&move_drop,
    'g'    => \&move_pickup,
    'i'    => \&manage_inventory,
    'p'    => sub { pkc_clear(); return MOVE_FAILED, 0 },
    'v'    => \&report_version,
    'x'    => \&move_examine,
    '~'    => \&report_version,
    "\003" => sub { return MOVE_FAILED, 0, '1203' },                 # <C-c>
    "\011" => sub { @_ = "\011"; goto &move_examine },               # TAB
    "\014" => sub { log_dim(); refresh_board(); MOVE_FAILED, 0 },    # <C-l>
    "\032" => sub { return MOVE_FAILED, 0, '1220' },                 # <C-z>
    "\033" => sub { return MOVE_FAILED, 0, '121B' },
);
# weak effort at numpad support (not supported for running nor for leaps
# in examine mode)
@Key_Commands{qw/1 2 3 4 5 6 7 8 9/} = @Key_Commands{qw/b j n h . l y k u/};

# limited duration run because the raycast does not stop for unseen gems
# or gates that the player may wish to take note of
$Key_Commands{'H'} = move_player_runner('h', RUN_MAX);
$Key_Commands{'J'} = move_player_runner('j', RUN_MAX);
$Key_Commands{'K'} = move_player_runner('k', RUN_MAX);
$Key_Commands{'L'} = move_player_runner('l', RUN_MAX);
$Key_Commands{'Y'} = move_player_runner('y', RUN_MAX);
$Key_Commands{'U'} = move_player_runner('u', RUN_MAX);
$Key_Commands{'B'} = move_player_runner('b', RUN_MAX);
$Key_Commands{'N'} = move_player_runner('n', RUN_MAX);

$Key_Commands{'S'} = move_player_snooze('.');

my @Level_Features = (
    {   ACID, 50, GATE, 2, HOLE, 200, RUBBLE, 400, WALL, 100,
        xarci => [ GHAST, GHAST, MIMIC ],
    },
    {   ACID, 100, GATE, 2, HOLE, 100, RUBBLE, 100, WALL, 200,
        xarci => [ GHAST, GHAST, MIMIC, MIMIC, STALKER, TROLL ],
    },
    {   ACID, 400, GATE, 2, RUBBLE, 50, WALL, 50,
        xarci => [ FUNGI, GHAST, GHAST, STALKER, TROLL, TROLL ],
    },
    {   ACID, 100, AMULET, 1, GATE, 2, RUBBLE, 0, WALL, 300,
        xarci => [ FUNGI, GHAST, GHAST, STALKER, TROLL, TROLL ],
    },
    {   ACID, 200, AMULET, 1, GATE, 1, RUBBLE, 200, WALL, 50,
        xarci => [ GHAST, STALKER, STALKER, TROLL, TROLL ],
    },
);

########################################################################
#
# SUBROUTINES

sub abort_run {
    my ($col, $row, $dcol, $drow) = @_;
    return 1
      if defined $LMap[$row][$col][VEGGIE]
      or defined $LMap[$drow][$dcol][ANIMAL]
      or $LMap[$row][$col][MINERAL][SPECIES] == GATE;
    my $dftype = $LMap[$drow][$dcol][MINERAL][SPECIES];
    return 1 unless $dftype == FLOOR or $dftype == GATE;
    return 0;
}

sub apply_damage {
    my ($ani, $cause, @rest) = @_;
    my $damage = $Damage_From{$cause}->(@rest);
    $ani->[STASH][HITPOINTS] -= $damage;
    if ($ani->[STASH][HITPOINTS] <= 0) {
        if ($ani->[SPECIES] == HERO) {
            $ani->[DISPLAY] = '&';                 # the @ got unravelled
            $ani->[UPDATE]  = \&update_gameover;
            log_message('Shield module failure.') unless $Warned_About{shieldfail}++;
        } else {
            log_message($Descript{ $ani->[SPECIES] }
                  . ' destroyed by '
                  . $Descript{ $rest[0]->[SPECIES] });
            if ($ani->[SPECIES] == FUNGI and $ani->[LMC][MINERAL] != GATE and onein(20)) {
                reify($ani->[LMC],
                    passive_msg_maker('Broken rainbow conduits jut up from the regolith.'));
            }
            $ani->[BLACK_SPOT] = 1;
            undef $ani->[LMC][ANIMAL];
        }
    } else {
        log_message($Descript{ $rest[0]->[SPECIES] }
              . ' does '
              . $damage
              . ' damage to '
              . $Descript{ $ani->[SPECIES] });
    }
    if ($ani->[SPECIES] == HERO) {
        undef $Sticky;
        print display_hitpoints();
    }
}

# this used to pass along more information to the passive_* calls
sub apply_passives {
    my ($ani, $duration, $isnewcell) = @_;
    my $fn = $ani->[LMC][MINERAL][UPDATE] // return;
    push @_, $ani->[LMC][MINERAL];
    goto $fn->&*;
}

sub await_quit { $RKFN->({ "\033" => 1, 'q' => 1 }) }

sub bad_terminal {
    return 0 unless -t *STDOUT;
    my ($cols, $rows) = (GetTerminalSize(*STDOUT))[ 0, 1 ];
    !defined $cols or $cols < NEED_COLS or $rows < NEED_ROWS;
}

sub bail_out {
    restore_term();
    print at_col(0), CLEAR_LINE;
    warn $_[0] if @_;
    game_over('Minos III was unexpectedly hit by a rogue planet, the end.');
}

sub between {
    my ($min, $max, $value) = @_;
    if ($value < $min) {
        $value = $min;
    } elsif ($value > $max) {
        $value = $max;
    }
    return $value;
}

sub display_cellobjs {
    my $s = AT_CELLOBJS . '[';
    for my $i (VEGGIE, MINERAL) {
        my $obj = $Animates[HERO][LMC][$i];
        $s .= (defined $obj and $obj->@*) ? $obj->[DISPLAY] : ' ';
    }
    return $s . ']';
}

sub display_hitpoints {
    my $hp = $Animates[HERO][STASH][HITPOINTS];
    $hp = 0 if $hp < 0;
    my $ticks = $hp >> 1;
    my $hpbar = '=' x $ticks;
    $hpbar .= '-' if $hp & 1;
    my $len = length $hpbar;
    $hpbar .= ' ' x (50 - $len) if $len < 50;
    return AT_HPBAR . "SP[\e[1m" . $hpbar . TERM_NORM . ']';
}

sub display_shieldup {
    my $ch = ' ';
    if (defined $Animates[HERO][STASH][SHIELDUP]) {
        if ($Animates[HERO][STASH][SHIELDUP][STASH][GEM_NAME] eq AMULET_NAME) {
            $ch = $Thingy{ AMULET, }->[DISPLAY];
        } else {
            $ch = $Thingy{ GEM, }->[DISPLAY];
        }
    }
    AT_SHIELDUP . '[' . $ch . ']';
}

# does a monster hit? -1 for out of range, 0 for miss, 1 for hit
sub does_hit {
    my ($dist, $weap) = @_;
    if ($dist > $weap->[W_RANGE]) {
        # snooze monster for minimum time for player to be in range
        my $away = $dist - $weap->[W_RANGE];
        return -1, DEFAULT_COST * $away;
    }
    return (irand(100) < $weap->[ W_TOHIT + $dist - 1 ]), $weap->[W_COST];
}

sub fisher_yates_shuffle {
    my ($array) = @_;
    my $i = @$array;
    return if $i < 2;
    while (--$i) {
        my $j = irand($i + 1);
        next if $i == $j;
        @$array[ $i, $j ] = @$array[ $j, $i ];
    }
}

sub game_loop {
    game_over('Terminal must be at least ' . NEED_COLS . 'x' . NEED_ROWS)
      if bad_terminal();
    ReadMode 'raw';
    $SIG{$_}    = \&bail_out for qw(INT HUP TERM PIPE QUIT USR1 USR2 __DIE__);
    $SIG{CONT}  = \&refresh_board;
    $SIG{WINCH} = sub {
        log_message('The terminal is too small!') if bad_terminal();
        refresh_board();
    };
    STDOUT->autoflush(1);

    init_jsf($Seed);
    init_map();
    make_player();
    generate_map();
    print ALT_SCREEN, HIDE_CURSOR, HIDE_POINTER, CLEAR_SCREEN, TERM_NORM;
    show_status_bar();

  GLOOP: while (1) {
        my $min_cost = min(map { $_->[ENERGY] } @Animates);
        my @movers;
        for my $ani (@Animates) {
            $ani->[ENERGY] -= $min_cost;
            push @movers, $ani if $ani->[ENERGY] <= CAN_MOVE;
        }
        # simultaneous move shuffle, all movers "get a go" though there
        # can be edge cases related to LOS and wall destruction and who
        # goes when
        fisher_yates_shuffle(\@movers);

        my $new_level = 0;
        for my $ani (@movers) {
            my ($status, $cost) = $ani->[UPDATE]->($ani);
            $ani->[ENERGY] += $ani->[STASH][ECOST] = $cost;
            $new_level = $status
              if $status == MOVE_LVLDOWN or $status == MOVE_LVLUP;
        }
        if ($new_level != 0) {
            $Level += $new_level;
            $Level_Max = max($Level, $Level_Max);
            has_won() if $Level <= 0;
            my $ammie = (generate_map())[0];
            $Violent_Sleep_Of_Reason = 1;
            # NOTE other half of this is applied in the Bump-into-HOLE
            # logic, elsewhere. this last half happens here as the new
            # level is not yet available prior to the fall
            apply_passives($Animates[HERO], $Animates[HERO][STASH][ECOST] >> 1, 1);
            show_status_bar();
            log_message('Proximal ' . AMULET_NAME . ' readings detected.') if $ammie;
            next GLOOP;
        }
        @Animates = grep { !$_->[BLACK_SPOT] } @Animates;
    }
}

sub game_over {
    my ($message) = @_;
    restore_term();
    print at_col(0), CLEAR_LINE, $message, "\n", CLEAR_LINE;
    exit(1);
}

sub generate_map {
    my $findex    = min($Level, scalar @Level_Features) - 1;
    my $has_ammie = has_amulet();

    splice @Animates, 1;
    my $herop = $Animates[HERO][LMC][WHERE];
    my ($col, $row) = $herop->@[ PCOL, PROW ];

    # reset to bare ground plus some white noise seed points
    my @seeds;
    my $left  = 80;         # hopefully overkill
    my $total = MAP_SIZE;
    for my $r (0 .. MAP_ROWS - 1) {
        for my $c (0 .. MAP_COLS - 1) {
            $LMap[$r][$c]->@[ MINERAL, VEGGIE ] = ($Thingy{ FLOOR, }, undef);
            unless ($r == $row and $c == $col) {
                undef $LMap[$r][$c]->@[ANIMAL];
                if (irand($total) < $left) {
                    push @seeds, [ $c, $r ];
                    $left--;
                }
            }
            $total--;
        }
    }

    my %floored;    # have we put some custom floor here?

    # brown noise for these features to make them clump together-ish
    for my $floor (RUBBLE, ACID, HOLE, WALL) {
        my $want = $Level_Features[$findex]{$floor} // 0;
        # ... and a few more than called for, for variety
        $want += irand(2 + ($want >> 1)) if $want > 0;
        while ($want > 0) {
            my $goal = max($want, min(20, int($want / 10)));
            my $seed = extract(\@seeds);
            $want -= place_floortype(
                $seed->@[ PCOL, PROW ],
                $floor, $goal, 60,
                [   [ -1, 0 ], [ -1, 1 ], [ 0,  -1 ], [ 0, 1 ],  [ 1, -1 ], [ 1, 0 ],
                    [ 1,  1 ], [ -2, 0 ], [ -2, 2 ],  [ 0, -2 ], [ 0, 2 ],  [ 2, -2 ],
                    [ 2,  0 ], [ 2,  2 ], [ 3,  0 ],
                ],
                \%floored
            );
        }
        bail_out("Conditions on Minos III proved too harsh.") unless @seeds;
    }

    # points that have gems or gates; these MUST be pathable and may
    # have monsters lurking near them
    my @goodp;

    for (1 .. $Level_Features[$findex]{ GATE, }) {
        my $point = extract(\@seeds);
        ($col, $row) = $point->@[ PCOL, PROW ];
        push @goodp, $point;
        $LMap[$row][$col][MINERAL] = $Thingy{ GATE, };
        bail_out("Conditions on Minos III proved too harsh.") unless @seeds;
    }

    my $put_ammie = 0;
    if (exists $Level_Features[$findex]{ AMULET, } and !$has_ammie) {
        my $gem   = (make_amulet())[0];
        my $point = extract(\@seeds);
        ($col, $row) = $point->@[ PCOL, PROW ];
        push @goodp, $point;
        $LMap[$row][$col][VEGGIE] = $gem;
        $put_ammie = 1;
    }

    # gems no longer generate during the climb out
    my $gmax   = 200;
    my $GGV    = 0;
    my $gcount = 0;
    while (!$has_ammie) {
        my ($gem, $value, $bonus) = make_gem();
        my $point = extract(\@seeds);
        ($col, $row) = $point->@[ PCOL, PROW ];
        push @goodp, $point;
        $LMap[$row][$col][VEGGIE] = $gem;
        # influences max score and how much shield repair is possible
        $GGV  += $value;
        $gmax += $bonus;
        $gcount++;
        last if $GGV > $gmax;
    }

    # ensure that the good points (gems, gates) and the hero are all
    # connected. this may provide some hints on the final level due to
    # the lack of rubble
    ($col, $row) = extract(\@seeds)->@[ PCOL, PROW ];
    $LMap[$row][$col][MINERAL] = $Thingy{ onein(100) ? RUBBLE : FLOOR };
    if (onein(4)) {
        reify($LMap[$row][$col],
            passive_msg_maker("Something was written here, but you can't make it out.", 1));
    }
    pathable($col, $row, $herop, @goodp);

    # and now an assortment of monsters
    for (1 .. $Level + roll(3, 3) + $has_ammie * 4) {
        my $energy = $has_ammie ? CAN_MOVE : DEFAULT_COST;
        place_monster($Level_Features[$findex]{xarci}, $energy, \@seeds);
    }

    # fungi camping -- fungi are not useful in the normal rotation as
    # it's too easy to simply ignore them. so sometimes they camp a good
    # spot. and since players are pretty good pattern detectors, allow
    # other monster types to camp spots as well
    my @campers = (FUNGI, FUNGI, FUNGI, FUNGI, TROLL, TROLL, STALKER, GHAST);
    my $camping = 0;
    my $codds   = ($has_ammie ? 31 : 0) + int exp $Level;
    for my $gp (@goodp) {
        next if irand(100) > $codds;
        # MUST check here that we're not clobbering some other Animate
        my @free;
        push @free, ($gp) x 7
          unless defined $LMap[ $gp->[PROW] ][ $gp->[PCOL] ][ANIMAL];
        with_adjacent(
            $gp->@[ PCOL, PROW ],
            sub {
                my ($adj) = @_;
                push @free, $adj unless defined $LMap[ $adj->[PROW] ][ $adj->[PCOL] ][ANIMAL];
            }
        );
        place_monster(\@campers, DEFAULT_COST, \@free) if @free;
        $camping++;
    }

    # be nice and put a gem close (but not too close) to the player when
    # they start the game
    if ($Level == 1 and !$has_ammie) {
        my $mindist = 2 + roll(3, 2);
        my $gem     = (make_gem())[0];
        my $point   = min_by sub {
            my $d =
              distance($Animates[HERO][LMC][WHERE]->@[ PCOL, PROW ], $_->@[ PCOL, PROW ]);
            $d < $mindist ? ~0 : $d;
        }, @seeds;
        # ... and that they can actually get to said gem
        ($col, $row) = $point->@[ PCOL, PROW ];
        $LMap[$row][$col][VEGGIE]  = $gem;
        $LMap[$row][$col][MINERAL] = $Thingy{ onein(10) ? RUBBLE : FLOOR };
        pathable($col, $row, $herop);
    }

    return $put_ammie, $gcount, $GGV, scalar(@seeds), $camping;
}

sub getkey {
    my ($expect) = @_;
    my $key;
    while (1) {
        $key = ReadKey(0);
        last if exists $expect->{$key};
    }
    print $Save_FH $key if defined $Save_FH;
    return $key;
}

sub has_amulet {
    for my $item ($Animates[HERO][STASH][LOOT]->@*) {
        return 1 if $item->[SPECIES] == AMULET;
    }
    # also must check shield regen slot; could set a flag but then they
    # could drop the damn thing or burn it up in the shield module argh
    # so complicated
    return 1
      if defined $Animates[HERO][STASH][SHIELDUP]
      and $Animates[HERO][STASH][SHIELDUP][STASH][GEM_NAME] eq AMULET_NAME;
    return 0;
}

sub has_lost {
    restore_term();
    my $score = score(0);
    print CLEAR_SCREEN, "Alas, victory was not to be yours.\n\n$score\n";
    exit(1);
}

sub has_won {
    restore_term();
    my $score = score(1);
    # some of this is borrowed from rogue 3.6.3
    print CLEAR_SCREEN, <<"WIN_SCREEN";

  @   @               @   @           @          @@@  @     @
  @   @               @@ @@           @           @   @     @
  @   @  @@@  @   @   @ @ @  @@@   @@@@  @@@      @  @@@    @
   @@@@ @   @ @   @   @   @     @ @   @ @   @     @   @     @
      @ @   @ @   @   @   @  @@@@ @   @ @@@@@     @   @     @
  @   @ @   @ @  @@   @   @ @   @ @   @ @         @   @  @
   @@@   @@@   @@ @   @   @  @@@@  @@@@  @@@     @@@   @@   @

    Congratulations. Victory is yours.

$score
WIN_SCREEN
    exit(0);
}

sub help_screen {
    print CLEAR_SCREEN, at(1, 1), <<'HELP_SCREEN', "\n:", SHOW_CURSOR;
                     Xomb Commands Reference Manual

     y  k  u     Motion is traditional to rogue(6) as shown in the
      \ | /      compass to the left. Other commands, of which some
    h - @ - l    take time to complete, include:
      / | \
     b  j  n                . - wait a turn      x - examine board
                          g , - pick up item     i - show inventory
    M - show messages     < > - activate gate    E - equip a gem
    p - clear PKC code    C-l - redraw screen    R - remove a gem
    ? - show help         v   - show version     d - drop a gem
    @ - show location     Q   - quit the game  TAB - examine monster
    S - snooze until healed     HJKLYUBN run in that direction

    Esc or q will exit from sub-displays such as this one. Prompts
    must be answered with Y to carry out the action; N or n or Esc
    will reject the action. Map symbols include:

      @  you     % gate    * gemstone    . empty cell
      #  wall    ~ acid    ^ rubble        crevasse

    Consult xomb(1) or `perldoc xomb` for additional documentation.
HELP_SCREEN
    await_quit();
    print HIDE_CURSOR;
    log_dim();
    refresh_board();
}

sub hide_screen {
    print CLEAR_SCREEN, at(1, 2), <<"BOSS_SCREEN", "\n:", SHOW_CURSOR;
LS(1)                     BSD General Commands Manual                    LS(1)

\e[1mNAME\e[m
     \e[1mls\e[m -- list directory contents

SYNOPSIS
     \e[1mls\e[m [-\e[1mABCFGHLOPRSTUW\@abcdefghiklmnopqrstuwx1\e[m] [\e[4mfile\e[m \e[4m...\e[m]

\e[1mDESCRIPTION\e[m
     For each operand that names a \e[4mfile\e[m of a type other than directory, ls
     displays its name as well as any requested, associated information.  For
     each operand that names a \e[4mfile\e[m of type directory, \e[1mls\e[m displays the names
     of files contained within that directory, as well as any requested, asso-
     ciated information.

     If no operands are given, the contents of the current directory are dis-
     played.  If more than one operand is given, non-directory operands are
     displayed first; directory and non-directory operands are sorted sepa-
     rately and in lexicographical order.

     The following options are available:
BOSS_SCREEN
    await_quit();
    print HIDE_CURSOR;
    log_dim();
    refresh_board();
}

sub init_map {
    for my $r (0 .. MAP_ROWS - 1) {
        for my $c (0 .. MAP_COLS - 1) {
            my $point = [ $c, $r ];
            push $LMap[$r]->@*, [$point];    # setup WHERE
        }
    }
}

{
    my $lc  = 1;
    my @log = ('Welcome to Xomb.');

    sub log_dim { return if $lc == 2; $lc = $lc == 0 ? 2 : 0 }

    sub log_message {
        my ($message) = @_;
        while (@log >= MSG_MAX) { shift @log }
        push @log, $message;
        $lc = 1;
        show_top_message();
    }

    sub show_messages {
        my $s = SHOW_CURSOR;
        while (my ($i, $message) = each @log) {
            $s .= at_row(MSG_ROW + $i) . CLEAR_RIGHT . $message;
        }
        print $s, at_row(MSG_ROW + @log), CLEAR_RIGHT, "-- press Esc to continue --";
        await_quit();
        print HIDE_CURSOR;
        log_dim();
        refresh_board();
    }

    sub show_top_message {
        print AT_MSG_ROW, CLEAR_RIGHT, "\e[", $lc, 'm', $log[-1], TERM_NORM;
    }
}

sub loot_value {
    my $value = 0;
    for my $item ($Animates[HERO][STASH][LOOT]->@*) {
        # AMULET considered as gem as they might have burned it up a bit
        $value += $item->[STASH][GEM_VALUE];
    }
    # they probably won't need to charge their shield after the game
    # is over?
    $value += $Animates[HERO][STASH][SHIELDUP][STASH][GEM_VALUE]
      if defined $Animates[HERO][STASH][SHIELDUP];
    return $value;
}

# expensive gem (vegetable) that speciated
sub make_amulet {
    my $gem;
    $gem->@[ GENUS, SPECIES, DISPLAY ] = $Thingy{ AMULET, }->@*;
    $gem->[STASH]->@[ GEM_NAME, GEM_VALUE, GEM_REGEN ] =
      (AMULET_NAME, AMULET_VALUE, AMULET_REGEN);
    return $gem, AMULET_VALUE;
}

sub make_gem {
    my ($name, $value, $regen);
    # lower regen is better and thus more rare. higher value makes for a
    # higher score, or more shield that can be repaired
    if (onein(100)) {
        $name  = "Bloodstone";
        $value = 90 + roll(2, 10);
        $regen = 3;
    } elsif (onein(20)) {
        $name  = "Sunstone";
        $value = 60 + roll(2, 10);
        $regen = 4;
    } else {
        $name  = "Moonstone";
        $value = 40 + roll(2, 10);
        $regen = 4;
    }
    # flavor text makes things better
    my $bonus = 0;
    if (onein(1000)) {
        $name = 'Pearl ' . $name;
        $value += 90 + roll(2, 10);
        $regen = 2;
        $bonus = 100;
    } elsif (onein(3)) {
        my @adj = qw/Imperial Mystic Rose Smoky Warped/;
        $name = pick(\@adj) . ' ' . $name;
        $value += 40 + roll(2, 10);
        $bonus = irand(30);
    }
    my $gem;
    $gem->@[ GENUS, SPECIES, DISPLAY ] = $Thingy{ GEM, }->@*;
    $gem->[STASH]->@[ GEM_NAME, GEM_VALUE, GEM_REGEN ] =
      ($name, $value, $regen);
    return $gem, $value, $bonus;
}

sub make_monster {
    my (%params) = @_;
    my $monst;
    $monst->@[ GENUS, SPECIES, DISPLAY, UPDATE, ENERGY ] =
      ($Thingy{ $params{species} }->@*, $params{energy});
    $monst->[STASH]->@[ HITPOINTS, ECOST ] =
      ($Hit_Points{ $params{species} }, CAN_MOVE);
    $monst->[STASH][WEAPON]->@[ WEAP_DMG, W_RANGE, W_COST ] =
      ($Damage_From{ $params{species} }, $Weap_Stats{ $params{species} }->@*,);
    push $monst->[STASH][WEAPON]->@*, $To_Hit{ $params{species} }->@*;
    return $monst;
}

sub make_player {
    my $hero;

    $hero->@[ GENUS, SPECIES, DISPLAY, UPDATE, ENERGY ] =
      ($Thingy{ HERO, }->@*, CAN_MOVE,);
    $hero->[STASH]->@[ HITPOINTS, ECOST, LOOT ] = (START_HP, CAN_MOVE, []);

    # bascially a bulldozer, unlike the other weapons
    $hero->[STASH][WEAPON][WEAP_DMG] = $Damage_From{ HERO, };

    my $col = irand(MAP_COLS);
    my $row = irand(MAP_ROWS);
    $LMap[$row][$col][ANIMAL] = $hero;
    $hero->[LMC] = $LMap[$row][$col];

    $Animates[HERO] = $hero;

    return $col, $row;
}

sub manage_inventory {
    my ($command, $message) = @_;
    print SHOW_CURSOR;
    my $loot = $Animates[HERO][STASH][LOOT];
    my $offset;
    my $s        = '';
    my $has_loot = 0;
    if ($loot->@*) {
        $has_loot = 1;
        my $label = 'A';
        while (my ($i, $item) = each $loot->@*) {
            $s .=
                at_row(MSG_ROW + $i)
              . CLEAR_RIGHT
              . $label++ . ') '
              . $item->[DISPLAY] . ' '
              . veggie_name($item);
        }
        $offset = $loot->@*;
    } else {
        $s .= AT_MSG_ROW . CLEAR_RIGHT . "Inventory is empty.";
        $offset = 1;
    }
    $s .= at_row(MSG_ROW + $offset) . CLEAR_RIGHT . '-- ';
    if ($message) {
        $s .= $message;
    } else {
        $s .= 'press Esc to continue';
        $s .= ' or (d)rop, (E)quip' if $has_loot;
    }
    print $s, ' --';

    my %choices = ("\033" => 1, 'q' => 1);
  CMD: while (1) {
        my $key = $command // $RKFN->({ "\033" => 1, 'q' => 1, 'd' => 1, 'E' => 1 });
        last if $key eq "\033" or $key eq 'q';
        undef $command;
        next unless $has_loot;
        if ($key eq 'd') {
            if (!defined $message) {
                print at_row(MSG_ROW + $offset), CLEAR_RIGHT,
                  "-- drop item L)able or Esc to exit --";
            }
            if (defined $Animates[HERO][LMC][VEGGIE]) {
                pkc_log_code('0104');
                last CMD;
            }
            while (1) {
                @choices{ map { chr 65 + $_ } 0 .. $loot->$#* } = ();
                my $drop = $RKFN->(\%choices);
                last CMD if $drop eq "\033" or $drop eq 'q';
                my $i = ord($drop) - 65;
                if ($i < $loot->@*) {
                    $Animates[HERO][LMC][VEGGIE] = splice $loot->@*, $i, 1;
                    print display_cellobjs();
                    last CMD;
                }
            }
        } elsif ($key eq 'E') {
            if (!defined $message) {
                print at_row(MSG_ROW + $offset), CLEAR_RIGHT,
                  "-- Equip item L)able or Esc to exit --";
            }
            while (1) {
                @choices{ map { chr 65 + $_ } 0 .. $loot->$#* } = ();
                my $use = $RKFN->(\%choices);
                last CMD if $use eq "\033" or $use eq 'q';
                my $i = ord($use) - 65;
                if ($i < $loot->@*) {
                    use_item($loot, $i, $Animates[HERO][STASH]) and print display_shieldup();
                    last CMD;
                }
            }
        }
    }
    print HIDE_CURSOR;
    log_dim();
    refresh_board();
    return MOVE_FAILED, 0;
}

# only the player can move in this game so this is not as generic as it
# should be
sub move_animate {
    my ($ani, $cols, $rows, $cost) = @_;
    my $lmc  = $ani->[LMC];
    my $dcol = $lmc->[WHERE][PCOL] + $cols;
    my $drow = $lmc->[WHERE][PROW] + $rows;
    if (   $dcol < 0
        or $dcol >= MAP_COLS
        or $drow < 0
        or $drow >= MAP_ROWS) {
        undef $Sticky;
        return MOVE_FAILED, 0, '0001';
    }
    if (defined $Sticky) {
        if (@Visible_Monst or abort_run($lmc->[WHERE]->@[ PCOL, PROW ], $dcol, $drow)) {
            undef $Sticky;
            return MOVE_FAILED, 0, '0065';
        }
    }
    # Bump combat, as is traditional
    my $target = $LMap[$drow][$dcol][ANIMAL];
    if (defined $target) {
        if (irand(100) < 90) {
            apply_damage($target, 'attackby', $ani);
        } else {
            pkc_log_code('0302');
        }
        $cost += rubble_delay($ani, $cost) if $lmc->[MINERAL][SPECIES] == RUBBLE;
        apply_passives($ani, $cost, 0);
        return MOVE_OKAY, $cost;
    }
    $target = $LMap[$drow][$dcol][MINERAL];
    return MOVE_FAILED, 0, '0002' if $target->[SPECIES] == WALL;
    # NOTE the rubble delay is applied *before* they can move out of
    # that acid pond that they are in:
    #   "Yes, we really hate players, damn their guts."
    #     -- Dungeon Crawl Stone Soup, cloud.cc
    $cost += rubble_delay($ani, $cost) if $target->[SPECIES] == RUBBLE;
    if ($target->[SPECIES] == HOLE) {
        return MOVE_FAILED, 0
          if nope_regarding('Falling may cause damage', undef,
            'You decide against it.');
        apply_passives($ani, $cost >> 1, 0);
        log_message('You plunge down into the crevasse.');
        relocate($ani, $dcol, $drow);
        pkc_log_code('0099');
        # KLUGE fake the source of damage as from the floor
        my $src;
        $src->[SPECIES] = FLOOR;
        apply_damage($ani, 'falling', $src);
        return MOVE_LVLDOWN, $cost;
    } else {
        apply_passives($ani, $cost >> 1, 0);
        relocate($ani, $dcol, $drow);
        apply_passives($ani, $cost >> 1, 1);
        return MOVE_OKAY, $cost;
    }
}

sub move_drop {
    return MOVE_FAILED, 0, '0104'
      if defined $Animates[HERO][LMC][VEGGIE];
    return MOVE_FAILED, 0, '0112'
      unless $Animates[HERO][STASH][LOOT]->@*;
    @_ = ('d', 'drop item L)abel or Esc to exit');
    goto &manage_inventory;
}

sub move_equip {
    return MOVE_FAILED, 0, '0112'
      unless $Animates[HERO][STASH][LOOT]->@*;
    @_ = ('E', 'Equip item L)abel or Esc to exit');
    goto &manage_inventory;
}

sub move_examine {
    my ($command) = @_;
    my ($col,  $row)  = $Animates[HERO][LMC][WHERE]->@[ PCOL, PROW ];
    my ($pcol, $prow) = ($col, $row);
    print AT_MSG_ROW, CLEAR_RIGHT, SHOW_CURSOR,
      "-- move cursor, SHIFT moves faster. TAB for monsters. Esc to exit --";
    my $monst = 0;
    while (1) {
        my $loc = $col . ',' . $row;
        my $s   = '[' . $loc . '] ';
        if (exists $Visible_Cell{$loc}) {
            for my $i (ANIMAL, VEGGIE) {
                my $x = $LMap[$row][$col][$i];
                $s .= $x->[DISPLAY] . ' ' . $Descript{ $x->[SPECIES] } . ' '
                  if defined $x;
            }
            my $g = $LMap[$row][$col][MINERAL];
            if (defined $g) {
                if ($g->[SPECIES] == HOLE) {
                    $s .= $Descript{ $g->[SPECIES] };
                } else {
                    $s .= $g->[DISPLAY] . ' ' . $Descript{ $g->[SPECIES] };
                }
            }
        } else {
            $s .= '-- negative return on FOV scanner query --';
        }
        print at_row(STATUS_ROW), CLEAR_RIGHT, $s, at(map { MAP_DOFF + $_ } $col, $row);
        # this would need to be a bit more complicated to support numpad
        my $key = $command // $RKFN->(
            {   "\033" => 1,
                'q'    => 1,
                "\011" => 1,
                'h'    => 1,
                'j'    => 1,
                'k'    => 1,
                'l'    => 1,
                'y'    => 1,
                'u'    => 1,
                'b'    => 1,
                'n'    => 1,
                'H'    => 1,
                'J'    => 1,
                'K'    => 1,
                'L'    => 1,
                'Y'    => 1,
                'U'    => 1,
                'B'    => 1,
                'N'    => 1,
            }
        );
        last if $key eq "\033" or $key eq 'q';
        undef $command;
        if ($key eq "\011") {
            ($col, $row) = $Visible_Monst[ $monst++ ]->@[ PCOL, PROW ];
            $monst %= @Visible_Monst;
        } else {
            my $distance = 1;
            if (ord $key < 97) {    # SHIFT moves faster
                $key      = lc $key;
                $distance = RUN_MAX;
            }
            my $dir = $Examine_Offsets{$key};
            $col = between(0, MAP_COLS - 1, $col + $dir->[PCOL] * $distance);
            $row = between(0, MAP_ROWS - 1, $row + $dir->[PROW] * $distance);
        }
    }
    print HIDE_CURSOR, at_row(STATUS_ROW), CLEAR_RIGHT;
    log_dim();
    show_top_message();
    show_status_bar();
    return MOVE_FAILED, 0, onein(5000) ? '1202' : ();
}

sub move_gate_down {
    return MOVE_FAILED, 0, '0004'
      if $Animates[HERO][LMC][MINERAL][SPECIES] != GATE;
    if ($Level > @Level_Features) {
        log_message('The gate appears to be inactive.');
        return MOVE_FAILED, 0, '0014';
    }
    log_message('Gate activated.');
    $Violent_Sleep_Of_Reason = 1;
    return MOVE_LVLDOWN, NLVL_COST;
}

sub move_gate_up {
    return MOVE_FAILED, 0, '0004'
      if $Animates[HERO][LMC][MINERAL][SPECIES] != GATE;
    unless (has_amulet()) {
        log_message('You need the ' . AMULET_NAME . ' to ascend.');
        return MOVE_FAILED, 0, '0010';
    }
    log_message('Gate activated.');
    $Violent_Sleep_Of_Reason = 1;
    return MOVE_LVLUP, NLVL_COST;
}

sub move_nop {
    if (defined $Sticky
        and (@Visible_Monst or $Animates[HERO][LMC][MINERAL][SPECIES] == ACID)) {
        undef $Sticky;
        return MOVE_FAILED, 0;
    }
    apply_passives($Animates[HERO], DEFAULT_COST, 0);
    # NOTE constant amount of time even if they idle in rubble
    return MOVE_OKAY, DEFAULT_COST;
}

sub move_pickup {
    my $lmc = $Animates[HERO][LMC];
    return MOVE_FAILED, 0, '0101' unless defined $lmc->[VEGGIE];
    my $loot = $Animates[HERO][STASH][LOOT];
    return MOVE_FAILED, 0, '0102' if $loot->@* >= LOOT_MAX;
    my $cost = DEFAULT_COST;
    $cost += rubble_delay($Animates[HERO], $cost)
      if $lmc->[MINERAL][SPECIES] == RUBBLE;
    if ($lmc->[VEGGIE][SPECIES] == AMULET) {
        log_message('Obtained ' . AMULET_NAME . '! Ascend to win!');
        $Violent_Sleep_Of_Reason = 1;
    } else {
        log_message('Obtained ' . veggie_name($lmc->[VEGGIE]));
    }
    push $loot->@*, $lmc->[VEGGIE];
    print display_cellobjs();
    $lmc->[VEGGIE] = undef;
    return MOVE_OKAY, $cost;
}

sub move_player_maker {
    my ($cols, $rows, $mvcost) = @_;
    sub {
        my @ret = move_animate($Animates[HERO], $cols, $rows, $mvcost);
        print display_cellobjs();
        return @ret;
    }
}

sub move_player_runner {
    my ($key, $count) = @_;
    sub {
        $Sticky     = $key;
        $Sticky_Max = $count;
        goto $Key_Commands{$key}->&*;
    }
}

sub move_player_snooze {
    my ($key) = @_;
    sub {
        # no long snooze unless something to charge from
        return MOVE_FAILED, 0, '0063' unless defined $Animates[HERO][STASH][SHIELDUP];
        $Sticky     = $key;
        $Sticky_Max = START_HP * 5;
        goto $Key_Commands{$key}->&*;
    }
}

sub move_quit {
    return MOVE_FAILED, 0
      if nope_regarding('Really quit game?', undef, 'You decide against it.');
    has_lost();
}

sub move_remove {
    return MOVE_FAILED, 0, '0113'
      unless defined $Animates[HERO][STASH][SHIELDUP];
    my $loot = $Animates[HERO][STASH][LOOT];
    return MOVE_FAILED, 0, '0102' if $loot->@* >= LOOT_MAX;
    push $loot->@*, $Animates[HERO][STASH][SHIELDUP];
    undef $Animates[HERO][STASH][SHIELDUP];
    print display_shieldup();
    return MOVE_FAILED, 0;
}

sub nope_regarding {
    my ($message, $yes, $no) = @_;
    print AT_MSG_ROW, CLEAR_RIGHT, '/!\ ', $message, ' (Y/N)';
    my $key = $RKFN->({ 'Y' => 1, 'N' => 1, 'n' => 1, "\033" => 1 });
    my $ret;
    if ($key eq 'Y') {
        log_message($yes) if defined $yes;
        $ret = 0;
    } else {
        log_message($no) if defined $no;
        $ret = 1;
    }
    return $ret;
}

# only to the hero; map generation must place rubble/floor under monsters
sub passive_burn {
    my ($ani, $duration, $isnewcell, $obj) = @_;
    pkc_log_code('007E');
    log_message('Acid intrusion reported by shield module.')
      unless $Warned_About{acidburn}++;
    apply_damage($ani, 'acidburn', $obj, $duration);
}

sub passive_msg_maker {
    my ($message, $oneshot) = @_;
    sub {
        my ($ani, $duration, $isnewcell, $obj) = @_;
        if ($isnewcell) {
            log_message($message);
            undef $obj->[UPDATE] if $oneshot;
        }
    }
}

sub pathable {
    my ($col, $row, @rest) = @_;
    for my $point (@rest) {
        linecb(
            sub {
                my ($c, $r) = @_;
                my $cell = $LMap[$r][$c][MINERAL];
                if (   $cell->[SPECIES] == WALL
                    or $cell->[SPECIES] == HOLE
                    or ($cell->[SPECIES] == ACID and onein(4))) {
                    $LMap[$r][$c][MINERAL] = $Thingy{ onein(7) ? RUBBLE : FLOOR };
                }
            },
            $col,
            $row,
            $point->@[ PCOL, PROW ]
        );
    }
}

# the PKC display unit - mostly useless error reporting (see xomb(1))
sub pkc_clear    { print AT_PKC_CODE, CLEAR_RIGHT }
sub pkc_log_code { print AT_PKC_CODE, $_[0] }

sub place_floortype {
    my ($col, $row, $species, $count, $odds, $offsets, $used) = @_;
    my $placed = 0;
    while ($count-- > 0) {
        my ($ncol, $nrow) = pick($offsets)->@[ PCOL, PROW ];
        $ncol += $col;
        $nrow += $row;
        next
          if $ncol < 0
          or $ncol >= MAP_COLS
          or $nrow < 0
          or $nrow >= MAP_ROWS;
        my $loc = $ncol . ',' . $nrow;
        # slightly different pattern for rubble: ignore the "have we put
        # something there" check
        if ($species != RUBBLE) {
            next if $used->{$loc}++;
        }
        $LMap[$nrow][$ncol][MINERAL] = $Thingy{$species};
        $placed++;
        # focus on a new starting point, sometimes
        if (irand(100) < $odds) { ($col, $row) = ($ncol, $nrow) }
    }
    return $placed;
}

sub place_monster {
    my ($species, $energy, $seeds) = @_;

    my $point = extract($seeds);
    my ($col, $row) = $point->@[ PCOL, PROW ];

    my $monst = make_monster(
        species => pick($species),
        energy  => $energy,
    );

    $LMap[$row][$col][MINERAL] = $Thingy{ onein(10) ? RUBBLE : FLOOR }
      unless $LMap[$row][$col][MINERAL][SPECIES] == GATE;

    $LMap[$row][$col][ANIMAL] = $monst;
    $monst->[LMC] = $LMap[$row][$col];

    push @Animates, $monst;

    return $point;
}

sub plasma_annihilator {
    my ($self, $seen, $spread, $depth, $max) = @_;

    return if $depth >= $max or !$spread->@*;

    my ($col, $row) = pick($spread)->@[ PCOL, PROW ];
    my $loc = $col . ',' . $row;
    $seen->{$loc} = 1;

    my $lmc = $LMap[$row][$col];
    if (defined $lmc->[ANIMAL]) {
        apply_damage($lmc->[ANIMAL], 'plsplash', $self) if coinflip();
    } elsif ($lmc->[MINERAL][SPECIES] == WALL) {
        reduce($lmc) if onein(40);
        return;
    }
    if (exists $Visible_Cell{$loc}) {
        print at(map { MAP_DOFF + $_ } $col, $row),
          onein(1000) ? $Thingy{ AMULET, }->[DISPLAY] : 'x';
    }

    with_adjacent(
        $col, $row,
        sub {
            my ($point) = @_;
            my $adj = join ',', $point->@[ PCOL, PROW ];
            return if $seen->{$adj} or !exists $Visible_Cell{$loc};
            push $spread->@*, $point;
            @_ = ($self, $seen, $spread, $depth + 1, $max);
            goto &plasma_annihilator;
        }
    );
}

sub raycast_fov {
    my ($refresh) = @_;
    state $FOV;
    if (!$refresh and defined $FOV) {
        print $FOV;
        return;
    }

    my (%blocked, %byrow, %seen);
    my ($cx, $cy) = $Animates[HERO][LMC][WHERE]->@[ PCOL, PROW ];
    %Visible_Cell  = ($cx . ',' . $cy => [ $cx, $cy ]);
    @Visible_Monst = ();

    # radius 7 points taken from Game:RaycastFOV cache
    for my $ep (
        [ -2, -7 ], [ -1, -7 ], [ 0,  -7 ], [ 1,  -7 ], [ 2,  -7 ], [ -4, -6 ],
        [ -3, -6 ], [ -2, -6 ], [ 2,  -6 ], [ 3,  -6 ], [ 4,  -6 ], [ -5, -5 ],
        [ -4, -5 ], [ 4,  -5 ], [ 5,  -5 ], [ -6, -4 ], [ -5, -4 ], [ 5,  -4 ],
        [ 6,  -4 ], [ -6, -3 ], [ 6,  -3 ], [ -7, -2 ], [ -6, -2 ], [ 6,  -2 ],
        [ 7,  -2 ], [ -7, -1 ], [ 7,  -1 ], [ -7, 0 ],  [ 7,  0 ],  [ -7, 1 ],
        [ 7,  1 ],  [ -7, 2 ],  [ -6, 2 ],  [ 6,  2 ],  [ 7,  2 ],  [ -6, 3 ],
        [ 6,  3 ],  [ -6, 4 ],  [ -5, 4 ],  [ 5,  4 ],  [ 6,  4 ],  [ -5, 5 ],
        [ -4, 5 ],  [ 4,  5 ],  [ 5,  5 ],  [ -4, 6 ],  [ -3, 6 ],  [ -2, 6 ],
        [ 2,  6 ],  [ 3,  6 ],  [ 4,  6 ],  [ -2, 7 ],  [ -1, 7 ],  [ 0,  7 ],
        [ 1,  7 ],  [ 2,  7 ]
    ) {
        linecb(
            sub {
                my ($col, $row, $iters) = @_;

                # "the moon is a harsh mistress" -- FOV degrades at range
                return -1 if $iters - 4 > irand(7);

                my $loc = $col . ',' . $row;
                return -1 if exists $blocked{$loc};

                my $point = [ $col, $row ];
                push @Visible_Monst, $point
                  if !$seen{$loc}++ and defined $LMap[$row][$col][ANIMAL];

                # walls MUST block, other features may due to the "harsh
                # environment" (vim on the 2009 MacBook, at the moment).
                # similar restrictions are applied to monster LOS walks
                # to the player (see update_*). hopefully.
                my $cell = $LMap[$row][$col][MINERAL];
                if ($cell->[SPECIES] == WALL) {
                    $blocked{$loc} = 1;
                    push $byrow{$row}->@*, [ $col, $cell->[DISPLAY] ];
                    $Visible_Cell{$loc} = $point;
                    return -1;
                } elsif ($cell->[SPECIES] == RUBBLE) {
                    $blocked{$loc} = 1 if onein(20);
                } elsif ($cell->[SPECIES] == ACID) {
                    $blocked{$loc} = 1 if onein(100);
                }

                return 0 if exists $Visible_Cell{$loc};
                $Visible_Cell{$loc} = [ $col, $row ];
                for my $i (ANIMAL, VEGGIE) {
                    if (defined $LMap[$row][$col][$i]) {
                        push $byrow{$row}->@*, [ $col, $LMap[$row][$col][$i][DISPLAY] ];
                        return 0;
                    }
                }
                push $byrow{$row}->@*, [ $col, $cell->[DISPLAY] ];
                return 0;
            },
            $cx,
            $cy,
            $cx + $ep->[0],
            $cy + $ep->[1]
        );
    }

    my $s = '';
    for my $r (0 .. MAP_ROWS - 1) {
        $s .= at_row(MAP_DOFF + $r) . CLEAR_RIGHT;
    }
    for my $r (nsort_by { $byrow{$_} } keys %byrow) {
        $s .= at_row(MAP_DOFF + $r);
        for my $ref (nsort_by { $_->[0] } $byrow{$r}->@*) {
            $s .= at_col(MAP_DOFF + $ref->[0]) . $ref->[1];
        }
    }

    # ensure @ is shown as FOV should not touch that cell
    print $FOV =
      $s . at(map { MAP_DOFF + $_ } $cx, $cy) . $LMap[$cy][$cx][ANIMAL][DISPLAY];
}

sub reduce {
    my ($lmc) = @_;
    if (exists $Visible_Cell{ join ',', $lmc->[WHERE]->@[ PCOL, PROW ] }) {
        log_message('A '
              . $Descript{ $lmc->[MINERAL][SPECIES] }
              . ' explodes in a shower of fragments!');
    }
    # rubble reification
    $lmc->[MINERAL] = [ $lmc->[MINERAL]->@* ];
    $lmc->[MINERAL]->@[ SPECIES, DISPLAY ] =
      $Thingy{ RUBBLE, }->@[ SPECIES, DISPLAY ];
}

sub refresh_board {
    print CLEAR_SCREEN;
    raycast_fov(0);
    show_top_message();
    show_status_bar();
}

# similar to tu'a in Lojban
sub reify {
    my ($lmc, $update) = @_;
    $lmc->[MINERAL] = [ $lmc->[MINERAL]->@* ];
    $lmc->[MINERAL][UPDATE] = $update if defined $update;
}

sub relocate {
    my ($ani, $col, $row) = @_;
    my $lmc = $ani->[LMC];

    my $src = $lmc->[WHERE];

    my $dest_lmc = $LMap[$row][$col];
    $dest_lmc->[ANIMAL] = $ani;
    undef $LMap[ $src->[PROW] ][ $src->[PCOL] ][ANIMAL];

    $ani->[LMC] = $dest_lmc;

    my $cell = $lmc->[VEGGIE] // $lmc->[MINERAL];
    print at(map { MAP_DOFF + $_ } $src->@[ PCOL, PROW ]), $cell->[DISPLAY],
      at(map { MAP_DOFF + $_ } $col, $row),
      $ani->[DISPLAY];
}

sub replay {
    my ($expect) = @_;
    my $key;
    sleep($Replay_Delay);
    local $/ = \1;
    while (1) {
        my $esc = ReadKey(-1);
        if (defined $esc and $esc eq "\033") {
            $RKFN = \&Game::Xomb::getkey;
            goto &Game::Xomb::getkey;
        }
        $key = readline $Replay_FH;
        if (defined $key) {
            last if exists $expect->{$key};
        } else {
            # KLUGE avoid busy-wait on "tail" of an active savegame
            sleep(0.2);
        }
    }
    print $Save_FH $key if defined $Save_FH;
    return $key;
}

sub report_position {
    log_message('Transponder reports ['
          . join(',', $Animates[HERO][LMC][WHERE]->@[ PCOL, PROW ])
          . ']');
    return MOVE_FAILED, 0;
}

sub report_version {
    log_message('Xomb v' . $VERSION . ' seed ' . $Seed . ' turn ' . $Turn_Count);
    return MOVE_FAILED, 0;
}

sub restore_term {
    ReadMode 'restore';
    print TERM_NORM, SHOW_CURSOR, UNALT_SCREEN;
}

sub rubble_delay {
    my ($ani, $cost) = @_;
    if (coinflip()) {
        if ($ani->[SPECIES] == HERO) {
            # Ultima IV does this. too annoying?
            $Violent_Sleep_Of_Reason = 1;
            log_message('Slow progress!');
        }
        return ($cost >> 1) + 2 + irand(4);
    } else {
        return 2 + irand(4);
    }
}

{
    my $energy = '00';

    sub sb_update_energy {
        $energy = sprintf "%02d", $Animates[HERO][STASH][ECOST];
    }

    sub show_status_bar {
        print at_row(STATUS_ROW),
          sprintf('Level %02d t', $Level), $energy, TERM_NORM,
          display_hitpoints(), display_cellobjs(), display_shieldup();
    }
}

sub score {
    my ($won) = @_;
    my $score = loot_value() + ($won ? 10000 : 0) + 10 * int exp $Level_Max;
    return "Score: $score in $Turn_Count turns (v$VERSION:$Seed)";
}

sub update_gameover {
    state $count = 0;
    raycast_fov(1);
    tcflush(STDIN_FILENO, TCIFLUSH);
    my $key = $RKFN->(\%Key_Commands);
    if ($count == 4) {
        has_lost();
    } elsif ($count >= 2) {
        print AT_MSG_ROW, CLEAR_RIGHT, '-- press Esc to continue --';
        has_lost() if $key eq "\033" or $key eq 'q';
    } elsif ($count == 1) {
        log_message('Communication lost with remote unit.');
    }
    $count++;
    return MOVE_OKAY, DEFAULT_COST;
}

sub update_fungi {
    my ($self) = @_;
    my ($mcol, $mrow) = $self->[LMC][WHERE]->@[ PCOL, PROW ];
    my ($tcol, $trow) = $Animates[HERO][LMC][WHERE]->@[ PCOL, PROW ];
    my $weap = $self->[STASH][WEAPON];

    my ($hits, $cost) = does_hit(distance($mcol, $mrow, $tcol, $trow), $weap);
    return MOVE_OKAY, $cost if $hits == -1;

    my (@burned, @path);
    $hits = 0;
    walkcb(
        sub {
            my ($col, $row, $iters) = @_;
            my $lmc = $LMap[$row][$col];
            push @path, [ $col, $row ];
            if (defined $lmc->[ANIMAL]) {
                push @burned, $lmc->[ANIMAL], $iters;
                $hits = 1 if $lmc->[ANIMAL][SPECIES] == HERO;
            } elsif ($lmc->[MINERAL][SPECIES] == WALL) {
                reduce($lmc) if onein(20);
                return -1;
            }
            # NOTE distance() and $iters give different numbers for diagonals
            return $iters > $weap->[W_RANGE] ? -1 : 0;
        },
        $mcol,
        $mrow,
        $tcol,
        $trow
    );
    return MOVE_OKAY, $cost unless $hits;

    bypair(
        sub {
            my ($ani, $iters) = @_;
            apply_damage($ani, 'plburn', $self, $iters) if coinflip();
        },
        @burned
    );

    my $loc = $mcol . ',' . $mrow;
    print at(map { MAP_DOFF + $_ } $mcol, $mrow), 'X'
      if exists $Visible_Cell{$loc};
    my %seen = ($loc => 1);

    for my $point (@path) {
        my ($col, $row) = $point->@[ PCOL, PROW ];
        my $loc = $col . ',' . $row;
        $seen{$loc} = 1;
        if (exists $Visible_Cell{$loc}) {
            print at(map { MAP_DOFF + $_ } $col, $row), coinflip() ? 'X' : 'x';
            $Violent_Sleep_Of_Reason = 1;
        }
    }

    my @spread;
    with_adjacent(
        $mcol, $mrow,
        sub {
            my $loc = join ',', $_[0]->@[ PCOL, PROW ];
            return if $seen{$loc}++ or !exists $Visible_Cell{$loc} or irand(10) < 8;
            print at(map { MAP_DOFF + $_ } $_[0]->@[ PCOL, PROW ]), 'X'
              if exists $Visible_Cell{$loc};
            push @spread, $_[0];
        }
    );
    if (@spread) {
        my $max = 3;
        $max += 2 if onein(40);
        $max += 3 if onein(250);
        # mostly it just looks impressive
        plasma_annihilator($self, \%seen, \@spread, 1, $max);
    }

    return MOVE_OKAY, $cost;
}

sub update_ghast {
    my ($self) = @_;
    my ($mcol, $mrow) = $self->[LMC][WHERE]->@[ PCOL, PROW ];
    my ($tcol, $trow) = $Animates[HERO][LMC][WHERE]->@[ PCOL, PROW ];
    my $weap = $self->[STASH][WEAPON];

    my ($hits, $cost) = does_hit(distance($mcol, $mrow, $tcol, $trow), $weap);
    return MOVE_OKAY, $cost if $hits == -1;

    # but a gatling gun is often trigger happy ...
    if ($hits == 0) {
        return MOVE_OKAY, $cost if onein(8);
        my @nearby;
        with_adjacent($tcol, $trow, sub { push @nearby, $_[0] });
        ($tcol, $trow) = pick(\@nearby)->@[ PCOL, PROW ];
    }

    my @path;
    linecb(
        sub {
            my ($col, $row) = @_;
            push @path, [ $col, $row ];
            if (defined $LMap[$row][$col][ANIMAL]
                and $LMap[$row][$col][ANIMAL][SPECIES] != HERO) {
                ($tcol, $trow) = ($col, $row) if $hits == 0 and coinflip();
                return -1;
            }
            my $cell = $LMap[$row][$col][MINERAL];
            if ($cell->[SPECIES] == WALL) {
                # they're not trigger happy enough to shoot a wall
                # (moreso that letting the wall be shot would reveal
                # where something is to the player)
                @path = ();
                return -1;
            } elsif ($cell->[SPECIES] == RUBBLE) {
                if (onein(10)) {
                    $hits = 0;
                    return -1;
                }
            }
            return 0;
        },
        $mcol,
        $mrow,
        $tcol,
        $trow
    );
    return MOVE_OKAY, $cost unless @path;

    for my $point (@path) {
        my $loc = join ',', $point->@[ PCOL, PROW ];
        if (exists $Visible_Cell{$loc}) {
            print at(map { MAP_DOFF + $_ } $point->@[ PCOL, PROW ]), '-';
            $Violent_Sleep_Of_Reason = 1;
        }
    }
    my $loc = $tcol . ',' . $trow;
    my $lmc = $LMap[$trow][$tcol];
    if ($hits == 0) {
        my $buddy = $LMap[$trow][$tcol][ANIMAL];
        apply_damage($buddy, 'attackby', $self) if defined $buddy;
    } else {
        apply_damage($Animates[HERO], 'attackby', $self);
        $Violent_Sleep_Of_Reason = 1;
    }

    return MOVE_OKAY, $cost;
}

sub update_mimic {
    my ($self) = @_;
    my ($mcol, $mrow) = $self->[LMC][WHERE]->@[ PCOL, PROW ];
    my ($tcol, $trow) = $Animates[HERO][LMC][WHERE]->@[ PCOL, PROW ];
    my $weap = $self->[STASH][WEAPON];

    my ($hits, $cost) = does_hit(distance($mcol, $mrow, $tcol, $trow), $weap);
    return MOVE_OKAY, $cost if $hits == -1;

    my @nearby;
    if ($hits == 0) {
        # maybe they're taking a break
        return MOVE_OKAY, $cost if onein(10);
        with_adjacent($tcol, $trow, sub { push @nearby, $_[0] });
    }

    # Mortars could, in theory, lob shells over walls but that would
    # allow Mortars to abuse things like ### that the player could
    # not get into.                      #M# so require LOS.
    linecb(
        sub {
            my ($col, $row) = @_;
            my $cell = $LMap[$row][$col][MINERAL];
            if ($cell->[SPECIES] == WALL) {
                $hits = 0;
                return -1;
            }
            return 0;
        },
        $mcol,
        $mrow,
        $tcol,
        $trow
    );
    return MOVE_OKAY, $cost if $hits < 1;

    if (@nearby) {
        log_message('A mortar shell explodes nearby!');
        my ($ncol, $nrow) = pick(\@nearby)->@[ PCOL, PROW ];
        my $lmc   = $LMap[$nrow][$ncol];
        my $buddy = $lmc->[ANIMAL];
        if (defined $buddy) {
            apply_damage($buddy, 'attackby', $self);
        } elsif ($lmc->[SPECIES] == WALL and onein(20)) {
            reduce($lmc);
        }
    } else {
        log_message('A mortar shell strikes you!');
        apply_damage($Animates[HERO], 'attackby', $self);
    }

    $Violent_Sleep_Of_Reason = 1;

    return MOVE_OKAY, $cost;
}

sub update_player {
    my ($self) = @_;
    my ($cost, $ret);

    # pre-move tasks
    sb_update_energy();
    if ($Violent_Sleep_Of_Reason == 1) {
        sleep($Draw_Delay);
        $Violent_Sleep_Of_Reason = 0;
    }
    raycast_fov(1);
    show_top_message();
    log_dim();
    show_status_bar();

    tcflush(STDIN_FILENO, TCIFLUSH);
    while (1) {
        my $key = defined $Sticky ? $Sticky : $RKFN->(\%Key_Commands);
        ($ret, $cost, my $code) = $Key_Commands{$key}->($self);
        pkc_log_code($code) if defined $code;
        last                if $ret != MOVE_FAILED;
    }

    if (defined $Sticky) {
        undef $Sticky if --$Sticky_Max <= 0;
        sleep($Draw_Delay) unless $Sticky eq '.';
    }

    my $hp = $self->[STASH][HITPOINTS];
    if (defined $self->[STASH][SHIELDUP] and $hp < START_HP) {
        my $need  = START_HP - $self->[STASH][HITPOINTS];
        my $offer = between(
            0,
            int($cost / $self->[STASH][SHIELDUP][STASH][GEM_REGEN]),
            $self->[STASH][SHIELDUP][STASH][GEM_VALUE]
        );

        my $heal = between(0, $need, $offer);
        $self->[STASH][SHIELDUP][STASH][GEM_VALUE] -= $heal;
        $hp = $self->[STASH][HITPOINTS] += $heal;
        undef $Sticky if $hp == START_HP;

        if ($self->[STASH][SHIELDUP][STASH][GEM_VALUE] <= 0) {
            pkc_log_code('0113');
            log_message(
                'The ' . $self->[STASH][SHIELDUP][STASH][GEM_NAME] . ' chips and shatters!');
            undef $self->[STASH][SHIELDUP];
            undef $Sticky;
            print display_shieldup();
        }
    }

    $Energy_Spent += $cost;
    $Turn_Count++;
    return $ret, $cost;
}

# when player is in range try to shoot them
sub update_troll {
    my ($self) = @_;
    my ($mcol, $mrow) = $self->[LMC][WHERE]->@[ PCOL, PROW ];
    my ($tcol, $trow) = $Animates[HERO][LMC][WHERE]->@[ PCOL, PROW ];
    my $weap = $self->[STASH][WEAPON];

    my ($hits, $cost) = does_hit(distance($mcol, $mrow, $tcol, $trow), $weap);
    return MOVE_OKAY, $cost if $hits == -1;

    my @path;
    my $property_damage = 0;
    walkcb(
        sub {
            my ($col, $row, $iters) = @_;
            push @path, [ $col, $row ];
            if ($iters > $weap->[W_RANGE]) {
                ($tcol, $trow) = ($col, $row) if $hits == 0;
                return -1;
            }
            if (defined $LMap[$row][$col][ANIMAL]
                and $LMap[$row][$col][ANIMAL][SPECIES] != HERO) {
                ($tcol, $trow) = ($col, $row) if $hits == 0;
                return -1;
            }
            my $cell = $LMap[$row][$col][MINERAL];
            if ($cell->[SPECIES] == WALL) {
                $hits = 0;
                if (onein(4)) {
                    ($tcol, $trow) = ($col, $row);
                    $property_damage = 1;
                } else {
                    # wall not getting blow'd up, do not (maybe) reveal
                    # to player that something is trying to do so
                    @path = ();
                }
                return -1;
            } elsif ($cell->[SPECIES] == RUBBLE) {
                # similar FOV problem as for player, see raycast. also
                # should mean that rubble is good cover for the hero
                if (onein(20)) {
                    $hits = 0;
                    ($tcol, $trow) = ($col, $row);
                    $property_damage = 1;
                    return -1;
                }
            }
            return 0;
        },
        $mcol,
        $mrow,
        $tcol,
        $trow
    );
    return MOVE_OKAY, $cost unless @path;

    for my $point (@path) {
        my $loc = join ',', $point->@[ PCOL, PROW ];
        if (exists $Visible_Cell{$loc}) {
            print at(map { MAP_DOFF + $_ } $point->@[ PCOL, PROW ]), '-';
            $Violent_Sleep_Of_Reason = 1;
        }
    }
    my $loc = $tcol . ',' . $trow;
    my $lmc = $LMap[$trow][$tcol];
    if ($property_damage) {
        reduce($lmc);
    } else {
        if ($hits == 0) {
            my $buddy = $LMap[$trow][$tcol][ANIMAL];
            apply_damage($buddy, 'attackby', $self) if defined $buddy;
        } else {
            apply_damage($Animates[HERO], 'attackby', $self);
            $Violent_Sleep_Of_Reason = 1;
        }
    }

    return MOVE_OKAY, $cost;
}

# like shooter but can only fire across totally open ground. advanced
# targetting arrays prevent friendly fire and property damage
sub update_stalker {
    my ($self) = @_;
    my ($mcol, $mrow) = $self->[LMC][WHERE]->@[ PCOL, PROW ];
    my ($tcol, $trow) = $Animates[HERO][LMC][WHERE]->@[ PCOL, PROW ];
    my $weap = $self->[STASH][WEAPON];

    my ($hits, $cost) = does_hit(distance($mcol, $mrow, $tcol, $trow), $weap);
    return MOVE_OKAY, $cost if $hits < 1;

    my @path;
    linecb(
        sub {
            my ($col, $row) = @_;
            if ($col == $tcol and $row == $trow) {    # gotcha
                push @path, [ $col, $row ];
                return 0;
            }
            # stalker needs a really clear shot (to offset for
            # their range)
            my $cell = $LMap[$row][$col][MINERAL];
            if (   defined $LMap[$row][$col][ANIMAL]
                or $cell->[SPECIES] == WALL
                or $cell->[SPECIES] == RUBBLE
                or ($cell->[SPECIES] == ACID and onein(3))) {
                $hits = 0;
                return -1;
            }
            push @path, [ $col, $row ];
        },
        $mcol,
        $mrow,
        $tcol,
        $trow
    );
    return MOVE_OKAY, $cost if $hits < 1 or !@path;

    for my $point (@path) {
        my $loc = join ',', $point->@[ PCOL, PROW ];
        print at(map { MAP_DOFF + $_ } $point->@[ PCOL, PROW ]), '='
          if exists $Visible_Cell{$loc};
    }
    apply_damage($Animates[HERO], 'attackby', $self);

    $Violent_Sleep_Of_Reason = 1;

    return MOVE_OKAY, $weap->[W_COST];
}

sub use_item {
    my ($loot, $i, $stash) = @_;
    if (!($loot->[$i][SPECIES] == GEM or $loot->[$i][SPECIES] == AMULET)) {
        pkc_log_code('0111');
        return 0;
    }
    if (defined $stash->[SHIELDUP]) {
        ($stash->[SHIELDUP], $loot->[$i]) = ($loot->[$i], $stash->[SHIELDUP]);
    } else {
        $stash->[SHIELDUP] = splice $loot->@*, $i, 1;
    }
    return 1;
}

sub veggie_name {
    my ($veg) = @_;
    my $s;
    if ($veg->[SPECIES] == GEM or $veg->[SPECIES] == AMULET) {
        $s = sprintf "(%d) %s", $veg->[STASH]->@[ GEM_VALUE, GEM_NAME ];
    } else {
        $s = $Descript{ $veg->[SPECIES] };
    }
    return $s;
}

sub with_adjacent {
    my ($col, $row, $callback) = @_;
    my @pairs = ( -1, -1, -1, 0, -1, 1, 0, -1, 0, 1, 1, -1, 1, 0, 1, 1 );
    my $max_index = $#pairs;
    my $i = 0;
    while ( $i < $max_index ) {
        my ($ac, $ar) = ($col + $pairs[$i], $row + $pairs[$i+1]);
        next if $ac < 0 or $ac >= MAP_COLS or $ar < 0 or $ar >= MAP_ROWS;
        $callback->([ $ac, $ar ]);
    } continue {
        $i += 2;
    }
}

1;
__END__
=encoding utf8

=head1 NAME

Game::Xomb - a game featuring @ versus the Xarci Bedo

=head1 SYNOPSIS

Xomb is a terminal-based roguelike. Assuming that the development tools
(C99 support is required), L<perl(1)>, L<App::cpanminus>, and optionally
L<local::lib> are installed and setup in a suitable terminal install and
run the game via:

    cpanm Game::Xomb
    xomb

Use the C<?> key in game to show the help text. The B<xomb>
documentation details other useful game information; it should be
available once the module is installed via:

    perldoc xomb

The remainder of this documentation concerns internal details likely
only of interest to someone who wants to modify the source code.

=head1 DESCRIPTION

The game is data oriented in design; adding a new floor tile would
require a new C<SPECIES> constant, suitable entries in C<%Thingy>,
C<%Descript>, and C<@Level_Features>, and then any additional code for
passive effects or whatever. Various routines may need adjustment for a
new floor type as there is not a good component system to indicate
whether a floor tile is solid, dangerous, etc. A new monster would
require similar additions, and would need a custom B<update_*> function
for when that critter has an action to make.

Only the player can move, so much of the code assumes that. New player
actions would need to be added to C<%Key_Commands> and suitable code
added to carry out the new action.

All entropy comes from the JSF random number generator (see
C<src/jsf.c>). The perl built-in C<rand> function MUST NOT be used;
instead use B<irand>, B<roll>, or one of the other utility functions
that call into the JSF code.

There are tests for some of the code, see the C<t> directory in the
module's distribution.

=head1 FUNCTIONS

=over 4

=item B<abort_run>

Called by the movement code to determine whether the run should be
aborted, e.g. before the player steps to a pool of acid. C<$Sticky>
indicates whether a run is in progress, and runs are caused by the
B<move_player_runner> or B<move_player_snooze> functions, see
C<%Key_Commands>.

=item B<apply_damage>

Removes hitpoints from the given animate, with complications to report
the damage and to mark the game as over (for the player) or otherwise
the monster as dead. Calls over to C<%Damage_From> table entries which
return the damage as appropriate for the arguments.

=item B<at> B<at_col> B<at_row>

These routines move the cursor around the terminal. B<at> takes
arguments in col,row (x,y) form.

=item B<apply_passives>

Floor tiles can have passive effects that can vary depending on the
duration the player is within the cell, or could be a message to the
player. See B<passive_burn>, B<passive_msg_maker>.

=item B<await_quit>

Waits for the player to quit usually from a submenu. C<$RKFN> holds the
function that read keys; these could either come from C<STDIN> or from a
save game file.

=item B<bad_terminal>

Indicates whether a terminal exists and is of suitable dimensions.

=item B<bail_out>

Called when something goes horribly wrong, usually on fatal signal or
internal error.

=item B<between>

Like C<clamp> from the Common LISP Alexandria library.

=item B<bypair> I<callback> I<list ...>

Calls the I<callback> function with pairs of items from the given
list of items.

=item B<coinflip>

Returns C<0> or C<1>. Uses the JSF random number generator (see
C<src/jsf.c>).

=item B<display_cellobjs>

Returns a string usually shown in the status bar consisting of the
C<VEGGIE> (item, if any) and C<MINERAL> (floor tile) of the cell the
player is in.

=item B<display_hitpoints>

Returns a string that prints the player's shield points in the status bar.

=item B<display_shieldup>

Returns a string that prints whether and if so what C<VEGGIE> is being
used to regenerate the shield.

=item B<distance>

Pythagorean distance between two cells, with rounding. Will differ in
some cases from the Chebyshev distance that the B<linecb> and B<walkcb>
line functions use for an iterations count.

=item B<does_hit>

Whether or not the given weapon hits at the given B<distance>, and
what the cost of that move was. The cost will be higher if the target
is out of range so that the animate will not wake up until the player
can be in range.

=item B<extract>

Removes a random element from the given array reference and returns it.
Uses the JSF random number generator (see C<src/jsf.c>).

Note that the original order of the array reference will not be
preserved. If that order is important, do not use this call. Order
preserving extraction can be done with:

  ... = splice @array, irand(scalar @array), 1;

=item B<fisher_yates_shuffle>

Shuffles an array reference in place. Uses the JSF random number
generator (see C<src/jsf.c>).

=item B<game_loop>

Entry point to the game, see C<bin/xomb> for how this gets called and
what needs to be setup before that. Loops using a simple integer
based energy system over active animates and calls the update
function for each on that gets a go, plus some complications to
change the level, etc.

=item B<game_over>

Called when the game needs to exit for various reasons mostly unrelated
to gameplay (terminal size too small, fatal signal).

=item B<generate_map>

Generates a level map around where the player is. Various knobs can be
found in C<@Level_Features>.

=item B<getkey>

Reads a key from the terminal until one in the hash of valid choices
is entered. See also C<$RKFN>.

=item B<has_amulet>

Whether the player is carrying (or has equiped) the Amulet.

=item B<has_lost>

Exits game with death screen and score.

=item B<has_won>

Exits game with win screen and score. Should be the only C<0> exit
status of the game.

=item B<help_screen>

In game information on keyboard command available

=item B<init_jsf>

Sets the seed for the JSF random number generator (see C<src/jsf.c>).

=item B<init_map>

Initial setup of the C<@LMap>. This is in row,col form though points use
the col,row form. Each cell (C<LMC>) has C<WHERE>, C<MINERAL>,
C<VEGGIE>, and C<ANIMAL> slots that contain a col,row point for the
cell, the floor tile, item (if any), and animate (if any).

=item B<irand> I<max>

Integer random value between C<0> and C<max - 1>. Uses the JSF random
number generator (see C<src/jsf.c>).

=item B<linecb> I<callback> I<x0> I<y0> I<x1> I<y1>

Bresenham line function with some features to keep it from going off of
the map and to skip the first point and to abort should the callback
return C<-1>.

=item B<log_dim>

Used to bold -> normal -> faint cycle log the most recent message (shown
at the top of the screen) depending on the age of the message.

=item B<log_message>

Adds a message to the log and displays it at the top of the screen.

=item B<loot_value>

Returns the value of the loot the player is carrying.

=item B<make_amulet>

Creates the amulet and returns it.

=item B<make_gem>

Creates a gem and returns it.

=item B<make_monster>

Creates a monster and returns it. Suitable parameters must be supplied.

=item B<make_player>

Creates the player, places them into the C<HERO> slot of the
C<@Animates> array, and returns the col,row starting position of the
player. B<generate_map> builds the level map around this position.

=item B<manage_inventory>

A far too complicated routine to inspect, drop, or equip items in the
inventory list.

=item B<move_animate>

Moves the player around the level map, with various game related
complications. See C<%Key_Commands> and B<move_player_maker>.

=item B<move_drop>

Drops an item from the inventory.

=item B<move_equip>

Equips an item from the inventory.

=item B<move_examine>

Lets the player move the cursor around the level map to inspect
various features.

=item B<move_gate_down>

For when the player climbs down the "stairs".

=item B<move_gate_up>

For when the player tries to climb up the "stairs".

=item B<move_nop>

For when the player rests for a turn.

=item B<move_pickup>

Picks an item (if any) up off of the level map.

=item B<move_player_maker>

Creates a function suitable for moving the player in a particular
direction. See C<%Key_Commands>.

=item B<move_player_runner>

Creates a function suitable for running the player in a particular
direction.

=item B<move_player_snooze>

Creates a function suitable for resting with over multiple turns.

=item B<move_quit>

Prompts whether they want to quit the game.

=item B<move_remove>

Unequips an item (if any).

=item B<nope_regarding>

Query the player whether they want to carry out some dangerous move.

=item B<onein> I<max>

Returns true if the RNG rolls C<0> within I<max>. Uses the JSF random
number generator (see C<src/jsf.c>).

=item B<passive_burn>

Apply acid damage because the player is in a pool of acid.

=item B<passive_msg_maker>

Returns a subroutine that issues a message when a cell is entered into.
The cell should probably be made unique with B<reify> first as otherwise
all floor tiles of that type will share the same update routine.

=item B<pathable> I<col> I<row> I<points ...>

Ensures that a path exists between the given coordinates and the given
list of points; used by B<generate_map> to ensure that the player can
reach all the gates and gems.

=item B<pick>

Picks a random item from the given array reference. Uses the JSF random
number generator (see C<src/jsf.c>).

=item B<pkc_clear>

Clears the PKC error code from the status bar.

=item B<pkc_log_code>

Prints a PKC error code in the status bar.

=item B<place_floortype>

Used by B<generate_map> to place floor tiles somewhat randomly (brown
noise) around the level map, as controlled by C<@Level_Features> counts.

=item B<place_monster>

Creates and places a monster onto the level map, and that the monster
has not been placed above a hole or in acid.

=item B<plasma_annihilator>

Displays and applies splash damage from Fungi attacks.

=item B<raycast_fov>

Calculates the FOV for the player and updates various related variables
such as what monsters are visible.

=item B<reduce>

Reduces a map cell floor tile to C<RUBBLE>. Some monsters can
destroy walls.

=item B<refresh_board>

Redraw the level map, status bar, and previous message if any.

=item B<reify>

Marks a particular level map item (C<MINERAL>, typically) as unique,
usually so that a B<passive_msg_maker> can be applied to it.

=item B<relocate>

Handles moving the player from one level map cell to another.

=item B<replay>

Replays commands from a save game file. See also C<$RKFN>.

=item B<report_position>

Logs a message showing where the player is on the level map.

=item B<report_version>

Logs a message with the game version, seed, and current turn number.

=item B<restore_term>

Gets the terminal out of raw mode and more back to normal.

=item B<roll> I<times> I<sides>

Dice rolling, so C<3d6> would be C<roll(3,6)>. Uses the JSF random
number generator (see C<src/jsf.c>).

=item B<rubble_delay>

Slow the player down when they move in (or into, or out of) rubble.

=item B<sb_update_energy>

Update the energy cost of the last move.

=item B<score>

Returns a string with the game score in it.

=item B<show_messages>

Show all the recent messages in the message log.

=item B<show_status_bar>

Prints the status bar at the bottom of the screen.

=item B<show_top_message>

Prints the most recent log message at the top of the screen.

=item B<update_fungi>

C<UPDATE> function for fungi.

=item B<update_gameover>

Custom C<UPDATE> function for when the player is dead.

=item B<update_ghast>

C<UPDATE> function for ghast.

=item B<update_mimic>

C<UPDATE> function for mimics.

=item B<update_player>

C<UPDATE> function for the player. Failed moves (zero-cost things) are
looped over until a move that costs energy is made. Input comes from the
C<$RKFN> which is usually a function that reads from standard input.

=item B<update_stalker>

C<UPDATE> function for stalkers.

=item B<update_troll>

C<UPDATE> function for trolls.

=item B<use_item>

Uses an item, possibly swapping it with some existing item.

=item B<veggie_name>

Returns a string with the name and value of a vegetable (a gem, or
the amulet).

=item B<walkcb>

Like B<linecb> but continues until the edge of the level map or until
the callback function returns C<-1>.

=item B<with_adjacent> I<col> I<row> I<callback>

Runs the I<callback> function for each cell adjacent to the given
coordinates that is within the level map.

=back

=head1 BUGS

    HP 100
    You plunge into the hole.
    HP -140314714594444

'tis but a flesh wound.

L<https://thrig.me/src/Game-Xomb.git>

=head1 SEE ALSO

L<Game::PlatformsOfPeril> from which this code evolved.

7DRL 2020 - L<https://itch.io/jam/7drl-challenge-2020>

Vektor - Terminal Redux

=head1 AUTHOR

Jeremy Mates

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

The C<src> directory code appears to be under a "I wrote this PRNG. I
place it in the public domain." license:

L<http://burtleburtle.net/bob/rand/smallprng.html>

=cut
