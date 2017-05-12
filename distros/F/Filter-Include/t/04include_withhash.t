#!/usr/bin/perl

use Test::More tests => 4;
use vars '$pkg';

use IO::File;
use File::Spec;

use strict;
use Filter::Include;

# no. 1
#include 't/sample.pl';

# no. 2
ok($::sample_test eq 'a string', '$::sample_test is set');

# no. 3
#include t::sample_test;

# no. 4
ok(t::sample_test->VERSION > 0, "version defined in test module");
