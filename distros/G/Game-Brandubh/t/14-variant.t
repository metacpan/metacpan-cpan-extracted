use strict;
use warnings;
use Test::More;

use Game::Brandubh::Variant;
use Game::Brandubh::Rules ();
my $V = 'Game::Brandubh::Variant';

sub dies_like {
    my ($code, $pattern, $why) = @_;
    my $lived = eval { $code->(); 1 };
    ok(!$lived, "$why: croaks");
    like($@, $pattern, 'and says why');
}

subtest 'the default rule set, field by field' => sub {
    my $v = $V->named('brandubh');
    is($v->name, 'brandubh', 'it is called brandubh');
    is($v->escape, 'corner', 'the king wins on a corner');
    is($v->king_everywhere_two, 0, 'he is not taken by two on the throne');
    is($v->king_strong, 0, 'nor does he need every side closed');
    is($v->throne_reentry, 0, 'he may not return to the throne');
    is($v->throne_pass, 1, 'a piece may slide across the empty throne');
    is($v->repeat, 3, 'the third occurrence of a position draws');
    is($v->ply_cap, 400, 'and four hundred moves');
    is($v->as_string, 'brandubh', 'written as its name');
    ok($V->named->equals($v), 'named with no argument is the same set');
    is_deeply([ $V->names ], ['brandubh'], 'it is the only set with a name');
    is_deeply([ $V->fields ],
        [qw(escape king_everywhere_two king_strong throne_reentry throne_pass repeat ply_cap)],
        'seven fields');
};

# The facade hands as_hash to the engine. If the two disagreed about what the
# default game is, a game made with no variant and one made with the default
# variant would be different games.
subtest 'the default here is the default of the engine' => sub {
    is_deeply($V->named->as_hash, Game::Brandubh::Rules->new->variant,
        'as_hash of the default is what a game with no variant plays');
    my $custom = $V->custom(escape => 'edge', repeat => 2, ply_cap => 60, throne_reentry => 1, throne_pass => 0);
    is_deeply(Game::Brandubh::Rules->new(variant => $custom->as_hash)->variant, $custom->as_hash,
        'and a custom set goes into a game and comes back the same');
};

subtest 'custom' => sub {
    my $v = $V->custom(repeat => 2, throne_reentry => 1);
    is($v->name, 'custom', 'a set that differs is called custom');
    is($v->repeat, 2, 'with the field it was given');
    is($v->throne_reentry, 1, 'and the other');
    is($v->ply_cap, 400, 'and every field left out at its default');
    is($v->as_string, 'custom throne_reentry=1,repeat=2', 'written as the fields that differ, in field order');

    is($V->custom->name, 'brandubh', 'custom with nothing is the default, and carries its name');
    is($V->custom(repeat => 3, escape => 'corner')->name, 'brandubh',
        'so does custom given the default\'s own values');
    is($V->custom(king_strong => 1)->as_string, 'custom king_strong=1', 'the strong king');
    is($V->custom(king_everywhere_two => 1)->as_string, 'custom king_everywhere_two=1', 'the king taken by two');
    is($V->custom(escape => 'edge')->as_string, 'custom escape=edge', 'the edge');
    is($V->custom(ply_cap => 1)->ply_cap, 1, 'the smallest cap');
    is($V->custom(ply_cap => 4096)->ply_cap, 4096, 'and the largest');
    is($V->custom(ply_cap => '060')->ply_cap, 60, 'a number written with a leading zero is the number');
    is(Game::Brandubh::Variant::PLY_CAP_MAX, 4096, 'which is PLY_CAP_MAX');
};

# A MISSPELT FIELD IS A CROAK. Object::Proto::Sugar drops a constructor key it
# does not know without a word, so `new` is closed and the three constructors
# check every name.
subtest 'what a rule set cannot be' => sub {
    dies_like(sub { $V->custom(repeats => 2) }, qr/no field is called 'repeats'/, 'a field that does not exist');
    dies_like(sub { $V->custom(name => 'mine') }, qr/no field is called 'name'/, 'the name, which is not a field');
    dies_like(sub { $V->custom('repeat') }, qr/pairs/, 'an odd list');
    dies_like(sub { $V->custom(repeat => undef) }, qr/repeat has no value/, 'a field with no value');
    dies_like(sub { $V->custom(repeat => [2]) }, qr/repeat has no value/, 'a field given a reference');
    dies_like(sub { $V->custom(repeat => 1) }, qr/repeat is a whole number from 2 up/, 'a repeat of 1');
    dies_like(sub { $V->custom(repeat => 0) }, qr/repeat is a whole number/, 'a repeat of 0');
    dies_like(sub { $V->custom(repeat => 2.5) }, qr/repeat is a whole number/, 'a repeat of two and a half');
    dies_like(sub { $V->custom(repeat => 'three') }, qr/repeat is a whole number/, 'a repeat in words');
    dies_like(sub { $V->custom(ply_cap => 0) }, qr/ply_cap is a whole number from 1 to 4096/, 'a cap of 0');
    dies_like(sub { $V->custom(ply_cap => 4097) }, qr/ply_cap is a whole number/, 'a cap above the ceiling');
    dies_like(sub { $V->custom(ply_cap => -1) }, qr/ply_cap is a whole number/, 'a negative cap');
    dies_like(sub { $V->custom(escape => 'side') }, qr/escape is 'corner' or 'edge'/, 'an escape that is neither');
    dies_like(sub { $V->custom(throne_pass => 2) }, qr/throne_pass is 0 or 1/, 'a flag that is 2');
    dies_like(sub { $V->custom(king_strong => 'yes') }, qr/king_strong is 0 or 1/, 'a flag that is a word');
    dies_like(sub { $V->custom(king_strong => 1, king_everywhere_two => 1) }, qr/contradict/,
        'the king both strong and taken by two');
    dies_like(sub { $V->named('tablut') }, qr/no rule set is called 'tablut'/, 'a name nothing is published under');
    dies_like(sub { $V->named('custom') }, qr/no rule set is called 'custom'/, 'custom, which is not a name to ask for');
    dies_like(sub { $V->new }, qr/made by named, custom or from_string/, 'new');
    dies_like(sub { $V->new(repeat => 2) }, qr/made by named, custom or from_string/, 'new with a field');

    ok($V->custom(king_strong => 1), 'after all that, a good set is still made');
    dies_like(sub { $V->new }, qr/made by named/, 'and new is still closed after one');
};

subtest 'it cannot be changed' => sub {
    my $v = $V->custom(repeat => 2);
    for my $field ($V->fields, 'name') {
        ok(!eval { $v->$field(9); 1 }, "$field is read-only");
    }
    is($v->repeat, 2, 'and nothing changed');
    my $hash = $v->as_hash;
    $hash->{repeat} = 99;
    is($v->repeat, 2, 'as_hash hands out a copy');
};

subtest 'as_string and from_string' => sub {
    my @sets = (
        $V->named,
        $V->custom(repeat => 2),
        $V->custom(escape => 'edge'),
        $V->custom(king_strong => 1, throne_reentry => 1),
        $V->custom(king_everywhere_two => 1, throne_pass => 0, repeat => 5, ply_cap => 77),
        $V->custom(escape => 'edge', king_strong => 1, throne_reentry => 1, throne_pass => 0, repeat => 2, ply_cap => 4096),
    );
    my %strings;
    for my $v (@sets) {
        my $text = $v->as_string;
        $strings{$text}++;
        my $back = $V->from_string($text);
        ok($back, "'$text' reads back");
        ok($back && $back->equals($v), 'to an equal set');
        is($back && $back->as_string, $text, 'which writes the same string');
        unlike($text, qr/\n/, 'on one line');
    }
    is(scalar(keys %strings), scalar(@sets), 'and different sets are written differently');

    is($V->from_string('  brandubh  ')->name, 'brandubh', 'space round it is ignored');
    is($V->from_string('custom')->name, 'brandubh', '"custom" with no fields is the default');
    ok($V->from_string('custom repeat=2,repeat=2') ? 0 : 1, 'a field given twice is not a rule set');

    for my $bad ('', 'tablut', 'custom repeats=2', 'custom repeat', 'custom repeat=1', 'custom repeat=2 ply_cap=9',
                 'custom king_strong=1,king_everywhere_two=1', 'brandubh repeat=2', 'custom escape=side', "custom\nrepeat=2") {
        (my $shown = $bad) =~ s/\n/\\n/;
        is($V->from_string($bad), undef, "'$shown' is not a rule set, and nothing dies");
    }
    is($V->from_string(undef), undef, 'nor is undef');
    is($V->from_string({}), undef, 'nor a reference');
};

subtest 'equals' => sub {
    my $x = $V->custom(repeat => 2);
    ok($x->equals($V->custom(repeat => 2)), 'the same fields are equal');
    ok(!$x->equals($V->named), 'different fields are not');
    ok(!$x->equals($V->custom(repeat => 2, ply_cap => 399)), 'one field apart is not');
    ok(!$x->equals(undef), 'nothing is not');
    ok(!$x->equals({ repeat => 2 }), 'a hash with the same field is not');
    ok(!$x->equals('custom repeat=2'), 'nor is its own string');
};

done_testing();
