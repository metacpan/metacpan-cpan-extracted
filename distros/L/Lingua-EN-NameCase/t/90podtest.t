#!/usr/bin/perl -w
use strict;

use Test::More;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTHOR_TESTING} );

use Test::Needs { "Test::Pod" => "1.00" };    # block form: no string eval

Test::Pod->import();
all_pod_files_ok();
