#!/usr/bin/env perl -w

use Test::Simple tests=>1;

ok(eval "use Filter::Unpound; 1", "loading.");
