#!perl
use strict;
use warnings;
use Test::More;
use Lox::Nil;

is ref $Nil, 'Lox::Nil', 'Get Nil singleton';
is "$Nil", 'nil', 'stringifies to "nil"';
ok $Nil || 1, 'nil is falsey';
done_testing;
