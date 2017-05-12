#!/usr/bin/perl -w
use strict;

use Test::More;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

plan skip_all => "Cannot require Mail::Outlook" if ! eval { require Mail::Outlook ; };

all_pod_coverage_ok({ also_private => [ qr/^ol/i ], },);
