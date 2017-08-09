#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( one_of );

like dies {
        my $x = one_of()
    },
    qr/at least one value/,
    'empty one_of causes exception';

my $one_of = one_of('a', 'b', 'c');

my ($v, $e);

($v, $e) = $one_of->('a');
ok $v, 'one_of passes a';

($v, $e) = $one_of->('b');
ok $v, 'one_of passes b';

($v, $e) = $one_of->('c');
ok $v, 'one_of passes c';

($v, $e) = $one_of->('A');
ok !$v, 'one_of fails A';
like $e, qr/be one of:/, 'got an error message';

done_testing;
