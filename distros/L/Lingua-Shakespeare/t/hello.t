#!perl

use Test::More tests => 2;
require "t/common.pl";

my $buffer = tie *OUT, 'Handle';
select OUT;
my $ok = require "examples/hello.spl";
select STDOUT;
ok($ok);
is($$buffer,"Hello World!\n");

