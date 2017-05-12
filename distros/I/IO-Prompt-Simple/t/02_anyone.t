use strict;
use warnings;
use Test::More;
use t::Util;

test_prompt(
    input  => 'y',
    answer => 'y',
    opts   => {
        anyone => [qw/y n/],
    },
    prompt => 'prompt (y/n) : ',
    desc   => 'anyone (y/n), answer: y',
);

test_prompt(
    input  => 'foo
n',
    answer => 'n',
    opts   => {
        anyone => [qw/y n/],
    },
    prompt => 'prompt (y/n) : # Please answer `y` or `n`
prompt (y/n) : ',
    desc   => 'anyone (y/n), input: foo -> n',
);

test_prompt(
    input  => 'foo
',
    answer => 'n',
    opts   => {
        default => 'n',
        anyone  => [qw/y n/],
    },
    prompt => 'prompt (y/n) [n]: # Please answer `y` or `n`
prompt (y/n) [n]: ',
    desc   => 'anyone (y/n), miss match, default: n',
);

test_prompt(
    input  => 'N',
    answer => 'n',
    opts   => {
        anyone      => [qw/y n/],
        ignore_case => 1,
    },
    prompt => 'prompt (y/n) : ',
    desc   => 'anyone (y/n), ignore_case, answer: N',
);

test_prompt(
    input  => 'N',
    answer => 'y',
    opts   => {
        default     => 'y',
        anyone      => [qw/y n/],
        use_default => 1,
    },
    prompt => 'prompt (y/n) [y]: y
',
    desc   => 'anyone (y/n), use_default: 1',
);

done_testing;
