#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

package Error::MyError;

use base 'Error::Simple';

package main;

# TEST
ok(1, "Testing that the use base worked.");

1;

