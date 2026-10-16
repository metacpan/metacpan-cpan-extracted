use strict;
use warnings;
use Test::More;

use Game::Sternhalma;
use Game::Sternhalma::Error;

# A PROGRAMMER'S MISTAKE dies with a named error; a player's never does.

sub dies_with {
    my ($code, $args, $why, $what) = @_;
    my $ok = eval { Game::Sternhalma->new(@$args); 1 };
    my $e = $@;
    ok(!$ok, "$what: no game");
    isa_ok($e, 'Game::Sternhalma::Error');
    is(ref $e ? $e->code : undef, $code, "  code $code");
    like("$e", $why, '  and it says why, in words');
    like("$e", qr/at \S+27-errors\.t line \d+\.$/, '  naming the caller\'s line, not the module\'s');
}

dies_with(bad_layout => [ seats => 5 ], qr/five cannot play/, 'five seats');
dies_with(bad_layout => [ seats => 4, pieces => 15 ], qr/share a hole/, 'fifteen pieces at four seats');
dies_with(bad_layout => [ seats => 1 ], qr/crossing alone/, 'one seat, not asked for');
dies_with(bad_layout => [ seats => 'two' ], qr/must be a number/, 'a word for a seat count');
dies_with(bad_first  => [ seats => 3, first => 3 ], qr/0 to 2/, 'a first seat the game does not have');
dies_with(bad_first  => [ first => 'x' ], qr/first seat/, 'a word for the first seat');
dies_with(bad_cap    => [ cap => 0 ], qr/above 0/, 'a cap of nothing');
dies_with(bad_cap    => [ cap => -5 ], qr/above 0/, 'a cap below nothing');
dies_with(bad_position => [ position => 'x' ], qr/character/, 'a position that is not one');
dies_with(bad_first  => [ position => Game::Sternhalma->new->position, first => 1 ], qr/seat to move/,
    'a position and a first seat both');

ok(Game::Sternhalma->new(seats => 1, solo => 1), 'one seat, asked for: a crossing alone');

{
    my $ok = eval { Game::Sternhalma->replay("not a game\n"); 1 };
    is(!$ok && ref $@ ? $@->code : undef, 'bad_log', 'a log that is not a game: bad_log');
    $ok = eval { Game::Sternhalma->replay("sternhalma 1\nseats 2\npieces 10\ncap 2000\nmoves\nd1-e6\nd1-e6\n"); 1 };
    like(!$ok ? "$@" : '', qr/bad_log: move 2, d1-e6: there is no piece there/, 'a log with a move that cannot be made names the move');
}

{
    my $ok = eval { Game::Sternhalma::Error->throw('no_such_code'); 1 };
    like(!$ok ? "$@" : '', qr/no such error as 'no_such_code'/, 'an error code that does not exist is refused');
    is_deeply([ Game::Sternhalma::Error->codes ], [ sort qw(bad_layout bad_first bad_cap bad_position bad_log) ],
        'the codes there are');
}

done_testing();
