#!/usr/bin/env perl
use warnings;
use strict;
use Hash::Inflator;
use Test::More tests => 7;
use Test::Differences;
my %h = (
    persons => [
        {   last_name  => 'Shindou',
            first_name => 'Hikaru',
        },
        {   last_name  => 'Touya',
            first_name => 'Akira',
        },
    ],
    primes => [ 2, 3, 5, 7, 11, 13, 17 ],
    mix => [ 1, 4, 9, { foo => 'bar', frobnule => 'baz' }, 25, 'flurble', ],
);
my $o = Hash::Inflator->new(%h);
isa_ok($o, 'Hash::Inflator');
my $expect = bless {
    persons => [
        bless(
            {   last_name  => 'Shindou',
                first_name => 'Hikaru',
            },
            'Hash::Inflator'
        ),
        bless(
            {   last_name  => 'Touya',
                first_name => 'Akira',
            },
            'Hash::Inflator'
        ),
    ],
    primes => [ 2, 3, 5, 7, 11, 13, 17 ],
    mix    => [
        1, 4, 9, bless({ foo => 'bar', frobnule => 'baz' }, 'Hash::Inflator'),
        25, 'flurble',
    ],
  },
  'Hash::Inflator';
eq_or_diff $o, $expect, 'contents of the object';

# Now test accessing the hash via autoloaded methods
eq_or_diff $o->primes, [ 2, 3, 5, 7, 11, 13, 17 ], 'primes';
my $persons = $o->persons;
eq_or_diff $persons,
  [ bless(
        {   last_name  => 'Shindou',
            first_name => 'Hikaru',
        },
        'Hash::Inflator'
    ),
    bless(
        {   last_name  => 'Touya',
            first_name => 'Akira',
        },
        'Hash::Inflator'
    ),
  ],
  'persons()';
is($o->persons->[0]->first_name, 'Hikaru', "first person's first name");
is($o->persons->[1]->last_name,  'Touya',  "second person's last name");
is($o->not_there, undef, "calling a method whose hash key doesn't exist");
