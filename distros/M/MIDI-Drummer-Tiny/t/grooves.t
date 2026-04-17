#!perl
use Test::More;

use_ok 'MIDI::Drummer::Tiny::Grooves';

subtest all => sub {
    my $grooves = new_ok 'MIDI::Drummer::Tiny::Grooves';
    my $all = $grooves->all_grooves;
    isa_ok $all, 'HASH', 'all_grooves';
    ok exists($all->{1}), '1 exists';
    is $all->{1}{name}, 'ONE AND SEVEN & FIVE AND THIRTEEN', '1 named';
    isa_ok $all->{1}{groove}, 'HASH', '1 groove';
};

subtest search => sub {
    my $grooves = new_ok 'MIDI::Drummer::Tiny::Grooves';
    my $got = $grooves->search({ cat => 'house' });
    isa_ok $got, 'HASH', 'search all';
    is scalar(keys %$got), 9, 'size';
    my $n = 27;
    ok exists($got->{$n}), 'exists';
    is $got->{$n}{name}, 'DIRTY HOUSE', 'named';
    isa_ok $got->{$n}{groove}, 'HASH', 'groove';
    $got = $grooves->search({ name => 'deep' });
    isa_ok $got, 'HASH', 'search subset';
    is scalar(keys %$got), 3, 'size';
};

subtest groove => sub {
    my $grooves = new_ok 'MIDI::Drummer::Tiny::Grooves' => [ return_patterns => 1 ];
    my $got = $grooves->search({ cat => 'rock' });
    my $n = 11;
    ok exists($got->{$n}), 'exists';
    is $got->{$n}{name}, 'ROCK 2', 'named';
    my %got = $grooves->groove($got->{$n}{groove});
    is_deeply $got{kick}, [qw(1 0 0 0 0 0 0 1 1 0 1 0 0 0 0 0)], 'kick';
};

done_testing();
