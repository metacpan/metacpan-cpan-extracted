#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use tools;

if ( not env_exists('STERILIZE_ENV') ) {
  diag("\e[31STERILIZE_ENV is not set, skipping, because this is probably Travis's Default ( and unwanted ) target");
  exit 0;
}
if ( not env_true('STERILIZE_ENV') ) {
  diag('STERILIZE_ENV unset or false, not sterilizing');
  exit 0;
}

if ( not env_true('TRAVIS') ) {
  diag('Is not running under travis!');
  exit 1;
}

deploy_sterile();
