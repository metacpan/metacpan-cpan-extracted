use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Engine ':all';
my $E = 'Game::RoyalUr::Engine';

# What the key is MEANT to stand for, built here from the reads and not from
# the key: every cell, the two homes, the side to move. Not the hands.
sub signature {
    my ($bd) = @_;
    return join '', (map { $bd->at($_) } $E->all_cells),
        '/', $bd->home(SIDE_LIGHT), $bd->home(SIDE_DARK), $bd->side;
}

# A consistent position of seven a side that nobody chose.
sub random_position {
    my $bd = $E->new;
    my @cells = sort { rand() <=> rand() } $E->all_cells;
    for my $side (SIDE_LIGHT, SIDE_DARK) {
        my $on   = int rand 8;
        my $home = int rand(8 - $on);
        $bd->put(shift @cells, piece_of($side)) for 1 .. $on;
        $bd->set_home($side, $home)->set_hand($side, 7 - $on - $home);
    }
    $bd->set_side(int rand 2);
    return $bd;
}

subtest 'the key is twelve hex characters' => sub {
    like($E->new->key_hex, qr/\A[0-9a-f]{12}\z/, 'for the empty board');
    my ($full) = $E->of_string('ddddxxdd/dddddddd/ddddxxdd d 0 7 0 7');
    like($full->key_hex, qr/\A[0-9a-f]{12}\z/, 'and for the fullest position there is');
    is(length($full->key_hex), 12, 'and no longer for being full');
};

# PINNED. A change to how the key is packed changes every key, and anything
# that ever stored one would then compare a new key with an old.
subtest 'what the parts of a key are worth' => sub {
    is($E->new->key_hex, '000000000000', 'nothing on the board, nothing home, light to move');
    is($E->new->set_side(SIDE_DARK)->key_hex,     '400000000000', 'dark to move');
    is($E->new->set_home(SIDE_LIGHT, 1)->key_hex, '010000000000', 'one light piece home');
    is($E->new->set_home(SIDE_LIGHT, 7)->key_hex, '070000000000', 'seven light pieces home');
    is($E->new->set_home(SIDE_DARK, 1)->key_hex,  '080000000000', 'one dark piece home');
    is($E->new->set_home(SIDE_DARK, 7)->key_hex,  '380000000000', 'seven dark pieces home');
    my ($full) = $E->of_string('ddddxxdd/dddddddd/ddddxxdd d 0 7 0 7');
    is($full->key_hex, '7faaaaaaaaaa', 'and everything at once');
};

subtest 'one piece on one cell, forty ways' => sub {
    my %seen;
    for my $cell ($E->all_cells) {
        for my $piece (LIGHT, DARK) {
            $seen{ $E->new->put($cell, $piece)->key_hex }++;
        }
    }
    is(scalar(keys %seen), 40, 'forty different keys');
    ok(!$seen{'000000000000'}, 'none of them the empty board');
    is(scalar(grep { $_ > 1 } values %seen), 0, 'and none twice');
};

# THE HANDS ARE NOT IN THE KEY, ON PURPOSE. In a position where each side's
# pieces add up, the hands follow from the cells and the homes, so two boards
# that differ only in a hand are not two positions of this game.
subtest 'the hands are left out, and that is chosen' => sub {
    my $bd = $E->new;
    my $key = $bd->key_hex;
    $bd->set_hand(SIDE_LIGHT, 3)->set_hand(SIDE_DARK, 0);
    is($bd->key_hex, $key, 'two different hands, one key');
    isnt($bd->to_string, $E->new->to_string, 'though the position string tells them apart');
};

subtest 'ten thousand positions: one key each, and each key one position' => sub {
    srand(20261009);
    my (%key_of, %sig_of, @bad);
    for my $n (1 .. 10_000) {
        my $bd = random_position();
        push @bad, 'a random position was not consistent' unless $bd->consistent(7);
        my ($sig, $key) = (signature($bd), $bd->key_hex);
        push @bad, "$sig has two keys" if exists $key_of{$sig} && $key_of{$sig} ne $key;
        push @bad, "$key stands for two positions" if exists $sig_of{$key} && $sig_of{$key} ne $sig;
        $key_of{$sig} = $key;
        $sig_of{$key} = $sig;
    }
    is(scalar @bad, 0, 'no position with two keys and no key with two positions')
        or diag(join "\n", @bad[0 .. ($#bad > 5 ? 5 : $#bad)]);
    cmp_ok(scalar(keys %key_of), '>', 9_900, 'and nearly all of them were different positions');
};

subtest 'the key follows every part it is made of' => sub {
    srand(42);
    my @bad;
    for my $n (1 .. 300) {
        my $bd = random_position();
        my $key = $bd->key_hex;

        my $turned = $bd->clone->set_side(other($bd->side));
        push @bad, 'the side to move did not change the key' if $turned->key_hex eq $key;

        for my $side (SIDE_LIGHT, SIDE_DARK) {
            my $moved = $bd->clone->set_home($side, ($bd->home($side) + 1) % 8);
            push @bad, "side $side home did not change the key" if $moved->key_hex eq $key;
        }

        my $cell = int rand 20;
        my $swapped = $bd->clone->put($cell, ($bd->at($cell) + 1) % 3);
        push @bad, "cell $cell did not change the key" if $swapped->key_hex eq $key;

        push @bad, 'a clone has a different key' unless $bd->clone->key_hex eq $key;
        my ($again) = $E->of_string($bd->to_string);
        push @bad, 'the position string lost the key' unless $again->key_hex eq $key;
    }
    is(scalar @bad, 0, 'the side, each home and a cell, over three hundred positions')
        or diag(join "\n", @bad[0 .. ($#bad > 5 ? 5 : $#bad)]);
};

subtest 'a put on a copy leaves the original key alone' => sub {
    my $bd = $E->new;
    my $key = $bd->key_hex;
    my $copy = $bd->clone;
    $copy->put(0, LIGHT)->set_home(SIDE_DARK, 3);
    is($bd->key_hex, $key, 'the original has not moved');
    isnt($copy->key_hex, $key, 'and the copy has');
};

done_testing();
