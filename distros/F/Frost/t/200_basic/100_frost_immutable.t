#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

$::MAKE_MUTABLE	= 0;

require '100_frost_body.pm';
