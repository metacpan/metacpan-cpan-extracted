#!/usr/bin/env perl

# Test that normal files are actually being loaded from disk after
#    loading an in-memory template
# test_data=[% test_data %]

use strict;
use warnings;
use Test::More;
use File::Basename;

use MVC::Neaf::View::TT;

my $view = MVC::Neaf::View::TT->new(
    INCLUDE_PATH => dirname( __FILE__ ),
    preload => { foo => '[% bar %]' },
);

my $content = $view->render(
    { -template => basename( __FILE__ ), test_data => 2+2 } );

like $content, qr/\n# [t]est_data=4\n/s, "This file is valid template";

done_testing;
