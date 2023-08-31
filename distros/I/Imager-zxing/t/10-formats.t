#!perl
use strict;
use warnings;

use Test::More;

use Imager::zxing;

my $d = Imager::zxing::Decoder->new;
my @f = $d->formats;
ok(grep(/DataMatrix/, @f), "check we have an expected format")
  or diag "Got formats @f";

done_testing();
