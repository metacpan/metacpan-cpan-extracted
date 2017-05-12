use strict;
use utf8;
use Test::More 'no_plan';
use Encode;
use Encode::JP::Mobile;

my @map = (
    { name => 'hare',  imode => "\xF8\x9F", 'ezweb-auto' => "\xF6\x60", 'softbank-auto' => "\xF9\x8B", 'softbank' => "\x1b\x24\x47\x6a\x0f" },
    { name => 'taifu', imode => "\xF8\xA4", 'ezweb-auto' => "\xF6\x41", 'softbank-auto' => "\xFB\x84", 'softbank' => "\x1b\x24\x50\x63\x0f" },
    { name => 'ramen', imode => "\xF9\xF1", 'ezweb-auto' => "\xF7\xD1", 'softbank-auto' => "\xF9\xE0", 'softbank' => "\x1b\x24\x4f\x60\x0f" },
);
for (@map) {
    $_->{airh} = $_->{imode};
}

my @carriers = qw/imode ezweb-auto softbank softbank-auto airh/;

for my $pict (@map) {

    for my $from_carrie (@carriers) {
        for my $to_carrie (@carriers) {
            is encode("x-sjis-${to_carrie}", decode("x-sjis-${from_carrie}", $pict->{$from_carrie}))
                => $pict->{$to_carrie}, 
                "$from_carrie => $to_carrie ($pict->{name})";
        }
    }
}


