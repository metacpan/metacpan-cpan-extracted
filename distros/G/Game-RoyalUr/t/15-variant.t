use strict;
use warnings;
use Test::More;

use Game::RoyalUr;
use Game::RoyalUr::Variant;
use Game::RoyalUr::Engine ();
my $V = 'Game::RoyalUr::Variant';

# THE TABLE, TYPED OUT. These ten values are the two named sets, and nothing
# else in this file says what they are.
my %WANT = (
    finkel  => { route => 'short', dice => 4, zero_rolls => 0, safe_rosettes => 1, pieces => 7 },
    masters => { route => 'long',  dice => 3, zero_rolls => 4, safe_rosettes => 0, pieces => 7 },
);

subtest 'the two named sets, field by field' => sub {
    is(join(' ', $V->names), 'finkel masters', 'the names');
    is(join(' ', $V->fields), 'route dice zero_rolls safe_rosettes pieces', 'the fields, in their order');
    for my $name (sort keys %WANT) {
        my $variant = $V->named($name);
        is($variant->$_, $WANT{$name}{$_}, "$name: $_ is $WANT{$name}{$_}") for $V->fields;
        is_deeply($variant->as_hash, $WANT{$name}, "$name: as a hash");
        is($variant->name, $name, "$name: and it knows its name");
    }
    is_deeply(Game::RoyalUr::Engine->rules($_), $WANT{$_}, "the engine means the same by $_") for sort keys %WANT;
};

subtest 'a name that is not one' => sub {
    ok(!eval { $V->named('bell'); 1 }, 'croaks');
    like($@, qr/the names are finkel, masters/, 'and lists the two');
    ok(!eval { $V->named(undef); 1 }, 'so does no name');
    ok(!eval { Game::RoyalUr->new(seed => 's', rules => 'bell'); 1 }, 'and the game says the same');
    like($@, qr/the names are finkel, masters/, 'in the same words');
};

subtest 'a value a field may not hold' => sub {
    my @bad = (
        [ dice => 2 ], [ dice => 5 ], [ dice => 'four' ], [ pieces => 0 ], [ pieces => 8 ],
        [ zero_rolls => 2 ], [ zero_rolls => 1 ], [ safe_rosettes => 2 ], [ safe_rosettes => 'yes' ],
        [ route => 'medium' ], [ route => undef ], [ dice => [ 4 ] ],
    );
    for my $case (@bad) {
        my ($field, $value) = @$case;
        my $shown = defined $value ? $value : 'undef';
        ok(!eval { $V->new($field => $value); 1 }, "new($field => $shown) croaks");
        ok(!eval { $V->custom($field => $value); 1 }, "and so does custom");
    }
    like($@, qr/may not be/, 'with a sentence');
};

subtest 'custom refuses a rule that does not exist' => sub {
    ok(!eval { $V->custom(safe_rosette => 0); 1 }, 'a misspelt rule croaks');
    like($@, qr/no rule is called 'safe_rosette'/, 'and is named');
    ok(!eval { Game::RoyalUr->new(seed => 's', rules => { safe_rosette => 0 }); 1 }, 'through the game as well');
    is($V->custom->name, 'finkel', 'and no rules at all is finkel');
};

subtest 'of takes whatever a caller has' => sub {
    is($V->of(undef)->name, 'finkel', 'undef is finkel');
    is($V->of('masters')->name, 'masters', 'a name');
    is($V->of({ pieces => 5 })->pieces, 5, 'a hash of what differs');
    my $variant = $V->named('masters');
    is($V->of($variant), $variant, 'and a variant is handed back as it is');
    ok(!eval { $V->of([ 'finkel' ]); 1 }, 'an array is none of those');
};

subtest 'a variant with no name' => sub {
    my $variant = $V->custom(route => 'long', safe_rosettes => 1);
    is($variant->name, undef, 'long and safe is nobody\'s set');
    is($variant->describe, 'route=long dice=4 zero_rolls=0 safe_rosettes=1 pieces=7', 'so it is spelled out');
    is($variant->dice, 4, 'what was not given is finkel\'s');
    is($V->custom(%{ $WANT{masters} })->name, 'masters', 'the five values of masters ARE masters, however it was made');
    is($V->named('finkel')->describe, 'route=short dice=4 zero_rolls=0 safe_rosettes=1 pieces=7', 'a named set can be spelled out too');
};

subtest 'equals' => sub {
    ok($V->named('finkel')->equals($V->custom), 'finkel equals no rules at all');
    ok(!$V->named('finkel')->equals($V->named('masters')), 'and not masters');
    ok(!$V->named('finkel')->equals($V->custom(pieces => 6)), 'nor finkel with six pieces');
    ok(!$V->named('finkel')->equals('finkel'), 'nor a string');
    ok(!$V->named('finkel')->equals(undef), 'nor nothing');
};

subtest 'a variant is not changed' => sub {
    my $variant = $V->named('finkel');
    ok(!eval { $variant->dice(3); 1 }, 'a field cannot be written');
    is($variant->dice, 4, 'and it has not been');
    my $hash = $variant->as_hash;
    $hash->{dice} = 3;
    is($variant->dice, 4, 'nor through the hash it hands out');
};

# THE FOUR COMBINATIONS OF ROUTE AND SAFETY, played. Two have names and two do
# not. The position is the same for all four: a light piece on g2 about to
# step onto g3, where a dark piece stands. On the long route g3 is a rosette on
# light's way; on the short route light never goes there.
subtest 'route and safety, all four ways' => sub {
    my $position = '4xxd1/6l1/4xx2 l 6 0 6 0';
    my %want = (
        'short 1' => 'hand-d1 g2-h2',
        'short 0' => 'hand-d1 g2-h2',
        'long 1'  => 'hand-d1',
        'long 0'  => 'hand-d1 g2-g3',
    );
    for my $key (sort keys %want) {
        my ($route, $safe) = split ' ', $key;
        my $game = Game::RoyalUr->new(script => [ { roll => 1 } ], first => 'light', position => $position,
            rules => { route => $route, safe_rosettes => $safe });
        is(join(' ', map { $_->from . '-' . $_->to } $game->legal), $want{$key},
            "$route route, safe_rosettes $safe: a roll of 1");
    }
    my $long_safe = Game::RoyalUr->new(script => [ { roll => 1 } ], first => 'light', position => $position,
        rules => { route => 'long', safe_rosettes => 1 });
    ok(!$long_safe->play('g2-g3'), 'LONG AND SAFE PROTECTS g3: the capture is refused');
    is($long_safe->error->code, 'safe_rosette', 'as a safe rosette, though g3 is not the middle one');
};

subtest 'three pieces a side is a whole game' => sub {
    my $game = Game::RoyalUr->new(seed => 'three a side', rules => { pieces => 3 });
    is($game->hand('light') + $game->hand('dark'), 6, 'three in each hand');
    my $turns = 0;
    until ($game->is_over) {
        my @moves = $game->legal;
        $game->play($moves[-1]) or die $game->error->code;
        die 'this game is not ending' if ++$turns > 2_000;
    }
    is($game->result->how, 'home', 'it ends with somebody home');
    is($game->home($game->result->winner), 3, 'with all three');
    is($game->variant->name, undef, 'and the game\'s variant has no name');
};

done_testing();
