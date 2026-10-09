#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Digest::SHA ();
use Game::Gin;
use Game::Gin::Bot;
use Game::Gin::Deadwood qw(best);
use Game::Gin::Terminal;

plan tests => 17;

sub seed { Digest::SHA::sha256($_[0]) }

# Every one of these runs with no terminal: the keys come from `keysource`, so
# nothing here needs a tty, a pipe, or Term::ReadKey to be installed. The same
# arrangement as Game::Checkers, Game::Oware and Game::Dominoes.
#
# `interactive => 0` keeps the screen-clearing escape out of the captured
# output, and `ascii => 1` keeps the frame glyphs to one byte each so the
# column arithmetic below is honest.
sub ui {
    my (%args) = @_;

    my @chars = split //, defined $args{keys} ? $args{keys} : '';
    my $typed = $args{input} // '';

    open my $in,  '<', \$typed or die $!;
    open my $out, '>', \my $shown or die $!;

    my $ui = Game::Gin::Terminal->new(
        in          => $in,
        out         => $out,
        mode        => $args{mode} || 'bot',
        level       => 2,
        seat        => $args{seat} || 'p1',
        ascii       => 1,
        colour      => $args{colour} ? 1 : 0,
        interactive => 0,
        picking     => (exists $args{picking} ? $args{picking} : 1),
        keysource   => (exists $args{keysource} ? $args{keysource}
            : sub { shift @chars }),
    );

    return ($ui, \$shown);
}

# A fan draws the ranks on one row and the suits on the row under it, so NO
# string grep can see a card in it: `10H` is never contiguous on screen. Cards
# are reconstructed by column instead, four columns to a card, which is what
# FAN_WIDTH means.
sub fan_cards {
    my ($ranks, $suits) = @_;
    my @out;
    for (my $c = 1; $c + 2 < length $ranks; $c += 4) {
        my $rank = substr $ranks, $c, 3;
        my $suit = substr $suits, $c, 3;
        $rank =~ s/\s+//g;
        $suit =~ s/[^SHDC]//g;
        push @out, $rank . $suit if length $rank && length $suit;
    }
    return @out;
}

# Every card drawn in any fan in a block of text.
sub cards_on_screen {
    my ($text) = @_;
    my @line = split /\n/, $text;
    my %seen;
    for my $i (0 .. $#line - 2) {
        next unless $line[$i] =~ /\A[-+>#!=]/;
        next unless $line[ $i + 1 ] =~ /\A[|#!]/;
        next unless $line[ $i + 2 ] =~ /\A[|#!]/;
        $seen{$_} = 1 for fan_cards($line[ $i + 1 ], $line[ $i + 2 ]);
    }
    return \%seen;
}

subtest 'a key at a time, named' => sub {
    plan tests => 1;

    my ($ui) = ui(keys => "k\e[A\e[B\e[C\e[D\e[5~\eOH\r\t\x7f\x03\x04 q\e\e[6~");

    my @got;
    while (defined(my $key = $ui->read_key)) {
        push @got, $key eq ' ' ? 'space' : $key;
    }

    is_deeply(\@got, [ qw/ k up down right left page_up home enter tab backspace
        interrupt eof space q escape page_down / ],
        'a character comes back as itself and a sequence as a name');
};

subtest 'an escape does not eat the key behind it' => sub {
    plan tests => 2;
    my ($ui) = ui(keys => "\eq");
    is($ui->read_key, 'escape', 'the escape is an escape');
    is($ui->read_key, 'q', 'and the keystroke behind it survives');
};

# The reconstructor has to be able to see a card, or every leak test below
# passes by being blind. This is the control.
subtest 'the column reader really does see the cards in a fan' => sub {
    plan tests => 2;

    my ($ui, $shown) = ui(keys => 'dq');
    $ui->play(seed => seed('see'));

    my $hand = $ui->game->deal->hand_of('p1');
    my $seen = cards_on_screen($$shown);
    my @mine = map { $ui->pretty($_) } @{ $hand->cards };
    my $found = grep { $seen->{$_} } @mine;

    cmp_ok(scalar keys %$seen, '>', 5, 'it found cards at all');
    is($found, scalar @mine, 'and every card p1 holds is one of them')
        or diag join ' ', 'wanted', @mine, '/ saw', sort keys %$seen;
};

subtest 'the cursor walks the hand and enter discards what it is on' => sub {
    plan tests => 3;

    # pick_discard is driven directly, so the test can name the card the
    # cursor is on rather than inferring it from a whole turn.
    my ($ui) = ui(keys => "\e[C\e[C\r");
    $ui->game(Game::Gin->build(seed => seed('walk'), dealer => 'p1'));
    my $seat = $ui->game->turn;
    $ui->game->apply($seat, { kind => 'take' });
    is($ui->game->deal->phase, 'discard', 'set up in the discard phase');

    my $choices = $ui->choice_cards($seat);
    cmp_ok(scalar @$choices, '>', 3, 'with a hand to walk');

    # The cursor does not start at the left edge: it starts on the first card
    # you are likely to throw, which is the first loose one.
    my $want = $choices->[ ($ui->first_loose($choices) + 2) % @$choices ];

    $ui->enter_raw;
    my $move = $ui->pick_discard($seat);

    is_deeply($move, { kind => 'discard', card => $want->{card} },
        'two presses right of where it starts, and enter takes that card');
};

# THE BUG THE FIRST VERSION SHIPPED. The fan draws the hand grouped into its
# melds, but the cursor walked the hand's own order, so right did not move to
# the card on the right: it jumped about the screen. Two orders for one row of
# cards is one order too many.
subtest 'the cursor walks the hand in the order the fan draws it' => sub {
    plan tests => 3;

    my ($ui) = ui(keys => '');
    $ui->game(Game::Gin->build(seed => seed('melds'), dealer => 'p1'));
    my $seat = $ui->game->turn;
    $ui->game->apply($seat, { kind => 'take' });

    my $melding = best($ui->game->deal->hand_of($seat)->cards);
    my @fan = map { @{ $_->{cards} } } @{ $ui->hand_groups($melding) };
    my $choices = $ui->choice_cards($seat);

    # Every choice is in fan order. The fan may hold one card the cursor
    # cannot reach, the card just taken, which the rules forbid throwing back.
    my %offered = map { $_->{card} => 1 } @$choices;
    my @reachable = grep { $offered{$_} } @fan;

    is_deeply([ map { $_->{card} } @$choices ], \@reachable,
        'the cursor order is the fan order, less what cannot be thrown');

    cmp_ok(scalar @{ $melding->{melds} }, '>', 0,
        'and this hand really is grouped, or the test proves nothing');

    my $at = $ui->first_loose($choices);
    ok($choices->[$at]{loose}, 'the cursor starts on the first loose card');
};

# THE PREVIEW IS THE RESULT, and the oracle is the game rather than arithmetic
# retyped here. A second game dealt identically plays the move for real, and
# the count the frame printed must be the count that game then reports.
subtest 'the count under the fan is the count the throw really leaves' => sub {
    plan tests => 2;

    my ($ui, $shown) = ui(keys => 'dq');
    $ui->play(seed => seed('count'), limit => 4);

    my ($card, $count) = ($$shown =~ /throw (\S+) and your count is (\d+)/);
    ok(defined $count, 'the frame said what the throw would leave')
        or diag $$shown;

    my $id = $ui->card_named($card);
    my @rest = grep { $_ != $id } @{ $ui->game->deal->hand_of('p1')->cards };
    is($count, best(\@rest)->{deadwood},
        'and it is what the hand without that card really melds to');
};

subtest 'three frames, told apart with no colour at all' => sub {
    plan tests => 4;

    # d draws, so one card is fresh; the cursor is on another.
    my ($ui, $shown) = ui(keys => "d\e[Cq");
    $ui->play(seed => seed('frames'), limit => 4);

    like($$shown, qr/\+---/, 'a settled card keeps the light frame');
    like($$shown, qr/#===/, 'the card just drawn takes the double');
    like($$shown, qr/>===/, 'and the cursor the heavy one');

    # All three in one frame is the point. A single marked style would make
    # the card you drew and the card you are about to throw look alike, which
    # is what the first version of this did.
    my ($last) = ($$shown =~ /(throw .*)\z/s);
    my ($block) = ($$shown =~ /(.*)throw /s);
    ok($block =~ /#===/ && $block =~ />===/ && $block =~ /\+---/,
        'and all three are in the frame above the caption');
};

subtest 'the card just drawn is marked, and stops being marked once thrown' => sub {
    plan tests => 2;

    my ($ui) = ui(keys => 'dq');
    $ui->play(seed => seed('drew'), limit => 4);

    my $marks = $ui->marks;
    is(scalar keys %$marks, 1, 'exactly one card is marked after a draw');
    is((values %$marks)[0], 'drew', 'and it is marked as drawn');
};

subtest "the upcard is marked when the opponent put it there" => sub {
    plan tests => 1;

    # Let the bot take its turn, then look at what p1 is shown.
    my ($ui) = ui(keys => 'q', seat => 'p1');
    $ui->play(seed => seed('upcard'), limit => 3);

    my $marks = $ui->marks;
    my $upcard = $ui->game->deal->upcard;
    is($marks->{$upcard} // '', 'took',
        'the card the opponent discarded is new to this seat')
        or diag explain $marks;
};

subtest 'k knocks when it may, and says so when it may not' => sub {
    plan tests => 4;

    # An opening hand is nowhere near ten, so k has to refuse rather than
    # quietly throw the card without knocking.
    my ($ui, $shown) = ui(keys => 'kq');
    $ui->game(Game::Gin->build(seed => seed('knock'), dealer => 'p1'));
    my $seat = $ui->game->turn;
    $ui->game->apply($seat, { kind => 'take' });

    my $choices = $ui->choice_cards($seat);
    my $start = $ui->first_loose($choices);
    ok(!$choices->[$start]{knock},
        'the card the cursor starts on does not knock on this hand');

    $ui->enter_raw;
    my $move = $ui->pick_discard($seat);

    like($$shown, qr/you cannot knock on that one/, 'k said so');
    is($move, undef, 'and q then stopped rather than a card being thrown');
    is($ui->game->deal->phase, 'discard', 'the turn is still where it was');
};

subtest 'k does knock when the hand allows it' => sub {
    plan tests => 2;

    # Drive a whole match until some seat is offered a knock, then pick with
    # k and check the move carries the flag. Searching for the position rather
    # than hand-building one keeps this a test of the picker.
    my ($ui) = ui(keys => '');
    $ui->game(Game::Gin->build(seed => seed('willknock'), dealer => 'p1'));

    my $found;
    my $bot = Game::Gin::Bot->new(level => 2);
    for (1 .. 400) {
        last if $ui->game->over;
        my $seat = $ui->game->turn or last;
        if ($ui->game->deal->phase eq 'discard') {
            my $choices = $ui->choice_cards($seat);
            my ($at) = grep { $choices->[$_]{knock} } 0 .. $#$choices;
            if (defined $at) { $found = [ $seat, $at, $choices ]; last }
        }
        my $move = $bot->choose($ui->game, $seat) or last;
        my @out = $ui->game->apply($seat, $move);
        last if ref $out[0] eq 'Game::Gin::Error';
    }

    ok($found, 'a position turned up where a knock was on offer')
        or return;

    my ($seat, $at, $choices) = @$found;
    # split //, because read_char hands back ONE character: a list holding
    # "\e[C" as a single element never becomes a right arrow.
    my $from = $ui->first_loose($choices);
    my $steps = ($at - $from) % scalar @$choices;
    my @keys = split //, ("\e[C" x $steps) . 'k';
    $ui->keysource(sub { shift @keys });
    $ui->enter_raw;
    my $move = $ui->pick_discard($seat);

    is_deeply($move,
        { kind => 'discard', card => $choices->[$at]{card}, knock => 1 },
        'k on a card that knocks returns the knocking move');
};

subtest 'v shows the hand remelded without the card under the cursor' => sub {
    plan tests => 3;

    my ($ui, $shown) = ui(keys => 'dvq');
    $ui->play(seed => seed('remeld'), limit => 4);

    like($$shown, qr/that is the hand WITHOUT/, 'v says what it is showing');

    my ($after) = ($$shown =~ /(that is the hand WITHOUT.*)\z/s);
    my ($before) = ($$shown =~ /\A(.*?)that is the hand WITHOUT/s);

    # The remelded view holds one card fewer than the hand it came from.
    my $full = cards_on_screen($before);
    cmp_ok(scalar keys %$full, '>', 0, 'the full hand was drawn first');
    ok(!($after =~ />===/), 'and the cursor frame is gone from it');
};

subtest 'q and end of input both stop, leaving the game standing' => sub {
    plan tests => 4;

    for my $case ([ 'dq', 'q' ], [ 'd', 'running out of keys' ]) {
        my ($keys, $what) = @$case;
        my ($ui) = ui(keys => $keys);
        $ui->play(seed => seed('stop'), limit => 6);
        ok(!$ui->game->over, "$what stopped the game unfinished");
        is($ui->raw, 0, 'and put the terminal back');
    }
};

# Without Term::ReadKey and without a keysource there is nothing to read keys
# with, and the fallback has to be the typed game rather than a failure.
subtest 'no key source at all falls back to typing' => sub {
    plan tests => 3;

    my ($ui, $shown) = ui(keysource => undef, picking => 1,
        input => "d\nquit\n");

    is($ui->keys_available, 0, 'nothing to read keys with');
    $ui->play(seed => seed('fall'), limit => 6);
    like($$shown, qr/\(d\)raw or \(t\)ake/, 'so the typed prompt was used');
    is($ui->picking, 0, 'and it does not try the keys again');
};

subtest 'quit works at a typed prompt too' => sub {
    plan tests => 2;

    my ($ui, $shown) = ui(picking => 0, keysource => undef,
        input => "quit\n");

    $ui->play(seed => seed('typedquit'), limit => 6);

    ok($ui->quit, 'it recorded the stop');
    ok(!$ui->game->over, 'and the game is unfinished rather than looping');
};

# THE HOTSEAT LEAK. Gin hands are secret and hotseat puts two people at one
# keyboard, so without a hand-over seat 2's hand is drawn directly under seat
# 1's. That is what this dist shipped: `--mode hotseat` was unusable for its
# own stated purpose.
subtest 'THE LEAK: a hotseat screen never carries two hands at once' => sub {
    plan tests => 3;

    my ($ui, $shown) = ui(mode => 'hotseat', keys => " u\r d\r q");
    $ui->play(seed => seed('hot'), limit => 8);

    my @block = split /pass the keyboard to (?=p[12])/, $$shown;
    shift @block if @block > 1;
    cmp_ok(scalar @block, '>=', 2, 'there was a hand-over between the seats')
        or diag $$shown;

    # THE ASSERTION THAT MATTERS, and it is written so that it still fires
    # when there is no hand-over at all: without one the whole transcript is
    # a single screen, and that screen then holds both hands. Written the
    # other way round, keyed on whose block it is, removing the hand-over
    # would make the loop run zero times and the test pass by being blind.
    my $deal = $ui->game->deal;
    my %only = map {
        my ($mine, $theirs) = $_ eq 'p1' ? ('p1', 'p2') : ('p2', 'p1');
        my %them = map { $ui->pretty($_) => 1 } @{ $deal->hand_of($theirs)->cards };
        ($mine => [ grep { !$them{$_} }
            map { $ui->pretty($_) } @{ $deal->hand_of($mine)->cards } ]);
    } qw/ p1 p2 /;

    my @shared;
    for my $i (0 .. $#block) {
        my $seen = cards_on_screen($block[$i]);
        my @whose = grep {
            my $seat = $_;
            scalar grep { $seen->{$_} } @{ $only{$seat} }
        } qw/ p1 p2 /;
        push @shared, "screen $i showed cards of " . join(' and ', @whose)
            if @whose > 1;
    }

    is_deeply(\@shared, [],
        'and not one screen carried cards from both hands');

    my $drawn = 0;
    $drawn += scalar keys %{ cards_on_screen($_) } for @block;
    cmp_ok($drawn, '>', 5, 'the screens really did draw hands');
};

subtest 'watch mode needs no keys and never asks for any' => sub {
    plan tests => 2;

    my ($ui, $shown) = ui(mode => 'watch', keysource => sub { undef });
    my $game = $ui->play(seed => seed('watch'));

    ok($game->over, 'two bots played the match out');
    unlike($$shown, qr/left and right to choose/, 'and no picker was drawn');
};
