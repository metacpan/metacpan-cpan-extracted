use strict;
use warnings;

use Test::More;
use HTTP::XSCookies qw[crush_cookie];

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
        [ 't12', '', {} ],
        [ 't13', undef, {} ],
    );

    for my $test (@tests) {
        is_deeply( crush_cookie($test->[1]), $test->[2], $test->[0] );
    }
}
