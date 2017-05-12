#!/usr/bin/perl

use warnings;
use strict;
use Test::More;

BEGIN {
  plan tests => 2;

  use_ok('Geo::PostalCode');
  use_ok('Geo::PostalCode::InstallDB');
}

1;
