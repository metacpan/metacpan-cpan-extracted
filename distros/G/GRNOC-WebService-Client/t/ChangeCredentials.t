#!/usr/bin/perl

use Test::More tests => 14;

use strict;
use warnings;

use GRNOC::WebService::Client;
use Data::Dumper;

# going to test basic auth navigation here and the ability to change our credentials on the fly
my $svc = GRNOC::WebService::Client->new(url => 'http://localhost:8529/protected/protected.cgi');

# should fail since we don't give any info for this basic auth
my $result = $svc->test();

is($result, undef, "successfully failed to get into webservice");

$svc->set_credentials(uid    => "dummy",
		      passwd => "banana",
		      realm  => "The Realm"
		      );

is($svc->{'uid'}, "dummy", "successfully updated uid");
is($svc->{'passwd'}, "banana", "successfully updated passwd");
is($svc->{'realm'}, "The Realm", "successfully updated realm");

$result = $svc->test();

ok(defined $result, "was able to get a result after setting credentials");

ok($result->{'results'}->{'success'} eq 1, "got expected output");


$svc->set_credentials(passwd => "not_right");

is($svc->{'uid'}, "dummy", "kept previous user");
is($svc->{'passwd'}, "not_right", "successfully updated passwd 2");
is($svc->{'realm'}, "The Realm", "kept previous realm");


$result = $svc->test();

ok(! defined $result, "failed to auth with bad password");

$svc->set_credentials(uid    => "dummy",
		      passwd => "banana",
		      realm  => "The Realm"
		      );

is($svc->{'uid'}, "dummy", "successfully updated uid 2");
is($svc->{'passwd'}, "banana", "successfully updated passwd 3");
is($svc->{'realm'}, "The Realm", "successfully updated realm 2");

$result = $svc->test();

ok(defined $result, "was able to get a result after resetting credentials");
