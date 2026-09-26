#!perl
use strict;
use warnings;
use Test::More;

# A search that peeks is behaviourally indistinguishable from a search that is
# good: it wins more, and every test of its moves passes. So this is a grep
# over the source, and the count of lines it read is asserted, because a sweep
# that opens the wrong file passes by comparing nothing.

my @FILES = ('lib/Game/Durak/Search.pm', 'lib/Game/Durak/Bot.pm');

my @FORBIDDEN = (
    [ qr/Game::Durak::Deck/    => 'the deck, which is the whole deal in order' ],
    [ qr/\border_for\b/        => 'the shuffle' ],
    [ qr/\bdeal_for\b/         => 'the deal' ],
    [ qr/\bhand_of\b/          => 'a hand by seat' ],
    [ qr/->hands\b/            => 'both hands' ],
    [ qr/->talon\b/            => 'the talon in order' ],
    [ qr/->history\b/          => 'the history' ],
    [ qr/->bout\b/             => 'the live bout object' ],
    [ qr/\$game\b/             => 'a game object' ],
);

my ($lines, $code) = (0, 0);
my @caught;

for my $file (@FILES) {
    ok(-r $file, "$file is there to be read");
    open my $fh, '<', $file or die "$file: $!";
    my $in_pod = 0;
    while (my $line = <$fh>) {
        $lines++;
        $in_pod = 1 if $line =~ /\A=\w/;
        $in_pod = 0 if $line =~ /\A=cut/;
        last if $line =~ /\A__END__/;
        next if $in_pod;
        next if $line =~ /\A\s*\z/;
        $code++;
        for my $rule (@FORBIDDEN) {
            my ($pattern, $what) = @$rule;
            push @caught, "$file:$.: $what" if $line =~ $pattern;
        }
    }
    close $fh;
}

is_deeply(\@caught, [], 'neither file can see anything a seat cannot');
cmp_ok($lines, '>=', 100, "$lines lines were read");
cmp_ok($code, '>=', 60, "$code of them were code, so the sweep had something to look at");

# The grep has to be able to fail, or it is decoration.
my $bad = "    my \$hand = \$game->hand_of(2);\n";
my @would = grep { $bad =~ $_->[0] } @FORBIDDEN;
cmp_ok(scalar @would, '>=', 2, 'a line that peeks is caught by more than one rule');

# The bot holds the game's seed, and that is only safe because of the rules
# above: the seed plus the deck is the whole deal.
ok(!grep({ $_ =~ /Deck/ } do {
    open my $fh, '<', 'lib/Game/Durak/Bot.pm' or die $!;
    <$fh>;
}), 'the bot never reaches for the deck it could rebuild the deal from');

done_testing();
