#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;
use Test::Exception;

BEGIN {
    use_ok('Forest::Tree');
    use_ok('Forest::Tree::Reader');
    use_ok('Forest::Tree::Reader::SimpleTextFile');
};

{
    my $reader = Forest::Tree::Reader::SimpleTextFile->new();
    isa_ok($reader, 'Forest::Tree::Reader::SimpleTextFile');
    ok($reader->does('Forest::Tree::Reader'), '... loader does Forest::Tree::Reader');

    my $tree = $reader->tree;
    isa_ok($tree, 'Forest::Tree'); 
    
    ok($tree->is_root, '... tree is a root');
    ok($tree->is_leaf, '... tree is a leaf');    
    is($tree->child_count, 0, '... tree has no children');
    
    lives_ok {
        $reader->load(\*DATA);
    } '... loaded the tree';   

    ok($tree->is_root, '... tree is a root');
    ok(!$tree->is_leaf, '... tree is not a leaf');    
    is($tree->child_count, 4, '... tree has 4 children');

    is($tree->get_child_at(0)->node, '1.0', '... got the right node');
    is($tree->get_child_at(0)->get_child_at(0)->node, '1.1', '... got the right node');
    is($tree->get_child_at(0)->get_child_at(1)->node, '1.2', '... got the right node');    
    is($tree->get_child_at(0)->get_child_at(1)->get_child_at(0)->node, '1.2.1', '... got the right node');        
    
    is($tree->get_child_at(1)->node, '2.0', '... got the right node');             
    is($tree->get_child_at(1)->get_child_at(0)->node, '2.1', '... got the right node');                 

    is($tree->get_child_at(2)->node, '3.0', '... got the right node');             
    
    is($tree->get_child_at(3)->node, '4.0', '... got the right node');                 
    is($tree->get_child_at(3)->get_child_at(0)->node, '4.1', '... got the right node');    
    is($tree->get_child_at(3)->get_child_at(0)->get_child_at(0)->node, '4.1.1', '... got the right node');    
    
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
