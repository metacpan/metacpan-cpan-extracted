#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;

BEGIN
{   eval "use Test::Prereq 2.00";
    plan skip_all => "Test::Prereq 2.00 required for testing prereqs" if $@;
}

prereq_ok;
