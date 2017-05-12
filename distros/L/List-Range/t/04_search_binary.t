use strict;
use Test::More 0.98;

use List::Range;
use List::Range::Set;
use List::Range::Search::Binary;

my @ranges = (
    List::Range->new(name => "B", lower =>  1, upper => 10),
    List::Range->new(name => "A",              upper =>  0),
    List::Range->new(name => "C", lower => 11, upper => 20),
    List::Range->new(name => "D", lower => 21, upper => 30),
    List::Range->new(name => "E", lower => 31, upper => 40),
    List::Range->new(name => "F", lower => 41, upper => 50),
);

my $set = List::Range::Set->new('MySet' => \@ranges);
my $searcher = List::Range::Search::Binary->new($set);
isa_ok $searcher, 'List::Range::Search::Binary';

isnt $searcher->ranges, \@ranges, 'should not return the same range of array reference.';
is_deeply $searcher->ranges, [$ranges[1], $ranges[0], @ranges[2..5]], 'ranges should be sorted';

is +$searcher->find(0)->name,  'A',    '0 is included in the A range';
is +$searcher->find(1)->name,  'B',    '1 is included in the B range';
is +$searcher->find(5)->name,  'B',    '5 is included in the B range';
is +$searcher->find(10)->name, 'B',   '10 is included in the B range';
is +$searcher->find(11)->name, 'C',   '11 is included in the C range';
is +$searcher->find(50)->name, 'F',   '50 is included in the F range';
is +$searcher->find(51),       undef, '51 is not included in the set';

done_testing;
