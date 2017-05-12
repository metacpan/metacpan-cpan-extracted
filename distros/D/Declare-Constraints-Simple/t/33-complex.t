#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use Declare::Constraints::Simple-All;

my $profile = And( IsHashRef,
                   HasAllKeys( qw(foo bar baz) ),
                   OnHashKeys( foo => IsArrayRef( IsInt ),
                               bar => Message('Definition Error', IsDefined),
                               baz => IsHashRef(-values => Matches(qr/oo/)),
                               boo => CaseValid( IsInt,      ReturnTrue,
                                                 IsArrayRef, And( HasArraySize(4,4),
                                                                  OnEvenElements(IsInt) ),
                                                 IsHashRef,  And( HasAllKeys(qw(ka kb)),
                                                                  OnHashKeys(ka => IsInt,
                                                                             kb => IsDefined) ),
                                                 ReturnTrue, ReturnFalse('default conseq') )));

our $data = {
    foo => [1, 2, 3],
    bar => "Fnord!",
    baz => { 
        23 => 'foobar',
        5  => 'Foo Fighters',
        12 => 'boolean rockz',
    },
    boo => 23,
};

my @ret = (ReturnFalse('foo'), ReturnFalse('bar'));

my @test_sets = (
    [sub {
        is($ret[0]->(23)->message, 'foo', 'correct false message I');
        is($ret[1]->(23)->message, 'bar', 'correct false message II');
    }, 2],
    [sub {
        $data->{boo} = [];
        like($profile->($data)->message, qr/4/, 'case valid array fail');
        $data->{boo} = [qw(1 foo 2 bar)];
        ok($profile->($data), 'case valid array success');

        $data->{boo} = {};
        like($profile->($data)->message, qr/ka/, 'case valid hash fail key a');
        $data->{boo}{ka} = 23;
        like($profile->($data)->message, qr/kb/, 'case valid hash fail key b');
        $data->{boo}{kb} = 'foo';
        ok($profile->($data), 'case valid hash success');

        $data->{boo} = "foo";
        is($profile->($data)->message, 'default conseq', 'case valid default');

        $data->{boo} = 23;
        ok($profile->($data), 'all is well');
    }, 7],
    [sub {
        push @{$data->{foo}}, 'Hooray';
        my $e = $profile->($data);
        ok(!$e, 'array ref fails');
        is($e->path, 'And.OnHashKeys[foo].IsArrayRef[3].IsInt', 'correct path');
        pop @{$data->{foo}};
    }, 2],
    [sub {
        $data->{baz}{42} = 'Not as hot as 23';
        my $e = $profile->($data);
        ok(!$e, 'value match on hoh fails');
        is($e->path, 'And.OnHashKeys[baz].IsHashRef[val 42].Matches', 'correct path');
        delete $data->{baz}{42};
    }, 2],
    [sub {
        undef $data->{bar};
        my $e = $profile->($data);
        ok(!$e, 'defined fails');
        is($e->path, 'And.OnHashKeys[bar].Message.IsDefined', 'correct path');
        is($e->message, 'Definition Error', 'correct message');
        $data->{bar} = "Fnord again!";
    }, 3],
    [sub {
        my $e = $profile->($data);
        ok($e, 'complex structure passes');
    }, 1],
);

#@test_sets = ($test_sets[3]);

my @counts = map { $_->[1] } @test_sets;
my $count;
$count += $_ for @counts;

plan tests => $count;

$_->[0]->() for @test_sets;

