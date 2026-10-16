use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SthCapture;
use SthT qw(near_home);

use Game::Sternhalma;
use Game::Sternhalma::Bot;
use Game::Sternhalma::Engine ();
use Game::Sternhalma::Notation qw(name_of hole_of);
use Game::Sternhalma::Terminal;
my $T = 'Game::Sternhalma::Terminal';
my $E = 'Game::Sternhalma::Engine';

# THE TERMINAL, PLAYED WITH THE ARROW KEYS. A key source stands in for the
# keyboard and hands over one character a call, exactly as a terminal does: an
# arrow is three characters and escape is one. Every screen the terminal draws
# starts by sending the cursor home, so what it wrote splits into the frames a
# person would have seen, in order.
#
# Nothing here needs Term::ReadKey, a terminal or a shell.

my %KEY = (up => "\e[A", down => "\e[B", right => "\e[C", left => "\e[D",
           enter => "\r", tab => "\t", backtab => "\e[Z", esc => "\e",
           home => "\e[H", end => "\e[F");

sub keys_of { join '', map { exists $KEY{$_} ? $KEY{$_} : $_ } @_ }

sub sitting {
    my ($keys, %with) = @_;
    my @chars = split //, keys_of(@$keys);
    my $written = '';
    my $out = SthCapture->handle(\$written);
    my $terminal = $T->new(
        out => $out, interactive => 1, colour => 0, unicode => 0, picking => 1, pause => 0,
        bots => [],
        keysource => sub { @chars ? shift @chars : undef },
        %with,
    );
    my $status = $terminal->start;
    close $out;
    my @frames = split /\e\[H/, $written;
    shift @frames;
    s/\e\[[0-9;?]*[A-Za-z]//g for @frames;
    return (\@frames, $terminal, $status, $written);
}

# every bracketed hole of a frame, as "mark@name", top row first
sub marked {
    my ($frame, $t) = @_;
    my @rows = grep { /^ *[a-q] [ \[<({:][.A-Z]/ } split /\n/, $frame;
    my @found;
    for my $h (0 .. 120) {
        my $cell = substr $rows[ $E->row_of($h) ] . (' ' x 80), $t->column($h) - 1, 3;
        push @found, $cell . '@' . name_of($h) if $cell =~ /\A[\[<({:].[\]>)}:]\z/;
    }
    return join ' ', @found;
}

sub mark_of {
    my ($frame, $t, $kind) = @_;
    return join ' ', map { /\A\Q$kind\E.\S*\@(\S+)\z/ ? $1 : () } split / /, marked($frame, $t);
}

sub near { Game::Sternhalma->new(position => (near_home(2, 0))[0]->to_string) }

my @LIT = qw(c1 c2 c3 d1 d2 d3 d4);

subtest 'the cursor walks the pieces that can move, and only those' => sub {
    my ($frames, $t) = sitting([ ('tab') x 7, 'backtab', 'end', 'home', 'q' ]);
    is(scalar(@$frames), 11, 'eleven frames: the first, and one a key');
    is_deeply([ map { name_of($_) } @{ $t->lit } ], \@LIT, 'seven pieces can move at the set-up, top row first, then left to right');
    my @cursor = map { mark_of($_, $t, '[') } @$frames;
    is("@cursor", 'c1 c2 c3 d1 d2 d3 d4 c1 d4 d4 c1', 'tab goes round them in the order they are drawn, and back; end and home');
    unlike(join('', @$frames), qr/\[R\]\s*$/m, 'never on a1, b1 or b2, which cannot move') ;
    is(mark_of($frames->[0], $t, '('), 'e5 e7', 'the holes the piece under the cursor can reach are lit');
    like($frames->[0], qr/^The piece at c1 can reach 2 holes\.$/m, 'and counted');
    like($frames->[0], qr/arrows choose a piece   enter pick it up/, 'and the foot of the screen says what the keys do');
    is($t->game->ply, 0, 'nothing was played');
    is($t->raw, 0, 'and the keyboard was handed back at the end');

    ($frames, $t) = sitting([ 'down', 'right', 'right', 'right', 'right', 'left', 'up', 'up', 'q' ]);
    @cursor = map { mark_of($_, $t, '[') } @$frames;
    is("@cursor", 'c1 d1 d2 d3 d4 d4 d3 c2 c2', 'the arrows: the nearest lit piece that way, and nowhere when there is none');
};

subtest 'steer: the nearest in a direction' => sub {
    my $t = $T->new(interactive => 0, picking => 0);
    my @h = map { hole_of($_) } qw(e5 e7 i5 a1 q1 m1 m13);
    is(name_of($t->steer(hole_of('i5'), 'right', [@h])), 'm13', 'right from the centre: m13, further right than it is down');
    is(name_of($t->steer(hole_of('i5'), 'left', [ map { hole_of($_) } qw(e7 q1) ])), 'i5', 'nothing to the left: it stays');
    is(name_of($t->steer(hole_of('i5'), 'up', [@h])), 'e7', 'up from the centre: e7, nearer the line straight up than e5');
    is(name_of($t->steer(hole_of('i5'), 'down', [@h])), 'q1', 'down: the bottom tip, straight below');
    is(name_of($t->steer(hole_of('e5'), 'right', [@h])), 'e7', 'right along a row');
    is(name_of($t->steer(hole_of('e7'), 'left', [@h])), 'e5', 'and left');
    is(name_of($t->steer(hole_of('i5'), 'x', [@h])), 'i5', 'a key that is no direction goes nowhere');
};

subtest 'a piece picked up, its way shown, and put back' => sub {
    my ($frames, $t) = sitting([ 'tab', 'tab', 'enter', 'tab', 'esc', 'q' ]);
    is(mark_of($frames->[3], $t, '<'), 'c3', 'enter: c3 is picked up');
    is(mark_of($frames->[3], $t, '['), 'e7', 'the cursor goes to the first hole it can reach');
    is(mark_of($frames->[3], $t, '('), 'e9', 'and the other is lit');
    like($frames->[3], qr/^Enter moves it c3:e7\.$/m, 'what enter would do, written out');
    like($frames->[3], qr/^arrows choose where it goes   enter move it there   esc put it back$/m, 'the keys now');
    is(mark_of($frames->[4], $t, '['), 'e9', 'tab: the next hole');
    like($frames->[4], qr/^Enter moves it c3:e9\.$/m, 'and the move with it');
    is(mark_of($frames->[5], $t, '['), 'c3', 'escape: the piece is put back, and the cursor is on it');
    is(mark_of($frames->[5], $t, '<'), '', 'nothing is picked up');
    is($t->game->ply, 0, 'and nothing was played');

    my @typed = ('d2-e6', 'o1-m5', 'c2-d2');
    my $game = Game::Sternhalma->new;
    $game->play($_) for @typed;
    my @lit = map { name_of($_) } @{ $T->new(interactive => 0, game => $game, bots => [])->lit };
    my $q1 = (grep { $lit[$_] eq 'q1' } 0 .. $#lit)[0];
    my $reach = [ map { name_of($_) } @{ $T->new(interactive => 0, game => $game, bots => [])->reach(hole_of('q1')) } ];
    my $m7 = (grep { $reach->[$_] eq 'm7' } 0 .. $#$reach)[0];
    ($frames, $t) = sitting([ ('tab') x $q1, 'enter', ('tab') x $m7, 'q' ], game => $game);
    my $last = $frames->[-1];
    is(mark_of($last, $t, '<'), 'q1', 'a chain of two hops: the piece on q1');
    is(mark_of($last, $t, '{'), 'o1', 'the hole it lands in on the way is marked');
    is(mark_of($last, $t, '['), 'm7', 'and the cursor on the end');
    like($last, qr/^Enter moves it q1:o1:m7\.$/m, 'the whole chain written out');
};

subtest 'a move made with the keys, and the reply' => sub {
    my ($frames, $t) = sitting([ 'tab', 'tab', 'enter', 'enter', 'q' ], bots => [1], level => 2);
    my @moves = $t->game->moves;
    is($moves[0], 'c3:e7', 'enter, enter: c3 to e7, played');
    is(scalar(@moves), 2, 'and the program answered');
    my $last = $frames->[-1];
    like($last, qr/^Blue played \Q$moves[1]\E\.$/m, 'what it played is above the board');
    like($last, qr/^Move 3\. Red to play, R\.$/m, 'and it is Red again');
    my $moved = (split /[-:]/, $moves[1])[-1];
    like(mark_of($last, $t, ':'), qr/\b\Q$moved\E\b/, 'the reply is framed on the board');
    like($frames->[-2], qr/The program is thinking\./, 'a frame said the program was thinking');
};

subtest 'u takes back to the last move made at the keys' => sub {
    my ($frames, $t) = sitting([ 'tab', 'tab', 'enter', 'enter', 'u', 'q' ], bots => [1], level => 1);
    is($t->game->ply, 0, 'with the program in a seat, u takes back the reply AND the move: back to the start');
    like($frames->[-1], qr/^Taken back\.$/m, 'said so');
    like($frames->[-1], qr/^r redo$/m, 'and r is offered');

    ($frames, $t) = sitting([ 'tab', 'tab', 'enter', 'enter', 'u', 'r', 'q' ], bots => [1], level => 1);
    is($t->game->ply, 2, 'r plays both again');

    ($frames, $t) = sitting([ 'tab', 'tab', 'enter', 'enter', 'enter', 'enter', 'u', 'q' ]);
    is($t->game->ply, 1, 'two people at the keys: u takes back one move');
    is_deeply([ $t->game->moves ], ['c3:e7'], 'the second');

    ($frames, $t) = sitting([ 'u', 'q' ]);
    like($frames->[-1], qr/^There is nothing to take back\.$/m, 'at the start, nothing to take back, and it says so');
};

subtest 'h shows the program\'s move, picked up' => sub {
    my ($frames, $t) = sitting([ 'h', 'enter', 'q' ]);
    my $move = Game::Sternhalma::Bot->choose(Game::Sternhalma->new, rung => 3, seed => 1);
    my $text = Game::Sternhalma->new->board->move_text($move->{from}, $move->{to});
    like($frames->[1], qr/^The program would play \Q$text\E\. Enter plays it; escape puts the piece back\.$/m, "h: $text");
    is(mark_of($frames->[1], $t, '<'), name_of($move->{from}), 'its piece is picked up');
    is(mark_of($frames->[1], $t, '['), name_of($move->{to}), 'and the cursor is where it goes');
    is(($t->game->moves)[0], $text, 'enter plays it');
};

# A WHOLE GAME BY KEYS: two seats each a step from home. Red goes in, and
# with two seats the first home ends it.
subtest 'a whole game through the keys' => sub {
    my $game = near();
    my $t0 = $T->new(interactive => 0, game => $game, bots => []);
    my @lit = map { name_of($_) } @{ $t0->lit };
    my $at = (grep { $lit[$_] eq 'm6' } 0 .. $#lit)[0];
    my @reach = map { name_of($_) } @{ $t0->reach(hole_of('m6')) };
    my $to = (grep { $reach[$_] eq 'n1' } 0 .. $#reach)[0];
    ok(defined $at && defined $to, 'm6 can move, and n1 is one of the holes it can reach');
    my ($frames, $t) = sitting([ ('tab') x $at, 'enter', ('tab') x $to, 'enter', 'q' ], game => $game);
    ok($t->game->over, 'the game is over');
    is($t->game->how, 'home', 'Red is home');
    like($frames->[-1], qr/^Red is home, 1st\.$/m, 'said above the board');
    like($frames->[-1], qr/^1st Red, 2nd Blue\.$/m, 'and the places under it');
    like($frames->[-1], qr/^n new game   u undo   r redo   R rules   : command   q quit$/m, 'with the keys for a game that is over');

    ($frames, $t) = sitting([ ('tab') x $at, 'enter', ('tab') x $to, 'enter', 'u', 'q' ], game => near());
    ok(!$t->game->over, 'u after the end takes the last move back');
    is($t->game->ply, 0, 'to the start');
};

subtest 'keys that do nothing, and the screens beside the board' => sub {
    my ($frames, $t) = sitting([ 'x', '?', 'a', 'R', 'b', 'q' ]);
    like($frames->[1], qr/^That key does nothing here\. Press \? for the ones that do\.$/m, 'a key that does nothing is told so');
    like($frames->[2], qr/^The keys:$/m, '? lists the keys');
    like($frames->[4], qr/A HOP/, 'R gives the rules');
    is($t->game->ply, 0, 'and nothing is played');
};

done_testing();
