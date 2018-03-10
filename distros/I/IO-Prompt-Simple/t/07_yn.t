use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../";
use t::Util;

test_prompt(
    input  => 'y',
    answer => '1',
    opts   => { yn => 1 },
    prompt => 'prompt (y/n) : ',
    desc   => 'answer: y',
);

test_prompt(
    input  => 'N',
    answer => '0',
    opts   => { yn => 1 },
    prompt => 'prompt (y/n) : ',
    desc   => 'answer: N',
);

test_prompt(
    input  => 'N
n',
    answer => '0',
    opts   => {
        yn          => 1,
        ignore_case => 0,
    },
    prompt => 'prompt (y/n) : # Please answer `y` or `n`
prompt (y/n) : ',
    desc   => 'ignore_case: 0, answer: N',
);

test_prompt(
    input  => 'y',
    answer => '1',
    opts   => {
        yn     => 1,
        anyone => [qw/foo bar/],
    },
    prompt => 'prompt (y/n) : ',
    desc   => 'skip anyone, answer: y',
);

test_prompt(
    input  => '',
    answer => '1',
    opts   => {
        yn      => 1,
        default => 'y',
    },
    prompt => 'prompt (y/n) [y]: ',
    desc   => 'skip anyone, default: y',
);

done_testing;
