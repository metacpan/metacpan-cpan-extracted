#!perl -w
use strict;
use Test::More;

use Imager::File::WEBP;

my $ver = Imager::File::WEBP::libversion();
isnt($ver, "", "check some sort of version is returned");

like($ver, qr/\bmux [0-9]+\.[0-9]+\.[0-9]+\b/,
     "and contains the mux version");

like($ver, qr/\bencoder [0-9]+\.[0-9]+\.[0-9]+\b/,
     "and contains the encoder version");

like($ver, qr/\bdecoder [0-9]+\.[0-9]+\.[0-9]+\b/,
     "and contains the decoder version");

done_testing();
