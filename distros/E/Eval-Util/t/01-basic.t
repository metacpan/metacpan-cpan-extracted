#!perl

use strict;
use warnings;
use Test::More 0.98;

use Eval::Util qw(
                     inside_eval
                     inside_block_eval
                     inside_string_eval
                     eval_level
             );

my $val1a = inside_eval();
my $val2a; eval { $val2a = inside_eval() };
my $val3a; eval q[$val3a = inside_eval()];

my $val1b = inside_block_eval();
my $val2b; eval { $val2b = inside_block_eval() };
my $val3b; eval q[$val3b = inside_block_eval()];

my $val1c = inside_string_eval();
my $val2c; eval { $val2c = inside_string_eval() };
my $val3c; eval q[$val3c = inside_string_eval()];

my $level1 = eval_level();
my $level2; eval { $level2 = eval_level() };
my $level3; eval { eval { $level3 = eval_level() } };

subtest inside_eval => sub {
    ok(!$val1a);
    ok( $val2a);
    ok( $val3a);
};

subtest inside_block_eval => sub {
    ok(!$val1b);
    ok( $val2b);
    ok(!$val3b);
};

subtest inside_string_eval => sub {
    ok(!$val1c);
    ok(!$val2c);
    ok( $val3c);
};

subtest eval_level => sub {
    is($level1, 0);
    is($level2, 1);
    is($level3, 2);
};

DONE_TESTING:
done_testing;
