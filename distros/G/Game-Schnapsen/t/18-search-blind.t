#!perl
use 5.010; use strict; use warnings;
use Test::More;
use FindBin ();

# THIS IS A GREP AND NOT A BEHAVIOURAL TEST, on purpose.
#
# A bot that could read the talon would know every card it is about to draw and
# every card its opponent holds. It would play LEGAL, REPLAYABLE, WINNING GAMES
# THAT NO ORDINARY TEST CAN TELL FROM A VERY GOOD PLAYER - which is precisely
# why an ordinary test cannot defend this. The cheapest defence available is a
# signature that cannot express the cheat, and this file is what keeps it that
# way.
#
# Two things it gets right that the first version of Game::Gin's equivalent did
# not:
#
#   1. POD IS STRIPPED AS WELL AS COMMENTS. Gin's version stripped comments only
#      and then failed on its own documentation, which discusses the stock at
#      length. A check that inspects the wrong text is worse than none.
#
#   2. IT ASSERTS THE PRESENT AS WELL AS THE ABSENT. A file that had been
#      emptied would pass every exclusion below. So the values that ARE allowed
#      must appear, and the one permitted use of a forbidden word is asserted to
#      be the only one.

my $file = "$FindBin::Bin/../lib/Game/Schnapsen/Search.pm";
ok(-e $file, 'Game::Schnapsen::Search is where it should be') or BAIL_OUT('no Search.pm');

open my $fh, '<', $file or BAIL_OUT("cannot read $file: $!");
my @all = <$fh>;
close $fh;

# Everything from __END__ is documentation and is allowed to discuss the talon,
# the opponent's hand and the seed as much as it likes.
my @code;
for my $line (@all) {
    last if $line =~ /^__END__/;
    next if $line =~ /^\s*#/;
    push @code, $line;
}
my $code = join '', @code;

cmp_ok(scalar @code, '>=', 40,
       'there are ' . scalar(@code) . ' lines of real code to inspect');

# ---- what it must not be able to see -----------------------------------------------

my @FORBIDDEN = (
    [ qr/\btalon\b/            => 'the talon, other than as a public count' ],
    [ qr/->hands\b/            => "the deal's hands" ],
    [ qr/->hand_of\b/          => "the other player's hand" ],
    [ qr/->deal\b/             => 'the deal' ],
    [ qr/->tricks\b/           => 'the played tricks' ],
    [ qr/Game::Schnapsen::Deal/ => 'the Deal class' ],
    [ qr/Game::Schnapsen::Bot/ => 'the Bot class' ],
    [ qr/->seed\b/             => 'the seed' ],
    [ qr/\border_for\b/        => 'the shuffle' ],
    [ qr/\bdeal_for\b/         => 'the deal layout' ],
    [ qr/Game::Schnapsen::Deck/ => 'the Deck' ],
    [ qr/\bturn_up\b.*=.*undef/ => 'writing to the turn-up' ],
);

for my $f (@FORBIDDEN) {
    my ($re, $what) = @$f;
    unlike($code, $re, "the search cannot reach $what");
}

# The variant never arrives either, by name or by predicate. The two games
# differ in what is legal and in how a deal scores, and both are settled before
# the search is called. The package statement and the `use` lines legitimately
# say "Schnapsen", so they come out before the word is looked for.
my $body = $code;
$body =~ s/^package [^;]+;//;
$body =~ s/^use Game::Schnapsen::\w+[^;]*;//mg;
unlike($body, qr/\bsixtysix\b/, 'the variant name never appears');
unlike($body, qr/\bvariant\b/, 'and neither does the word variant');

# ---- the other direction, so this is not measuring an empty file --------------------

like($code, qr/\$o\{cards\}/,        'it is given cards to choose between');
like($code, qr/\$o\{trump\}/,        'and the trump suit, which is on the table');
like($code, qr/\$o\{talon_left\}/,   'and how many cards are left, which is a COUNT and public');
like($code, qr/\$o\{my_points\}/,    'and its own card points');
like($code, qr/\$o\{level\}/,        'and the rung it is playing at');

# THE TRICK WORTH COPYING: the one allowed occurrence of a forbidden word is
# asserted to be the ONLY one, so the exclusion is itself under test rather than
# quietly weakened by a rename.
my @bare_talon = grep { /\btalon\b/ && !/talon_left/ } @code;
is(scalar @bare_talon, 0, 'and "talon" appears only ever as the public count')
    or diag(join '', @bare_talon);

my @bare_tricks = grep { /\btricks\b/ && !/their_tricks/ } @code;
is(scalar @bare_tricks, 0, 'and "tricks" only ever as the opponent\'s public count')
    or diag(join '', @bare_tricks);

# ---- the exclusions are real, checked against a file that would fail them ------------

subtest 'the forbidden list would actually catch a cheat' => sub {
    # A list of patterns that match nothing is a list that passes for ever. Each
    # one is run against a line that a cheating search really would contain.
    plan tests => scalar @FORBIDDEN;
    my %sample = (
        'the talon, other than as a public count' => 'my @rest = @{ $o{talon} };',
        "the deal's hands"                        => 'my $h = $game->hands;',
        "the other player's hand"                 => 'my $them = $deal->hand_of($other);',
        'the deal'                                => 'my $d = $game->deal;',
        'the played tricks'                       => 'my @t = @{ $deal->tricks };',
        'the Deal class'                          => 'use Game::Schnapsen::Deal ();',
        'the Bot class'                           => 'use Game::Schnapsen::Bot ();',
        'the seed'                                => 'my $s = $game->seed;',
        'the shuffle'                             => 'my $o = order_for($seed, 1, $v);',
        'the deal layout'                         => 'my $d = deal_for($seed, 1, $v);',
        'the Deck'                                => 'use Game::Schnapsen::Deck ();',
        'writing to the turn-up'                  => '$deal->turn_up = undef;',
    );
    for my $f (@FORBIDDEN) {
        my ($re, $what) = @$f;
        like($sample{$what}, $re, "the pattern for $what matches a line that has it");
    }
};

done_testing();
