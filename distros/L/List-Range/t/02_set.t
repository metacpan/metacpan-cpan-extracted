use strict;
use Test::More 0.98;

use List::Range;
use List::Range::Set;

my @ranges = (
    List::Range->new(name => "B", lower =>  1, upper => 10),
    List::Range->new(name => "A",              upper =>  0),
    List::Range->new(name => "C", lower => 11, upper => 20),
    List::Range->new(name => "D", lower => 21, upper => 30),
    List::Range->new(name => "E", lower => 31, upper => 40),
    List::Range->new(name => "F", lower => 41, upper => 50),
);

my $set = List::Range::Set->new('MySet' => \@ranges);
isa_ok $set, 'List::Range';
isa_ok $set, 'List::Range::Set';

is $set->lower, '-Inf', 'should set least lower';
is $set->upper,     50, 'should set largest upper';

is $set->ranges, \@ranges, 'should return the same range of array reference.';

done_testing;

