use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona;
use Game::Fanorona::Bot;
my $G = 'Game::Fanorona';
my $B = 'Game::Fanorona::Bot';

subtest 'levels' => sub {
    my @levels = $B->levels;
    cmp_ok(scalar(@levels), '>=', 2, scalar(@levels) . ' levels: ' . join(', ', @levels));
    is_deeply(\@levels, [ sort { $a <=> $b } @levels ], 'weakest first');
    is($levels[0], 0, 'the weakest is level 0, which does not look ahead');
    my %seen;
    is(scalar(grep { $seen{$_}++ } @levels), 0, 'no level twice');
};

subtest 'thinking' => sub {
    my $g = $G->new;
    my $before = $g->position;
    my $thought = $B->think($g, level => 2000, seed => 'a seed');
    is($thought->{level}, 2000, 'the level asked for');
    ok((grep { $_ eq $thought->{move} } $g->legal_strings), "the move, $thought->{move}, is a legal one");
    like($thought->{nodes}, qr/\A[0-9]+\z/, 'the positions looked at, as a string of digits');
    cmp_ok($thought->{depth}, '>=', 1, "to a depth of $thought->{depth}");
    like($thought->{score}, qr/\A-?[0-9]+\z/, 'and a score');
    is($g->position, $before, 'thinking does not move');
    is($B->choose($g, level => 2000, seed => 'a seed'), $thought->{move}, 'choose is the move and nothing else');
    is($B->think($g, level => 2000, seed => 'a seed')->{move}, $thought->{move}, 'the same seed, the same move');
    is($B->think($g, seed => 's', depth => 1)->{level}, ($B->levels)[-1], 'with no level given, the strongest');
    is($B->hint($g, level => 0, depth => 1)->{level}, ($B->levels)[-1], 'and a hint is the strongest whatever is asked');
};

subtest 'level 0 takes the most it can' => sub {
    #   w . b . w . b b b      one stone to take on the left, three on the right
    my $g = $G->new(position => '9/9/w1b1w1bbb/9/9 w');
    my $thought = $B->think($g, level => 0, seed => 1);
    is($thought->{move}, 'e3-f3A', 'it takes the three');
    is($thought->{level}, 0, 'at level 0');
    is($thought->{score}, undef, 'with no score: it did not look ahead');
    is($thought->{nodes}, '0', 'and looked at nothing');

    # and goes on taking
    my $chain = $G->new(position => '9/2b6/9/1w1b5/8b w');
    is($B->choose($chain, level => 0, seed => 1), 'b2-c2A-c3A', 'it goes on while there is something to take');

    # with nothing to take it moves a stone, and which one depends on the seed
    my $quiet = $G->new(position => '8b/9/9/9/w8 w');
    my %moves = map { $B->choose($quiet, level => 0, seed => $_) => 1 } 1 .. 30;
    is_deeply([ sort keys %moves ], [ qw(a1-a2 a1-b1 a1-b2) ], 'over thirty seeds it makes each of the three quiet moves there are');
    ok((grep { $_ eq $B->choose($g, level => 0, seed => 'x') } $g->legal_strings), 'and whatever it chooses is legal');
};

subtest 'playing' => sub {
    my $g = $G->new;
    my $thought = $B->play($g, level => 1000, seed => 'play');
    is_deeply([ $g->moves ], [ $thought->{move} ], 'play makes the move it thought of');
    is($g->turn, 'black', 'and the turn passes');
    ok(!$g->in_chain, 'with no move left in progress');

    # A MOVE THAT ENDS WHERE IT COULD GO ON is played with its stop
    my $s = $G->new(position => '9/9/2wb5/9/bb7 w', variant => { board => 'sivy', quiet_limit => 0, repeat => 0 });
    $s->step('c3-b2A');
    my $rest = $B->play($s, level => 3000, seed => 1);
    is($rest->{move}, '', 'from the middle of a move, the player may answer that the thing to do is stop');
    ok(!$s->in_chain, 'and play stops');
    is($s->turn, 'black', 'so that it is Black to move');
    is_deeply([ $s->moves ], [ 'c3-b2A' ], 'and the move in the log is the one step');

    my $over = $G->new(position => '9/9/w1b6/9/9 w', script => [ 'a3-b3A' ]);
    is($B->play($over, level => 1000), undef, 'play on a finished game does nothing');
    is($B->think($over), undef, 'nor is there anything to think about');
    is($B->choose($over), undef, 'or to choose');
};

# WHOLE GAMES, every level against every other, and each must be a game: every
# move legal (the game would croak), an ending reached, and the log playable.
subtest 'games between the levels' => sub {
    my @levels = (0, 300, 1500);
    my ($games, $moves, %how, @bad) = (0, 0);
    for my $white (@levels) {
        for my $black (@levels) {
            my $g = $G->new;
            my $guard = 0;
            until ($g->over) {
                $B->play($g, level => ($g->turn eq 'white' ? $white : $black), seed => "$white v $black");
                last if ++$guard > 4000;
            }
            $games++;
            $moves += $g->ply;
            push @bad, "$white v $black: did not end" unless $g->over;
            $how{ $g->result->how }++ if $g->over;
            my ($again, $error) = $G->replay([ $g->moves ]);
            push @bad, "$white v $black: its log does not replay" if $error || $again->position ne $g->position;
        }
    }
    is($games, 9, 'nine games');
    cmp_ok($moves, '>', 100, "$moves moves made by the player");
    is(scalar(@bad), 0, 'each ended, and replays from its log: ' . join(', ', map { "$_ $how{$_}" } sort keys %how))
        or diag join "\n", @bad;
};

subtest 'a draw offered to the player' => sub {
    my $level = $G->new(position => '8b/9/9/9/w8 w');
    is($B->answer_draw($level), undef, 'with no offer there is nothing to answer');
    $level->offer_draw('white');
    is($B->answer_draw($level), 'decline', 'level on stones with the game young: declined');

    my $behind = $G->new(position => '8b/9/9/9/ww7 w');
    $behind->offer_draw('white');
    is($B->answer_draw($behind), 'accept', 'a stone down, the side asked accepts');
    my $ahead = $G->new(position => '7bb/9/9/9/w8 w');
    $ahead->offer_draw('white');
    is($B->answer_draw($ahead), 'decline', 'a stone up, it declines');
    my $white_asked = $G->new(position => '7bb/9/9/9/w8 w');
    $white_asked->offer_draw('black');
    is($B->answer_draw($white_asked), 'accept', 'and it is the side the offer was made TO whose stones are counted');

    # level, and half the quiet limit gone
    my $stale = $G->new(variant => { board => 'sivy', quiet_limit => 4, repeat => 0 }, position => '8b/9/9/9/w8 w',
        script => [ 'a1-a2', 'i5-i4' ]);
    $stale->offer_draw('black');
    is($B->answer_draw($stale), 'accept', 'level on stones with half the quiet limit gone: accepted');

    my $over = $G->new;
    $over->resign('white');
    is($B->answer_draw($over), undef, 'and nothing is answered once the game is over');
};

subtest 'what is refused' => sub {
    ok(!eval { $B->think('a game'); 1 }, 'think croaks on something that is not a game');
    like($@, qr/takes a Game::Fanorona/, 'saying what it takes');
    ok(!eval { $B->think($G->new, level => 'strong'); 1 }, 'and on a level that is not a number');
    like($@, qr/a level is a whole number/, 'saying what a level is');
    ok(!eval { $B->think($G->new, level => -1); 1 }, 'or is below nothing');

    # A SEED IS BYTES, AND THE SAME BYTES HOWEVER PERL IS HOLDING THEM. On perl
    # 5.14 the hash underneath read a string's internal buffer, so a seed that
    # had ever been stored wide chose differently from the same seed stored
    # narrow; a sibling's matrix found that. And a character above 255 is not
    # a byte at all: it is refused in this module's words, not the hash's.
    my $quiet = $G->new(position => '9/9/9/8b/w8 w');
    my $narrow = "caf\xe9";
    my $wide = $narrow;
    utf8::upgrade($wide);
    ok(utf8::is_utf8($wide) && !utf8::is_utf8($narrow), 'one seed, held two ways');
    my @narrow = map { $B->choose($quiet, level => 0, seed => "$narrow$_") } 1 .. 30;
    my @wide = map { $B->choose($quiet, level => 0, seed => "$wide$_") } 1 .. 30;
    is("@wide", "@narrow", 'chooses the same thirty moves');
    my %chosen = map { $_ => 1 } @narrow;
    cmp_ok(scalar(keys %chosen), '>=', 2, 'which are not all one move, so the seed is being read');
    ok(!eval { $B->choose($quiet, level => 0, seed => "a seed with \x{263a} in it"); 1 }, 'a seed with a character above 255 is refused');
    like($@, qr/a seed is bytes, and that one holds a character above 255/, 'saying why');
    ok(!eval { $B->choose($G->new, level => 100, seed => "\x{263a}"); 1 }, 'and by a level that searches too');
    like($@, qr/a seed is bytes/, 'in the same words');
};

done_testing();
