use strict;
use warnings;
use utf8;

use Test::More 0.98;
use Test::Base::Less;

use JSON5;
use JSON5::Parser;

my $parser = JSON5::Parser->new->allow_nonref->utf8;

for my $block (blocks) {
    eval { $parser->parse($block->input) };
    like $@, qr/^Syntax Error:/, $block->get_section('name')
        or diag $block->input;
}

done_testing;

__DATA__
===
--- name: invalid value
--- input
a

===
--- name: not closed array
--- input
[

===
--- name: empty array with comma
--- input
[,]

===
--- name: invalid value in array
--- input
[a]

===
--- name: valid value in array but not closed
--- input
["valid value"

===
--- name: valid value and comma in array but not closed
--- input
["valid value",

===
--- name: not closed object
--- input
{

===
--- name: not closed object with identifier
--- input
{identifier

===
--- name: not closed object with identifier and colon
--- input
{identifier:

===
--- name: not closed object with identifier and colon and invalid value
--- input
{identifier:a

===
--- name: not closed after valid value
--- input
{identifier:"valid value"


===
--- name: not closed after valid value and comma
--- input
{identifier:"valid value",

===
--- name: complex nested broken object
--- input
{
 a: {
  b: [[[]]]],
 }
}
