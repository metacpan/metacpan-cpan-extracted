use strict;
use warnings;
use Test::More;

# Game::Brandubh::Notation LOADS ON ITS OWN. It is the one module here a
# caller can use with no compiled code behind it: to tell a position from a
# typo, or to read a saved game, on a machine where the engine was never built.
#
# So the engine is made impossible to load before the module is asked for, and
# the test then uses everything the module exports. A `use` of the engine that
# crept into Notation.pm would die here and nowhere else.

my @tried;
BEGIN {
    require XSLoader;
    no warnings 'redefine';
    *XSLoader::load = sub { die "XSLoader::load was called for @_\n" };
    unshift @INC, sub {
        my (undef, $file) = @_;
        push @tried, $file;
        die "something asked for $file\n" if $file =~ m{\AGame/Brandubh(?:/(?:Engine|Rules))?\.pm\z};
        return;
    };
}

BEGIN { use_ok('Game::Brandubh::Notation', ':all') }

ok(!exists $INC{'Game/Brandubh/Engine.pm'}, 'the engine was not loaded');
ok(!exists $INC{'Game/Brandubh/Rules.pm'}, 'nor the rules');
ok(!exists $INC{'Object/Proto/Sugar.pm'}, 'nor Object::Proto::Sugar: these are functions, not a class');
ok(!(grep { m{\AGame/Brandubh/(?:Engine|Rules)\.pm\z} } @tried), 'and nothing so much as asked for them');

is(square_name(3, 3), 'd4', 'square_name');
is_deeply([ square_parse('g7') ], [ 6, 6 ], 'square_parse');
is(move_wire('d1', 'd3'), 'd1d3', 'move_wire');
is_deeply([ move_split('d1d3') ], [ 'd1', 'd3' ], 'move_split');
is(move_parse('Kd4-d1xc1++'), 'd4d1', 'move_parse');
is(move_display('d1d3', { captures => ['c3'] }), 'd1-d3xc3', 'move_display');
ok(position_ok(SETUP), 'position_ok, and SETUP');
is(scalar(@{ (position_cells(SETUP))[0] }), 7, 'position_cells');
my $text = game_string({ moves => [qw(d1c1 d3c3)] });
is($text, "variant brandubh\nmoves d1c1 d3c3\n", 'game_string');
is_deeply(game_parse($text)->{moves}, [qw(d1c1 d3c3)], 'game_parse');

is(scalar(@Game::Brandubh::Notation::EXPORT_OK), 11, 'eleven names are exported, and all eleven were used above');
ok(!@Game::Brandubh::Notation::EXPORT, 'and none of them unless asked for');

done_testing();
