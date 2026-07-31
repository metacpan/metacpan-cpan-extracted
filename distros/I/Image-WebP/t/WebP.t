#!/usr/bin/perl

use strict;
use warnings;
use 5.10.0;
use Test::More 0.88;

use Image::WebP;

my $web = Image::WebP->new;

my $data_buff;
open my $input, "<", "t/test.webp" or die "$!";
binmode $input;
read $input, $data_buff, -s "t/test.webp";
close $input;

my $info = $web->WebPGetInfo($data_buff);
is($info->{status}, 1, "recognises the WebP fixture");

for my $format (qw(RGB BGR RGBA ARGB BGRA)) {
    my $channels = length($format) == 4 ? 4 : 3;
    my $decoded = $web->WebPDecodeSimple($data_buff, $format);
    is($decoded->{width}, $info->{width}, "$format decode width");
    is($decoded->{height}, $info->{height}, "$format decode height");
    is(
        length($decoded->{data}),
        $info->{width} * $info->{height} * $channels,
        "$format decode returns every pixel byte",
    );
}

my $decoded = $web->WebPDecodeSimple($data_buff, "RGB");
my $encoded = $web->WebPEncodeSimple(
    $decoded->{'data'},
    $decoded->{'width'},
    $decoded->{'height'},
    "RGB",
    {}
   );

ok($encoded->{size} > 0, "encodes lossy WebP data");
is(length($encoded->{data}), $encoded->{size}, "reports the lossy output size");
is($web->WebPGetInfo($encoded->{data})->{status}, 1, "lossy output is WebP");

$encoded = $web->WebPEncodeSimple(
    $decoded->{'data'},
    $decoded->{'width'},
    $decoded->{'height'},
    "RGB",
    { 'lossless' => 1, quality => 80.0 }
   );

ok($encoded->{size} > 0, "encodes lossless WebP data");
is(length($encoded->{data}), $encoded->{size}, "reports the lossless output size");
is($web->WebPGetInfo($encoded->{data})->{status}, 1, "lossless output is WebP");

my $decoded_rgba = $web->WebPDecodeSimple($data_buff, "RGBA");
my $encoded_rgba = $web->WebPEncodeSimple(
    $decoded_rgba->{data},
    $decoded_rgba->{width},
    $decoded_rgba->{height},
    "RGBA",
    { loseless => 1 },
);
is(
    $web->WebPGetInfo($encoded_rgba->{data})->{status},
    1,
    "legacy loseless option encodes a four-channel image",
);

eval { $web->WebPDecodeSimple("not a WebP image", "RGB") };
like($@, qr/failed to decode WebP data/, "rejects invalid WebP input");

eval { $web->WebPEncodeSimple("\0" x 3, 2, 2, "RGB", {}) };
like(
    $@,
    qr/input buffer is shorter than its dimensions and stride require/,
    "rejects a short raw input buffer",
);

eval { $web->WebPDecodeSimple($data_buff, "XYZ") };
like($@, qr/Unsupported WebP decode format/, "rejects unknown decode formats");

eval { Image::WebP::xs_WebPDecodeSimple("x", 4096, 4) };
like(
    $@,
    qr/data size exceeds the input buffer/,
    "rejects an oversized direct XS decode length",
);

done_testing;
