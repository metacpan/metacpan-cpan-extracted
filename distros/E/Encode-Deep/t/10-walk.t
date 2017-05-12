use strict;
use warnings;

use Test::More tests => 17;

use_ok( 'Encode::Deep' );

my $sub_reverse = sub { return scalar reverse $_[0]; };

# Basic scalar tests
is(
    Encode::Deep::_walk('abc', $sub_reverse, {}),
    'cba',
    'Simple scalar value',
);
is(
    Encode::Deep::_walk('12345', $sub_reverse, {}),
    '54321',
    'Simple numbers',
);

# Scalar reference
is_deeply(
    Encode::Deep::_walk(\'abc', $sub_reverse, {}),
    \'cba',
    'Scalar ref',
);

# Array reference
is_deeply(
    Encode::Deep::_walk(['abc','def','12345'], $sub_reverse, {}),
    ['cba','fed','54321'],
    'Array ref',
);

# Hash reference
is_deeply(
    Encode::Deep::_walk({foo => 'bar', baz => 123,}, $sub_reverse, {}),
    {oof => 'rab', zab => 321},
    'Hash ref',
);

# Array of scalar references
is_deeply(
    Encode::Deep::_walk([\'abc',\'def',\'12345'], $sub_reverse, {}),
    [\'cba',\'fed',\'54321'],
    'Array of scalar refs',
);

# Array of array references
is_deeply(
    Encode::Deep::_walk([['abc','def'],['12345','67890'],['a1b2c3',12,'xyz']], $sub_reverse, {}),
    [['cba','fed'],['54321','09876'],['3c2b1a',21,'zyx']],
    'Array of array refs',
);

# Array of hash references
is_deeply(
    Encode::Deep::_walk([{'abc' => 'def'},{'12345' => '67890', foo => 'bar'},{'a1b2c3' => 'xyz'}], $sub_reverse, {}),
    [{'cba','fed'},{'54321' => '09876', oof => 'rab'},{'3c2b1a' => 'zyx'}],
    'Array of hash refs',
);

# Hash tree with references
is_deeply(
    Encode::Deep::_walk({
            foo => 'bar',
            array => ['abc','defgh'],
            hash => {baz => 'foo'},
        }, $sub_reverse, {}),
    {
        oof => 'rab',
        yarra => ['cba', 'hgfed'],
        hsah => {zab => 'oof'},
    },
    'Hash with refs',
);

# Deep hash
is_deeply(
    Encode::Deep::_walk({
            ab => {
                    cd => { efg => { foo => 'bar' }}
                },
        }, $sub_reverse, {}),
    {
        ba => {
                dc => { gfe => { oof => 'rab' }}
            },
    },
    'Multi-level hash',
);

# Double-used reference
my $double_hash_source = {foo => 'bar'};
my $result = Encode::Deep::_walk({
        ab => $double_hash_source,
        cde => $double_hash_source,
    }, $sub_reverse, {});
is_deeply(
    $result,
    {
        ba => { oof => 'rab' },
        edc => { oof => 'rab' },
    },
    'Double-used reference',
);
is($result->{ba},$result->{edc},'Double-used reference: Result ref reuse');

# Circular hash reference
my $circular_hash_source = {};
$circular_hash_source->{abc} = $circular_hash_source;
my $circular_hash_result = {};
$circular_hash_result->{cba} = $circular_hash_result;
$result = Encode::Deep::_walk($circular_hash_source, $sub_reverse, {});
is_deeply(
    $result,
    $circular_hash_result,
    'Circular reference',
);
is($result->{cba},$result,'Circular reference: self-reference');

# Hidden circular hash reference
$circular_hash_source = {};
$circular_hash_source->{abc} = { test => $circular_hash_source };
$circular_hash_result = {};
$circular_hash_result->{cba} = { tset => $circular_hash_result };
$result = Encode::Deep::_walk($circular_hash_source, $sub_reverse, {});
is_deeply(
    $result,
    $circular_hash_result,
    'Circular reference',
);
is($result->{cba}->{tset},$result,'Circular reference: self-reference');
