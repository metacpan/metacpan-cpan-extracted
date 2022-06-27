#!perl
use strict;
use warnings;
use Test::More;
use Imager;
use Imager::File::PNG;

my $lib_version = Imager::File::PNG::i_png_lib_version();

diag <<EOS;

Imager           : $Imager::VERSION
Imager::File::PNG: $Imager::File::PNG::VERSION
libpng           : $lib_version
EOS

ok(1, "a test");

done_testing();
