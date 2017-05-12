#!/usr/bin/perl -w

use strict;
use Test::More;

eval 'use Test::Weaken qw(leaks)';
plan skip_all => 'Test::Weaken required to test for memory leaks' if $@;

plan tests => 6;

use FSA::Rules;

my $leaks = leaks(sub {
    ok my $fsa = +FSA::Rules->new(
        foo => {},
    ), "Construct with a single state";
    return $fsa;
});

ok !$leaks, 'There should be no leaks' or
    diag sprintf '%d of %d original references were not freed',
    $leaks->unfreed_count, $leaks->probe_count;

my %states;
$leaks = leaks(sub {
    ok my $fsa = +FSA::Rules->new(
        foo => {
            on_enter => sub { shift->machine->{foo_enter}++ },
            do => sub { shift->machine->{foo}++ },
            on_exit => sub { shift->machine->{foo_exit}++ },
            rules => [
                bar => sub { shift->machine->{foo} },
            ],
        },
        bar => {
            on_enter => sub { shift->machine->{bar_enter}++ },
            do => sub { $_[0]->machine->{bar} = $_[0]->machine->{bar_enter} },
            rules => [
                foo => sub { shift->machine->{bar} },
            ],
        },
    ), "Construct with mutually-referenced state rule";
    %states = map { $_->name => "$_" } $fsa->states;
    return $fsa;
});

ok !$leaks, 'There should be no leaks with circular rules' or
    diag sprintf '%d of %d original references were not freed',
    $leaks->unfreed_count, $leaks->probe_count;

# FSA::State sneakily uses the memory address of the object to find its
# attributes in the file-coped %states lexical. So we take advantage of that
# by trapping the addresses as strings in the call to leaks() above, and then
# passing them to name() as if they were objects. If there is no leak, the
# objects should not exist. If there is a leak, they will still exist and
# return their names.
while (my ($state, $address) = each %states) {
    ok !FSA::State::name($address), qq{State "$state" should no longer exist};
}
