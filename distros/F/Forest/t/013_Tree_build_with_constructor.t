#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

BEGIN {
    use_ok('Forest::Tree');
}

my $root = Forest::Tree->new(
    node     => 'root',
    children => [
        Forest::Tree->new(
            node     => '1.0',
            children => [
                Forest::Tree->new(node => '1.1'),
                Forest::Tree->new(node => '1.2'),
            ]
        ),
        Forest::Tree->new(
            node     => '2.0',
            children => [
                Forest::Tree->new(
                    node     => '2.1',
                    children => [
                        Forest::Tree->new(node => '2.1.1'),
                        Forest::Tree->new(node => '2.1.2'),
                    ]
                ),
            ]
        )
    ]
);
isa_ok($root, 'Forest::Tree');

my @output;

$root->traverse(sub {
    my $t = shift;
    isa_ok($t, 'Forest::Tree');
    ok($t->has_parent, '... got a parent node');
    push @output => [ $t->depth, $t->node, $t->parent->node ]
});

is_deeply(
    \@output,
    [
        [0,'1.0','root'],
        [1,'1.1','1.0'],
        [1,'1.2','1.0'],
        [0,'2.0','root'],
        [1,'2.1','2.0'],
        [2,'2.1.1','2.1'],
        [2,'2.1.2','2.1'],
    ],
    '... the tree was properly initialized'
);


