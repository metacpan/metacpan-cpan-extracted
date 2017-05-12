#============================================================= -*-perl-*-
#
# t/element.t
#
# Test 'query' export hook which monkey patches the query() method
# into HTML::Element.
#
# Written by Andy Wardley, October 2008
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use Badger::Filesystem '$Bin Dir';
use Badger::Test
    tests => 3,
    debug => 'HTML::Query',
    args  => \@ARGV;

use HTML::TreeBuilder;
use HTML::Query 'Query query';

our $Query    = 'HTML::Query';
our $Builder  = 'HTML::TreeBuilder';
our $test_dir = Dir($Bin);
our $html_dir = $test_dir->dir('html')->must_exist;
our $test1    = $html_dir->file('test1.html')->must_exist;

my ($query, $tree);


#-----------------------------------------------------------------------
# load up test file and create tree
#-----------------------------------------------------------------------

$tree = $Builder->new;
$tree->parse_file( $test1->absolute );
ok( $tree, 'parsed tree for first test file: ' . $test1->name );


#-----------------------------------------------------------------------
# should now be able to call query() on root element
#-----------------------------------------------------------------------

my $links = $tree->query('a');
ok( $links, 'got links from tree query() method' );
is( $links->size, 6, 'got six links' );
