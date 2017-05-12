use strict;
use utf8;
use warnings;

use JavaBin;
use Scalar::Util 'dualvar';
use Test::More;

sub enum {
    my $e = &dualvar;

    bless \$e, 'JavaBin::Enum';
}

open my $fh, '<', 't/solr';

undef $/;

is_deeply from_javabin(<$fh>), {
    maxScore => .1,
    numFound => 2,
    start    => 3,
    docs     => [{
        byte_arr           => [qw/-128 0 127/],
        byte_max           => 127,
        byte_min           => -128,
        byte_zero          => 0,
        enum_max           => enum( 2_147_483_647, 'max'),
        enum_min           => enum(-2_147_483_648, 'min'),
        enum_snowman       => enum(123, '☃'),
        enum_zero          => enum(0, 'zero'),
        false              => $JavaBin::false,
        hash_map           => {qw/foo bar baz qux/},
        iterator           => [qw/foo bar baz qux/],
        named_list         => {qw/foo bar baz qux/},
        null               => undef,
        one_small_step     => '1969-07-21T02:56:00.000Z',
        pangram            => 'The quick brown fox jumped over the lazy dog',
        pi_double          => 3.14159265358979,
        pi_float           => 3.141593,
        short_max          => 32_767,
        short_min          => -32_768,
        simple_ordered_map => {qw/foo bar baz qux/},
        snowman            => '☃',
        str_arr            => [qw/foo bar baz qux/],
        true               => $JavaBin::true,
    }],
};

done_testing;
