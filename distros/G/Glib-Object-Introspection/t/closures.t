#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;

plan tests => 3;

is (Regress::test_closure (sub { return 23; }), 23);
is (Regress::test_closure_one_arg (sub { is (shift, 42); return 23; }, 42), 23);
