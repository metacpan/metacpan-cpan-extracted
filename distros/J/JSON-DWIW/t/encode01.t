#!/usr/bin/env perl

# Creation date: 2008-06-21T02:18:22Z
# Authors: don

use strict;
use warnings;

use Test;

BEGIN { plan tests => 4 }

use JSON::DWIW;

my $json_obj = JSON::DWIW->new({ detect_circular_refs => 1 });

my $data = { blah => 1 };

my $data2 = { foo => 'bar', data => $data };

$data->{data2} = $data2;

my $str = $json_obj->to_json($data);

ok(defined($str) and not $json_obj->get_error_string);

$str = JSON::DWIW->to_json($data, { detect_circular_refs => 1 });

ok(defined($str) and not JSON::DWIW->get_error_string);

ok(defined($str));

my $r_data = JSON::DWIW::deserialize($str);
ok(not defined(JSON::DWIW->get_error_string));

