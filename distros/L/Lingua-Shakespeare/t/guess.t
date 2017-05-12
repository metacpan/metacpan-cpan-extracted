#!perl

use Test::More tests => 2;
require "t/common.pl";

my $buffer = tie *OUT, 'Handle';
my $input  = tie *STDIN, 'Handle';

$$input = ">><><>>><=";
my $expect = join("\r\n", qw(500?  750?  875?  812?  843?  827?  835?  839?  841?  840?  840),'');

select OUT;
my $ok = require "examples/guess.spl";
select STDOUT;
ok($ok);
is($$buffer,$expect);
