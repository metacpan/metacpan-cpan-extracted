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
    tests => 5,
    debug => 'HTML::Query',
    args  => \@ARGV;

use HTML::Query 'Query';

our $Query    = 'HTML::Query';
our $Builder  = 'HTML::TreeBuilder';
our $test_dir = Dir($Bin);
our $html_dir = $test_dir->dir('html')->must_exist;
our $test2    = $html_dir->file('test2.html')->must_exist;

my ($query, $tree);


#-----------------------------------------------------------------------
# load up second test file and create an HTML::Query object for it.
#-----------------------------------------------------------------------

$tree = $Builder->new;
$tree->parse_file( $test2->absolute );
ok( $tree, 'parsed tree for second test file: ' . $test2->name );
$query = Query $tree;
ok( $query, 'created query' );

#-----------------------------------------------------------------------
# look for some basic elements using duplicate tagnames in query
#-----------------------------------------------------------------------

my $vars = $query->query('div div span');
ok( $vars, 'got div div span' );
is( $vars->size, 1, 'on var in div div span query' );
is( join(', ', $vars->as_trimmed_text), 'some span deep in some divs','got var' );
