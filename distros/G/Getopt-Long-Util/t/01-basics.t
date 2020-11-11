#!perl

use 5.010;
use strict;
use warnings;

use Getopt::Long::Util qw(
                             parse_getopt_long_opt_spec
                             humanize_getopt_long_opt_spec
                     );
use Test::More 0.98;

# TODO: more extensive tests

subtest parse_getopt_long_opt_spec => sub {
    ok(!parse_getopt_long_opt_spec('?'));
    ok(!parse_getopt_long_opt_spec('a|-b'));

    is_deeply(
        parse_getopt_long_opt_spec('help'),
        {dash_prefix=>'', opts=>['help']});
    is_deeply(
        parse_getopt_long_opt_spec('--help|h|?'),
        {dash_prefix=>'--', opts=>['help', 'h', '?']});
    is_deeply(
        parse_getopt_long_opt_spec('a|b.c|d#e'),
        {dash_prefix=>'', opts=>['a', 'b.c', 'd#e']});
    is_deeply(
        parse_getopt_long_opt_spec('-name|alias=i'),
        {dash_prefix=>'-', opts=>['name','alias'], type=>'i', desttype=>''});
    is_deeply(
        parse_getopt_long_opt_spec('bool!'),
        {dash_prefix=>'', opts=>['bool'], is_neg=>1});
    is_deeply(
        parse_getopt_long_opt_spec('inc+'),
        {dash_prefix=>'', opts=>['inc'], is_inc=>1});
    is_deeply(
        parse_getopt_long_opt_spec('num:1'),
        {dash_prefix=>'', opts=>['num'], optnum=>1, type=>'i', desttype=>''});
    is_deeply(
        parse_getopt_long_opt_spec('<>'),
        {is_arg=>1, dash_prefix=>'', opts=>[]});
};

subtest humanize_getopt_long_opt_spec => sub {
    is(humanize_getopt_long_opt_spec('help|h|?'), '--help, -h, -?');
    is(humanize_getopt_long_opt_spec('h|help|?'), '-h, --help, -?');
    is(humanize_getopt_long_opt_spec('foo!'), '--(no)foo');
    is(humanize_getopt_long_opt_spec('foo|f!'), '--(no)foo, -f');
    is(humanize_getopt_long_opt_spec('foo=s'), '--foo=s');
    is(humanize_getopt_long_opt_spec('--foo=s'), '--foo=s');
    is(humanize_getopt_long_opt_spec('foo|bar=s'), '--foo=s, --bar');
    is(humanize_getopt_long_opt_spec('<>'), 'argument');
};

DONE_TESTING:
done_testing;
