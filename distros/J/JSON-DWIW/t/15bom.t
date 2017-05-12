#!/usr/bin/env perl

# Creation date: 2007-11-30 21:41:48
# Authors: don

use strict;
use warnings;

use Test;

BEGIN { plan tests => 6 }

use JSON::DWIW;

my $str;
my $data;

$str = qq{\xEF\xBB\xBF{"stuff":"blah"}};

$data = JSON::DWIW->from_json($str);
ok($data and $data->{stuff} eq 'blah' and not JSON::DWIW->get_error_string);

$str = qq{\xFE\xFF{"stuff":"blah"}};
$data = JSON::DWIW->from_json($str);
ok(not defined($data) and JSON::DWIW->get_error_string);

$str = qq{\xFF\xFE{"stuff":"blah"}};
$data = JSON::DWIW->from_json($str);
ok(not defined($data) and JSON::DWIW->get_error_string);

$str = qq{\xFF\xFE\x00\x00{"stuff":"blah"}};
$data = JSON::DWIW->from_json($str);
ok(1); # still alive
ok(not defined($data) and JSON::DWIW->get_error_string);

$str = qq{\x00\x00\xFE\xFF{"stuff":"blah"}};
$data = JSON::DWIW->from_json($str);
ok(not defined($data) and JSON::DWIW->get_error_string);

