use strict;
use warnings;
use Test::More;

# A GAME WRITES NOTHING, OPENS NOTHING, AND ASKS NOBODY THE TIME. The classes
# that play this game are for a server to hold in memory and a terminal to
# wrap; neither wants a rules engine that prints, warns, touches the disk, or
# plays a different game on a different day. The dice are the only chance
# there is, and they take a seed.
#
# open, sysopen, opendir, rand, srand and time are replaced before anything is
# compiled, so a call from any of the modules lands in the counters below, and
# %ENV is tied so that a read is counted. Once the modules are loaded, STDOUT
# and STDERR are pointed at two strings, a batch of games is played through
# every public method, and both strings must be empty and every counter zero.
#
# Game::RoyalUr::Terminal is the one place in this distribution allowed to do
# any of this. It is not loaded here, and this file says so.

my (%called, $watching);
BEGIN {
    no warnings 'redefine';
    *CORE::GLOBAL::open = sub (*;$@) {
        $called{open}++ if $watching;
        if (defined $_[0] && !ref $_[0] && ref(\$_[0]) ne 'GLOB') {
            no strict 'refs';
            my $name = $_[0] =~ /::|'/ ? $_[0] : (caller)[0] . "::$_[0]";
            return @_ == 1 ? CORE::open(*{$name})
                 : @_ == 2 ? CORE::open(*{$name}, $_[1])
                 :           CORE::open(*{$name}, $_[1], @_[2 .. $#_]);
        }
        return @_ == 1 ? CORE::open($_[0])
             : @_ == 2 ? CORE::open($_[0], $_[1])
             :           CORE::open($_[0], $_[1], @_[2 .. $#_]);
    };
    *CORE::GLOBAL::sysopen = sub (*$$;$) {
        $called{sysopen}++ if $watching;
        return @_ == 3 ? CORE::sysopen($_[0], $_[1], $_[2]) : CORE::sysopen($_[0], $_[1], $_[2], $_[3]);
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        $called{opendir}++ if $watching;
        return CORE::opendir($_[0], $_[1]);
    };
    *CORE::GLOBAL::rand  = sub (;$) { $called{rand}++  if $watching; return @_ ? CORE::rand($_[0]) : CORE::rand() };
    *CORE::GLOBAL::srand = sub (;$) { $called{srand}++ if $watching; return @_ ? CORE::srand($_[0]) : CORE::srand() };
    *CORE::GLOBAL::time  = sub ()   { $called{time}++  if $watching; return CORE::time() };
}

{
    package Local::Env;
    require Tie::Hash;
    our @ISA = ('Tie::StdHash');
    sub FETCH  { $called{env}++ if $watching; return $_[0]->SUPER::FETCH($_[1]) }
    sub EXISTS { $called{env}++ if $watching; return $_[0]->SUPER::EXISTS($_[1]) }
}

use Game::RoyalUr;
use Game::RoyalUr::Variant;
use Game::RoyalUr::Notation qw(:all);
use Game::RoyalUr::Dice qw(:all);
use Game::RoyalUr::Engine ();
use Game::RoyalUr::Rules ();
use Game::RoyalUr::Error ();
use Game::RoyalUr::Result ();

ok(!exists $INC{'Game/RoyalUr/Terminal.pm'}, 'the terminal is not loaded');

my ($out, $err) = ('', '');
my @warnings;
my ($games, $plies, $refusals, $replays) = (0, 0, 0, 0);

{
    my %real = %ENV;
    tie %ENV, 'Local::Env';
    %ENV = %real;

    open my $keep_out, '>&', \*STDOUT or die "cannot keep STDOUT: $!";
    open my $keep_err, '>&', \*STDERR or die "cannot keep STDERR: $!";
    close STDOUT;
    close STDERR;
    open STDOUT, '>', \$out or die "cannot redirect STDOUT: $!";
    open STDERR, '>', \$err or die "cannot redirect STDERR: $!";
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    $watching = 1;
    for my $i (1 .. 40) {
        my $game = Game::RoyalUr->new(
            seed => "no io $i",
            ($i % 2 ? (rules => 'masters') : ()),
            ($i % 3 ? (first => ($i % 2 ? 'light' : 'dark')) : ()),
            ($i % 7 == 0 ? (rules => { route => 'long', pieces => 4 }) : ()),
        );
        $games++;
        my $pick = 0;
        until ($game->is_over) {
            my @moves = $game->legal;
            $refusals++ unless $game->play('a1-h3');
            $refusals++ unless $game->play('nonsense');
            my @asked = ($game->side, $game->roll, $game->throw, $game->position, $game->key, $game->ply,
                $game->rolls, $game->first, $game->opening, $game->variant->describe, $game->seed,
                $game->hand('light'), $game->home('dark'), $game->at('d2'), $game->chances, $game->log,
                $game->forfeits_since(0), $game->error);
            $game->play($moves[ $pick++ % @moves ]);
            $plies++;
            if ($pick % 17 == 0) { $game->undo; $game->play(($game->legal)[0]) }
            if ($i % 10 == 0 && $game->ply > 60) { $game->resign; last }
        }
        my $result = $game->result;
        my @said = ($result->winner, $result->loser, $result->how, $result->final, $result->home, $result->plies, $result->is_draw);
        my $text = $game->to_record;
        my ($again, $error) = Game::RoyalUr->replay($text);
        $replays++ if $again;
        my ($none, $why) = Game::RoyalUr->replay("junk\n");
        my @errors = ($why->code, $why->message, $why->detail);
        my ($record) = parse_record($text);
        format_record($record);
        validate_position($game->position);
        my $rules = Game::RoyalUr::Rules->new(rules => 'masters');
        $rules->apply(($rules->moves(2))[0]);
        $rules->undo;
        Game::RoyalUr::Engine->new->walk(2, 'finkel');
        opening_for("no io $i", 3);
    }
    $watching = 0;

    close STDOUT;
    close STDERR;
    open STDOUT, '>&', $keep_out or die "cannot restore STDOUT: $!";
    open STDERR, '>&', $keep_err or die "cannot restore STDERR: $!";
    untie %ENV;
    %ENV = %real;
}

cmp_ok($games, '==', 40, 'forty games were played');
cmp_ok($plies, '>', 3_000, "over $plies plies");
cmp_ok($refusals, '>', 6_000, "with $refusals moves refused on the way");
is($replays, 40, 'and every one replayed from its record');

is($out, '', 'nothing was printed');
is($err, '', 'nothing was written to STDERR');
is(scalar @warnings, 0, 'nothing warned') or diag(@warnings[0 .. ($#warnings > 3 ? 3 : $#warnings)]);
is($called{$_} || 0, 0, "$_ was never called") for qw(open sysopen opendir rand srand time);
is($called{env} || 0, 0, 'and %ENV was never read');

# THE CHECK CHECKS. Each counter is seen to count, here, with the watch on, so
# that a zero above is a zero and not a deaf instrument.
{
    $watching = 1;
    %called = ();
    my %real = %ENV;
    tie %ENV, 'Local::Env';
    %ENV = %real;
    my @noise = (rand(), time, exists $ENV{PATH}, $ENV{HOME});
    srand(1);
    my ($dir, $fh);
    closedir($dir) if opendir($dir, '.');
    close($fh) if open($fh, '<', $0);
    untie %ENV;
    %ENV = %real;
    $watching = 0;
}
cmp_ok($called{$_} || 0, '>', 0, "(and $_ is counted when it is called)") for qw(open opendir rand srand time env);

done_testing();
