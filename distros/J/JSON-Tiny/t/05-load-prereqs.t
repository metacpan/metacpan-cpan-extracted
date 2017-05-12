#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

sub msg { "*** $_[0] MUST BE INSTALLED BEFORE PROCEEDING ***\n"; }

BEGIN { use_ok $_ or BAIL_OUT msg $_ for qw/Scalar::Util Encode/; }
