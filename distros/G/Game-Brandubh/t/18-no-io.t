use strict;
use warnings;

# A GAME WRITES NOTHING AND OPENS NOTHING. The classes that play brandubh are
# for a server to hold in memory and a terminal to wrap; neither wants a rules
# engine that prints, warns or touches the disk. The terminal is the one place
# in this distribution allowed to do any of that, and it is not loaded here.
#
# open, sysopen and opendir are replaced before anything is compiled, so a call
# from any of the modules lands in the counters below. Once the modules are
# loaded, STDOUT and STDERR are pointed at two strings, a batch of games is
# played through every public method, and both strings must be empty and all
# three counters zero.

my (%opened, $watching);
BEGIN {
    no warnings 'redefine';
    *CORE::GLOBAL::open = sub (*;$@) {
        $opened{open}++ if $watching;
        # a bareword handle arrives as its name and belongs to the caller's
        # package; anything else is passed on as the very variable it came in,
        # so that `open my $fh` still fills the caller's $fh
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
        $opened{sysopen}++ if $watching;
        return @_ == 3 ? CORE::sysopen($_[0], $_[1], $_[2]) : CORE::sysopen($_[0], $_[1], $_[2], $_[3]);
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        $opened{opendir}++ if $watching;
        return CORE::opendir($_[0], $_[1]);
    };
}

use Test::More;
use Game::Brandubh;
use Game::Brandubh::Variant;
use Game::Brandubh::Notation qw(:all);
use Game::Brandubh::Engine ();
use Game::Brandubh::Rules ();

ok(!exists $INC{'Game/Brandubh/Terminal.pm'}, 'the terminal is not loaded');

my ($out, $err) = ('', '');
my @warnings;
my ($games, $plies, $refusals) = (0, 0, 0);

{
    open my $keep_out, '>&', \*STDOUT or die "cannot keep STDOUT: $!";
    open my $keep_err, '>&', \*STDERR or die "cannot keep STDERR: $!";
    close STDOUT;
    close STDERR;
    open STDOUT, '>', \$out or die "cannot redirect STDOUT: $!";
    open STDERR, '>', \$err or die "cannot redirect STDERR: $!";
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    $watching = 1;
    my $state = 1818;
    my $roll = sub { $state = ($state * 1103515245 + 12345) % 2147483648; int($state / 65536) % $_[0] };

    for my $i (1 .. 40) {
        my $g = Game::Brandubh->new(
            attackers => ($i % 2 ? 'p1' : 'p2'),
            ($i % 3 == 0 ? (variant => { repeat => 2, ply_cap => 90 }) : ()),
            ($i % 5 == 0 ? (seed => 'k' x 32) : ()),
        );
        my $took_back = 0;
        while ($g->status eq 'active') {
            my $legal = $g->legal;
            $refusals++ if $g->play('a4a7');
            $refusals++ if $g->play('zz', 'p3');
            $g->play($legal->[ $roll->(scalar @$legal) ]{move});
            $plies++;
            my @read = ($g->turn, $g->side_to_move, $g->position, $g->signature, $g->repeats, $g->ply,
                        $g->at('d4'), $g->pieces, $g->log, $g->shown, $g->seed, $g->draw_offered_by);
            # ONCE a game. Without the flag this takes two moves back at ply 7,
            # plays up to ply 7 again and takes them back again, for ever: the
            # first version of this file did exactly that.
            if ($g->ply == 7 && !$took_back++) {
                $g->offer_draw('p1');
                $g->decline_draw('p2');
                $g->undo;
                $g->undo;
            }
            $g->resign('p2') if $i % 9 == 0 && $g->ply > 20 && $g->status eq 'active';
        }
        my $r = $g->result;
        my @said = ($r->how, $r->winner, $r->seat, $r->loser, $r->is_draw, $r->by_players, $r->ply, $r->position);
        my $text = $g->as_text;
        my $again = Game::Brandubh->from_text($text);
        my $replayed = $g->replay($g->log);
        my $variant = Game::Brandubh::Variant->from_string($g->variant->as_string);
        $games++;
    }
    $watching = 0;

    close STDOUT;
    close STDERR;
    open STDOUT, '>&', $keep_out or die "cannot restore STDOUT: $!";
    open STDERR, '>&', $keep_err or die "cannot restore STDERR: $!";
}

is($games, 40, 'forty games were played to their end');
cmp_ok($plies, '>', 1500, "$plies moves");
cmp_ok($refusals, '>', 1500, "$refusals refusals, which are not errors and print nothing either");
is($out, '', 'nothing was written to STDOUT');
is($err, '', 'nothing was written to STDERR');
is(scalar(@warnings), 0, 'nothing warned') or diag(@warnings);
is($opened{open} // 0, 0, 'open was never called');
is($opened{sysopen} // 0, 0, 'sysopen was never called');
is($opened{opendir} // 0, 0, 'opendir was never called');

# and the instrument is checked, so that zero means zero and not "not looking"
{
    $watching = 1;
    open my $probe, '<', $0 or die "cannot open this file: $!";
    close $probe;
    $watching = 0;
    is($opened{open}, 1, 'an open made on purpose is counted, so the three zeros above are real');
}

done_testing();
