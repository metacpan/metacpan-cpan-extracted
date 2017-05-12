#!perl

use Test::More tests => 2;
require "t/common.pl";

my $buffer = tie *OUT, 'Handle';
my $input  = tie *STDIN, 'Handle';

$$input = "100\n";
my $expect = ">" . join("\n", qw(2 3 5 7 11 13 17 19 23 29 31 37 41 43
			47 53 59 61 67 71 73 79 83 89 97)) . "\n";

select OUT;
my $ok = require "examples/primes.spl";
select STDOUT;
ok($ok);
is($$buffer,$expect);
