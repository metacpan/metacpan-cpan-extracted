#!perl
use strict;
use warnings;
use Test::More;

use Game::Durak ();
use Game::Durak::Table ();
use Game::Durak::Card qw(id_of);

# The painted table, read as plain characters. Every assertion here is about
# what a person would SEE, and none of them needs a terminal: Table builds a
# grid of characters and a parallel grid of paint names, and `lines` throws
# the paint away. A screen composed out of coloured strings instead would have
# a length that is not its width and could only be tested by eye.

my $view = {
    seat       => 1,
    trump      => 'H',
    trump_card => id_of('7H'),
    talon      => 12,
    discard    => 4,
    counts     => { 1 => 3, 2 => 5 },
    hand       => [ id_of('TS'), id_of('8S'), id_of('KH') ],
    legal      => [ { kind => 'attack', card => id_of('TS') },
                    { kind => 'attack', card => id_of('KH') } ],
    bout       => { pairs => [
        { attack => id_of('6C'), beat => id_of('9C') },
        { attack => id_of('AD'), beat => undef },
    ] },
};

my $table = Game::Durak::Table->new;
my $grid  = $table->screen($view, header => 'they throw in the ace of diamonds',
                                  footer => '[1 3] a card  t take');
my $lines = $table->lines($grid);

is(scalar @$lines, 24, 'the screen is twenty-four rows');
is_deeply([ map { length } @$lines ], [ (80) x 24 ],
          'and every one of them is exactly eighty columns');

my $screen = join "\n", @$lines;

subtest 'everything a seat has to be able to read is on it' => sub {
    is($lines->[0], sprintf('%-80s', ' they throw in the ace of diamonds'),
       'the header says what just happened, and fills its row');
    like($screen, qr/they hold 5/, 'their hand is counted');
    like($screen, qr/trump \x{2665}\s+talon 12\s+heap 4/,
         'and the trump, the talon and the heap are one line');
    like($lines->[-1], qr/\[1 3\] a card  t take/, 'the footer is the prompt');
};

subtest 'the ten is a ten, in the fan and in the whole card' => sub {
    # The engine spells it T because a card id there is two characters. A
    # person reading a table has never heard of that, and the site shipped
    # this bug to a live page once already.
    unlike($screen, qr/\|T/, 'no card index reads as T');
    like($screen, qr/\x{2502}10/, 'the ten of spades is drawn as 10');
};

subtest 'a fanned card shows its rank over its suit, at any pitch' => sub {
    # THE REASON THIS IS DOWN THE ROWS AND NOT ALONG ONE. A twenty card hand
    # closes the pitch to three columns, so an index written along the row
    # would show a ten as `10` with its suit covered by the next card, and a
    # hand holding two tens would be unreadable.
    my $wide = Game::Durak::Table->new;
    my @hand = map { id_of($_) } qw(TS TH TD TC AS KS QS JS 9S 8S
                                    7S 6S AH KH QH JH 9H 8H 7H 6H);
    my $many = $wide->lines($wide->screen({
        %$view, hand => \@hand, legal => [], counts => { 1 => 20, 2 => 5 },
    }));

    my $pitch = $wide->pitch_for(2, scalar @hand);
    is($pitch, 3, "twenty cards close the pitch to $pitch columns");

    # ANCHORED ON THE BORDER. A first version grepped for `10` and found the
    # row of hand NUMBERS, which reaches 10 in a twenty card hand, so it read
    # the wrong two rows and failed about the right thing for the wrong
    # reason.
    my $row = 0;
    $row++ until $row > $#$many || $many->[$row] =~ /\x{2502}10/;
    cmp_ok($row, '<', scalar @$many, "the rank row is row $row");
    my $ranks = $many->[$row];
    my $suits = $many->[ $row + 1 ];

    like($ranks, qr/10.10.10.10/, 'the four tens are all on the rank row');
    my $spades = () = $suits =~ /\x{2660}/g;
    cmp_ok($spades, '>', 1, "$spades spades are readable on the suit row");
};

subtest 'an unanswered attack is ringed and nothing is written on it' => sub {
    # The rule the template and the client already follow: an attack with no
    # answer is marked by how it is drawn, so there is nothing to translate
    # and nothing to read twice.
    like($screen, qr/\x{2554}\x{2550}+\x{2557}/, 'the ace of diamonds is ringed');
    my $rings = () = $screen =~ /\x{2554}/g;
    is($rings, 1, 'and it is the only one, because the six of clubs was beaten');

    my $beaten = Game::Durak::Table->new->lines(Game::Durak::Table->new->screen({
        %$view,
        bout => { pairs => [ { attack => id_of('6C'), beat => id_of('9C') } ] },
    }));
    my $none = () = join('', @$beaten) =~ /\x{2554}/g;
    is($none, 0, 'a bout with every attack answered has no ring at all');
};

subtest 'the paint is a name in a parallel grid, never a byte in the line' => sub {
    my $plain = join '', @$lines;
    unlike($plain, qr/\e/, 'no escape reached the plain screen');

    my $painted = $table->paint($grid);
    is(scalar @$painted, 24, 'the painted screen is the same twenty-four rows');
    like($painted->[0], qr/\e\[/, 'and it does carry escapes');

    (my $stripped = join "\n", @$painted) =~ s/\e\[[0-9;]*m//g;
    is($stripped, join("\n", map { $_ } @$lines),
       'which strip back to exactly the plain screen, so the paint moves nothing');
};

subtest 'a card that cannot be played is drawn grey, and the numbers agree' => sub {
    my $paint = $grid->{paint};
    my %ink;
    for my $row (@$paint) { $ink{$_}++ for @$row }

    ok($ink{grey}, 'something is grey');
    ok($ink{pick}, 'and something is lit');

    # The 8 of spades is the one the legal list does not carry, and it is the
    # second card in the hand, so its number is quiet and the other two are
    # lit. A screen that disagreed with `legal` would be a screen that offers
    # a move the engine refuses.
    my $numbers = 24 - 7;
    my $pitch = $table->pitch_for(2, 3);
    is($paint->[$numbers][2], 'pick', 'the first card is offered');
    is($paint->[$numbers][ 2 + $pitch ], 'quiet', 'the second is not');
    is($paint->[$numbers][ 2 + $pitch * 2 ], 'pick', 'and the third is');
};

subtest 'the screen says which side of the bout you are on' => sub {
    # THE ONE THING THE REST OF THE SCREEN CANNOT SAY. Attacking and defending
    # draw identically: the same cards in the same places and the same hand
    # lit the same way. What changes is what playing a card MEANS, and a
    # player who has lost track of that plays a card that beats nothing.
    my %said = (
        attack  => qr/you attack/,
        defend  => qr/you defend/,
        pile_on => qr/they took it/,
    );

    for my $phase (sort keys %said) {
        my $on = join "\n", @{ $table->lines($table->screen({
            %$view, phase => $phase, turn => 1,
        })) };
        like($on, $said{$phase}, "$phase says so when it is your move");

        my $off = join "\n", @{ $table->lines($table->screen({
            %$view, phase => $phase, turn => 2,
        })) };
        unlike($off, $said{$phase}, "and does not when it is theirs");
        like($off, qr/they (attack|defend)|you took it/,
             'which says what THEY are doing rather than going blank');
    }

    my $quiet = join "\n", @{ $table->lines($table->screen($view)) };
    unlike($quiet, qr/you attack|you defend|they attack/,
           'a view with no phase in it says nothing about the bout at all');
};

subtest 'nothing is written outside the screen' => sub {
    # put() clips rather than growing the grid, because a grid that grows is a
    # screen that scrolls, and a painted screen that scrolls is a smear.
    my $small = Game::Durak::Table->new(width => 30, height => 12);
    my $tight = $small->lines($small->screen($view, header => 'x' x 200,
                                                    footer => 'y' x 200));
    is(scalar @$tight, 12, 'twelve rows');
    is_deeply([ map { length } @$tight ], [ (30) x 12 ],
              'and none of them longer than the screen');
};

subtest 'ascii draws the same table out of ascii' => sub {
    my $plainly = Game::Durak::Table->new(ascii => 1);
    my $flat = join "\n", @{ $plainly->lines($plainly->screen($view)) };

    unlike($flat, qr/[^\x00-\x7f]/, 'not one character above 127');
    like($flat, qr/trump H/, 'the trump is a letter');
    like($flat, qr/\|10/, 'the ten is a ten there too');
    like($flat, qr/\|S/, 'with its suit on the row below it');
    like($flat, qr/\+={5}\+/, 'the ring is still a ring');
};

subtest 'the talon and the turn-up come and go' => sub {
    # READ OUT OF THE PAINT GRID AND NOT THE CHARACTERS. A first version
    # grepped the whole screen for the weave and found the OTHER seat's hand,
    # which is drawn face down too, so it could never have failed usefully.
    my $pack = sub {
        my ($at) = @_;
        my $drawn = $table->screen($at);
        my $backs = 0;
        for my $row (9 .. 13) {
            $backs += grep { $_ eq 'back' } @{ $drawn->{paint}[$row] }[ 2 .. 8 ];
        }
        return $backs;
    };

    is($pack->({ %$view, talon => 0, trump_card => undef }), 0,
       'an empty talon draws no pack');
    cmp_ok($pack->($view), '>', 20, 'a full one does');

    my $gone = join "\n", @{ $table->lines($table->screen({
        %$view, talon => 0, trump_card => undef,
    })) };
    like($gone, qr/trump \x{2665}\s+talon 0/,
         'but the trump suit is still named, because it still decides every bout');

    my $last = join "\n", @{ $table->lines($table->screen({
        %$view, talon => 1,
    })) };
    like($last, qr/7\x{2665}/,
         'the turn-up is on the table when it is the last card in the pack');
};

# And the real thing: a whole deal, every position rendered, nothing ragged.
subtest 'every position of a played deal draws a whole screen' => sub {
    require Game::Durak::Bot;
    my ($bad, $seen, $widest) = (0, 0, 0);

    for my $n (1 .. 6) {
        my $game = Game::Durak->build(seed => sprintf '%-32.32s', "table $n");
        my $bot  = Game::Durak::Bot->new(level => 2, seed => "bot $n");

        while (!$game->over) {
            my $seat = $game->turn;
            my $at   = $game->view($seat);
            my $drawn = $table->lines($table->screen($at,
                header => 'a deal in progress', footer => 'x'));
            $seen++;
            $widest = @{ $at->{hand} } if @{ $at->{hand} } > $widest;
            $bad++ if grep { length($_) != 80 } @$drawn;
            $bad++ if @$drawn != 24;

            my $move = $bot->choose($at) or last;
            $game->apply($seat, $move);
        }
    }

    is($bad, 0, 'no position drew a ragged screen');
    cmp_ok($seen, '>', 100, "$seen positions were drawn");
    cmp_ok($widest, '>', 6, "and the widest hand in them held $widest cards");
};

done_testing();
