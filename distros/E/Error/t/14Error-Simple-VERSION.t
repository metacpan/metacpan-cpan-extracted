#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use vars qw($VERSION);

$VERSION = '0.001';

require Error::Simple;

# TEST
is ($VERSION, '0.001', "Testing that the VERSION was not overrided");

1;

