use strict;
use warnings;
use Test::More;

# Game::Sternhalma::Notation LOADS ON ITS OWN. It is the one module here a
# caller can use with no compiled code behind it: to read a saved game, or tell
# a move from a typo, on a machine where the engine was never built.
#
# So the engine is made impossible to load before the module is asked for, and
# the test then uses everything the module exports. A `use` of the engine that
# crept into Notation.pm would die here and nowhere else. That the answers are
# the engine's is t/21-position-string.t's business, with both loaded.

my @tried;
BEGIN {
    require XSLoader;
    no warnings 'redefine';
    *XSLoader::load = sub { die "XSLoader::load was called for @_\n" };
    unshift @INC, sub {
        my (undef, $file) = @_;
        push @tried, $file;
        die "something asked for $file\n" if $file =~ m{\AGame/Sternhalma(?:/Engine)?\.pm\z};
        return;
    };
}

BEGIN { use_ok('Game::Sternhalma::Notation', ':all') }

ok(!exists $INC{'Game/Sternhalma/Engine.pm'}, 'the engine was not loaded');
ok(!exists $INC{'Object/Proto/Sugar.pm'}, 'nor Object::Proto::Sugar: these are functions, not a class');
ok(!(grep { m{\AGame/Sternhalma(?:/Engine)?\.pm\z} } @tried), 'and nothing so much as asked for them');

is(name_of(60), 'i5', 'name_of');
is(hole_of('i5'), 60, 'hole_of');
is(row_len(4), 13, 'row_len');
is(HOLES, 121, 'HOLES');
my $m = parse_move('e5:g5:g7');
is($m->{kind}, 'chain', 'parse_move');
is(format_move($m), 'e5:g5:g7', 'format_move');
my ($p, $code) = parse_position(SETUP_TWO);
is($code, 0, 'parse_position reads SETUP_TWO');
is(scalar(grep { defined } @{ $p->{cells} }), 20, '  twenty pieces');
is(format_position($p), SETUP_TWO, 'format_position writes it back');
my ($q) = parse_position(SETUP_TWO . ';p=3 k=1');
is_deeply([ $q->{ply}, $q->{pass_run} ], [ 3, 1 ], 'parse_position reads the game after the ;');
my (undef, $bad) = parse_position('x');
is($bad, 3, 'and refuses with the engine\'s codes');
my $text = format_game({ seats => 2, pieces => 10, moves => [ 'd1-e6', 'pass' ] });
is($text, "sternhalma 1\nseats 2\npieces 10\ncap 2000\nmoves\nd1-e6\npass\n", 'format_game');
my ($g) = parse_game($text);
is_deeply($g->{moves}, [ 'd1-e6', 'pass' ], 'parse_game');
my (undef, $why) = parse_game("sternhalma 1\nseats 5\npieces 10\ncap 10\nmoves\n");
like($why, qr/no game is 5 seats/, '  and says what is wrong with a game that cannot be');
(undef, $why) = parse_game("sternhalma 1\nseats 2\npieces 10\ncap 10\nmoves\nd1-e6\nhello\n");
like($why, qr/line 7 is not a move/, '  naming the line');

done_testing();
