use strict;
use warnings;
use Test::More;

use JSON::Lines;

my @data = (
        { foo => 'a', bar => 'b' },
        { foo => 'f', baz => 'g' },
        { foo => 'x', bar => 'y', baz => 'z' }
);

my $expected = join("\n",
        '["bar","baz","foo"]',
        '["b",null,"a"]',
        '[null,"g","f"]',
        '["y","z","x"]',
        '',
);

my $got = JSON::Lines->new(
        parse_headers => 1,
        canonical => 1,
)->encode( @data );

is( $got, $expected, "missing fields in output" );
done_testing;
