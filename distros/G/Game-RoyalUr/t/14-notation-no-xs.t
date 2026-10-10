use strict;
use warnings;
use Test::More;

# THE NOTATION NEEDS NO COMPILED CODE, and this file is what keeps it so.
#
# Before anything is loaded, every module of this distribution that has C
# behind it is made unloadable. If Game::RoyalUr::Notation, or anything it
# loads, reaches for one of them, this file dies at the `use` below and says
# which.
BEGIN {
    unshift @INC, sub {
        my (undef, $file) = @_;
        die "the notation tried to load $file, which needs the compiled engine\n"
            if $file =~ m{\AGame/RoyalUr(?:/(?:Engine|Move|Rules))?\.pm\z};
        return;
    };
}

use Game::RoyalUr::Notation ':all';

ok(!$INC{'Game/RoyalUr/Engine.pm'}, 'the engine was not loaded');
ok(!$INC{'Game/RoyalUr/Move.pm'},   'nor the move class');
ok(!$INC{'Game/RoyalUr/Rules.pm'},  'nor the rules');
ok(!$INC{'Game/RoyalUr.pm'},        'nor the distribution\'s own module');
ok(!$INC{'Object/Proto/Sugar.pm'},  'and no class was declared: the notation is functions');
ok(!defined &Game::RoyalUr::Engine::_abi_ptr, 'and there is no compiled function in sight');

is_deeply([ parse_move('hand-b1') ], [ { from => 'hand', to => 'b1' }, undef ], 'a move is read');
is((parse_move('e1-d1'))[1], 'place', 'a bad one is refused');
is(format_move({ from => 'g1', to => 'home' }), 'g1-home', 'and written');
is(format_display({ from => 'a2', to => 'd2', roll => 3, captures => 1, rosette => 1 }), '3: a2-d2x*', 'and displayed');
is(format_forfeit(0), '0: -', 'a forfeit is written');

is(validate_position('4xx2/8/4xx2 l 7 0 7 0'), POS_OK, 'a position is validated');
is(validate_position('8/8/4xx2 l 7 0 7 0'), POS_GAP, 'and a bad one named');

my $text = "[rules masters]\n[first light]\n[seed 00ff10]\n";
my ($record, $problem) = parse_record($text);
ok($record, 'a record with a seed is read') or diag(explain $problem);
is(format_record($record), $text, 'and written back the same');

my $played = "[rules finkel]\n[first light]\n1. l 4: hand-a1\n2. l 2: hand-c1\n3. d 0: -\n[result light resign]\n";
($record, $problem) = parse_record($played);
ok($record, 'a record with turns is read') or diag(explain $problem);
is(scalar @{ $record->{turns} }, 3, 'three of them');
is(format_record($record), $played, 'and written back the same');
is((parse_record("[rules finkel]\n[first light]\n1. l 4: hand-a1\n2. d 2: hand-c3\n"))[1]{error}, 'side',
    'and the side after a rosette is checked, with no board to ask');

done_testing();
