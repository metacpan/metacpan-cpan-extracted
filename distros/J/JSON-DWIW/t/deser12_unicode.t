#!/usr/bin/env perl

# Creation date: 2007-12-27 20:51:49
# Authors: don

use strict;
use warnings;

use Test;

BEGIN { plan tests => 2 }

use JSON::DWIW;

my $str;
my $data;

# normal case
$str = qq{{"var":"\xc3\xa9"}};
$data = JSON::DWIW::deserialize($str);

ok($data and $data->{var} and JSON::DWIW->flagged_as_utf8($data->{var}));

$str = qq{{"var":"\xe9"}};
$data = JSON::DWIW::deserialize($str);
ok(not $data and JSON::DWIW->get_error_string =~ /bad utf-8/);

