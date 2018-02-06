#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

print -T '/dev/null';

__DATA__
open("/dev/null", *, *) = * at last-statement.pl line 7.
