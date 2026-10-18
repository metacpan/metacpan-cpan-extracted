use strict;
use warnings;
use Test::More;

use Game::Senet;
use Game::Senet::Notation qw(parse_record format_record);

# REPLAY, plan_game_senet/06: a record played again through `play`, throw by
# throw, arrives at the same game; a record that disagrees with the rules is
# refused at the ply where it does.

sub played {
    my ($set, $seed) = @_;
    my $g = Game::Senet->new(seed => $seed, rules => $set);
    while (!$g->is_over) {
        my @m = $g->legal;
        $g->play($m[ int(rand(@m)) ]) or die $g->error->code;
    }
    return $g;
}

for my $set (qw(kendall skyruk)) {
    subtest "200 games, $set, recorded and replayed" => sub {
        srand($set eq 'kendall' ? 21 : 12);
        my @bad;
        for my $n (1 .. 200) {
            my $g = played($set, "replay $set $n");
            my $text = $g->to_record;
            my ($back, $error) = Game::Senet->replay($text);
            push @bad, "#$n " . $error->code . ' ' . join(',', %{ $error->detail }) and next unless $back;
            push @bad, "#$n key"    unless $back->key eq $g->key;
            push @bad, "#$n ply"    unless $back->ply == $g->ply;
            push @bad, "#$n throws" unless $back->throws == $g->throws;
            push @bad, "#$n log"    unless Test::More::eq_array($back->log, $g->log);
            push @bad, "#$n text"   unless $back->to_record eq $text;
        }
        is("@bad", '', 'the same final key, ply, count of throws and log, entry by entry, and the same text');
    };
}

my $GAME = played('kendall', 'replay edits');
my $TEXT = $GAME->to_record;
my ($RECORD) = parse_record($TEXT);

subtest 'a record with one throw edited is refused at that ply' => sub {
    my @lines = split /\n/, $TEXT;
    my ($index) = grep { $lines[$_] =~ /\A10\. / } 0 .. $#lines;
    my ($roll) = $lines[$index] =~ /\A10\. [ld] (\d)/;
    my $other = { 1 => 4, 4 => 1, 5 => 1, 2 => 3, 3 => 2 }->{$roll};
    (my $edited = $TEXT) =~ s/^10\. ([ld]) $roll \d{4}: /10. $1 $other: /m;
    my ($game, $error) = Game::Senet->replay($edited);
    ok(!$game, 'refused');
    is($error->detail->{line}, $index + 1, 'at the line of the tenth ply, by the seed');
};

subtest 'a seeded record as a hash, one roll edited, is refused by the facade itself' => sub {
    my %record = %$RECORD;
    my @plies = map { { %$_ } } @{ $record{plies} };
    my ($i) = grep { defined $plies[$_]{move} } 10 .. $#plies;
    $plies[$i]{roll} = { 1 => 4, 4 => 1, 5 => 1, 2 => 3, 3 => 2 }->{ $plies[$i]{roll} };
    delete $plies[$i]{sticks};
    $record{plies} = \@plies;
    my ($game, $error) = Game::Senet->replay(\%record);
    ok(!$game, 'refused');
    is($error->detail->{ply}, $i, "at ply $i");
    is($error->detail->{why}, 'roll', '  because the seed throws another roll');
};

subtest 'a record with one move\'s to edited is refused at that ply' => sub {
    my %record = %$RECORD;
    my @plies = map { { %$_ } } @{ $record{plies} };
    my ($i) = grep { defined $plies[$_]{move} && $plies[$_]{move} =~ /\A(\d+)-(\d+)\z/ && $2 < 26 } 5 .. $#plies;
    my ($from, $to) = $plies[$i]{move} =~ /\A(\d+)-(\d+)\z/;
    $plies[$i]{move} = $from . '-' . ($to + 1);
    $record{plies} = \@plies;
    my ($game, $error) = Game::Senet->replay(\%record);
    ok(!$game, 'refused');
    is($error->detail->{ply}, $i, "at ply $i");
};

subtest 'a record with a forfeit deleted is refused at that ply' => sub {
    my %record = %$RECORD;
    my @plies = map { { %$_ } } @{ $record{plies} };
    my ($i) = grep { !defined $plies[$_]{move} } 0 .. $#plies;
    ok(defined $i, "the game has a forfeit, at ply $i");
    splice @plies, $i, 1;
    $record{plies} = \@plies;
    my ($game, $error) = Game::Senet->replay(\%record);
    ok(!$game, 'refused: the seed throws the deleted forfeit\'s roll again') or return;
    is($error->detail->{ply}, $i, "at ply $i, where the game forfeits and the record moves");
    is($error->detail->{why}, 'forfeit', '  as a forfeit');
};

subtest 'a bound segment moved to another piece is refused' => sub {
    my ($record, $at, $other);
    for my $n (1 .. 50) {
        my $g = Game::Senet->new(seed => "bound $n", rules => 'skyruk');
        while (!$g->is_over) {
            my $bound = $g->turn->{bound};
            if ($bound) {
                my $board = Game::Senet::Engine->new(position => $g->position);
                my ($free) = grep { $_->from != $bound }
                    $board->moves($g->roll, $g->variant->as_hash);
                if ($free) {
                    $at = scalar @{ $g->log };
                    $other = $free->from . '-' . ($free->off ? 'off' : $free->to);
                }
            }
            my @m = $g->legal;
            $g->play($m[0]) or die $g->error->code;
            last if defined $at;
        }
        next unless defined $at;
        ($record) = parse_record($g->to_record);
        last;
    }
    ok($record, "a skyruk game with a bound throw another piece could have used, at ply $at");
    $record->{plies}[$at]{move} = $other;
    my ($game, $error) = Game::Senet->replay($record);
    ok(!$game, "the bound throw given to $other instead is refused");
    is($error->code, 'bound_piece', '  as bound_piece');
    is($error->detail->{ply}, $at, "  at ply $at");
};

subtest 'a kendall record replayed as skyruk is refused where they part, not at the end' => sub {
    my ($game, $error) = Game::Senet->replay($TEXT, rules => 'skyruk');
    ok(!$game, 'refused');
    my $n = scalar @{ $RECORD->{plies} };
    cmp_ok($error->detail->{ply}, '<', $n, "at ply " . $error->detail->{ply} . " of $n");
    my ($same) = Game::Senet->replay($TEXT);
    ok($same, 'and the record replays as the kendall it is');
};

done_testing();
