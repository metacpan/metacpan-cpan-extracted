use strict;
use warnings;
use Test::More;

use Game::Senet;
use Game::Senet::Variant;
my $V = 'Game::Senet::Variant';

# THE NAMED SETS, FIELD BY FIELD, from plan_game_senet/06's table.
my %TABLE = (
    kendall => { exits => 'kendall', pieces => 5, blockade => 3, protect => 'run',
                 backward => 1, reach26 => 'exact', throw_on_26 => 0 },
    skyruk  => { exits => 'skyruk', pieces => 5, blockade => 2, protect => 'ends',
                 backward => 1, reach26 => 'any', throw_on_26 => 1 },
);

# AND THEIR EXITS, from 00's two tables: each house 26 to 30, each roll 1 to 5.
my %EXITS = (
    kendall => {
        26 => [ ['walk'], [28], [29], [30], ['off'] ],
        27 => [ [], [], [], [], [] ],
        28 => [ [], [], ['off'], [], [] ],
        29 => [ [], ['off'], [], [], [] ],
        30 => [ ['off'], [], [], [], [] ],
    },
    skyruk => {
        26 => [ [27, 'walk'], [28, 27, 'walk'], [29, 27, 'walk'], [30, 27, 'walk'], ['off'] ],
        27 => [ ['walk'], ['walk'], ['walk'], ['off'], ['stay'] ],
        28 => [ [], [], ['off'], [], [] ],
        29 => [ [], ['off'], [], [], [] ],
        30 => [ ['off'], ['off'], ['off'], ['off'], ['off'] ],
    },
);

for my $name (sort keys %TABLE) {
    subtest "$name, field by field and exit by exit" => sub {
        my $v = $V->named($name);
        is($v->$_, $TABLE{$name}{$_}, "$_") for $V->fields;
        is($v->name, $name, 'its name');
        is($v->describe, $name, 'and its description');
        for my $house (26 .. 30) {
            for my $roll (1 .. 5) {
                is_deeply($v->exit_for($house, $roll), $EXITS{$name}{$house}[$roll - 1], "house $house, roll $roll");
            }
        }
    };
}

subtest 'values outside the table croak' => sub {
    for my $bad ([ pieces => 6 ], [ pieces => 4 ], [ blockade => 1 ], [ blockade => 4 ], [ protect => 'all' ],
                 [ reach26 => 'never' ], [ backward => 2 ], [ throw_on_26 => -1 ], [ exits => 'bell' ]) {
        ok(!eval { $V->custom(@$bad); 1 }, "@$bad croaks");
        like($@, qr/\Q$bad->[0]\E may not be/, '  naming the field');
    }
    ok(!eval { $V->custom(blokade => 2); 1 }, 'custom refuses a key that is not a field');
    like($@, qr/no rule is called 'blokade'/, '  naming it');
    ok(!eval { $V->named('masters'); 1 }, 'a name that is not a set croaks');
    like($@, qr/the names are kendall, skyruk/, '  listing the names');
    ok(!eval { $V->exit_for(25, 1) }, 'exit_for asks a house from 26');
};

subtest 'pieces is not part of a set\'s name' => sub {
    my $seven = $V->named('kendall', pieces => 7);
    is($seven->pieces, 7, 'seven pieces');
    is($seven->name, 'kendall', 'still kendall');
    is($seven->describe, 'kendall pieces=7', 'and described with its pieces');
    ok(!$seven->equals($V->named('kendall')), 'but not equal to five-piece kendall');
    ok($seven->equals($V->named('kendall', pieces => 7)), 'and equal to itself');
    ok(!eval { $V->named('kendall', blockade => 2); 1 }, 'named takes pieces and nothing else');
    like($@, qr/takes pieces and nothing else/, '  and says so');
};

subtest 'of, as_hash' => sub {
    is($V->of(undef)->name, 'kendall', 'undef is kendall');
    is($V->of('skyruk')->name, 'skyruk', 'a name');
    is($V->of({ exits => 'skyruk', protect => 'ends', blockade => 2, reach26 => 'any', throw_on_26 => 1 })->name,
        'skyruk', 'a hash that spells skyruk is named skyruk');
    my $v = $V->named('skyruk');
    is($V->of($v), $v, 'a variant is itself');
    is_deeply($v->as_hash, $TABLE{skyruk}, 'as_hash');
};

my %UNNAMED = (
    'kendall exits with a blockade of two' => { exits => 'kendall', blockade => 2 },
    'skyruk exits with protect => run'     => { exits => 'skyruk', protect => 'run', blockade => 2,
                                                reach26 => 'any', throw_on_26 => 1 },
    'the masters row, unnamed'             => { exits => 'kendall', protect => 'none', blockade => 0, backward => 0 },
);

for my $what (sort keys %UNNAMED) {
    subtest "$what: constructs and plays a whole game" => sub {
        my $v = $V->custom(%{ $UNNAMED{$what} });
        is($v->name, undef, 'it has no name');
        like($v->describe, qr/\Aexits=/, 'and describes every field');
        my $g = Game::Senet->new(seed => "unnamed $what", rules => $v);
        my $n = 0;
        while (!$g->is_over && $n < 5_000) {
            my @m = $g->legal;
            $g->play($m[ $n++ % @m ]) or last;
        }
        ok($g->is_over, "over after $n plays");
        is($g->result->how, 'home', 'by bearing off');
    };
}

done_testing();
