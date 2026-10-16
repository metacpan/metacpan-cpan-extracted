use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
use Game::Sternhalma::Notation qw(parse_move format_move hole_of);
my $E = 'Game::Sternhalma::Engine';

my $C = $E->hole_at(0, 0);
sub at_ { my ($h, $d, $k) = @_; $h = $E->next_to($h, $d) for 1 .. ($k || 1); $h }
sub n { $E->name($_[0]) }

# ---- the text, with no board -------------------------------------------------------

is_deeply(parse_move('e5-f5'), { kind => 'step', holes => [ hole_of('e5'), hole_of('f5') ] }, 'a step');
is_deeply(parse_move('e5:g5:g7'), { kind => 'chain', holes => [ map { hole_of($_) } qw(e5 g5 g7) ] }, 'a chain');
is_deeply(parse_move('pass'), { kind => 'pass' }, 'a pass');
is_deeply(parse_move('resign 2'), { kind => 'resign', seat => 2 }, 'a resignation');
for my $t ('e5-e5', 'e5:e5', 'e5', 'e5-', 'e5-f5-g5', 'e5:', 'x1-e5', 'resign 6', 'resign', 'Pass', 'e5 - f5') {
    ok(!defined parse_move($t), "'$t' is not a move");
}
for my $t (qw(e5-f5 e5:g5:g7 a1:c1 pass), 'resign 0') {
    is(format_move(parse_move($t)), $t, "'$t' writes back as itself");
}

# ---- against a board ----------------------------------------------------------------

{
    my $bd = $E->new(seats => 2);
    is($bd->move_text(6, 15), 'd1-e6', 'a step is written with -');
    is($bd->move_text(3, 14), 'c1:e5', 'a one-hop chain with :');
    ok(!defined $bd->move_text(6, 7), 'and a move that is not one is not written');
}

{
    my $bd = $E->new(seats => 2, empty => 1);
    $bd->put($C, 0);
    $bd->put(at_($C, E), 1);
    $bd->put(at_($C, E, 3), 1);
    my $far = at_($C, E, 4);
    my $want = join ':', map { n($_) } $C, at_($C, E, 2), $far;
    is($bd->move_text($C, $far), $want, 'a two-hop chain is written by its path');
    my ($m) = $bd->read_move(n($C) . '-' . n($far));
    is_deeply($m && $m->{path}, [ $C, at_($C, E, 2), $far ], 'from-to is read for a chain, and answers with the path it is shown by');
    ($m) = $bd->read_move($want);
    is($m && $m->{to}, $far, 'and the chain written out reads the same');
}

# ---- two paths to one hole: the same move ----------------------------------------------
#
# Out east then north-east, or out north-east then east, to the same hole.

{
    my $bd = $E->new(seats => 2, empty => 1);
    $bd->put($C, 0);
    $bd->put($_, 1) for at_($C, E), at_($C, NE), at_(at_($C, E, 2), NE), at_(at_($C, NE, 2), E);
    my $X = at_(at_($C, E, 2), NE, 2);
    is($X, at_(at_($C, NE, 2), E, 2), 'two ways round meet at one hole');
    my $one = join ':', map { n($_) } $C, at_($C, E, 2), $X;
    my $two = join ':', map { n($_) } $C, at_($C, NE, 2), $X;
    my ($first) = $bd->read_move($one);
    my ($second) = $bd->read_move($two);
    ok($first && $second, 'both paths are read');
    is_deeply([ $first->{from}, $first->{to} ], [ $second->{from}, $second->{to} ], '  as the same move');
    is_deeply($first->{path}, $second->{path}, '  shown by the same path');
    is($bd->move_text($C, $X), $one, '  which is the one found first, east before north-east');
}

# ---- refusals, saying why ----------------------------------------------------------------

{
    my $bd = $E->new(seats => 2, empty => 1);
    $bd->put($C, 0);
    $bd->put(at_($C, E), 1);
    my (undef, $why) = $bd->read_move(n($C) . ':' . n(at_($C, E, 2)) . ':' . n(at_($C, E, 4)));
    like($why, qr/\Ahop 2: /, 'a chain whose second hop is no hop is refused, and says which hop');
    (undef, $why) = $bd->read_move(n($C) . '-' . n(at_($C, W, 2)));
    like($why, qr/is not where/, 'a stop out of reach is refused');
    (undef, $why) = $bd->read_move(n(at_($C, SE)) . '-' . n(at_($C, SE, 2)));
    like($why, qr/holds no piece/, 'a move from an empty hole is refused');
    (undef, $why) = $bd->read_move('hello');
    like($why, qr/not a move/, 'and text that is not a move');
}

done_testing();
