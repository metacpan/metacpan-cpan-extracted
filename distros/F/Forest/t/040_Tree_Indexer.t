#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 36;

BEGIN {
    use_ok('Forest::Tree::Pure');
    use_ok('Forest::Tree');
    use_ok('Forest::Tree::Reader::SimpleTextFile');
    use_ok('Forest::Tree::Indexer');
    use_ok('Forest::Tree::Indexer::SimpleUIDIndexer');
};

{
    my $tree = Forest::Tree::Pure->new(
        node => 3,
        uid  => "three",
        children => [
            Forest::Tree::Pure->new(
                node => 10,
                uid => "ten",
            ),
        ],
    );

    my $index = Forest::Tree::Indexer::SimpleUIDIndexer->new(tree => $tree);

    isa_ok($index, 'Forest::Tree::Indexer::SimpleUIDIndexer');

    $index->build_index;

    my @keys = $index->get_index_keys;
    is_deeply([ sort @keys ], [sort qw(ten three)], '... got the right keys');

    foreach my $key (@keys) {
        my $tree = $index->get_tree_at($key);
        isa_ok($tree, 'Forest::Tree::Pure');
        is($tree->uid, $key, '... indexed by uid');
    }
}

{
    my $reader = Forest::Tree::Reader::SimpleTextFile->new;
    isa_ok($reader, 'Forest::Tree::Reader::SimpleTextFile');
    
    $reader->read(\*DATA);

    my $index = Forest::Tree::Indexer::SimpleUIDIndexer->new(tree => $reader->tree);
    isa_ok($index, 'Forest::Tree::Indexer::SimpleUIDIndexer');

    $index->build_index;

    my @keys = $index->get_index_keys;
    is(scalar @keys, 11, '... got the right amount of keys');

    foreach my $key (@keys) {
        my $tree = $index->get_tree_at($key);
        isa_ok($tree, 'Forest::Tree');
        is($tree->uid, $key, '... indexed by uid');
    }
}

__DATA__
1.0
    1.1
    1.2
        1.2.1
2.0
    2.1
3.0
4.0
    4.1
        4.1.1
