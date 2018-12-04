#!perl -w
use strict;
use Test::More;

use Imager::File::WEBP;

my $ver = Imager::File::WEBP::i_webp_libversion();
isnt($ver, "", "check some sort of version is returned");

like($ver, qr/\bmux [0-9]+\.[0-9]+\.[0-9]+\b/,
     "and contains the mux version");

done_testing();
