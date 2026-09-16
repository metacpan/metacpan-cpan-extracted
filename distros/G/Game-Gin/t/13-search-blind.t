#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();

# THE ANTI-CHEAT TEST, and it is a grep rather than a behaviour.
#
# Game::Gin::Search decides the bot's moves and must only ever see what the
# seat can see. A bot that could read the stock would know every card it is
# about to draw; a bot that could read the other hand would know exactly when
# to knock. Either plays legal, replayable, winning games that no ordinary
# test can tell from a very good player, which is precisely why an ordinary
# test cannot defend this.
#
# So the defence is structural: the functions have nowhere to put a game, a
# stock or an opponent's hand, and this file checks that the file never
# mentions one. Game-Backgammon guards its board encapsulation the same way,
# by grepping the tree.

my $FILE = "$FindBin::Bin/../lib/Game/Gin/Search.pm";
ok(-e $FILE, 'Game::Gin::Search is where it should be') or BAIL_OUT('nothing to check');

open my $fh, '<', $FILE or BAIL_OUT("cannot read $FILE: $!");
my @lines = <$fh>;
close $fh;

# CODE ONLY. Comments and POD are allowed to discuss the stock at length, and
# do: the POD explains why the module cannot see it and links to
# Game::Gin::Bot. The first version of this file stripped comments and not
# POD, and failed on its own documentation, which is a check inspecting the
# wrong thing rather than a module doing the wrong thing.
my @code;
for my $line (@lines) {
    last if $line =~ /^__END__/;
    next if $line =~ /^\s*#/;
    push @code, $line;
}
my $code = join '', @code;

cmp_ok(scalar @code, '>', 40, 'there is a real amount of code to check');

# Each of these is a way the module could reach something the seat cannot see.
my @forbidden = (
    [ qr/\bstock\b/           => 'the stock' ],
    [ qr/->hands\b/           => "the deal's hands" ],
    [ qr/->hand_of\b/         => 'another seat\'s hand' ],
    [ qr/->deal\b/            => 'the deal object' ],
    [ qr/Game::Gin::Deal/     => 'the deal class' ],
    [ qr/Game::Gin::Bot/      => 'the bot class' ],
    [ qr/->seed\b/            => 'the seed' ],
    [ qr/\border_for\b/       => 'the shuffle' ],
    [ qr/Game::Gin::Deck/     => 'the deck' ],
);

for my $rule (@forbidden) {
    my ($re, $what) = @$rule;
    my @hit = grep { $_ =~ $re } @code;
    is(scalar @hit, 0, "Search.pm never reaches $what")
        or diag("found: " . join('', @hit));
}

# The other direction. A module that reached for nothing at all would pass
# every check above and decide nothing: it has to actually be given the hand
# and the upcard, or the test is measuring an empty file.
like($code, qr/\$o\{hand\}/,   'it is given the hand it is playing');
like($code, qr/\$o\{upcard\}/, 'and the card everybody can see');
like($code, qr/\$o\{stock_left\}/,
     'and how many cards are left, which is a COUNT and public');

# stock_left is the one word containing "stock" that is allowed, because a
# count is public and the cards behind it are not. The check above excludes
# it deliberately, so this asserts the exclusion is doing what it claims.
my @bare_stock = grep { /\bstock\b/ && !/stock_left/ } @code;
is(scalar @bare_stock, 0, 'and "stock" appears only ever as the public count')
    or diag("found: " . join('', @bare_stock));

done_testing();
