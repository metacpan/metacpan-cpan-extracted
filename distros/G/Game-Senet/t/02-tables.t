use strict;
use warnings;
use Test::More;

use Game::Senet::Engine ':all';
my $E = 'Game::Senet::Engine';

# BOTH NAMED SETS, WRITTEN OUT FIELD BY FIELD AND CHAIN BY CHAIN, from
# plan_game_senet/00-overview.md and the table in plan_game_senet/01. A test
# that read the sets from the engine and compared them with the engine would
# pass for any table. A chain is what a piece standing on that house may do
# with that roll, tried in order; an empty one is not a move.
my %KENDALL = (
    pieces      => 5,
    blockade    => 3,
    protect     => 'run',
    backward    => 1,
    reach26     => 'exact',
    throw_on_26 => 0,
    safe        => [ 15, 26, 28, 29, 30 ],
    exits       => {
        26 => { 1 => ['walk'], 2 => [28], 3 => [29], 4 => [30], 5 => ['off'] },
        27 => { 1 => [], 2 => [], 3 => [], 4 => [], 5 => [] },
        28 => { 1 => [], 2 => [], 3 => ['off'], 4 => [], 5 => [] },
        29 => { 1 => [], 2 => ['off'], 3 => [], 4 => [], 5 => [] },
        30 => { 1 => ['off'], 2 => [], 3 => [], 4 => [], 5 => [] },
    },
);

my %SKYRUK = (
    pieces      => 5,
    blockade    => 2,
    protect     => 'ends',
    backward    => 1,
    reach26     => 'any',
    throw_on_26 => 1,
    safe        => [ 15, 26, 27, 28, 29, 30 ],
    exits       => {
        26 => {
            1 => [27, 'walk'],
            2 => [28, 27, 'walk'],
            3 => [29, 27, 'walk'],
            4 => [30, 27, 'walk'],
            5 => ['off'],
        },
        27 => { 1 => ['walk'], 2 => ['walk'], 3 => ['walk'], 4 => ['off'], 5 => ['stay'] },
        28 => { 1 => [], 2 => [], 3 => ['off'], 4 => [], 5 => [] },
        29 => { 1 => [], 2 => ['off'], 3 => [], 4 => [], 5 => [] },
        30 => { 1 => ['off'], 2 => ['off'], 3 => ['off'], 4 => ['off'], 5 => ['off'] },
    },
);

subtest 'kendall, by name and by number' => sub {
    is_deeply($E->rules('kendall'), \%KENDALL, 'rules("kendall") is the table written here');
    is_deeply($E->rules_named(RULES_KENDALL), \%KENDALL, 'and so is rules_named(RULES_KENDALL)');
    is_deeply($E->rules(undef), \%KENDALL, 'and undef means kendall');
    is($E->rules_id('kendall'), RULES_KENDALL, 'rules_id knows the name');
};

subtest 'skyruk, by name and by number' => sub {
    is_deeply($E->rules('skyruk'), \%SKYRUK, 'rules("skyruk") is the table written here');
    is_deeply($E->rules_named(RULES_SKYRUK), \%SKYRUK, 'and so is rules_named(RULES_SKYRUK)');
    is($E->rules_id('skyruk'), RULES_SKYRUK, 'rules_id knows the name');
};

subtest 'a name that is not a set' => sub {
    is($E->rules_named(2), undef, 'rules_named with a third number answers nothing');
    is($E->rules_named(-1), undef, 'nor with -1');
    is($E->rules_id('masters'), -1, 'masters is not a set in this build');
    is($E->rules_id('Kendall'), -1, 'and a name is matched exactly');
    ok(!eval { $E->rules('bell'); 1 }, 'rules("bell") croaks');
    like($@, qr/no rule set is called 'bell'/, 'naming the set');
};

subtest 'the safe houses differ in exactly one' => sub {
    my %k = map { $_ => 1 } @{ $KENDALL{safe} };
    my %s = map { $_ => 1 } @{ $SKYRUK{safe} };
    my @only = grep { !($k{$_} && $s{$_}) } sort { $a <=> $b } keys %{ { %k, %s } };
    is("@only", '27', 'kendall and skyruk disagree only about the house of water');
};

subtest 'a hash of what differs' => sub {
    my $r = $E->rules({ protect => 'none', blockade => 0, backward => 0 });
    is($r->{protect}, 'none', 'protect overridden');
    is($r->{blockade}, 0, 'blockade overridden');
    is($r->{backward}, 0, 'backward overridden');
    is_deeply($r->{exits}, $KENDALL{exits}, 'and the chains are still kendall\'s');

    my $s = $E->rules({ exits => 'skyruk', pieces => 7 });
    is($s->{pieces}, 7, 'pieces overridden');
    is_deeply($s->{exits}, $SKYRUK{exits}, 'on skyruk\'s chains');
    is_deeply($s->{safe}, $SKYRUK{safe}, 'and skyruk\'s safe houses');
    is($s->{blockade}, 2, 'and skyruk\'s scalars where not overridden');

    my $t = $E->rules({ reach26 => 'any', throw_on_26 => 1 });
    is($t->{reach26}, 'any', 'reach26 overridden');
    is($t->{throw_on_26}, 1, 'throw_on_26 overridden');

    for my $bad (
        [ { blockdae => 3 },        qr/no rule is called 'blockdae'/ ],
        [ { exits => 'bell' },      qr/exits names a rule set/ ],
        [ { protect => 'all' },     qr/protect is 'none', 'run' or 'ends'/ ],
        [ { reach26 => 'never' },   qr/reach26 is 'exact' or 'any'/ ],
        [ { pieces => 8 },          qr/pieces is 1 to 7/ ],
        [ { pieces => 0 },          qr/pieces is 1 to 7/ ],
        [ { blockade => 1 },        qr/blockade is 0, 2 or 3/ ],
        [ { backward => 2 },        qr/backward and throw_on_26 are 0 or 1/ ],
        [ { throw_on_26 => -1 },    qr/backward and throw_on_26 are 0 or 1/ ],
    ) {
        my ($hash, $re) = @$bad;
        ok(!eval { $E->rules($hash); 1 }, 'croaks: ' . join(',', %$hash));
        like($@, $re, 'with the right sentence');
    }
    ok(!eval { $E->rules([]); 1 }, 'an array reference is not a rule set');
};

# ---- rules_ok, on structs written for it ----------------------------------------

sub flat_chains {
    my ($exits) = @_;
    my %code = (off => X_OFF, walk => X_WALK, stay => X_STAY);
    my @flat;
    for my $h (26 .. 30) {
        for my $roll (1 .. 5) {
            my @c = map { $code{$_} // $_ } @{ $exits->{$h}{$roll} };
            push @c, X_END while @c < CHAIN_MAX;
            push @flat, @c;
        }
    }
    return \@flat;
}

sub safe_mask {
    my $m = 0;
    $m |= 1 << $_ for @_;
    return $m;
}

sub ok_raw {
    my (%f) = @_;
    my %r = (
        pieces => 5, blockade => 3, protect => PROTECT_RUN, backward => 1,
        reach26 => REACH_EXACT, throw_on_26 => 0,
        safe => safe_mask(@{ $KENDALL{safe} }),
        chains => flat_chains($KENDALL{exits}),
        reserved => 0,
        %f,
    );
    return Game::Senet::Engine::_rules_ok_raw(
        @r{qw(pieces blockade protect backward reach26 throw_on_26 safe chains reserved)});
}

subtest 'rules_ok refuses each field out of range' => sub {
    ok(ok_raw(), 'kendall written by hand is ok');
    ok(ok_raw(safe => safe_mask(@{ $SKYRUK{safe} }), chains => flat_chains($SKYRUK{exits}),
              blockade => 2, protect => PROTECT_ENDS, reach26 => REACH_ANY, throw_on_26 => 1),
       'and so is skyruk');
    ok(ok_raw(protect => PROTECT_NONE, blockade => 0, backward => 0),
       'and so is a set nobody plays: rules_ok does not judge sense');

    ok(!ok_raw(pieces => 0), 'pieces 0');
    ok(!ok_raw(pieces => 8), 'pieces 8');
    ok(!ok_raw(blockade => 1), 'blockade 1');
    ok(!ok_raw(blockade => 4), 'blockade 4');
    ok(!ok_raw(protect => 3), 'protect 3');
    ok(!ok_raw(protect => -1), 'protect -1');
    ok(!ok_raw(backward => 2), 'backward 2');
    ok(!ok_raw(reach26 => 2), 'reach26 2');
    ok(!ok_raw(throw_on_26 => 2), 'throw_on_26 2');
    ok(!ok_raw(reserved => 1), 'a reserved int that is not 0');
};

subtest 'rules_ok refuses a safe mask outside the houses' => sub {
    ok(!ok_raw(safe => safe_mask(0, 15)), 'bit 0, which is not a house');
    ok(!ok_raw(safe => safe_mask(15, 31)), 'bit 31, which is not a house');
    ok(ok_raw(safe => 0), 'no safe house at all is a value it may hold');
    ok(ok_raw(safe => safe_mask(1 .. 30)), 'and so is every house');
};

subtest 'rules_ok refuses a chain entry that is none of the five kinds' => sub {
    my $c = flat_chains($KENDALL{exits});
    my @bad = @$c;  $bad[0] = 34;
    ok(!ok_raw(chains => \@bad), 'an entry of 34');
    @bad = @$c;     $bad[0] = -1;
    ok(!ok_raw(chains => \@bad), 'an entry of -1');
    @bad = @$c;     $bad[2] = 28;
    ok(!ok_raw(chains => \@bad), 'an entry after SEN_X_END');
    @bad = @$c;     $bad[5 * 5 * 4 - 1] = X_OFF;
    ok(!ok_raw(chains => \@bad), 'and one in the very last place, after an END');
    @bad = @$c;     $bad[2] = 30;
    ok(!ok_raw(chains => \@bad), 'and a house after an END is no better');
    @bad = @$c;     @bad[0, 1, 2, 3] = (27, 28, 29, X_WALK);
    ok(ok_raw(chains => \@bad), 'a chain four long is a value it may hold');
};

done_testing();
