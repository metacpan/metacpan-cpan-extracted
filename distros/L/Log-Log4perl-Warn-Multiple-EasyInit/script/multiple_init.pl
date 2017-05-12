#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;
use lib "${FindBin::Bin}/../t/lib";

BEGIN {
    use Log::Log4perl::Warn::Multiple::EasyInit;
}

use foo;
use bar;
use baz;
use quux;
