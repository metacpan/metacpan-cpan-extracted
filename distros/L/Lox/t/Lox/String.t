#!perl
use strict;
use warnings;
use Test::More;
use Lox::String;

ok my $str = Lox::String->new('foo'), 'construct a new Lox::String obj';
is "$str", 'foo', 'stringifies to "foo"';
ok $str && 1, 'Lox::String is truthy';

done_testing;
