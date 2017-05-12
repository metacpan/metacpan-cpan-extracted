#!/usr/local/bin/perl -w

## until I get time to write a test suite, at least see if the
## thing compiles and exports ok :).

use strict;
use Test;
use Devel::TraceSAX;

plan tests => 2;

ok 1;  ## We lived this far :)

ok defined &trace_SAX;

