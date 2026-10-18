use strict;
use warnings;
use Test::More;

# THE NOTATION NEEDS NO COMPILED CODE, and this file is what keeps it so.
#
# Before anything is loaded, every module of this distribution that has C
# behind it is made unloadable. If Game::Senet::Notation, or anything it loads,
# reaches for one of them, this file dies at the `use` below and says which.
BEGIN {
    unshift @INC, sub {
        my (undef, $file) = @_;
        die "the notation tried to load $file, which needs the compiled engine\n"
            if $file =~ m{\AGame/Senet(?:/(?:Engine|Move|Rules))?\.pm\z};
        return;
    };
}

use Game::Senet::Notation ':all';
use Game::Senet::Sticks qw(throw_for roll_for);

ok(!$INC{'Game/Senet/Engine.pm'}, 'the engine was not loaded');
ok(!$INC{'Game/Senet/Move.pm'},   'nor the move class');
ok(!$INC{'Game/Senet/Rules.pm'},  'nor the rules');
ok(!$INC{'Game/Senet.pm'},        'nor the distribution\'s own module');
ok(!$INC{'Object/Proto/Sugar.pm'}, 'and no class was declared: the notation is functions');
ok(!defined &Game::Senet::Engine::_abi_ptr, 'and there is no compiled function in sight');

is_deeply([ parse_move('26-off') ], [ { from => 26, to => 'off' }, undef ], 'a move is read');
is((parse_move('0-5'))[1], 'house', 'a bad one is refused');
is(format_move({ from => 12, to => 15 }), '12-15', 'and written');
is(format_display({ from => 22, to => 20, roll => 2, back => 1, swap => 1 }, 0), '2: 22-20<x', 'and displayed');
is(format_forfeit(4, 1), '4: -+', 'a forfeit is written');

is(validate_position('dldldldldl/........../.......... l 5'), POS_OK, 'a position is validated');
is(validate_position('llllll..../........../.......... l 5'), POS_EXCESS, 'and a bad one named');

my $seed = 'senet no xs';
my $text = "[variant kendall pieces=5 blockade=3 protect=run backward=1 reach26=exact throw_on_26=0]\n"
         . "[first light]\n[seed " . unpack('H*', $seed) . "]\n";
my ($record, $problem) = parse_record($text);
ok($record, 'a record with a seed is read') or diag(explain $problem);
is(format_record($record), $text, 'and written back the same');

my $roll = roll_for($seed, 0);
my $sticks = join '', @{ throw_for($seed, 0) };
($record, $problem) = parse_record($text . "1. l $roll $sticks: -\n");
ok($record, "its first throw, $sticks for a $roll, is checked against the seed with no engine")
    or diag(explain $problem);
my $wrong = $roll == 2 ? 3 : 2;
is((parse_record($text . "1. l $wrong: -\n"))[1]{error}, 'roll', 'and a wrong one is refused');

done_testing();
