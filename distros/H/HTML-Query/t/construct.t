#============================================================= -*-perl-*-
#
# t/construct.t
#
# Test script which works through the various different ways to construct
# HTML::Query objects, checks for correctness, errors, etc.
#
# Written by Andy Wardley, October 2008
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use HTML::TreeBuilder;
use Badger::Filesystem '$Bin Dir';
use Badger::Test
    tests => 34,
    debug => 'HTML::Query',
    args  => \@ARGV;

use HTML::Query 'Query';

our $Query    = 'HTML::Query';
our $Builder  = 'HTML::TreeBuilder';
our $test_dir = Dir($Bin);
our $html_dir = $test_dir->dir('html')->must_exist;
our $test1    = $html_dir->file('test1.html')->must_exist;

my ($query, $tree);


#-----------------------------------------------------------------------
# load up first test file
#-----------------------------------------------------------------------

$tree = $Builder->new;
$tree->parse_file( $test1->absolute );
ok( $tree, 'parsed tree for first test file: ' . $test1->name );


#-----------------------------------------------------------------------
# create a an object via the regular constructor
#-----------------------------------------------------------------------

$query = $Query->new($tree);
ok( $query, 'got html query via constructor method' );
is( ref $query, $Query, "got $Query object from constructor method" );
is( $query->size, 1, 'got one element in query from constructor method' );


#-----------------------------------------------------------------------
# test the Query() constructor subroutine
#-----------------------------------------------------------------------

# explicit parens
$query = Query($tree);
ok( $query, 'got html query' );
is( ref $query, $Query, "got $Query object for html from constructor sub" );
is( $query->size, 1, 'got one <html> element in query' );

# no parens, single argument
$query = Query $tree->look_down( _tag => 'body' );
ok( $query, 'got body query' );
is( ref $query, $Query, "got $Query object for body" );
is( $query->size, 1, 'got one <body> element in query' );

# no parens, multiple arguments
$query = Query $tree->look_down( _tag => 'p' );
ok( $query, 'got p query' );
is( ref $query, $Query, "got $Query object for p" );
is( $query->size, 2, 'got two <p> elements in query' );

# no parens, multiple arguments as single list ref
$query = Query [$tree->look_down( _tag => 'p' )];
ok( $query, 'got p query again' );
is( ref $query, $Query, "got $Query object for p again" );
is( $query->size, 2, 'got two <p> elements in query again' );

# no arguments
$query = Query;
ok( $query, 'got query with no args' );
is( $query->size, 0, 'no items in query' );


#-----------------------------------------------------------------------
# test we can construct trees using named arguments
#-----------------------------------------------------------------------

$query = Query( text => $test1->text );
ok( $query, 'got query from text' );

$query = Query( file => $test1->absolute );
ok( $query, 'got query from file' );

$query = Query( tree => $tree );
ok( $query, 'got query from tree' );

$query = Query( query => $query );
ok( $query, 'got query from query' );

$query = Query( file => $test1->absolute, 'p' );
ok( $query, 'got query from file' );
is( $query->size, 2, 'got two paras from file' );

$query = Query( tree => $tree, 'p' );
ok( $query, 'got query from file' );
is( $query->size, 2, 'got two paras from tree' );

$query = Query( query => Query( tree => $tree ), 'p' );
ok( $query, 'got query from query' );
is( $query->size, 2, 'got two paras from query' );

$query = Query( 
    text => $test1->text,
    file => $test1->absolute,
    tree => $tree,
    'p' 
);
ok( $query, 'got query from file' );
is( $query->size, 6, 'got six paras from composite query' );


#-----------------------------------------------------------------------
# multiple named params
#-----------------------------------------------------------------------



#-----------------------------------------------------------------------
# test errors being thrown
#-----------------------------------------------------------------------

$query = eval { Query 'hello' };
ok( ! $query, 'no query' );
is( $@, 'html.query error - Invalid element specified: hello',
    'got bad element error message'
);

# should be able to do the same thing using try()
$query = $Query->try( new => 'goodbye' );
ok( ! $query, 'no query using try' );
is( $Query->reason, 'html.query error - Invalid element specified: goodbye',
    'got bad element error message via reason'
);

