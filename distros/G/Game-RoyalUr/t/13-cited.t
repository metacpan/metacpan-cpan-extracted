use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Engine ':all';
use Game::RoyalUr::Rules;
use Game::RoyalUr::Dice qw(roll_of);
my $E = 'Game::RoyalUr::Engine';
my $R = 'Game::RoyalUr::Rules';

=pod

EVERY CASE HERE CARRIES THE SENTENCE IT TESTS.

A case is a rule, where it comes from, and a check. The source is one of three
texts read on 9 October 2026 and quoted word for word:

    W   Wikipedia, "Royal Game of Ur", revision 1378861936
    M   Masters Traditional Games, "The Rules / Instructions of The Royal
        Game of Ur", mastersofgames.com
    N   RoyalUr.net, "Rules of the Royal Game of Ur"

or it is one of the places where those texts are silent or disagree and this
distribution had to decide, which are numbered G2 to G10 and say so.

A case with no source fails this file before its check is run. That is the
point of the file: a rule nobody can point to is a rule somebody made up.

=cut

sub game { $R->new(@_) }

sub said {
    my ($game, $roll) = @_;
    return join ' ', map {
        $_->from . '-' . $_->to . ($_->captures ? 'x' : '') . ($_->rosette ? '*' : '')
    } $game->moves($roll);
}

sub played {
    my ($game, $roll, $from) = @_;
    my ($move) = grep { $_->from eq $from } $game->moves($roll);
    die "no move from $from on a roll of $roll" unless $move;
    $game->apply($move);
    return $game;
}

my @CASES = (

    # ---- the board and the routes ---------------------------------------------

    [ 'the short route is fourteen steps and the fifteenth leaves',
      'M: "This makes a track of 14 squares, the 15th move being to bear off the board"',
      sub {
          is($E->route_len(ROUTE_SHORT), 14, 'fourteen steps');
          is(said(game(position => '4xx2/8/4xxl1 l 0 6 7 0'), 1), 'g1-home', 'and from the fourteenth a roll of 1 leaves');
      } ],

    [ 'the long route is sixteen steps and the seventeenth leaves',
      'M: "This a path of 16 squares, the 17th being to bear off."',
      sub {
          is($E->route_len(ROUTE_LONG), 16, 'sixteen steps');
          is(said(game(rules => 'masters', position => '4xx2/8/4xxl1 l 0 6 7 0'), 1), 'g1-home', 'and from the sixteenth a roll of 1 leaves');
      } ],

    [ 'on the long route every fourth step is a rosette',
      'M: "a rosette is encountered every 4 squares"',
      sub {
          for my $side (SIDE_LIGHT, SIDE_DARK) {
              my @steps = grep { $E->is_rosette($E->route_cell(ROUTE_LONG, $side, $_)) } 1 .. 16;
              is("@steps", '4 8 12 16', "side $side");
          }
      } ],

    [ 'on the short route six squares are a side\'s own and eight are fought over',
      'W: "This means there are six "safe" squares and eight "combat" squares."',
      sub {
          is(scalar(grep { $E->route_shared(ROUTE_SHORT, $_) } $E->all_cells), 8, 'eight shared');
          is(scalar(grep { $E->route_step(ROUTE_SHORT, SIDE_LIGHT, $_) && !$E->route_shared(ROUTE_SHORT, $_) } $E->all_cells),
              6, 'and six that are light alone');
      } ],

    [ 'a piece on its own squares cannot be reached',
      'W: "When a piece is on one of the player\'s own squares, it is safe from capture."',
      sub {
          my $game = game(position => '2d1xx2/8/l2lxx1l d 4 0 6 0');
          my @captures = map { grep { $_->captures } $game->moves($_) } 1 .. 4;
          is(scalar @captures, 0, 'dark has no roll that captures a light piece on a1, d1 or h1');
      } ],

    [ 'on the long route no square past the first four is a side\'s own',
      'N: "there are no longer any safe zones for pieces after they leave the start of the board"',
      sub {
          my @own = grep { !$E->route_shared(ROUTE_LONG, $E->route_cell(ROUTE_LONG, SIDE_LIGHT, $_)) } 1 .. 16;
          is("@own", '1 2 3 4', 'only steps 1 to 4');
      } ],

    # ---- moving ----------------------------------------------------------------

    [ 'one piece moves, and it moves forward by the roll',
      'M: "Only one piece may be moved per throw of the dice and pieces must always move forward around the track."',
      sub {
          my $game = game(position => '4xx2/l2l4/1l2xx2 l 4 0 7 0');
          for my $roll (1 .. 4) {
              my @bad = grep { $_->to_step != $_->from_step + $roll } $game->moves($roll);
              is(scalar @bad, 0, "a roll of $roll: every move is $roll steps on");
          }
          played($game, 3, 'b1');
          is($game->position, '4xx2/ll1l4/4xx2 d 4 0 7 0', 'b1 went to b2, and a2 and d2 stayed where they were');
      } ],

    [ 'a piece enters only onto a vacant square',
      'M: "Pieces can be moved onto the board at any stage of the game as long as the square that is moved to upon the first turn is vacant."',
      sub {
          my $game = game(position => '4xx2/8/2l1xx2 l 6 0 7 0');
          is(said($game, 2), 'c1-a1*', 'c1 is taken, so a roll of 2 does not enter');
          is(said($game, 1), 'hand-d1 c1-b1', 'and a roll of 1 does');
      } ],

    [ 'two pieces never share a square',
      'W: "There can never be more than one piece on a single square at any given time"',
      sub {
          my $game = game(position => '4xx2/l1l5/4xx2 l 5 0 7 0');
          is(said($game, 2), 'hand-c1 c2-e2', 'a2 has no move onto c2, where its own piece stands');
      } ],

    [ 'a piece passes over any piece in its way',
      'G5',
      sub {
          my $game = game(position => '4xx2/lldl4/4xx2 l 4 0 6 0');
          my ($move) = grep { $_->from eq 'a2' } $game->moves(4);
          is($move->to, 'e2', 'a2 goes to e2 over its own piece on b2, a dark piece on c2 and its own on d2');
          ok(!$move->captures, 'and captures none of them');
      } ],

    # ---- capturing ---------------------------------------------------------------

    [ 'landing on an enemy piece sends it back to the start',
      'W: "sending the piece back off the board so that it must restart the course from the beginning"',
      sub {
          my $game = played(game(position => '4xx2/l1d5/4xx2 l 6 0 5 1'), 2, 'a2');
          is($game->hand('dark'), 6, 'the dark piece is in dark hand, 5 to 6');
          is($game->home('dark'), 1, 'not at home');
          is($game->hand('light'), 6, 'and not in light hand');
          is($game->board->count(SIDE_DARK), 0, 'nor on the board');
      } ],

    [ 'the same under the long route, in the other side\'s row',
      'M: "If a counter lands upon a square occupied by an opposing counter, the counter landed upon is sent off the board and must start again from the beginning."',
      sub {
          my $game = played(game(rules => 'masters', position => '4xx1d/6l1/4xx2 l 6 0 6 0'), 2, 'g2');
          is($game->position, '4xx1l/8/4xx2 d 6 0 7 0', 'light takes h3 and the dark piece is back in hand');
      } ],

    [ 'a capture is allowed and is not compulsory',
      'W: "A player is not required to capture a piece every time they have the opportunity."',
      sub {
          my $game = game(position => '4xx2/l1d5/4xx2 l 6 0 6 0');
          is(said($game, 2), 'hand-c1 a2-c2x', 'a roll of 2 offers the capture and a move that is not one');
      } ],

    # ---- the rosette ------------------------------------------------------------

    [ 'under finkel a piece on the middle rosette cannot be captured',
      'W: "if a piece is located on the space with the rosette, it is safe from capture"',
      sub {
          is(said(game(position => '4xx2/l2d4/4xx2 l 6 0 6 0'), 3), 'hand-b1', 'a2 has no move onto the dark piece on d2');
      } ],

    [ 'and the rule is about rosettes, not about one square',
      'N: "you cannot capture pieces on rosettes"',
      sub {
          my $game = game(rules => { route => 'long', safe_rosettes => 1 }, position => '4xxd1/6l1/4xx2 l 6 0 6 0');
          is(said($game, 1), 'hand-d1', 'long route with safe rosettes: the dark piece on g3 is safe too');
      } ],

    [ 'a landing on an enemy on a safe rosette is refused; the square is not closed',
      'G8',
      sub {
          my $game = game(position => '4xx2/l2d4/4xx2 l 6 0 6 0');
          is(said($game, 4), 'hand-a1* a2-e2', 'a2 may go past d2 to e2');
      } ],

    [ 'under masters no rosette is safe',
      'N: "The rosette tiles should not be safe"',
      sub {
          is(said(game(rules => 'masters', position => '4xx2/l2d4/4xx2 l 6 0 6 0'), 3), 'hand-b1 a2-d2x*', 'a2 captures on d2');
      } ],

    [ 'which is this distribution\'s reading of the set\'s own silence',
      'G9',
      sub {
          is($E->rules('masters')->{safe_rosettes}, 0, 'masters: not safe');
          is($E->rules('finkel')->{safe_rosettes}, 1, 'finkel: safe');
      } ],

    [ 'a piece that lands on a rosette earns another roll',
      'N: "Landing on a rosette grants an extra roll of the dice."',
      sub {
          is(played(game(), 4, 'hand')->side, 'light', 'light enters on a1 and is to move again');
          is(played(game(), 3, 'hand')->side, 'dark', 'and on b1 is not');
      } ],

    [ 'and again, and with a different piece',
      'M: "(and again if another rosette is landed upon). The same piece need not be moved on the additional throw"',
      sub {
          my $game = played(game(), 4, 'hand');
          played($game, 4, 'a1');
          is($game->side, 'light', 'a1 to d2: a second rosette and light again');
          played($game, 4, 'hand');
          is($game->side, 'light', 'a different piece enters on a1: a third');
          is($game->position, '4xx2/3l4/l3xx2 l 5 0 7 0', 'and dark has not moved at all');
      } ],

    [ 'without limit: the whole long route on fours',
      'W: "a player\'s piece may make an entire run-through of the board with successive rolls of 4"',
      sub {
          my $game = game(rules => 'masters');
          played($game, 4, $_) for qw(hand a1 d2 g3);
          is($game->position, '4xx2/8/4xxl1 l 6 0 7 0', 'four fours: on g1, the last step, and still light to move');
          is($game->ply, 4, 'in four plies');
      } ],

    [ 'the extra roll chains without limit',
      'G4',
      sub {
          my $game = game(rules => 'masters');
          played($game, 4, $_) for qw(hand a1 d2 g3 hand a1 d2);
          is($game->side, 'light', 'seven rosettes running and light is still to move');
      } ],

    [ 'going home earns no roll, though the last step is a rosette',
      'G10',
      sub {
          is(played(game(position => '4xx2/8/4xxl1 l 3 3 7 0'), 1, 'g1')->side, 'dark', 'short route: g1 to home, dark to move');
          is(played(game(rules => 'masters', position => '4xx2/8/4xxl1 l 3 3 7 0'), 1, 'g1')->side, 'dark', 'and long');
      } ],

    # ---- leaving, and losing a turn -----------------------------------------------

    [ 'a piece leaves only on the exact roll',
      'M: "Exact throws are needed to bear pieces off the board."',
      sub {
          my $game = game(position => '4xx2/8/4xx1l l 0 6 7 0');
          is(said($game, 2), 'h1-home', 'from h1 a roll of 2 leaves');
          is(said($game, 3), '', 'and a roll of 3 does nothing');
      } ],

    [ 'from the last rosette that is exactly a one',
      'N: "to score a piece from the final rosette tile, you would need to roll exactly a one"',
      sub {
          my $game = game(position => '4xx2/8/4xxl1 l 0 6 7 0');
          is(said($game, 1), 'g1-home', 'a one leaves');
          is(said($game, $_), '', "and a $_ does not") for 2 .. 4;
      } ],

    [ 'a side that can move must, and a side that cannot loses the turn',
      'M: "A player must always move a counter if it is possible to do so but if it is not possible, the turn is lost."',
      sub {
          my $game = game(position => '4xx2/8/4xxl1 l 0 6 7 0');
          is(scalar($game->moves(2)), 0, 'a piece on g1 and a roll of 2: nothing to move');
          ok($game->forfeit, 'the turn is lost');
          is($game->side, 'dark', 'and dark is to move');
      } ],

    [ 'a turn is lost to the roll, by the game',
      'G2',
      sub {
          my $game = game();
          is(scalar($game->moves(0)), 0, 'a roll of nothing allows nothing');
          $game->forfeit;
          is($game->position, '4xx2/8/4xx2 d 7 0 7 0', 'nothing moved, and dark is to move');
      } ],

    [ 'an extra roll that allows nothing is a turn lost like any other',
      'G3',
      sub {
          my $game = played(game(), 4, 'hand');
          is($game->side, 'light', 'light has an extra roll');
          $game->forfeit;
          is($game->side, 'dark', 'loses it, and dark is to move');
      } ],

    # ---- the dice, and the end ---------------------------------------------------

    [ 'under finkel a throw of nothing moves nothing',
      'M: "0 - move 0 squares - i.e. miss a go."',
      sub { is(roll_of(0, $E->rules('finkel')), 0, 'worth 0') } ],

    [ 'under masters a throw of nothing moves four',
      'M: "0 - move 4 squares"',
      sub { is(roll_of(0, $E->rules('masters')), 4, 'worth 4') } ],

    [ 'the game is won by bringing all seven home',
      'W: "move all seven of their pieces along the course and off the board before their opponent"',
      sub {
          my $game = game(position => '4xx2/1d6/4xxl1 l 0 6 5 1');
          is($game->status, 'ongoing', 'six home is not seven');
          played($game, 1, 'g1');
          is($game->status, 'won', 'seven is');
          is($game->winner, 'light', 'and light has won');
      } ],
);

# THE FILE'S OWN CHECK, before any case runs.
my $SOURCE = qr/\A(?:[WMN]: ".{12,}"|G(?:[2-9]|10))\z/s;
my @unsourced = grep { !defined $_->[1] || $_->[1] !~ $SOURCE } @CASES;
is(scalar @unsourced, 0, 'every case names its source: a quotation from W, M or N, or a gap from G2 to G10')
    or diag('no source: ' . join('; ', map { $_->[0] } @unsourced));

my %gaps = map { $_->[1] => 1 } grep { $_->[1] =~ /\AG/ } @CASES;
is(join(' ', sort { substr($a, 1) <=> substr($b, 1) } keys %gaps), 'G2 G3 G4 G5 G8 G9 G10',
    'and the gaps tested are these');

for my $case (@CASES) {
    my ($name, $source, $check) = @$case;
    next unless defined $source && $source =~ $SOURCE;
    subtest "$name [$source]" => $check;
}

done_testing();
