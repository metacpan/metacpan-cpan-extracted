#!perl

use Test::More tests => 2;
require "t/common.pl";

my $buffer = tie *OUT, 'Handle';
my $input  = tie *STDIN, 'Handle';

$$input = "abcdefghi";
my $expect = reverse $$input;

select OUT;
my $ok = require "examples/reverse.spl";
select STDOUT;
ok($ok);
is($$buffer,$expect);
