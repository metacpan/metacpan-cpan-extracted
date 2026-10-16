use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
use Game::Sternhalma::Notation qw(parse_position format_position);
use FindBin;
use lib "$FindBin::Bin/lib";
use SthT qw(near_home);
my $E = 'Game::Sternhalma::Engine';

# ---- the game after the ';' -------------------------------------------------------------

{
    my $bd = $E->new(seats => 3);
    unlike($bd->to_string, qr/;/, 'a board at its set-up writes no ;');
    $bd->play(6, 15);
    like($bd->to_string, qr/ 1 3 10;p=1\z/, 'one move on: ;p=1');
    $bd->set_cap(40);
    like($bd->to_string, qr/;p=1 c=40\z/, 'a cap that is not the default is written');
    $bd->resign(2);
    like($bd->to_string, qr/;r=2 p=1 c=40\z/, 'a resignation');
    my ($back, $code) = $E->from_string($bd->to_string);
    is($code, POS_OK, 'and it reads back');
    is($back->to_string, $bd->to_string, '  to the same string');
    is($back->ply, 1, '  the ply');
    is($back->cap, 40, '  the cap');
    is($back->to_move, $bd->to_move, '  the seat to move');
}

# ---- every game, at every ply, through the engine and through Notation -----------------

srand 20261022;
my ($strings, $engine_ok, $notation_ok, %kinds) = (0, 1, 1);
for my $seats (2, 3, 4, 6) {
    for (1 .. 40) {
        my $bd = $E->new(seats => $seats);
        $bd->set_cap(60 + int rand 200);
        while (1) {
            my $s = $bd->to_string;
            my ($back, $code) = $E->from_string($s);
            $engine_ok = 0 unless $code == POS_OK && $back->to_string eq $s && $back->key eq $bd->key
                && $back->over == $bd->over && $back->how == $bd->how && $back->ply == $bd->ply
                && join(',', $back->places) eq join(',', $bd->places);
            my ($p, $pcode) = parse_position($s);
            $notation_ok = 0 unless $pcode == POS_OK && format_position($p) eq $s;
            $strings++;
            $kinds{ $bd->how }++;
            last if $bd->over;
            if (rand() < 0.01 && $seats > 2) { $bd->resign(int rand $seats) }
            elsif ($bd->can_pass) { $bd->pass }
            else { my @l = $bd->legal; $bd->play(@{ $l[ rand @l ] }) }
        }
    }
}
cmp_ok($strings, '>', 10_000, "$strings positions from 160 random games");
ok($engine_ok, '  every one written and read back by the engine to the same game: key, ply, places, how');
ok($notation_ok, '  and by Notation, in plain Perl, to the same string');
ok(($kinds{ (BY_CAP) } // 0) && ($kinds{ (BY_RESIGN) } // 0) + ($kinds{ (BY_HOME) } // 0),
    '  among them games ended by the cap and by resigning or getting home');

# ---- the endings random play never reaches: home, and resigning to one --------------------
#
# Random players never get anyone home. These boards are built by hand, with
# exactly ten pieces a seat so a string can write them (no spares), and every
# position on the way is read back by both.

sub same {
    my ($bd, $what) = @_;
    my $s = $bd->to_string;
    my ($back, $code) = $E->from_string($s);
    my ($p, $pcode) = parse_position($s);
    ok($code == POS_OK && $back->to_string eq $s && $back->how == $bd->how && $back->over == $bd->over
        && join(',', $back->places) eq join(',', $bd->places) && $back->to_move == $bd->to_move,
        "$what: the engine reads it back");
    ok($pcode == POS_OK && format_position($p) eq $s, "  and Notation");
}

{
    my ($bd, @gap) = near_home(3, 0);
    same($bd, 'three seats, each a step from home');
    $bd->play($gap[0][1], $gap[0][0]);
    same($bd, 'seat 0 home');
    $bd->play($gap[1][1], $gap[1][0]);
    ok($bd->over && $bd->how == BY_HOME, 'seat 1 home: seat 2 is alone, over by home');
    same($bd, 'over by home');
}

{
    my ($bd, @gap) = near_home(3, 0);
    $bd->play($gap[0][1], $gap[0][0]);
    $bd->resign(1);
    ok($bd->over && $bd->how == BY_RESIGN, 'seat 0 home, seat 1 resigns: over by resigning');
    same($bd, 'over by resigning');
}

# A deadlock cannot be built with ten pieces a seat: there is always a step
# somewhere. Its suffix is checked for agreeing with itself, which is all the
# reader can check, and read back by both.
{
    my $s = $E->new(seats => 2)->to_string . ';p=2 k=2 o=3';
    my ($bd, $code) = $E->from_string($s);
    is($code, POS_OK, 'a deadlock written out reads');
    ok($bd->over && $bd->how == BY_DEADLOCK, '  as over by deadlock');
    same($bd, 'over by deadlock');
}

# ---- refused, and the engine and Notation refuse alike ---------------------------------------

my $set = $E->new(seats => 2)->to_string;
my $three = $E->new(seats => 3)->to_string;
my @BAD = (
    [ POS_GAME, "$set;",                'a ; with nothing after it' ],
    [ POS_GAME, "$set;p=0",             'a ply of 0, which is written by writing nothing' ],
    [ POS_GAME, "$set;p=07",            'a leading zero' ],
    [ POS_GAME, "$set;p=1 f=0",         'fields out of order' ],
    [ POS_GAME, "$set;p=1 p=2",         'a field twice' ],
    [ POS_GAME, "$set;p=1 ",            'a space after the last field' ],
    [ POS_GAME, "$set;f=2 o=1",         'a seat home that the game does not have' ],
    [ POS_GAME, "$three;f=1 r=1 o=1",   'a seat both home and resigned' ],
    [ POS_GAME, "$three;f=1,1",         'a seat home twice' ],
    [ POS_GAME, "$set;o=5",             'an ending that does not exist' ],
    [ POS_GAME, "$set;f=1",             'one of two seats home and the game not over' ],
    [ POS_GAME, "$set;o=1",             'over by home with nobody home' ],
    [ POS_GAME, "$set;p=5 c=10 o=2",    'over by the cap below the cap' ],
    [ POS_GAME, "$set;k=1 o=3",         'a deadlock with one pass of two' ],
    [ POS_GAME, "$set;p=10 c=10",       'at the cap and not over' ],
    [ POS_GAME, "$three;f=0",           'the seat to move is home and the game runs' ],
    [ POS_GAME, "$set;x=1",             'a field that does not exist' ],
    [ POS_FIELDS, "$set:p=1",           'something other than ; after the fields' ],
    [ POS_OK,   "$set;p=10 c=10 o=2",   'the cap reached, and over by it: fine' ],
    [ POS_OK,   "$three;f=1 p=4",       'one of three home and two racing: fine' ],
    [ POS_OK,   "$set;r=0 o=4",         'seat 0 resigned and over by it: fine' ],
);
for my $r (@BAD) {
    my ($want, $s, $what) = @$r;
    my (undef, $code) = $E->from_string($s);
    my (undef, $pcode) = parse_position($s);
    is($code, $want, "engine: $what");
    is($pcode, $want, "  Notation alike");
}

# ---- and on the refusals of the rows and fields ---------------------------------------------

srand 20261023;
my ($tries, $agree) = (0, 1);
for my $s (map { $E->new(seats => $_)->to_string } 2, 3, 4, 6) {
    for (1 .. 500) {
        my $m = $s;
        my $at = int rand length $m;
        my @junk = ('0', '5', '7', '[', ']', '/', ' ', ';', '[1]', '[13]', '[14]', 'x', '');
        substr($m, $at, int rand 3) = $junk[ rand @junk ];
        my (undef, $code) = $E->from_string($m);
        my (undef, $pcode) = parse_position($m);
        $tries++;
        $agree = 0 unless (defined $code ? $code : -1) == (defined $pcode ? $pcode : -1);
        diag "differ on '$m': engine $code, Notation $pcode" if $code != $pcode && $agree == 0 && $tries < 3000;
    }
}
is($tries, 2000, '2,000 damaged set-up strings');
ok($agree, '  and the engine and Notation give every one the same answer');

done_testing();
