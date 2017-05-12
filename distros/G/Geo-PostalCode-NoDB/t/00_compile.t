#!/usr/bin/perl

use warnings;
use strict;
use Test::More;

BEGIN {
  plan tests => 1;

  use_ok('Geo::PostalCode::NoDB');
}

1;
