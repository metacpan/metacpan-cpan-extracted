use strict;
use warnings;
use Test::More;
use t::Util;

test_prompt(
    input  => 'y',
    answer => 'y',
    opts   => {
        regexp => 'y',
    },
    prompt => 'prompt : ',
    desc   => 'regexp y',
);

test_prompt(
    input  => 'Y',
    answer => 'Y',
    opts   => {
        regexp      => 'y',
        ignore_case => 1,
    },
    prompt => 'prompt : ',
    desc   => 'regexp: y, ignore_case: 1',
);

test_prompt(
    input  => 'd',
    answer => 'a',
    opts   => {
        default => 'a',
        regexp  => '[abc]',
    },
    prompt => qr'prompt \[a\]: # Please answer pattern \(.+\[abc]\)
prompt \[a\]: 
',
    desc   => 'regexp: [abc]',
);

test_prompt(
    input  => '1234',
    answer => '1234',
    opts   => {
        regexp => qr/[0-9]{4}/,
    },
    prompt => 'prompt : ',
    desc   => 'regexp: qr/[0-9]{4}/',
);

test_prompt(
    input  => '1234',
    answer => '3456',
    opts   => {
        default     => '3456',
        regexp      => qr/[0-9]{4}/,
        use_default => 1,
    },
    prompt => 'prompt [3456]: 3456
',
    desc   => 'regexp: qr/[0-9]{4}/',
);

done_testing;
