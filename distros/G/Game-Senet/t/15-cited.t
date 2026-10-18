use strict;
use warnings;
use Test::More;

use Game::Senet::Engine ':all';
use Game::Senet::Rules;
my $E = 'Game::Senet::Engine';

=pod

EVERY RULE, WITH WHERE IT CAME FROM. plan_game_senet/00 pins each rule of this
game to a quotation from one of five texts, or names it a gap and decides it.
Each case below is one rule played, and carries its quotation (cite) or its
gap's number (gap). A case with neither fails this file's own check.

The quotations are checked word for word, whitespace aside, against the texts
by plan_game_senet/check-citations.pl, which reads this file:

    W  rules-wikipedia-1375538342.txt      M  rules-mastersofgames-2026-10-17.txt
    C  rules-gamecabinet-2026-10-17.txt    G  rules-gym-senet-2026-10-17.txt
    S  rules-steam-kendall-2026-10-17.txt

=cut

sub t {
    my ($position, $roll, $set, $only) = @_;
    return join ' ', map { $_->trace } $E->new(position => $position)->moves($roll, $set, $only);
}

sub after {
    my ($position, $roll, $set, $trace) = @_;
    my $bd = $E->new(position => $position);
    my ($m) = grep { $_->trace eq $trace } $bd->moves($roll, $set);
    die "no $trace\n" unless $m;
    $bd->apply($m, $set);
    return $bd;
}

my @CASES = (
    { what => 'G2: the extra throw chains', gap => 'G2',
      cite => [ G => q{Player obtains an extra move if the number of steps is 1, 4 or 5.} ],
      run  => sub {
          my $bd = $E->new(position => 'dldldldldl/........../.......... l 5');
          for my $step ([1, '10>11'], [4, '11>15'], [5, '15>20'], [1, '20>21']) {
              my ($m) = grep { $_->trace eq $step->[1] } $bd->moves($step->[0], 'kendall');
              $bd->apply($m, 'kendall');
          }
          $bd->side == SIDE_LIGHT;
      } },
    { what => 'G3: a forfeit on a 4 keeps the turn', gap => 'G3',
      run  => sub { my $bd = $E->new(position => 'l.ddd...../........../.......... l 5'); $bd->forfeit(4); $bd->side == SIDE_LIGHT } },
    { what => 'G4: backward only when no forward move exists',
      cite => [ G => q{if no dancer can move forward, player should move one of the dancers in backward direction} ],
      run  => sub {
          t('........../.........d/.l.l.d.... l 5', 1, 'kendall') eq '22>23 24>25'
          && t('........../.........d/.l.l.d.... l 5', 2, 'kendall') eq '22<20x';
      } },
    { what => 'G5: a backward swap sends the enemy forward', gap => 'G5',
      run  => sub { after('........../.........d/.l.l.d.... l 5', 2, 'kendall', '22<20x')->at(22) == DARK } },
    { what => 'G6: a piece passes over a lone enemy',
      cite => [ W => q{Players can move their pawns ahead of each other's pawns as necessary} ],
      run  => sub { t('l.d......./........../.......... l 5', 4, 'kendall') eq '1>5' } },
    { what => 'G7: under kendall two in a row are protected',
      cite => [ G => q{two or more opponent's dancers in a row, none of dancers within protected group can be beaten} ],
      run  => sub { t('l.dd....../........../.......... l 5', 3, 'kendall') eq '' } },
    { what => 'G8: a blockade stops a backward move', gap => 'G8',
      run  => sub { t('........../........dd/.l.l.d.... l 5', 4, 'skyruk') eq '' } },
    { what => 'G9: under kendall nothing stands on 27',
      cite => [ W => q{must be immediately moved to House 15} ],
      run  => sub { t('........../........../.....l.... l 5', 1, 'kendall') eq '26>15' } },
    { what => 'G10: the walk passes the mover\'s own piece on 15',
      cite => [ G => q{the dancer is moved to the first empty house preceding the House of Rebirth} ],
      run  => sub { t('........../....l...../.....l.... l 5', 1, 'kendall', 26) eq '26>14' } },
    { what => 'G11: kendall, a roll past 26 from below is not a move',
      cite => [ W => q{Pawns cannot bypass this house under any circumstance} ],
      run  => sub { t('d........./........../....l..... l 5', 3, 'kendall') eq '25<22' } },
    { what => 'G12: 28 with a 1 is not a move',
      cite => [ W => q{on the first turn that they roll exactly 3 white sticks} ],
      run  => sub { t('d........./........../.......l.. l 5', 1, 'kendall') eq '' } },
    { what => 'G13: W\'s row-one clause for 30 is not built', gap => 'G13',
      cite => [ W => q{or if the first row of the senet board (Houses 1 through 10) is not occupied by any pawns} ],
      run  => sub { t('........../d........./.........l l 5', 2, 'kendall') eq '' } },
    { what => 'G14: a bear-off on a 1 throws again', gap => 'G14',
      run  => sub { after('d........./........../.l.......l l 5', 1, 'kendall', '30>off')->side == SIDE_LIGHT } },
    { what => 'G15: the ply cap draws', gap => 'G15',
      run  => sub {
          my $bd = $E->new(position => 'd........./........../.....l.... l 5');
          $bd->set_ply($bd->ply_cap - 1);
          $bd->forfeit(2);
          $bd->status == DRAWN;
      } },

    { what => 'pieces: five a side', cite => [ M => q{Each person has five pieces} ],
      run  => sub { Game::Senet::Rules->new(rules => 'kendall')->home('light') == 0
                    && $E->rules('kendall')->{pieces} == 5 } },
    { what => 'the start: interleaved on the first ten',
      cite => [ M => q{Pieces are placed on the first ten squares of the first row with the colours alternating.} ],
      run  => sub { Game::Senet::Rules->new(rules => 'kendall')->position eq 'dldldldldl/........../.......... l 5' } },
    { what => 'who moves first: the side on the even houses', cite => [ G => q{First move takes the} ],
      run  => sub { Game::Senet::Rules->new(rules => 'skyruk')->side eq 'light' } },
    { what => 'landing on your own piece is not a move',
      cite => [ G => q{Dancer can not move to the house where another dancer of the same player is located} ],
      run  => sub { t('l.l......./........../.......... l 5', 2, 'kendall') eq '3>5' } },
    { what => 'landing on an enemy is the swap', cite => [ G => q{the dancers swaps their houses} ],
      run  => sub { after('l...d...../........../.......... l 5', 4, 'kendall', '1>5x')->at(1) == DARK } },
    { what => 'the same, in another source', cite => [ C => q{they have to exchange their positions} ],
      run  => sub { after('l...d...../........../.......... l 5', 4, 'skyruk', '1>5x')->at(1) == DARK } },
    { what => 'W\'s capture is NOT the one built: nothing goes to the first empty house',
      cite => [ W => q{the opponent's pawn can be captured} ],
      run  => sub { my $bd = after('..l.d...../........../.......... l 5', 2, 'kendall', '3>5x');
                    $bd->at(3) == DARK && $bd->at(1) == EMPTY } },
    { what => 'three in a row cannot be passed',
      cite => [ W => q{cannot move any of their own pawns past that formation} ],
      run  => sub { t('l...ddd.../........../.......... l 5', 5, 'kendall') eq '' } },
    { what => 'every piece lands on 26',
      cite => [ M => q{Every piece must land upon it before preceding onward.} ],
      run  => sub { t('d........./........../...l...... l 5', 2, 'kendall') eq '24>26'
                    && t('d........./........../...l...... l 5', 3, 'kendall') eq '24<21' } },
    { what => '27 sends the piece to 15', cite => [ G => q{reappears in the House of Rebirth} ],
      run  => sub { after('d........./........../.....l.... l 5', 1, 'kendall', '26>15')->at(15) == LIGHT } },
    { what => '28 off on exactly 3',
      cite => [ G => q{if the number of steps is 3, this is the only legal move for this dancer} ],
      run  => sub { t('d........./........../.......l.. l 5', 3, 'kendall') eq '28>off' } },
    { what => '29 off on exactly 2',
      cite => [ G => q{if the number of steps is 2, this is the only legal move for this dancer} ],
      run  => sub { t('d........./........../........l. l 5', 2, 'kendall') eq '29>off'
                    && t('d........./........../........l. l 5', 3, 'kendall') eq '' } },
    { what => '30 off on exactly 1 under kendall',
      cite => [ G => q{if the number of steps is 1, this is the only legal move for this dancer} ],
      run  => sub { t('d........./........../.........l l 5', 1, 'kendall') eq '30>off'
                    && t('d........./........../.........l l 5', 4, 'kendall') eq '' } },
    { what => 'from 26 a 5 bears off', cite => [ G => q{if number of steps is 5, the dancer bourne off the board} ],
      run  => sub { t('d........./........../.....l.... l 5', 5, 'kendall') eq '26>off' } },
    { what => 'an enemy on a safe house cannot be swapped', cite => [ G => q{The *safe* houses are all special houses} ],
      run  => sub { t('........../l...d...../.......... l 5', 4, 'kendall') eq '11<7' } },
    { what => 'the win', cite => [ M => q{The first player to bear all pieces off the board wins.} ],
      run  => sub { after('d........./........../.........l l 1', 1, { exits => 'kendall', pieces => 1 }, '30>off')->status == WON } },

    { what => 'skyruk: a blockade of two',
      cite => [ G => q{two or more opponent's dancers in a row, all dancers should stand next to each other} ],
      run  => sub { t('.l..dd..../........../.......... l 5', 5, 'skyruk') eq '' } },
    { what => 'skyruk: only the ends of a run are protected', cite => [ G => q{the first and the last one are protected} ],
      run  => sub { t('...l..ddd./........../.......... l 5', 4, { exits => 'skyruk', blockade => 0 }) eq '4>8x' } },
    { what => 'skyruk: from 25 any roll reaches 26',
      cite => [ G => q{it lands to the House of Happiness whatever the number of steps is} ],
      run  => sub { t('d........./........../....l..... l 5', 5, 'skyruk') eq '25>26' } },
    { what => 'skyruk: a piece arriving on 26 is thrown for again',
      cite => [ G => q{sticks should be thrown again and this dancer performs an extra move} ],
      run  => sub { my $bd = $E->new(position => 'd........./........../....l..... l 5');
                    my ($m) = $bd->moves(2, 'skyruk'); my (undef, $bound) = $bd->apply($m, 'skyruk');
                    $bound == 26 && $bd->side == SIDE_LIGHT } },
    { what => 'skyruk: 27 bears off on a 4', cite => [ G => q{if number of steps is 4, the dancer is bourne off the board} ],
      run  => sub { t('d........./........../......l... l 5', 4, 'skyruk') eq '27>off' } },
    { what => 'skyruk: 27 on a 5 stays, and the turn does not pass (M2)', gap => 'G18',
      cite => [ G => q{remains in House of Water and the turn is passed to the opponent} ],
      run  => sub { my $bd = $E->new(position => 'd........./........../......l... l 5');
                    !$bd->moves(5, 'skyruk') && do { $bd->forfeit(5); $bd->side == SIDE_LIGHT } } },
    { what => 'skyruk: 30 bears off on any roll',
      cite => [ G => q{can be bourne off the board regardless the number of steps} ],
      run  => sub { join('|', map { t('d........./........../.........l l 5', $_, 'skyruk') } 1 .. 5)
                    eq join('|', ('30>off') x 5) } },
    { what => 'S\'s 30 is skyruk\'s and not kendall\'s', cite => [ S => q{a roll of any number permits the pawn to escape} ],
      run  => sub { t('d........./........../.........l l 5', 3, 'kendall') eq '' } },
);

subtest 'every case carries a quotation or a gap' => sub {
    for my $case (@CASES) {
        my $cited = $case->{cite} && $case->{cite}[0] =~ /\A[WMCGS]\z/ && length $case->{cite}[1];
        my $gap   = $case->{gap} && $case->{gap} =~ /\AG\d+\z/;
        ok($cited || $gap, "$case->{what}: " . ($cited ? "cited from $case->{cite}[0]" : "gap $case->{gap}"));
    }
};

for my $case (@CASES) {
    ok($case->{run}->(), $case->{what});
}

done_testing();
