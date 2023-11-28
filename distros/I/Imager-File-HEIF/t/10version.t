#!perl -w
use strict;
use Test::More;

use Imager::File::HEIF;

my $ver = Imager::File::HEIF->libversion();
isnt($ver, "", "check some sort of version is returned");

my $bver = Imager::File::HEIF->buildversion();
isnt($bver, "", "check some sort of build version is returned");

like($ver, qr/^[0-9]+\.[0-9]+\.[0-9]+$/,
     "and contains the version");

diag "libheif version $ver";
diag "libheif build version $bver";

done_testing();
