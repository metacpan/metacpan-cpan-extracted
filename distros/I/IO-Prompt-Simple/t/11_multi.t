use strict;
use warnings;
use Test::More;
use t::Util;

test_prompt(
    input  => 'foo bar',
    answer => [qw/hoge fuga/],
    opts   => {
        choices => { foo => 'hoge', bar => 'fuga' },
        multi   => 1,
    },
    prompt => 'prompt (bar/foo) : ',
    desc   => 'choices multi',
);

test_prompt(
    input  => 'hoge
foo bar',
    answer => 'hoge',
    opts   => {
        choices => { foo => 'hoge', bar => 'fuga' },
        multi   => 1,
    },
    prompt => 'prompt (bar/foo) : # Please answer `bar` or `foo`
prompt (bar/foo) : ',
    desc   => 'multi, retry: 1, answer: foo',
);

done_testing;
