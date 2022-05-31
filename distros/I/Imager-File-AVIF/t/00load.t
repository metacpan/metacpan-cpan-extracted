#!perl -w
use strict;
use Test::More;

if (use_ok("Imager::File::AVIF")) {
  diag "";
  diag "libavif runtime version: ".Imager::File::AVIF->libversion;
  diag "libavif build time version: ".Imager::File::AVIF->buildversion;
  diag "libavif codecs: ".Imager::File::AVIF->codecs;
}

done_testing();
