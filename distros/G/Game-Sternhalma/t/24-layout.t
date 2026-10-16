use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
use Game::Sternhalma::Layout qw(seat_counts points home_of pieces_ok why_not);
my $E = 'Game::Sternhalma::Engine';

# W's table, typed here; Layout's table and the engine's are each held to it.
my %WANT = (2 => [0, 3], 3 => [0, 2, 4], 4 => [0, 1, 3, 4], 6 => [0, 1, 2, 3, 4, 5]);
my %HOME = (2 => [3, 0], 3 => [3, 5, 1], 4 => [3, 4, 0, 1], 6 => [3, 4, 5, 0, 1, 2]);

is_deeply([ seat_counts() ], [ 2, 3, 4, 6 ], 'two, three, four or six seats');
for my $n (2, 3, 4, 6) {
    is_deeply([ points($n) ], $WANT{$n}, "$n seats start at points @{ $WANT{$n} }");
    is_deeply([ map { $E->layout_point($n, $_) } 0 .. $n - 1 ], $WANT{$n}, '  as the engine has it');
    is_deeply([ map { home_of($n, $_) } 0 .. $n - 1 ], $HOME{$n}, "  and race to @{ $HOME{$n} }, the points opposite");
    my $ascending = 1;
    my @p = points($n);
    $ascending = 0 if grep { $p[$_] <= $p[ $_ - 1 ] } 1 .. $#p;
    ok($ascending, '  seat order runs clockwise round the star');
}

{
    my @at3 = (points(3), map { home_of(3, $_) } 0 .. 2);
    is_deeply([ sort { $a <=> $b } @at3 ], [ 0 .. 5 ], 'three seats race into the three points nobody started in');
    my %empty = map { $_ => 1 } 0 .. 5;
    delete $empty{$_} for points(4);
    is_deeply([ sort keys %empty ], [ 2, 5 ], 'four seats leave two opposite points empty');
}

for my $case ([2, 10], [3, 10], [4, 10], [6, 10], [2, 15], [3, 15]) {
    ok(pieces_ok(@$case), "$case->[0] seats of $case->[1]: a game");
    ok($E->layout_ok(@$case), '  and the engine builds it');
}
for my $case ([4, 15, qr/neighbouring points would share a hole/], [6, 15, qr/share a hole/],
              [5, 10, qr/five cannot play/], [7, 10, qr/2, 3, 4 or 6/], [1, 10, qr/crossing alone/],
              [2, 12, qr/10 pieces, or 15/], ['two', 10, qr/must be a number/]) {
    my ($s, $p, $why) = @$case;
    ok(!pieces_ok($s, $p), "$s seats of $p: no game");
    like(why_not($s, $p), $why, '  and why');
}
ok(!defined why_not(1, 10, 1), 'one seat is allowed when a crossing alone is asked for');

done_testing();
