use strict;
use warnings;
use Test::More;
use B ();

use Game::Fanorona;
use Game::Fanorona::Bot;
use Game::Fanorona::Engine;
use Game::Fanorona::Rules;
use Game::Fanorona::Terminal;

# AN EXCEPTION KEEPS ITS MESSAGE WHEN IT PASSES A GAME ON THE WAY OUT.
#
# On perls 5.14 to 5.26, an eval that runs inside a destructor while an
# exception is unwinding past a TEMPORARY object leaves $@ empty. The board
# and the game were let go by a DEMOLISH, which Object::Proto calls under an
# eval, so
#
#     eval { Game::Fanorona::Bot->think(Game::Fanorona->new, level => 'x') };
#
# died with no message at all on those perls. The first packaging matrix
# found it, in t/25-bot.t. The board and the game are now let go by a
# destructor written in C, which runs no perl.
#
# THIS FILE CANNOT FAIL ON A PERL FROM 5.28 ON for the first reason, so it
# also asserts the structure: nothing here has a DEMOLISH, and the two
# destructors are XSUBs.

sub dies { die "the message\n" }

my %make = (
    'a board'          => sub { Game::Fanorona::Engine->new },
    'a game of Rules'  => sub { Game::Fanorona::Rules->new },
    'a Game::Fanorona' => sub { Game::Fanorona->new },
    'a clone'          => sub { Game::Fanorona::Rules->new->clone },
    'a board from a string' => sub { (Game::Fanorona::Engine->of_string('9/9/w1b6/9/9 w'))[0] },
);

my ($games, $boards) = (Game::Fanorona::Rules->live, Game::Fanorona::Engine->live);

for my $what (sort keys %make) {
    my $made = $make{$what};
    ok(ref $made->(), "$what is made");
    eval { dies($made->()) };
    is($@, "the message\n", "an exception past $what that was a temporary keeps its message");
    eval { my $kept = $made->(); dies($kept) };
    is($@, "the message\n", "and past one held in a variable");
    eval { my @kept = map { $made->() } 1 .. 3; dies(@kept, $made->()) };
    is($@, "the message\n", 'and past four of them');
}

eval { Game::Fanorona::Bot->think(Game::Fanorona->new, level => 'strong') };
like($@, qr/a level is a whole number/, 'the call the matrix failed on: the refusal arrives with its words');
eval { Game::Fanorona::Bot->think(Game::Fanorona->new->position) };
like($@, qr/takes a Game::Fanorona/, 'and a refusal while a game is being thrown away');

is(Game::Fanorona::Rules->live, $games, 'every game made on the way was let go');
is(Game::Fanorona::Engine->live, $boards, 'and every board');

for my $class (qw(Game::Fanorona Game::Fanorona::Engine Game::Fanorona::Rules Game::Fanorona::Move
                  Game::Fanorona::Variant Game::Fanorona::Error Game::Fanorona::Result Game::Fanorona::Terminal)) {
    ok(!$class->can('DEMOLISH'), "$class has no DEMOLISH");
}
for my $class (qw(Game::Fanorona::Engine::Hold Game::Fanorona::Rules::Hold)) {
    my $destroy = $class->can('DESTROY');
    ok($destroy, "$class has a destructor");
    ok($destroy && B::svref_2object($destroy)->XSUB, 'and it is not written in perl');
}

done_testing();
