#! perl

use v5.28;
use Test2::V0;

use Iterator::Flex::Factory 'construct_from_iterable';
use Iterator::Flex::Utils 'RETURN';

subtest 'invalid iterable' => sub {

    isa_ok(
        dies { construct_from_iterable( 1 ) },
        ['Iterator::Flex::Failure::parameter'],
        'throws parameter failure'
    );
};

subtest 'invalid iterable return action' => sub {
    is(
        construct_from_iterable( 1, { action_on_failure => RETURN } ),
        undef, 'returns undef for invalid iterable',
    );
};

subtest 'unknown model parameter' => sub {
    isa_ok(
        dies { construct_from_iterable( [1], { foo => 1 } ) },
        ['Iterator::Flex::Failure::parameter'],
        'throws parameter failure',
    );
};

subtest 'unknown action on failure' => sub {
    isa_ok(
        dies { construct_from_iterable( [1], { action_on_failure => 'bogus' } ) },
        ['Iterator::Flex::Failure::parameter'],
        'throws parameter failure',
    );
};

done_testing;
