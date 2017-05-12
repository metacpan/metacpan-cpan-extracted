#!/usr/bin/env perl

# Creation date: 2007-11-30 21:41:48
# Authors: don

use strict;
use warnings;

use Test;

use JSON::DWIW;

if (JSON::DWIW->has_deserialize) {
    plan tests => 5;
}
else {
    plan tests => 1;
    
    print "# deserialize not implemented on this platform\n";
    skip("Skipping on this platform", 0); # skipping on this platform
    exit 0;
}

my $str;
my $data;

$str = qq{\xEF\xBB\xBF{"stuff":"blah"}};

$data = JSON::DWIW::deserialize($str);
ok($data and $data->{stuff} eq 'blah' and not JSON::DWIW->get_error_string);

$str = qq{\xFE\xFF{"stuff":"blah"}};
$data = JSON::DWIW::deserialize($str);
ok(not defined($data) and JSON::DWIW->get_error_string);

$str = qq{\xFF\xFE{"stuff":"blah"}};
$data = JSON::DWIW::deserialize($str);
ok(not defined($data) and JSON::DWIW->get_error_string);

$str = qq{\xFF\xFE\x00\x00{"stuff":"blah"}};
$data = JSON::DWIW::deserialize($str);
ok(not defined($data) and JSON::DWIW->get_error_string);

$str = qq{\x00\x00\xFE\xFF{"stuff":"blah"}};
$data = JSON::DWIW::deserialize($str);
ok(not defined($data) and JSON::DWIW->get_error_string);

