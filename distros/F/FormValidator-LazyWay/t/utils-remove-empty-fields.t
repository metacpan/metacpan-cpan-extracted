use strict;
use warnings;
use Test::More qw/no_plan/;
use FormValidator::LazyWay::Utils;
use utf8;

is_deeply(
    FormValidator::LazyWay::Utils::remove_empty_fields(
        { foo => '', hoge => undef, a => 'aa' }
    ),
    { a => 'aa' }
);

is_deeply(
    FormValidator::LazyWay::Utils::remove_empty_fields(
        { foo => [ undef  ,'' ,'' ,'' , undef ] , oppai => 1 }
    ),
    { oppai => 1 }
);

