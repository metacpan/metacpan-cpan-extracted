#============================================================= -*-perl-*-
#
# t/combinator.t
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
    tests => 29,
    debug => 'HTML::Query',
    args  => \@ARGV;

use HTML::Query 'Query';

our $Query    = 'HTML::Query';
our $Builder  = 'HTML::TreeBuilder';
our $test_dir = Dir($Bin);
our $html_dir = $test_dir->dir('html')->must_exist;
our $multi = $html_dir->file('multioperator.html')->must_exist;

my ($query, $tree);

#-----------------------------------------------------------------------
# load up second test file and create an HTML::Query object for it.
#-----------------------------------------------------------------------

$tree = $Builder->new;
$tree->parse_file( $multi->absolute );
ok( $tree, 'parsed tree for second test file: ' . $multi->name );
$query = Query $tree;
ok( $query, 'created query' );

#-----------------------------------------------------------------------
# look for some basic elements using duplicate tagnames in query
#-----------------------------------------------------------------------

my $test0 = $query->query('body');
ok( $test0, 'body' );
is( $test0->size, 1, 'body' );
is( join(', ', $test0->as_trimmed_text), '(body) (div) (div) (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div) (div)(/div)(div)(/div) (/div) (/div) (/body)','got var' );

my $test1 = $query->query('body > div');
ok( $test1, 'body > div' );
is( $test1->size, 1, 'body > div' );
is( join(', ', $test1->as_trimmed_text), '(div) (div) (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div) (div)(/div)(div)(/div) (/div) (/div)','got var' );

my $test2 = $query->query('body>div');
ok( $test2, 'body>div' );
is( $test2->size, 1, 'body>div' );
is( join(', ', $test2->as_trimmed_text), '(div) (div) (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div) (div)(/div)(div)(/div) (/div) (/div)','got var' );

my $test3 = $query->query('body> div');
ok( $test3, 'body > div' );
is( $test3->size, 1, 'body > div' );
is( join(', ', $test3->as_trimmed_text), '(div) (div) (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div) (div)(/div)(div)(/div) (/div) (/div)','got var' );

my $test4 = $query->query('body >div');
ok( $test4, 'body > div' );
is( $test4->size, 1, 'body > div' );
is( join(', ', $test4->as_trimmed_text), '(div) (div) (div class="danger") (div class="green") (div class="yellow") (div class="danger") (div class="green")(/div) (/div) (/div) (/div) (/div) (div)(/div)(div)(/div) (/div) (/div)','got var' );

my $test5 = $query->query('div + div');
ok( $test5, 'div + div' );
is( $test5->size, 2, 'div + div' );
is( join(', ', $test5->as_trimmed_text), '(div)(/div), (div)(/div)','got var' );

my $test6 = $query->query('div+ div');
ok( $test6, 'div + div' );
is( $test6->size, 2, 'div+ div' );
is( join(', ', $test6->as_trimmed_text), '(div)(/div), (div)(/div)','got var' );

my $test7 = $query->query('div +div');
ok( $test7, 'div + div' );
is( $test7->size, 2, 'div +div' );
is( join(', ', $test7->as_trimmed_text), '(div)(/div), (div)(/div)','got var' );

my $test8 = $query->query('div+div');
ok( $test8, 'div + div' );
is( $test8->size, 2, 'div+div' );
is( join(', ', $test8->as_trimmed_text), '(div)(/div), (div)(/div)','got var' );
