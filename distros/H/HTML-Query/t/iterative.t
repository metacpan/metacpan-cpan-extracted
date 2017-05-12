#!/usr/bin/env perl

# Test to assess bug reported by tnt [...] netsafe.cz
#
# https://rt.cpan.org/Public/Bug/Display.html?id=62100
#

use strict;
use warnings;
use lib qw( ./lib ../lib );
use HTML::Query 'Query';
use HTML::TreeBuilder;

use Badger::Test
    tests => 10,
    debug => 'HTML::Query',
    args  => \@ARGV;

my $tree = HTML::TreeBuilder->new;
$tree->parse( '<p id="1" class="a">A</p><p id="2" class="b">B</p>' );
ok( $tree, 'parsed tree');

# test method interface

my $doc = HTML::Query->new(text => $tree->as_HTML );

my $result1 = $doc->query('p');
is( $result1->size, 2, 'two p elements in query' ); 
is( join(', ', $result1->as_trimmed_text()), 'A, B', 'proper elements returned' );

my $result2 = $result1->query('.b');
is( $result2->size, 1, 'one p element in query' ); 
is( join(', ', $result2->as_trimmed_text), 'B', 'proper element returned' ); 

# test class interface

my $query = Query $tree;
ok( $query, 'created query' );

my $result3 = $query->query('p');
is( $result3->size, 2, 'two p elements in query' ); 
is( join(', ', $result3->as_trimmed_text()), 'A, B', 'proper elements returned' );

my $result4 = $result3->query('.b');
is( $result4->size, 1, 'one p element in query' ); 
is( join(', ', $result4->as_trimmed_text), 'B', 'proper element returned' ); 
