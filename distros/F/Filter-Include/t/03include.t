#!/usr/bin/perl

use Test::More tests => 5;
use vars '$pkg';

use IO::File;
use File::Spec;

use strict;
use Filter::Include;

my $line = __LINE__;
# no. 1
include 't/sample.pl';

# no. 2, 3
is($::sample_test, 'a string',     '$::sample_test is set');
cmp_ok($line + 10, '==', __LINE__, 'line numbering incremented correctly');


# no. 4
include t::sample_test;

# no. 5
ok(t::sample_test->VERSION > 0, "version defined in test module");
