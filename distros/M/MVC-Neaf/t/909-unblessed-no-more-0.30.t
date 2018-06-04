#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

# NOTE! This is NOT about set_path_defaults being deprecated
# This is about MVC::Neaf->method call being deprecated
warnings_like {
    MVC::Neaf->set_path_defaults( { foo => 42 } );
} [ qr/MVC::Neaf->set_path_defaults.*DEPRECATED.*neaf.*new/ ], "Deprecated warning";

done_testing;
