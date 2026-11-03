use 5.020;
use strict;
use warnings;
use Test::More;
use Devel::XSCover::Gcov ();

my $text = <<'GCOV';
        -:    0:Source:s.c
        -:    0:Graph:s.gcno
        -:    0:Data:s.gcda
        -:    0:Runs:1
        4:    3:    switch (n) {
        4:    3-block  0
branch  0 taken 1
branch  1 taken 1
branch  2 taken 1
branch  3 taken 0
branch  4 taken 1
        -:    4:    case 0:
        1:    5:        return 0;
        1:    5-block  0
        3:    9:    if (a && b && c)
        3:    9-block  0
branch  0 taken 2
branch  1 taken 1
        2:    9-block  1
branch  2 taken 2
branch  3 taken 0
        2:    9-block  2
branch  4 taken 1
branch  5 taken 1
        1:   12:    x = y;
branch  0 taken 1
branch  1 taken 0
GCOV

my $files = Devel::XSCover::Gcov->new(silent => 1)->parse($text);
my $b = $files->{'s.c'}{blocks};
is(scalar @$b, 5, 'five blocks with arms');
is_deeply($b->[0], { line => 3, arms => [1, 1, 1, 0, 1] }, 'the switch is one block with five arms, never split');
is_deeply([ map { $_->{arms} } @{$b}[1 .. 3] ], [[2, 1], [2, 0], [1, 1]], 'three conditions on one line are three blocks');
is_deeply($b->[4], { line => 12, arms => [1, 0] }, 'branch lines without a block line make one block for the line');

done_testing;
