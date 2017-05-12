#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 29;

BEGIN {
    use_ok('Forest::Tree');
    use_ok('Forest::Tree::Reader::SimpleTextFile');
    use_ok('Forest::Tree::Indexer');
    use_ok('Forest::Tree::Indexer::SimpleUIDIndexer');
};

{
    {
        package My::Tree::Reader;
        use Moose;
        extends 'Forest::Tree::Reader::SimpleTextFile';
        
        sub create_new_subtree {
            shift;
            my $t = Forest::Tree->new(@_);
            $t->uid($t->node);
            $t;
        }
        
        __PACKAGE__->meta->make_immutable();
    }
    
    my $reader = My::Tree::Reader->new;
    isa_ok($reader, 'My::Tree::Reader');    
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
        next if $tree->is_root;
        is($tree->node, $key, '... got the right key match');
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
