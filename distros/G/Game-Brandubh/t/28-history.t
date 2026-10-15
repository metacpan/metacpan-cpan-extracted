use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use Game::Brandubh;
use Game::Brandubh::Terminal;
my $T = 'Game::Brandubh::Terminal';

# UNDO AND REDO, through the kit's history. The keys go in one character a
# call, as in t/24, and a code reference among them is run, with the
# terminal, at the moment the next key is asked for: so it sees the game as
# the person would see it then.

my %KEY = (up => "\e[A", down => "\e[B", right => "\e[C", left => "\e[D", enter => "\r");

sub sitting {
    my ($keys, %with) = @_;
    my @queue = map { ref $_ ? $_ : split //, (exists $KEY{$_} ? $KEY{$_} : $_) } @{$keys};
    my $written = '';
    open my $out, '>', \$written or die "out: $!";
    my $terminal;
    $terminal = $T->new(
        out => $out, interactive => 1, colour => 0, unicode => 0, picking => 1,
        seed => 'H' x 32, pause => 0,
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

my $opening = Game::Brandubh->new(seed => 'H' x 32)->as_text;

subtest 'u takes back your move and the reply, r plays them again' => sub {
    my %seen;
    my $snap = sub { my $name = shift; sub { $seen{$name} = $_[0]->game->as_text; $seen{"$name ply"} = $_[0]->game->ply } };
    my ($t, $frames) = sitting([
        'enter', 'enter', $snap->('second'), 'enter', 'enter', $snap->('third'),
        'u', $snap->('u'), 'r', $snap->('r'), 'u', 'u', $snap->('u u'), 'q',
    ], human => 'attackers', level => 1);
    is($seen{'second ply'}, 2, 'by the second turn the program had replied');
    is($seen{u}, $seen{second}, 'u went back to the start of the second turn');
    is($seen{'u ply'}, 2, 'so the reply to the second move went with it');
    is($seen{r}, $seen{third}, 'r played the turn again');
    is($seen{'u u'}, $opening, 'two more u go back to the opening');
    is($t->history->redo_count, 2, 'with two turns left to play again');
    ok(scalar(grep { /Taken back\./ } @$frames), 'u said so');
    ok(scalar(grep { /Played again\./ } @$frames), 'and so did r');
};

subtest 'a move after u forgets what could be played again' => sub {
    my %seen;
    my ($t, $frames) = sitting([
        'enter', 'enter', 'u', sub { $seen{could} = $_[0]->history->can_redo },
        'tab', 'enter', 'enter', sub { $seen{after} = $_[0]->history->can_redo; $seen{text} = $_[0]->game->as_text },
        'r', sub { $seen{again} = $_[0]->game->as_text }, 'q',
    ], human => 'attackers', level => 1);
    ok($seen{could}, 'after u there was a turn to play again');
    ok(!$seen{after}, 'after another move there was not');
    is($seen{again}, $seen{text}, 'so r changed nothing');
    like($frames->[-1], qr/There is nothing to play again\./, 'and said so');
};

subtest 'u at the start notes it and changes nothing' => sub {
    my %seen;
    my ($t, $frames) = sitting([ 'u', sub { $seen{u} = $_[0]->game->as_text }, 'r', 'q' ],
        human => 'attackers', level => 1);
    is($seen{u}, $opening, 'the game is still the opening');
    is($t->game->ply, 0, 'with nothing played');
    ok(scalar(grep { /There is nothing to take back\./ } @$frames), 'u said there was nothing');
    like($frames->[-1], qr/There is nothing to play again\./, 'and so did r');
};

subtest 'between two people every move is a step' => sub {
    my @ply;
    my $ply = sub { push @ply, $_[0]->game->ply };
    my ($t) = sitting([ 'enter', 'enter', 'enter', 'enter', $ply, 'u', $ply, 'u', $ply, 'r', $ply, 'q' ],
        human => 'both');
    is_deeply(\@ply, [ 2, 1, 0, 1 ], 'two moves, u twice takes back one each, r plays one again');
};

subtest 'undo and redo typed' => sub {
    my @ply;
    my $ply = sub { push @ply, $_[0]->game->ply };
    my ($t) = sitting([ 'enter', 'enter', ':', split(//, 'undo'), 'enter', $ply,
                        ':', split(//, 'redo'), 'enter', $ply, 'q' ],
        human => 'attackers', level => 1);
    is_deeply(\@ply, [ 0, 2 ], 'after a colon, undo and redo are commands');

    my $typed = join '', map { "$_\n" } 'd1c1', 'undo', 'redo', 'undo', 'quit';
    open my $in, '<', \$typed or die "in: $!";
    my $said = '';
    open my $out, '>', \$said or die "out: $!";
    $t = $T->new(in => $in, out => $out, interactive => 0, colour => 0, picking => 0,
                 seed => 'H' x 32, human => 'attackers', level => 1);
    $t->start;
    is($t->game->ply, 0, 'typed: undo, redo, undo leaves the turn taken back');
    is($t->history->redo_count, 1, 'with it to play again');
    is(scalar(() = $said =~ /Taken back\./g), 2, 'each undo said so');
    like($said, qr/Played again\./, 'and so did the redo');
};

subtest 'with the program on both sides there is nothing to take back' => sub {
    my $typed = '';
    open my $in, '<', \$typed or die "in: $!";
    my $said = '';
    open my $out, '>', \$said or die "out: $!";
    my $t = $T->new(in => $in, out => $out, interactive => 0, colour => 0, picking => 0,
                    seed => 'H' x 32, human => 'none', level => 1, pause => 0);
    $t->start;
    ok($t->game->status eq 'finished', 'the program played to the end');
    is($t->history->undo_count, 0, 'and nothing was kept');
    my $ply = $t->game->ply;
    $t->take_back;
    is($t->game->ply, $ply, 'so undo changes nothing');
};

subtest 'with the defenders, the program\'s opening is not a step' => sub {
    my @seen;
    my ($t, $frames) = sitting([
        sub { push @seen, $_[0]->history->can_undo }, 'u', sub { push @seen, $_[0]->game->ply },
        'enter', 'enter', 'u', sub { push @seen, $_[0]->game->ply }, 'q',
    ], human => 'defenders', level => 1);
    ok(!$seen[0], 'on the first turn there is nothing to take back');
    ok(scalar(grep { /There is nothing to take back\./ } @$frames), 'and u says so');
    is($seen[1], 1, 'leaving the program\'s opening on the board');
    is($seen[2], 1, 'and u after a turn comes back to it');
};

subtest 'a game that has ended: u takes the last move back, r plays it again' => sub {
    my @seen;
    my $game = Game::Brandubh->new(position => '7/7/7/k6/7/7/3a3 d');
    my ($t, $frames) = sitting([ 'enter', 'down', 'down', 'down', 'enter',
        'u', sub { push @seen, $_[0]->game->status }, 'r', sub { push @seen, $_[0]->game->status }, 'q' ],
        human => 'both', game => $game);
    is_deeply(\@seen, [ 'active', 'finished' ], 'the win is taken back and played again');
    is($t->game->result->how, 'corner', 'the same win');
    like($frames->[-1], qr/n new game   u undo   r redo   R rules   q quit/, 'and the end says what the keys do');
};

subtest 'a swap clears what the old game left behind' => sub {
    my %seen;
    my ($t) = sitting([ 'enter', 'enter', 'enter', 'enter', 'enter',
        sub { $_[0]->_log->record('stale') },
        'u', sub {
            my ($t) = @_;
            $seen{focus} = $t->focus;
            $seen{first} = $t->movable->[0];
            $seen{chosen} = $t->chosen;
            $seen{notice} = $t->notice;
            ($seen{mark}) = $t->marks('plain');
            ($seen{last}) = $t->game->shown->[-1] =~ /([a-g][1-7]-[a-g][1-7])/;
        }, 'q' ], human => 'both');
    is($seen{focus}, $seen{first}, 'the cursor starts again on the first piece that can move');
    is($seen{chosen}, undef, 'no piece held, though one was picked up before u');
    is_deeply($seen{notice}, [ 'Taken back.' ], 'and nothing old left to say');
    my ($from, $to) = split /-/, $seen{last};
    is_deeply($seen{mark}, { $from => 'trail', $to => 'trail' }, 'the last move marked is the one now last');
};

subtest 'a new game and a loaded game start their history afresh' => sub {
    my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'game.txt');
    my ($t) = sitting([ 'enter', 'enter', 'enter', 'enter', ':', split(//, "save $file"), 'enter',
                        ':', split(//, "load $file"), 'enter', 'q' ], human => 'both');
    is($t->game->ply, 2, 'the game came back');
    ok(!$t->history->can_undo, 'with nothing to take back');

    ($t) = sitting([ 'enter', 'enter', 'n', 'q' ], human => 'both');
    ok(!$t->history->can_undo, 'and n leaves nothing to take back');
};

subtest 'the keys are listed' => sub {
    my $t = $T->new(interactive => 0, picking => 0, seed => 'H' x 32);
    like($t->legend('which'), qr/u undo   r redo/, 'u and r on the board');
    is($Game::Brandubh::Terminal::KEY{r}, 'redo', 'r is redo');
    is($Game::Brandubh::Terminal::KEY{R}, 'rules', 'and R the rules');
    like(join("\n", @{ $t->help_lines }), qr/^  redo +play again/m, 'redo is a typed command');
};

done_testing;
