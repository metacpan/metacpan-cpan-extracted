use strict;
use warnings;
use Test::Requires 'Hash::MultiValue';
use Test::More;
use t::Util;

test_prompt(
    input  => 'b',
    answer => 'foo',
    opts   => { anyone => Hash::MultiValue->new(b => 'foo', a => 'bar') },
    prompt => 'prompt (b/a) : ',
    desc   => 'answer: b',
);

test_prompt(
    input  => 'c
b',
    answer => 'foo',
    opts   => { anyone => Hash::MultiValue->new(b => 'foo', a => 'bar') },
    prompt => 'prompt (b/a) : # Please answer `b` or `a`
prompt (b/a) : ',
    desc   => 'answer: c => b',
);

test_prompt(
    input  => 'c
b',
    answer => 'foo',
    opts   => {
        anyone  => Hash::MultiValue->new(b => 'foo', a => 'bar'),
        verbose => 1,
    },
    prompt => '# b => foo
# a => bar
prompt : # Please answer `b` or `a`
# b => foo
# a => bar
prompt : ',
    desc   => 'verbose => 1',
);

done_testing;
