use strict;
use warnings;
use lib qw( ./lib ../lib );
use HTML::TreeBuilder;
use Badger::Filesystem '$Bin Dir';
use Badger::Test
    tests => 14,
    debug => 'HTML::Query',
    args  => \@ARGV;

use HTML::Query 'Query';

our $Query    = 'HTML::Query';
our $Builder  = 'HTML::TreeBuilder';
our $test_dir = Dir($Bin);
our $html_dir = $test_dir->dir('html')->must_exist;
our $pseudo  = $html_dir->file('pseudoclasses.html')->must_exist;

my ($query, $tree);

$tree = $Builder->new;
$tree->parse_file( $pseudo->absolute );

ok( $tree, 'parsed tree for test file: ' . $pseudo->name );
$query = Query $tree;
ok( $query, 'created query' );

my $test1 = $query->query('table td:first-child');
is( $test1->size, 3, 'test1 - size' );
is( join(" | ", $test1->as_trimmed_text), "1,1 | 2,1 | 3,1", 'test1 - text');

my $test2 = $query->query('table td:first-child');
is( $test2->size, 3, 'test2 - size' );
is( join(" | ", $test2->as_trimmed_text), "1,1 | 2,1 | 3,1", 'test2 - text');

my $test3 = $query->query('table td:last-child');
is( $test3->size, 3, 'test3 - size' );
is( join(" | ", $test3->as_trimmed_text), "1,3 | 2,3 | 3,3", 'test3 - text');

my $test4 = $query->query('table tr:first-child td');
is( $test4->size, 3, 'test4 - size' );
is( join(" | ", $test4->as_trimmed_text), "1,1 | 1,2 | 1,3", 'test4 - text');

my $test5 = $query->query('table tr:last-child td');
is( $test5->size, 3, 'test5 - size' );
is( join(" | ", $test5->as_trimmed_text), "3,1 | 3,2 | 3,3", 'test5 - text');

my $test6 = $query->query('table tr::last-child td');
is( $test6->size, 3, 'test6 - size' );
is( join(" | ", $test6->as_trimmed_text), "3,1 | 3,2 | 3,3", 'test6 - text');
