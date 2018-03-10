use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../";
use t::Util;

test_prompt(
    input  => 'foo',
    answer => 'hoge',
    opts   => {
        anyone => { foo => 'hoge', bar => 'fuga' },
    },
    prompt => 'prompt (bar/foo) : ',
    desc   => 'anyone (bar/foo), answer: foo',
);

test_prompt(
    input  => 'hoge
foo',
    answer => 'hoge',
    opts   => {
        anyone => { foo => 'hoge', bar => 'fuga' },
    },
    prompt => 'prompt (bar/foo) : # Please answer `bar` or `foo`
prompt (bar/foo) : ',
    desc   => 'anyone: (bar/foo), retry: 1, answer: foo',
);

test_prompt(
    input  => 'BaR',
    answer => 'fuga',
    opts   => {
        anyone      => { foo => 'hoge', bar => 'fuga' },
        ignore_case => 1,
    },
    prompt => 'prompt (bar/foo) : ',
    desc   => 'anyone: (bar/foo), ignore_case: 1, answer: foo',
);

test_prompt(
    input  => 'foo',
    answer => 'hoge',
    opts   => {
        anyone  => { foo => 'hoge', bar => 'fuga' },
        verbose => 1,
    },
    prompt => '# bar => fuga
# foo => hoge
prompt : ',
    desc   => 'anyone: (bar/foo), verbose: 1, answer: foo',
);

test_prompt(
    input  => 'fo',
    answer => 'hoge',
    opts   => {
        anyone  => { fo => 'hoge', bar => 'fuga' },
        verbose => 1,
    },
    prompt => '# bar => fuga
# fo  => hoge
prompt : ',
    desc   => 'anyone: (bar/foo), verbose: 1, answer: foo, format',
);

test_prompt(
    input  => 'Hoge
foo',
    answer => 'hoge',
    opts   => {
        anyone  => { foo => 'hoge', bar => 'fuga' },
        verbose => 1,
    },
    prompt => '# bar => fuga
# foo => hoge
prompt : # Please answer `bar` or `foo`
# bar => fuga
# foo => hoge
prompt : ',
    desc   => 'anyone: (bar/foo), retry: 1, answer: foo',
);

test_prompt(
    input  => 'Foo',
    answer => 'hoge',
    opts   => {
        anyone      => { foo => 'hoge', bar => 'fuga' },
        verbose     => 1,
        ignore_case => 1,
    },
    prompt => '# bar => fuga
# foo => hoge
prompt : ',
    desc   => 'anyone: (bar/foo), verbose:1, ignore_case: 1, answer: foo',
);

done_testing;
