use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use FnCapture;
use File::Spec;
use File::Temp qw(tempdir);

use Game::Fanorona;
use Game::Fanorona::Terminal;
my $T = 'Game::Fanorona::Terminal';

# UNDO AND REDO, through the kit's history. The keys go in one character a
# call, as in t/28, and a code reference among them is run, with the
# terminal, at the moment the next key is asked for: so it sees the game as
# the person would see it then. h then enter plays the move the program
# would, which is a legal move wherever it is asked.

my %KEY = (up => "\e[A", down => "\e[B", right => "\e[C", left => "\e[D", enter => "\r");

sub sitting {
    my ($keys, %with) = @_;
    my @queue = map { ref $_ ? $_ : split //, (exists $KEY{$_} ? $KEY{$_} : $_) } @{$keys};
    my $written = '';
    my $out = FnCapture->handle(\$written);
    my $terminal;
    $terminal = $T->new(
        out => $out, interactive => 1, colour => 0, unicode => 0, picking => 1, pause => 0,
        keysource => sub {
            (shift @queue)->($terminal) while @queue && ref $queue[0];
            return @queue ? shift @queue : undef;
        },
        %with,
    );
    $terminal->start;
    close $out;
    my @frames = split /\e\[H/, $written;
    shift @frames;
    s/\e\[[0-9;?]*[A-Za-z]//g for @frames;
    return ($terminal, \@frames);
}

sub board_of { { cols => 9, rows => 5, start => $_[0], @_[1 .. $#_] } }

my $opening = Game::Fanorona->new->as_text;

subtest 'u takes back your move and the reply, r plays them again' => sub {
    my %seen;
    my $snap = sub { my $name = shift; sub { $seen{$name} = $_[0]->game->as_text; $seen{"$name ply"} = $_[0]->game->ply } };
    my ($t, $frames) = sitting([
        'h', 'enter', $snap->('second'), 'h', 'enter', $snap->('third'),
        'u', $snap->('u'), sub { $seen{last} = $_[0]->last }, 'r', $snap->('r'), 'u', 'u', $snap->('u u'), 'q',
    ], human => 'white', level => 1);
    is($seen{'second ply'}, 2, 'by the second turn the program had replied');
    is($seen{u}, $seen{second}, 'u went back to the start of the second turn');
    is($seen{'u ply'}, 2, 'so the reply to the second move went with it');
    is($seen{r}, $seen{third}, 'r played the turn again');
    is($seen{'u u'}, $opening, 'two more u go back to the opening');
    is($t->history->redo_count, 2, 'with two turns left to play again');
    is($seen{last}{side}, 'black', 'after u the last move shown is the reply now last');
    my ($second) = Game::Fanorona->from_text($seen{second});
    is($seen{last}{move}, ($second->moves)[-1], 'and it is that move');
    ok(scalar(grep { /^Taken back\.$/m } @$frames), 'u said so');
    ok(scalar(grep { /^Played again\.$/m } @$frames), 'and so did r');
};

subtest 'a move after u forgets what could be played again' => sub {
    my %seen;
    my ($t, $frames) = sitting([
        'h', 'enter', 'u', sub { $seen{could} = $_[0]->history->can_redo },
        'h', 'enter', sub { $seen{after} = $_[0]->history->can_redo; $seen{text} = $_[0]->game->as_text },
        'r', sub { $seen{again} = $_[0]->game->as_text }, 'q',
    ], human => 'white', level => 1);
    ok($seen{could}, 'after u there was a turn to play again');
    ok(!$seen{after}, 'after another move there was not');
    is($seen{again}, $seen{text}, 'so r changed nothing');
    like($frames->[-1], qr/^There is nothing to play again\.$/m, 'and said so');
};

subtest 'u at the start notes it and changes nothing' => sub {
    my %seen;
    my ($t, $frames) = sitting([ 'u', sub { $seen{u} = $_[0]->game->as_text }, 'r', 'q' ],
        human => 'white', level => 1);
    is($seen{u}, $opening, 'the game is still the opening');
    is($t->game->ply, 0, 'with nothing played');
    ok(scalar(grep { /^There is nothing to take back\.$/m } @$frames), 'u said there was nothing');
    like($frames->[-1], qr/^There is nothing to play again\.$/m, 'and so did r');
};

subtest 'between two people every move is a step' => sub {
    my @ply;
    my $ply = sub { push @ply, $_[0]->game->ply };
    my ($t) = sitting([ 'h', 'enter', 'h', 'enter', $ply, 'u', $ply, 'u', $ply, 'r', $ply, 'q' ],
        human => 'both');
    is_deeply(\@ply, [ 2, 1, 0, 1 ], 'two moves, u twice takes back one each, r plays one again');
};

subtest 'undo and redo typed' => sub {
    my @ply;
    my $ply = sub { push @ply, $_[0]->game->ply };
    my ($t) = sitting([ 'h', 'enter', ':', split(//, 'undo'), 'enter', $ply,
                        ':', split(//, 'redo'), 'enter', $ply, 'q' ],
        human => 'white', level => 1);
    is_deeply(\@ply, [ 0, 2 ], 'after a colon, undo and redo are commands');

    my $typed = join '', map { "$_\n" } 'd2-e3A', 'undo', 'redo', 'undo', 'quit';
    open my $in, '<', \$typed or die "in: $!";
    my $said = '';
    my $out = FnCapture->handle(\$said);
    $t = $T->new(in => $in, out => $out, interactive => 0, colour => 0, unicode => 0, picking => 0,
                 human => 'white', level => 1, pause => 0);
    $t->start;
    is($t->game->ply, 0, 'typed: undo, redo, undo leaves the turn taken back');
    is($t->history->redo_count, 1, 'with it to play again');
    is(scalar(() = $said =~ /^Taken back\.$/mg), 2, 'each undo said so');
    like($said, qr/^Played again\.$/m, 'and so did the redo');
};

subtest 'with the program on both sides there is nothing to take back' => sub {
    my $typed = '';
    open my $in, '<', \$typed or die "in: $!";
    my $said = '';
    my $out = FnCapture->handle(\$said);
    my $t = $T->new(in => $in, out => $out, interactive => 0, colour => 0, unicode => 0, picking => 0,
                    human => 'neither', level => 1, pause => 0, variant => 'telo');
    $t->start;
    ok($t->game->over, 'the program played to the end');
    is($t->history->undo_count, 0, 'and nothing was kept');
    my $ply = $t->game->ply;
    ok(!$t->take_back, 'so undo takes nothing back');
    is($t->game->ply, $ply, 'and changes nothing');
};

subtest 'with Black, the program\'s opening is not a step' => sub {
    my @seen;
    my ($t, $frames) = sitting([
        sub { push @seen, $_[0]->history->can_undo }, 'u', sub { push @seen, $_[0]->game->ply },
        'h', 'enter', 'u', sub { push @seen, $_[0]->game->ply }, 'q',
    ], human => 'black', level => 1);
    ok(!$seen[0], 'on the first turn there is nothing to take back');
    ok(scalar(grep { /^There is nothing to take back\.$/m } @$frames), 'and u says so');
    is($seen[1], 1, 'leaving the program\'s opening on the board');
    is($seen[2], 1, 'and u after a turn comes back to it');
};

subtest 'a game that has ended: u takes the last move back, r plays it again' => sub {
    my @seen;
    my ($t, $frames) = sitting([ 'enter', '6', 'enter',
        'u', sub { push @seen, $_[0]->game->over }, 'r', sub { push @seen, $_[0]->game->over }, 'q' ],
        human => 'both', variant => board_of('9/9/w1b6/9/9 w'));
    is_deeply(\@seen, [ 0, 1 ], 'the win is taken back and played again');
    is($t->game->result->how, 'stones', 'the same win');
    like($frames->[-1], qr/^n new game   u undo   r redo   R rules   : command   q quit$/m,
        'and the end says what the keys do');
};

subtest 'a swap clears what the old game left behind' => sub {
    my %seen;
    my ($t) = sitting([ 'h', 'enter', 'h', 'enter', 'enter', '6',
        sub { $seen{held} = $_[0]->chosen; $_[0]->_log->record('stale') },
        'u', sub {
            my ($t) = @_;
            $seen{focus} = $t->focus;
            $seen{first} = $t->lit->[0];
            $seen{chosen} = $t->chosen;
            $seen{prefix} = $t->prefix;
            $seen{notice} = $t->notice;
            $seen{last} = $t->last;
            $seen{move} = ($t->game->moves)[-1];
        }, 'q' ], human => 'both');
    ok(defined $seen{held}, 'a stone was picked up before u');
    is($seen{chosen}, undef, 'and none is held after it');
    is_deeply($seen{prefix}, [], 'with no steps built');
    is($seen{focus}, $seen{first}, 'the cursor starts again on the first stone that can move');
    is_deeply($seen{notice}, [ 'Taken back.' ], 'and nothing old is left to say');
    is($seen{last}{move}, $seen{move}, 'the last move marked is the one now last');
    is($seen{last}{side}, 'white', 'played by White');
};

subtest 'a new game and a loaded game start their history afresh' => sub {
    my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'game.txt');
    my ($t) = sitting([ 'h', 'enter', 'h', 'enter', ':', split(//, "save $file"), 'enter',
                        ':', split(//, "load $file"), 'enter', 'q' ], human => 'both');
    is($t->game->ply, 2, 'the game came back');
    ok(!$t->history->can_undo, 'with nothing to take back');

    ($t) = sitting([ 'h', 'enter', ':', split(//, 'new'), 'enter', 'q' ], human => 'both');
    ok(!$t->history->can_undo, 'and new leaves nothing to take back');
};

subtest 'the keys are listed' => sub {
    my ($t, $frames) = sitting([ 'h', 'enter', 'u', 'q' ], human => 'both');
    like($frames->[2], qr/^u undo$/m, 'after a move the board offers u');
    like($frames->[-1], qr/^r redo$/m, 'and after u, r');
    unlike($frames->[0], qr/^u undo/m, 'with nothing offered at the start');
    my $help = join "\n", @{ $t->_help_lines };
    like($help, qr/^  u +take back your last move/m, 'u is undo');
    like($help, qr/^  r +play again what u took back$/m, 'r is redo');
    like($help, qr/^  R +the rules$/m, 'and R the rules');
    like($help, qr/^  redo +play again what undo took back$/m, 'redo is a typed command');
    unlike($help, qr/y u b n/, 'u is no longer a step');
};

done_testing;
