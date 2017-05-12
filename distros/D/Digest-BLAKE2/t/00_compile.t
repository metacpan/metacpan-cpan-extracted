# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use Test::More;

use_ok $_ for qw(
  Digest::BLAKE2
  Digest::BLAKE2b
  Digest::BLAKE2s
);

done_testing;
