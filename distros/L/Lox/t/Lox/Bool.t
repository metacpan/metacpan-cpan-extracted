#!perl
use strict;
use warnings;
use Test::More;
use Lox::Bool;

is ref $True, 'Lox::True', 'Get the Lox::True singleton';
is "$True", 'true', 'stringifies to "true"';
ok $True && 1, 'True is truthy';
is ref !$True, 'Lox::False', 'True negates to False';

is ref $False, 'Lox::False', 'Get the False singleton';
is "$False", 'false', 'stringifies to "false"';
ok $False || 1, 'False is falsey';
ok ref !$False eq 'Lox::True', 'False negates to True';

done_testing;
