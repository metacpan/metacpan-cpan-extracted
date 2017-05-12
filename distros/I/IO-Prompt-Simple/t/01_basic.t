use strict;
use warnings;
use Test::More;
use t::Util;

test_prompt(
    input  => 'foo',
    answer => 'foo',
    prompt => 'prompt : ',
    desc   => 'minimal args',
);

test_prompt(
    input  => 0,
    answer => 0,
    prompt => 'prompt : ',
    desc   => 'input 0',
);

test_prompt(
    input  => '',
    answer => 'foo',
    opts   => 'foo',
    prompt => 'prompt [foo]: ',
    desc   => 'choose default',
);

test_prompt(
    input  => 'bar',
    answer => 'bar',
    opts   => 'foo',
    prompt => 'prompt [foo]: ',
    desc   => 'overwite default',
);

test_prompt(
    input  => '',
    answer => '',
    opts   => '',
    prompt => 'prompt []: ',
    desc   => 'default empty',
);

test_prompt(
    input  => '',
    answer => 0,
    opts   => 0,
    prompt => 'prompt [0]: ',
    desc   => 'default 0',
);

test_prompt(
    input  => 0,
    answer => 0,
    opts   => '',
    prompt => 'prompt []: ',
    desc   => 'default empty and input 0',
);

do {
    local $ENV{PERL_IOPS_USE_DEFAULT} = 1;
    test_prompt(
        input  => '',
        answer => 'foo',
        opts   => 'foo',
        prompt => "prompt [foo]: foo\n",
        desc   => 'use default',
    );
};

do {
    local $SIG{__WARN__} = sub {}; # suppress uninitialized value
    test_prompt(
        input  => undef,
        answer => '',
        prompt => "prompt : \n",
        desc   => 'input is undef (funny case)',
    );

    test_prompt(
        input  => undef,
        answer => 'foo',
        opts   => 'foo',
        prompt => "prompt [foo]: \n",
        desc   => 'input is undef with default',
    );
};

done_testing;
