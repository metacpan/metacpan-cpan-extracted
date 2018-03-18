use strict;
use warnings;

use Data::Dumper;
use Test::More;
use HTTP::XSCookies qw[crush_cookie bake_cookie];

exit main();

sub main {
    test_crush_cookie();

    done_testing();
    return 0;
}

sub test_crush_cookie {
    my $longkey = 'x'x1024;

    my @tests = (
        [ 't00', 'Foo=Bar; Bar=Baz; XXX=Foo%20Bar; YYY=0; YYY=3', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
        [ 't01', 'Foo=Bar; Bar=Baz; XXX=Foo%20Bar; YYY=0; YYY=3;', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
        [ 't02', 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=0; YYY=3;', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
        [ 't03', 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=0; YYY=3;   ', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
        [ 't07', 'Foo=Bar; XXX=Foo%20Bar   ; YYY=', { Foo => 'Bar', XXX => 'Foo Bar', YYY => "" }],
        [ 't08', 'Foo=Bar; XXX=Foo%20Bar   ; YYY=;', { Foo => 'Bar', XXX => 'Foo Bar', YYY => "" }],
        [ 't09', 'Foo=Bar; XXX=Foo%20Bar   ; YYY=; ', { Foo => 'Bar', XXX => 'Foo Bar',YYY => "" }],
        [ 't10', "Foo=Bar; $longkey=Bar", { Foo => 'Bar', $longkey => 'Bar'}],
        [ 't11', "Foo=Bar; $longkey=Bar; Bar=Baz", { Foo => 'Bar', $longkey => 'Bar', 'Bar'=>'Baz'}],
        [
            't20', 'product_data=blah; Expires=Mon, 30-Oct-2017 19:02:53 GMT; Path=/; HttpOnly',
            {
                product_data => 'blah',
                Expires => 'Mon, 30-Oct-2017 19:02:53 GMT',
                Path => '/',
            },
        ],
        [
            't21', 'product_data=blah; HttpOnly; Expires=Mon, 30-Oct-2017 19:02:53 GMT',
            {
                product_data => 'blah',
                Expires => 'Mon, 30-Oct-2017 19:02:53 GMT',
            },
        ],
        [ 't30', '', {} ],
        [ 't31', undef, {} ],
        [ 't40', 'foo=bar%26baz; Secure', { foo => [qw/bar baz/] } ],
        [ 't50', 'Foo=Bar; XXX=Foo%20Bar   ; YYY', { Foo => 'Bar', XXX => 'Foo Bar', YYY => undef }, [ 1 ] ],
        [ 't51', 'Foo=Bar; XXX=Foo%20Bar   ; YYY;', { Foo => 'Bar', XXX => 'Foo Bar', YYY => undef }, [ 1 ] ],
        [ 't52', 'Foo=Bar; XXX=Foo%20Bar   ; YYY; ', { Foo => 'Bar', XXX => 'Foo Bar', YYY => undef }, [ 1 ] ],
        [ 't60', 'Foo=Bar; XXX=Foo%20Bar   ; YYY', { Foo => 'Bar', XXX => 'Foo Bar' }, [ 0 ] ],
        [ 't61', 'Foo=Bar; XXX=Foo%20Bar   ; YYY;', { Foo => 'Bar', XXX => 'Foo Bar' }, [ 0 ] ],
        [ 't62', 'Foo=Bar; XXX=Foo%20Bar   ; YYY; ', { Foo => 'Bar', XXX => 'Foo Bar' }, [ 0 ] ],
        [ 't70', 'Foo=Bar; XXX=Foo%20Bar   ; YYY', { Foo => 'Bar', XXX => 'Foo Bar'} ],
        [ 't71', 'Foo=Bar; XXX=Foo%20Bar   ; YYY;', { Foo => 'Bar', XXX => 'Foo Bar'} ],
        [ 't72', 'Foo=Bar; XXX=Foo%20Bar   ; YYY; ', { Foo => 'Bar', XXX => 'Foo Bar'} ],
    );

    for my $test (@tests) {
        my $got = crush_cookie($test->[1], @{ $test->[3] || [] });
        is_deeply( $got, $test->[2], $test->[0] );
    }
}
