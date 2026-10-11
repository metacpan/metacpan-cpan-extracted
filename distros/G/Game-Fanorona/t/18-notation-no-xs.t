use strict;
use warnings;
use Test::More;

# Game::Fanorona::Notation LOADS ON ITS OWN. It is the one module here a caller
# can use with no compiled code behind it: to tell a move from a typo, or to
# read a saved game, on a machine where the engine was never built.
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
        die "something asked for $file\n" if $file =~ m{\AGame/Fanorona(?:/(?:Engine|Rules|Move))?\.pm\z};
        return;
    };
}

BEGIN { use_ok('Game::Fanorona::Notation', ':all') }

ok(!exists $INC{'Game/Fanorona/Engine.pm'}, 'the engine was not loaded');
ok(!exists $INC{'Game/Fanorona/Rules.pm'}, 'nor the rules');
ok(!exists $INC{'Game/Fanorona/Move.pm'}, 'nor the move');
ok(!exists $INC{'Object/Proto/Sugar.pm'}, 'nor Object::Proto::Sugar: these are functions, not a class');
ok(!(grep { m{\AGame/Fanorona/(?:Engine|Rules|Move)\.pm\z} } @tried), 'and nothing so much as asked for them');

is_deeply([ parse_point('e3') ], [ 4, 2 ], 'parse_point');
is(format_point(4, 2), 'e3', 'format_point');
# e3 is file 4, rank 2: (2 + 1) * 11 + 4 + 1
is(square_of('e3'), 38, 'square_of');
is(name_of(38), 'e3', 'name_of');
my $move = parse_move('b2-c2A-c3A');
is(scalar(@{ $move->{steps} }), 2, 'parse_move');
is(format_move($move), 'b2-c2A-c3A', 'format_move');
is_deeply([ move_points('b2-c2A-c3A') ], [ qw(b2 c2 c3) ], 'move_points');
is(mirror_move('d3-e3A', 'files'), 'f3-e3A', 'mirror_move');
is(parse_position(SETUP)->{stones}{d3}, 'w', 'parse_position, and SETUP');
is(format_position(SETUP, 2, 5), SETUP . ' 2 5', 'format_position');
is(mirror_position('bbb/w1b/www w', 'files'), 'bbb/b1w/www w', 'mirror_position');
my $text = format_game({ moves => [ 'd3-e3A', 'c3-d3W' ] });
is($text, "fanorona 1\nvariant sivy\nmoves\nd3-e3A\nc3-d3W\n", 'format_game');
is_deeply(parse_game($text)->{moves}, [ 'd3-e3A', 'c3-d3W' ], 'parse_game');

# a move object is anything with `from` and `steps`: format_move does not need
# the class to be loaded to write one
{
    package Local::MoveLike;
    sub new   { bless { from => 24, steps => [ { to => 25, kind => 1 } ] }, shift }
    sub from  { $_[0]{from} }
    sub steps { $_[0]{steps} }
}
is(format_move(Local::MoveLike->new), 'b2-c2A', 'format_move of an object with from and steps');

is(scalar(@Game::Fanorona::Notation::EXPORT_OK), 14, 'fourteen names are exported, and all fourteen were used above');
ok(!@Game::Fanorona::Notation::EXPORT, 'and none of them unless asked for');

done_testing();
