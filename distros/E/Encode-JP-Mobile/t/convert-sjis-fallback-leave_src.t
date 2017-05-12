use strict;
use warnings;
use Test::More tests => 10;
use Encode;
use Encode::JP::Mobile;

{
    my $x = 'F';

    is decode( 'x-sjis-kddi-auto', $x ), $x;

    is decode( 'x-sjis-kddi-auto', $x, Encode::FB_PERLQQ|Encode::LEAVE_SRC ), $x;
    is $x, $x, 'leave';

    is decode( 'x-sjis-kddi-auto', $x, Encode::FB_CROAK ), $x;

    is decode( 'x-sjis-kddi-auto', $x, sub { $_ } ), $x;
}

{
    my $sjis = "\xF6\xD5";
    my $uni = "\x{E001}";
    my $x;

    $x = $uni;
    is encode( 'x-sjis-kddi-auto', $x ), $sjis;

    $x = $uni;
    is encode( 'x-sjis-kddi-auto', $x, Encode::FB_PERLQQ ), $sjis;
    is $x, $uni, 'leave!';

    $x = $uni;
    is encode( 'x-sjis-kddi-auto', $x, Encode::FB_CROAK ), $sjis;

    $x = $uni;
    is encode( 'x-sjis-kddi-auto', $x, sub { } ), $sjis;
}
