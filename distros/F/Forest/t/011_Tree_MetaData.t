#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 34;

BEGIN {
    use_ok('Forest::Tree');
    use_ok('Forest::Tree::Reader::SimpleTextFile');
    use_ok('Forest::Tree::Indexer');
    use_ok('Forest::Tree::Indexer::SimpleUIDIndexer');
    use_ok('Forest::Tree::Roles::MetaData');
};


{
    {
        package My::Tree;
        use Moose;
        extends 'Forest::Tree';
           with 'Forest::Tree::Roles::MetaData';
           
        __PACKAGE__->meta->make_immutable();
        
        package My::Tree::Reader;
        use Moose;
        extends 'Forest::Tree::Reader::SimpleTextFile';
        
        has '+tree' => (
            default => sub { 
                My::Tree->new(
                    node      => '0.0|DEFAULT', 
                    metadata => { number => '0.0', name => 'DEFAULT' }
                ) 
            }
        );        
        
        sub build_parser { 
            return sub {
                my ($self, $line) = @_;
                my ($indent, $node) = ($line =~ /^(\s*)(.*)$/);
                my $depth = ((length $indent) / $self->tab_width); 
            
                my ($number, $name) = (split /\|/ => $node);
            
                my $tree = My::Tree->new(
                    node      => $node,
                    metadata => { 
                        (($number) ? (number => $number) : ()), 
                        (($name)   ? (name   => $name  ) : ()),
                    }
                );
            
                return ($depth, $tree);
            }
        }
        
        __PACKAGE__->meta->make_immutable();
    }

    ok(My::Tree->isa('Forest::Tree'), '... My::Tree isa Forest::Tree');
    ok(My::Tree->isa('Forest::Tree::Pure'), '... My::Tree isa Forest::Tree::Pure');
    ok(My::Tree->does('Forest::Tree::Roles::MetaData'), '... My::Tree does Forest::Tree::Roles::MetaData');
    
    my $reader = My::Tree::Reader->new;
    isa_ok($reader, 'My::Tree::Reader');    
    isa_ok($reader, 'Forest::Tree::Reader::SimpleTextFile');    
    
    $reader->read(\*DATA);

    my $tree = $reader->tree;

    isa_ok($tree, 'My::Tree');
    isa_ok($tree, 'Forest::Tree');  
    ok($tree->does('Forest::Tree::Roles::MetaData'), '... our tree does Forest::Tree::Roles::MetaData');  
    
    is($tree->node, '0.0|DEFAULT', '... got the right root node');
    is_deeply($tree->metadata, { number => '0.0', name => 'DEFAULT' }, '... got the right metadata hash');
    is($tree->fetch_metadata_for('number'), '0.0',     '... got the right root node metadata');    
    is($tree->fetch_metadata_for('name'),   'DEFAULT', '... got the right root node metadata');     
    
    is($tree->get_child_at(0)->node, '1.0', '... got the right root node');
    is_deeply($tree->get_child_at(0)->metadata, { number => '1.0' }, '... got the right metadata hash');
    is($tree->get_child_at(0)->get_metadata_for('number'), '1.0', '... got the right metadata hash');
    is($tree->get_child_at(0)->fetch_metadata_for('number'), '1.0',     '... got the right root node metadata');    
    is($tree->get_child_at(0)->fetch_metadata_for('name'),   'DEFAULT', '... got the right root node metadata');       

    is($tree->get_child_at(0)->get_child_at(0)->node, '1.1|One-Point-One', '... got the right root node');
    is($tree->get_child_at(0)->get_child_at(0)->fetch_metadata_for('number'), '1.1',     '... got the right root node metadata');    
    is($tree->get_child_at(0)->get_child_at(0)->fetch_metadata_for('name'),   'One-Point-One', '... got the right root node metadata');    
    
    is($tree->get_child_at(0)->get_child_at(1)->node, '1.2|One-Point-Two', '... got the right root node');
    is($tree->get_child_at(0)->get_child_at(1)->fetch_metadata_for('number'), '1.2',     '... got the right root node metadata');    
    is($tree->get_child_at(0)->get_child_at(1)->fetch_metadata_for('name'),   'One-Point-Two', '... got the right root node metadata');    
    
    is($tree->get_child_at(0)->get_child_at(1)->get_child_at(0)->node, '1.2.1', '... got the right root node');
    is($tree->get_child_at(0)->get_child_at(1)->get_child_at(0)->fetch_metadata_for('number'), '1.2.1',     '... got the right root node metadata');    
    is($tree->get_child_at(0)->get_child_at(1)->get_child_at(0)->fetch_metadata_for('name'),   'One-Point-Two', '... got the right root node metadata');    
    
    is($tree->get_child_at(0)->get_child_at(1)->get_child_at(1)->node, '|One-Point-Two-Point-Two', '... got the right root node');
    is($tree->get_child_at(0)->get_child_at(1)->get_child_at(1)->fetch_metadata_for('number'), '1.2',     '... got the right root node metadata');    
    is($tree->get_child_at(0)->get_child_at(1)->get_child_at(1)->fetch_metadata_for('name'),   'One-Point-Two-Point-Two', '... got the right root node metadata');    
}

__DATA__
1.0
    1.1|One-Point-One
    1.2|One-Point-Two
        1.2.1
        |One-Point-Two-Point-Two
