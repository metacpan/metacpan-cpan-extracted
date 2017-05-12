#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Fun;

is(foo(), "FOO");

fun foo { "FOO" }

done_testing;
