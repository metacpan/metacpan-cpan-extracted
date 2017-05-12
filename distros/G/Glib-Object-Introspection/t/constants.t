#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;
use utf8;

plan tests => 6;

is (GI::CONSTANT_NUMBER, 42);
is (GI::CONSTANT_UTF8, 'const ♥ utf8');

is (Regress::INT_CONSTANT, 4422);
delta_ok (Regress::DOUBLE_CONSTANT, 44.22);
is (Regress::STRING_CONSTANT, "Some String");
is (Regress::Mixed_Case_Constant, 4423);
