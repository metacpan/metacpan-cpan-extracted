#============================================================= -*-perl-*-
#
# t/universal.t
#
# Test script for the query() method.
#
# Written by Chelsea Rio/Kevin Kamel, September 24, 2010
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use HTML::TreeBuilder;
use Badger::Filesystem '$Bin Dir';
use Badger::Test
    tests => 47,
    debug => 'HTML::Query',
    args  => \@ARGV;

use HTML::Query 'Query';

our $Query    = 'HTML::Query';
our $Builder  = 'HTML::TreeBuilder';
our $test_dir = Dir($Bin);
our $html_dir = $test_dir->dir('html')->must_exist;
our $multi = $html_dir->file('universal.html')->must_exist;

my ($query, $tree);

#-----------------------------------------------------------------------
# load up second test file and create an HTML::Query object for it.
#-----------------------------------------------------------------------

$tree = $Builder->new;
$tree->parse_file( $multi->absolute );
ok( $tree, 'parsed tree for second test file: ' . $multi->name );
$query = Query $tree;
ok( $query, 'created query' );

$query->suppress_errors(1);

#-----------------------------------------------------------------------
# Make sure suppression was stored successfully
#-----------------------------------------------------------------------

my $test0 = $query->suppress_errors();
is ($test0, 1, 'errors suppressed');

#-----------------------------------------------------------------------
# look for some basic elements using the *
#-----------------------------------------------------------------------

my $test1 = $query->query('div.danger *');
ok( $test1, 'div.danger *' );
is( $test1->size, 4, 'div.danger *' ); #includes javascript and metas
is( join(', ', $test1->as_trimmed_text), '(div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div), (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div), (div class="danger") (div class="green")(/div) (/div), (div class="green")(/div)','got var' );

my $test2 = $query->query('* div.danger');
ok( $test2, '* div.danger' );
is( $test2->size, 2, '* div.danger' ); #includes javascript and metas
is( join(', ', $test2->as_trimmed_text), '(div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div), (div class="danger") (div class="green")(/div) (/div)','got var' );

my $test22 = $query->query('div.danger *, * div.danger');
ok( $test22, 'div.danger *, * div.danger' );
is( $test22->size, 5, 'div.danger *, * div.danger' ); #includes javascript and metas
is( join(', ', $test22->as_trimmed_text), '(div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div), (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div), (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div), (div class="danger") (div class="green")(/div) (/div), (div class="green")(/div)','got var' );

my $test3 = $query->query('div.green');
ok( $test3, 'div.green' );
is( $test3->size, 2, 'div.green' );
is( join(', ', $test3->as_trimmed_text), '(div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div), (div class="green")(/div)','got var' );

my $test4 = $query->query('div.yellow');
ok( $test4, 'div.yellow' );
is( $test4->size, 1, 'div.yellow' );
is( join(', ', $test4->as_trimmed_text), '(div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div)','got var' );

my $test5 = $query->query('div.danger * [class="green"]');
ok( $test5, 'div.danger * [class="green"]' );
is( $test5->size, 1, 'div.danger * [class="green"]' );
is( join(', ', $test5->as_trimmed_text), '(div class="green")(/div)','got var' );

my $test6 = $query->query('div.danger *[class="green"]');
ok( $test6, 'div.danger *[class="green"]' );
is( $test6->size, 2, 'div.danger *[class="green"]' );
is( join(', ', $test6->as_trimmed_text), '(div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div), (div class="green")(/div)','got var' );

my $test7 = $query->query('div.danger * *[class="green"]');
ok( $test7, 'div.danger * *[class="green"]' );
is( $test7->size, 1, 'div.danger * *[class="green"]' );
is( join(', ', $test7->as_trimmed_text), '(div class="green")(/div)','got var' );

my $test8 = $query->query('div.danger * * *[class="green"]');
ok( $test8, 'div.danger * * *[class="green"]' );
is( $test8->size, 1, 'div.danger * * *[class="green"]' );
is( join(', ', $test8->as_trimmed_text), '(div class="green")(/div)','got var' );

my $test9 = $query->query('body * div');
ok( $test9, 'body * div' );
is( $test9->size, 8, 'body * div' );
is( join(', ', $test9->as_trimmed_text), '(div) (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div) (div)(/div)(div)(/div) (/div), (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div), (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div), (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div), (div class="danger") (div class="green")(/div) (/div), (div class="green")(/div), (div)(/div), (div)(/div)','got var' );

#you must use spaces for this operator

my $test10 = $query->query('body* div');
ok( !defined($test10), 'No object returned');
is( $query->get_error(), 'Invalid specification "body*" in query: body* div', 'Rejected bad selector' );

my $test11 = $query->query('body *div');
ok( !defined($test11), 'No object returned');
is( $query->get_error(), 'Invalid specification "*div" in query: body *div', 'Rejected bad selector' );

my $test12 = $query->query('body*');
ok( !defined($test12), 'No object returned');
is( $query->get_error(), 'Invalid specification "body*" in query: body*', 'Rejected bad selector' );

my $test13 = $query->query('*div');
ok( !defined($test13), 'No object returned');
is( $query->get_error(), 'Invalid specification "*div" in query: *div', 'Rejected bad selector' );

my $test14 = $query->query('* div');
ok( $test14, '* div' );
is( $test14->size, 9, '* div' );
is( join(', ', $test14->as_trimmed_text), '(div) (div) (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div) (div)(/div)(div)(/div) (/div) (/div), (div) (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div) (div)(/div)(div)(/div) (/div), (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div), (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div), (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div), (div class="danger") (div class="green")(/div) (/div), (div class="green")(/div), (div)(/div), (div)(/div)','got var' ); 

#should match the prior test...
my $test15 = $query->query(' * div');
ok( $test15, ' * div' );
is( $test15->size, 9, ' * div' );
is( join(', ', $test15->as_trimmed_text), '(div) (div) (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div) (div)(/div)(div)(/div) (/div) (/div), (div) (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div) (div)(/div)(div)(/div) (/div), (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div), (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div), (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div), (div class="danger") (div class="green")(/div) (/div), (div class="green")(/div), (div)(/div), (div)(/div)','got var' ); 

1;
