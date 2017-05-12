#============================================================= -*-perl-*-
#
# t/query.t
#
# Test script for the query() method.
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
    tests => 57,
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
# load up first test file and create an HTML::Query object for it.
#-----------------------------------------------------------------------

$tree = $Builder->new;
$tree->parse_file( $test1->absolute );
ok( $tree, 'parsed tree for first test file: ' . $test1->name );
$query = Query $tree;
ok( $query, 'created query' );

#-----------------------------------------------------------------------
# look for a specific element type: html
#-----------------------------------------------------------------------

my $html = $query->query('html');
ok( $html, 'got <html> query' );
is( $html->size, 1, 'one html element in query' );

#-----------------------------------------------------------------------
# look for a specific element type: p
#-----------------------------------------------------------------------

my $paras = $query->query('p');
ok( $paras, 'got <p> query' );
is( $paras->size, 2, 'two <p> elements in query' );
is( $paras->first->as_trimmed_text, 'paragraph one', 'got first para' );
is( $paras->last->as_trimmed_text, 'paragraph two', 'got last para' );
is( join(', ', $paras->as_trimmed_text), 'paragraph one, paragraph two',
    'got both paras as trimmed text' );


#-----------------------------------------------------------------------
# look for an element by id: #foo
#-----------------------------------------------------------------------

my $foo = $query->query('#foo');
ok( $foo, 'got #foo query' );
is( $foo->size, 1, 'one #foo element in query' );
is( $foo->first->as_trimmed_text, 'This is the foo div', 'got foo div' );


#-----------------------------------------------------------------------
# same again for specific element types: div#foo
#-----------------------------------------------------------------------

$foo = $query->query('div#foo');
ok( $foo, 'got div#foo query' );
is( $foo->size, 1, 'one div#foo element in query' );
is( $foo->first->as_trimmed_text, 'This is the foo div', 'got div#foo' );

my $none = $query->query('span#foo');
ok( $none, 'got span#foo query' );
is( $none->size, 0, 'no elements in query' );


#-----------------------------------------------------------------------
# look for specific elements by class: div.bar
#-----------------------------------------------------------------------

my $bars = $query->query('div.bar');
ok( $bars, 'got div.bar query' );
is( $bars->size, 2, 'two div.bar elements in query' );
is( $bars->first->as_trimmed_text, 'This is a div with bar class', 'got first div.bar' );
is( $bars->last->as_trimmed_text, 'This is another div with bar class', 'got last div.bar' );


#-----------------------------------------------------------------------
# look for all elements by class: .bar
#-----------------------------------------------------------------------

$bars = $query->query('.bar');
ok( $bars, 'got .bar query' );
is( $bars->size, 3, 'three .bar elements in query' );
is( $bars->first->as_trimmed_text, 'This is a div with bar class', 'got first .bar' );
is( $bars->last->as_trimmed_text, 'This is a span with bar class', 'got last .bar' );


#-----------------------------------------------------------------------
# look for all elements with a particular attribute value
#-----------------------------------------------------------------------

my $links = $query->query("a[href='index.html']");
ok( $links, "got a[href='index.html'] query" );
is( $links->size, 2, "two a[href='index.html'] elements in query" );
is( $links->first->as_trimmed_text, 'Link to home page', 'got first link to home page' );
is( $links->last->as_trimmed_text, 'Another link to home page', 'got second link to home page' );

# also check that works with different/no quoting
is( $query->query('a[href="index.html"]')->size, 2, 'got 2 with double quotes' );
is( $query->query('a[href=index.html]')->size, 2, 'got 2 with no quotes' );


#-----------------------------------------------------------------------
# look for elements with any value defined for an attribute
#-----------------------------------------------------------------------

$links = $query->query("a[rel]");
ok( $links, "got a[rel] query" );
is( $links->size, 3, "three a[rel] elements in query" );
is( join(', ', $links->as_trimmed_text), 'Forage, Nuts, Berries', 'got link with rel' );


#-----------------------------------------------------------------------
# multiple attributes
#-----------------------------------------------------------------------

my @inputs = $query->query('input.search[type=text][width=32]');
is( scalar(@inputs), 1, 'got one input with multiple attributes' );


#-----------------------------------------------------------------------
# multiple elements
#-----------------------------------------------------------------------

my $tds = $query->query('table tr.wibble td');
ok( $tds, 'got table tr.wibble td query' );
is( $tds->size, 2, 'two elements in table tr.wibble td query' );
is( join(', ', $tds->as_trimmed_text), 'Wibble1, Wibble2', 'got wibbles' );


#-----------------------------------------------------------------------
# list of specifications: table.foo, input.bar, etc
#-----------------------------------------------------------------------

$tds = $query->query('table.one tr.wibble td, table tr.wobble td, a[rel=nuts]');
ok( $tds, 'got comma sequence query' );
is( $tds->size, 4, 'four elements in composite query' );
is( join(', ', $tds->as_trimmed_text), 'Nuts, Wibble1, Wobble1, Wobble2', 'got wibbles, wobbles and nuts' );


#-----------------------------------------------------------------------
# check whitespace tolerance
#-----------------------------------------------------------------------

$tds = $query->query(
    'table.one tr.wibble td, 
    table 
    tr.wobble 
    td, 
    a[rel=nuts]'
);
is( $tds->size, 4, 'four elements in whitespace query' );


#-----------------------------------------------------------------------
# check we can call it in list context and get elements
#-----------------------------------------------------------------------

my @elems = $query->query('p');
is( scalar(@elems), 2, 'got two p elements in list context' );
is( ref $elems[0], 'HTML::Element', 'got HTML::Element object' );


#-----------------------------------------------------------------------
# check bad queries return errors
#-----------------------------------------------------------------------

ok( ! $query->try('query'), 'no query failed' );
is( $query->reason, 'html.query error - No query specified', 'got no query error message' );

ok( ! $query->try( query => '' ), 'empty query failed' );
is( $query->reason, 'html.query error - No query specified', 'got empty query error message' );

ok( ! $query->try( query => '  ' ), 'blank query failed' );
is( $query->reason, 'html.query error - Invalid query specified:   ', 'got blank query error message' );


#-----------------------------------------------------------------------
# check id/class with minus-character
#-----------------------------------------------------------------------

my @found = $query->query('#test-id');
is( scalar(@found), 1, 'found element with id "test-id"' );
is( $found[0]->as_trimmed_text, 'test-id content', 'got right element' );

@found = $query->query('.new-class');
is( scalar(@found), 4, 'found all elements with class "new-class"' );
is( $found[0]->as_trimmed_text, 'This is another div with bar class', 'got right 1st element' );
is( $found[1]->as_trimmed_text, 'This is a span with bar class', 'got right 2nd element' );
is( $found[2]->as_trimmed_text, 'Wobble1', 'got right 3rd element' );
is( $found[3]->as_trimmed_text, 'test-id content', 'got right 4th element' );
