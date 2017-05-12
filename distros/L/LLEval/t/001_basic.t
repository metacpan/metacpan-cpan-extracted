#!perl -w
use strict;
use Test::More;

use LLEval;

my $lleval = LLEval->new();
my $status = $lleval->eval(<<'PL', 'pl', \my $stdout, \my $stderr);
print STDOUT 'foo';
print STDERR 'bar';
PL

is $status, 0, 'status';
is $stdout, 'foo', 'stdout';
is $stderr, 'bar', 'stderr';

done_testing;
