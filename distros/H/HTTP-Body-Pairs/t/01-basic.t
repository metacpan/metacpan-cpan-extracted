use HTTP::Body::Pairs;
use Test::More tests => 2;

use warnings;
use strict;

my $form = 'foo=foo_one;bar=bar_one;foo=foo_two;baz=baz_one;foo=foo_three;bar=bar_two';
my $body = HTTP::Body->new('application/x-www-form-urlencoded', length $form);
$body->add($form);

is_deeply(
    [$body->flat_pairs], [
        'foo', 'foo_one', 
        'bar', 'bar_one', 
        'foo', 'foo_two', 
        'baz', 'baz_one', 
        'foo', 'foo_three', 
        'bar', 'bar_two',
    ]
);

is_deeply(
    [$body->pairs], [
        ['foo', 'foo_one'], 
        ['bar', 'bar_one'], 
        ['foo', 'foo_two'], 
        ['baz', 'baz_one'], 
        ['foo', 'foo_three'], 
        ['bar', 'bar_two'],
    ]
);
