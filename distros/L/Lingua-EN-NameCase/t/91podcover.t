#!/usr/bin/perl -w
use strict;

use Test::More;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTHOR_TESTING} );

use Test::Needs { "Test::Pod::Coverage" => "0.08" };    # block form: no string eval

Test::Pod::Coverage->import();
all_pod_coverage_ok({ also_private => ['new'] });
