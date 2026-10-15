use strict;
use warnings;
use Test::More;
use Symbol qw(gensym);

use Game::RoyalUr;
use Game::RoyalUr::Terminal;
my $T = 'Game::RoyalUr::Terminal';

{
    package Local::Out;
    sub TIEHANDLE { my $text = ''; return bless \$text, shift }
    sub PRINT     { my $self = shift; $$self .= join '', @_; return 1 }
    sub PRINTF    { my $self = shift; $$self .= sprintf shift, @_; return 1 }
    sub BINMODE   { 1 }
    sub FILENO    { -1 }

    package Local::In;
    sub TIEHANDLE { my ($class, @lines) = @_; return bless [@lines], $class }
    sub READLINE  { my $self = shift; return @$self ? shift(@$self) . "\n" : undef }
    sub EOF       { !@{ $_[0] } }
    sub BINMODE   { 1 }
    sub FILENO    { -1 }
}

sub keyed {
    my ($keys, %with) = @_;
    my @queue = @$keys;
    my ($in, $out) = (gensym, gensym);
    tie *$in, 'Local::In';
    my $written = tie *$out, 'Local::Out';
    my $t;
    my $source = sub {
        while (@queue && ref $queue[0]) { (shift @queue)->($t) }
        return shift @queue;
    };
    $t = $T->new(
        in => $in, out => $out, interactive => 1, colour => 0, unicode => 0, picking => 1, pace => 0,
        keysource => $source, sleeper => sub { },
        seed => 'history 3', first => 'light', mode => 'bot', side => 'light', level => 1, %with,
    );
    return ($t, $written);
}

sub dice_of {
    my ($game) = @_;
    return join ',', ($game->roll // '-'), ($game->throw ? join('', @{ $game->throw }) : '-');
}

sub bot_entries {
    my ($from, $to) = @_;
    my @log = @{ Game::RoyalUr->from_text($to)->log };
    my $had = @{ Game::RoyalUr->from_text($from)->log };
    return scalar grep { $_->{side} eq 'dark' } @log[ $had .. $#log ];
}

my $opening = Game::RoyalUr->new(seed => 'history 3', first => 'light')->to_text;

subtest 'u takes back your move and every reply, r plays them again, with the same dice' => sub {
    my %seen;
    my $snap = sub { my $name = shift; sub { $seen{$name} = $_[0]->game->to_text; $seen{"$name dice"} = dice_of($_[0]->game) } };
    my ($t, $written) = keyed([
        "\n", $snap->('second'), "\n", $snap->('third'),
        'u', $snap->('u'), 'r', $snap->('r'), 'u', 'u', $snap->('u u'), 'q', 'q',
    ]);
    $t->start;
    isnt($seen{second}, $opening, 'by the second turn the game had moved on');
    is(bot_entries($seen{second}, $seen{third}), 2, 'and the program had moved twice in reply to the second move');
    is($seen{u}, $seen{second}, 'u went back to the start of the second turn');
    is($seen{'u dice'}, $seen{'second dice'}, 'with the dice thrown for it then');
    is($seen{r}, $seen{third}, 'r played the turn and the reply again');
    is($seen{'r dice'}, $seen{'third dice'}, 'and the dice after it are the ones thrown before');
    is($seen{'u u'}, $opening, 'two more u go back to the opening');
    like($$written, qr/Taken back\./, 'u said so');
    like($$written, qr/Played again\./, 'and so did r');
    is($t->history->redo_count, 2, 'leaving two turns to play again');
};

subtest 'the same move after u meets the same reply and the same dice' => sub {
    my %seen;
    my ($t) = keyed([
        "\n", "\n", sub { $seen{before} = $_[0]->game->to_text },
        'u', "\n", sub { $seen{again} = $_[0]->game->to_text }, 'q', 'q',
    ]);
    $t->start;
    is($seen{again}, $seen{before}, 'the rebuilt game threw the dice it threw the first time');
};

subtest 'a move after u forgets what could be played again' => sub {
    my %seen;
    my ($t, $written) = keyed([
        "\n", "\n", 'u', sub { $seen{redo} = $_[0]->history->can_redo },
        "\n", sub { $seen{after} = $_[0]->history->can_redo; $seen{text} = $_[0]->game->to_text },
        'r', sub { $seen{again} = $_[0]->game->to_text }, 'q', 'q',
    ]);
    $t->start;
    ok($seen{redo}, 'after u there was a turn to play again');
    ok(!$seen{after}, 'after another move there was not');
    is($seen{again}, $seen{text}, 'so r changed nothing');
    like($$written, qr/There is nothing to play again\./, 'and said so');
};

subtest 'u at the start notes it and changes nothing' => sub {
    my %seen;
    my ($t, $written) = keyed([ 'u', 'r', sub { $seen{text} = $_[0]->game->to_text }, 'q', 'q' ]);
    $t->start;
    is($seen{text}, $opening, 'the game is still the opening');
    like($$written, qr/There is nothing to take back\./, 'u said there was nothing');
    like($$written, qr/There is nothing to play again\./, 'and so did r');
};

subtest 'a swap leaves nothing of the old game to tell' => sub {
    my %seen;
    my ($t) = keyed([
        "\n", "\n", sub { $seen{told} = scalar @{ $_[0]->events } },
        'u', sub { $seen{after} = $_[0]->events }, "\n", sub { $seen{again} = $_[0]->events }, 'q', 'q',
    ]);
    $t->start;
    is($seen{after}[-1], 'Taken back.', 'the last thing said is the take-back');
    is(scalar @{ $seen{after} }, $seen{told} + 1, 'and nothing of the undone game was told again');
    like($seen{again}[ $seen{told} + 1 ], qr/\AYou played /, 'the move made after it is told');
};

subtest 'in hotseat every move is a turn' => sub {
    my @ply;
    my $ply = sub { push @ply, $_[0]->game->ply };
    my ($t) = keyed([ "\n", $ply, "\n", $ply, 'u', $ply, 'u', $ply, 'r', $ply, 'q', 'q' ],
        mode => 'hotseat', seed => 'facade 46');
    $t->start;
    is($ply[0], 3, 'a move and two lost turns');
    cmp_ok($ply[1], '>', $ply[0], 'and the second move');
    is($ply[2], $ply[0], 'u takes back the second move alone');
    is($ply[3], 0, 'and the next u the first, with the lost turns after it');
    is($ply[4], $ply[0], 'r plays the first again');
};

subtest 'undo and redo typed' => sub {
    my ($in, $out) = (gensym, gensym);
    tie *$in, 'Local::In', 'hand-c1', 'undo', 'redo', 'undo', 'quit';
    my $written = tie *$out, 'Local::Out';
    my $t = $T->new(in => $in, out => $out, interactive => 0, colour => 0, unicode => 0, picking => 0,
                    pace => 0, seed => 'facade 46', first => 'light', mode => 'hotseat');
    $t->start;
    is($t->game->to_text, Game::RoyalUr->new(seed => 'facade 46', first => 'light')->to_text,
        'undo, redo, undo leaves the move taken back');
    is($t->history->redo_count, 1, 'with that turn to play again');
    is(scalar(grep { $_ eq 'Taken back.' } @{ $t->events }), 2, 'each undo said so');
    like($$written, qr/Played again\./, 'and redo too');

    my ($keyed) = keyed([ "\n", "\n", 'q', 'q' ]);
    $keyed->start;
    my $text = $keyed->game->to_text;
    ok(!$keyed->command('r'), 'r typed is redo, and does not leave');
    is($keyed->game->to_text, $text, 'with nothing to redo it changes nothing');
    $keyed->command('undo');
    isnt($keyed->game->to_text, $text, 'undo typed takes the turn back');
    $keyed->command('r');
    is($keyed->game->to_text, $text, 'and r typed plays it again');
    ok(!$keyed->route, 'r is no longer the route');
    $keyed->command('route');
    ok($keyed->route, 'the word route still is');
};

subtest 'when the program moves first, its opening is not a turn to go back to' => sub {
    my @seen;
    my ($t, $written) = keyed([
        sub { push @seen, $_[0]->history->can_undo, $_[0]->game->to_text }, 'u',
        sub { push @seen, $_[0]->game->to_text }, 'q', 'q',
    ], side => 'dark');
    $t->start;
    ok(!$seen[0], 'on the first turn there is nothing to take back');
    isnt($seen[1], $opening, 'though the program has moved');
    is($seen[2], $seen[1], 'and u leaves its opening on the board');
    like($$written, qr/There is nothing to take back\./, 'saying so');
};

subtest 'with the program on both sides there is nothing to take back' => sub {
    my ($t) = keyed([], mode => 'watch', interactive => 0, picking => 0);
    $t->start;
    ok($t->game->is_over, 'the program played to the end');
    is($t->history->undo_count, 0, 'and nothing was recorded');
    my $text = $t->game->to_text;
    ok(!$t->take_back, 'so undo takes nothing back');
    is($t->game->to_text, $text, 'and changes nothing');
};

subtest 'a game that is over goes back to your last turn, and forward again' => sub {
    my ($in, $out) = (gensym, gensym);
    tie *$in, 'Local::In';
    my $written = tie *$out, 'Local::Out';
    my (%seen, $t, $last);
    my $stage = 0;
    $t = $T->new(
        in => $in, out => $out, interactive => 1, colour => 0, unicode => 0, picking => 1, pace => 0,
        seed => 'facade 46', first => 'light', mode => 'bot', level => 1, sleeper => sub { },
        keysource => sub {
            my $game = $t->game;
            if ($stage == 0 && !$game->is_over) {
                $last = $game->to_text;
                return "\n";
            }
            if ($stage == 0) { $seen{over} = $game->to_text; $stage++; return 'u' }
            if ($stage == 1) { $seen{back} = $game->to_text; $stage++; return 'r' }
            if ($stage == 2) { $seen{again} = $game->to_text; $stage++; return 'q' }
            return undef;
        },
    );
    $t->start;
    ok(defined $seen{over}, 'the game was played to its end');
    is($seen{back}, $last, 'u went back to the last turn you had');
    is($seen{again}, $seen{over}, 'and r to the end');
    like($$written, qr/n new game  u take back  q leave/, 'the ended keys are as they were');
};

subtest 'the keys' => sub {
    my ($t) = keyed(['r']);
    is($t->pick, 'redo', 'r asks to play again');
    ($t) = keyed(['R']);
    is($t->pick, 'route', 'R asks for the route');
    ($t) = keyed(['u']);
    is($t->pick, 'undo', 'u asks to take back');
    my ($line) = grep { /take back/ } @{ $t->screen('pick') };
    like($line, qr/u take back  r play again  R route/, 'the legend names all three');
    like(join("\n", @{ $t->help_lines }), qr/^  r +play a turn taken back again$/m, 'and so does the help');
    like(join("\n", @{ $t->help_lines }), qr/^  R +show or hide the route$/m, 'the route among them');
};

done_testing;
