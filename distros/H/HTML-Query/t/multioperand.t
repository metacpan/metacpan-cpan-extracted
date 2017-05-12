#============================================================= -*-perl-*-
#
# t/query.t
#
# Test script for the query() method.
#
# Written by Kevin Kamel, October 2010
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use HTML::TreeBuilder;
use Badger::Filesystem '$Bin Dir';
use Badger::Test
    tests => 39,
    debug => 'HTML::Query',
    args  => \@ARGV;

use HTML::Query 'Query';

our $Query    = 'HTML::Query';
our $Builder  = 'HTML::TreeBuilder';
our $test_dir = Dir($Bin);
our $html_dir = $test_dir->dir('html')->must_exist;
our $mytest    = $html_dir->file('test3.html')->must_exist;

my ($query, $tree);

#-----------------------------------------------------------------------
# load up first test file and create an HTML::Query object for it.
#-----------------------------------------------------------------------

$tree = $Builder->new;
$tree->parse_file( $mytest->absolute );
ok( $tree, 'parsed tree for first test file: ' . $mytest->name );
$query = Query $tree;
ok( $query, 'created query' );

$query->suppress_errors(1);
is ($query->suppress_errors(), 1, 'errors suppressed');

#-----------------------------------------------------------------------
# validate that multi class operands work
#-----------------------------------------------------------------------

my $test1 = $query->query('.bar.new-class');
is( $test1->size, 2, 'found all elements with class ".bar.new-class"' );
is( join(', ', $test1->as_trimmed_text), 'This is another div with bar class, This is a span with bar class','got correct stacked result' );

my $test2 = $query->query('.new-class.bar');
is( $test2->size, 2, 'found all elements with class ".new-class.new-bar"' );
is( join(', ', $test2->as_trimmed_text), 'This is another div with bar class, This is a span with bar class','got correct stacked result' );

my $test3 = $query->query('span.bar.new-class');
is( $test3->size(), 1, 'found all elements with class "span.bar.new-class"' );
is( join(', ', $test3->as_trimmed_text), 'This is a span with bar class', 'got correct stacked result' );

my $test4 = $query->query('span.new-class.bar');
is( $test4->size(), 1, 'found all elements with class "span.new-class.bar"' );
is( join(', ', $test4->as_trimmed_text), 'This is a span with bar class', 'got correct stacked result' );

#-----------------------------------------------------------------------
# validate that class/id operands work
#-----------------------------------------------------------------------

my $test5 = $query->query('#test-id.new-class');
is( $test5->size(), 3, 'found all elements with class "#test-id.new-class"' );
is( join(', ', $test5->as_trimmed_text), 'test-id content, test-id content, crazy span content', 'got correct stacked result' );

my $test6 = $query->query('div#test-id.new-class');
is( $test6->size(), 2, 'found all elements with class "#test-id.new-class"' );
is( join(', ', $test6->as_trimmed_text), 'test-id content, test-id content', 'got correct stacked result' );

my $test7 = $query->query('div#test-id.new-class.new-class2');
is( $test7->size(), 1, 'found all elements with class "div#test-id.new-class.new-class2"' );
is( join(', ', $test7->as_trimmed_text), 'test-id content', 'got correct stacked result' );

my $test8 = $query->query('div.new-class#test-id.new-class2');
is( $test8->size(), 1, 'found all elements with class "div.new-class#test-id.new-class2"' );
is( join(', ', $test8->as_trimmed_text), 'test-id content', 'got correct stacked result' );

my $test9 = $query->query('div.new-class.new-class2#test-id');
is( $test9->size(), 1, 'found all elements with class "div.new-class.new-class2#test-id"' );
is( join(', ', $test9->as_trimmed_text), 'test-id content', 'got correct stacked result' );

#-----------------------------------------------------------------------
# validate that class/attribute operands work
#-----------------------------------------------------------------------

#baseline
my $test10 = $query->query('div[]');
ok( !defined($test10), 'failed query for "div[]"' );
is( $query->get_error(), 'Invalid specification "" in query: div[]', 'got correct error' );

#try with class
my $test11 = $query->query('.new-class[]');
ok( !defined($test11), 'got error for bad query ".new-class[]"' );
is( $query->get_error(), 'Invalid specification "" in query: .new-class[]', 'got correct stacked result' );

#try with partial attr
my $test12 = $query->query('.new-class[title]');
is( $test12->size(), 2, 'found all elements with class ".new-class[title]"' );
is( join(', ', $test12->as_trimmed_text), 'test-id content, crazy span content', 'got correct stacked result' );

#try with out of order
my $test13 = $query->query('span[title="w00t"].new-class');
is( $test13->size(), 1, 'found all elements with class ".new-class[]"' );
is( join(', ', $test13->as_trimmed_text), 'crazy span content', 'got correct stacked result' );

#try with multiple attr
my $test14 = $query->query('.new-class[title="w00t"][lang="en"]');
is( $test14->size(), 2, 'found all elements with class ".new-class[]"' );
is( join(', ', $test14->as_trimmed_text), 'test-id content, crazy span content', 'got correct stacked result' );

#-----------------------------------------------------------------------
# validate that id/attribute operands work
#-----------------------------------------------------------------------

#try with expanded attr
my $test15 = $query->query('#test-id[title=""]');
is( $test15->size(), 1, 'found all elements with class "#test-id[title=""]' );
is( join(', ', $test15->as_trimmed_text), 'empty title', 'got correct stacked result' );

#flipped
my $test16 = $query->query('[title=""]#test-id');
is( $test16->size(), 1, 'found all elements with class "[title=""]#test-id' );
is( join(', ', $test16->as_trimmed_text), 'empty title', 'got correct stacked result' );

#flipped and more complex
my $test17 = $query->query('[title="w00t"]#test-id[lang="en"]');
is( $test17->size(), 2, 'found all elements with class "[title="w00t"]#test-id[lang="en"]' );
is( join(', ', $test17->as_trimmed_text), 'test-id content, crazy span content', 'got correct stacked result' );

#-----------------------------------------------------------------------
# validate that class/attribute/id operands work
#-----------------------------------------------------------------------

#ultimate test!
my $test18 = $query->query('span[title="w00t"][title].new-class#test-id[lang="en"]');
is( $test18->size(), 1, 'found all elements with class "span[title="w00t"][title].new-class#test-id[lang="en"]' );
is( join(', ', $test18->as_trimmed_text), 'crazy span content', 'got correct stacked result' );
