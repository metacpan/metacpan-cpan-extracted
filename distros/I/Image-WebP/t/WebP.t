#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use 5.10.0;
use Test::More;

plan tests => 3;

# use lib "../lib/";
# use blib "../blib/arch/auto";
use Image::WebP;


my $web = new Image::WebP;

my $data_buff;
open(FINP, "<", "t/test.webp") or die "$!";
read(FINP, $data_buff, -s "t/test.webp");
close(FINP);

my $decoded = $web->WebPDecodeSimple($data_buff, "RGB");
ok($decoded->{height} == 128, "testing decompression");



my $encoded = $web->WebPEncodeSimple(
    $decoded->{'data'},
    $decoded->{'width'},
    $decoded->{'height'},
    "RGB",
    {  }
   );

ok($encoded->{size} != 0, "testing lossy compression");

$encoded = $web->WebPEncodeSimple(
    $decoded->{'data'},
    $decoded->{'width'},
    $decoded->{'height'},
    "RGB",
    { 'loseless' => 1, quality => 80.0 }
   );

ok($encoded->{size} != 0, "testing losseless compression");
