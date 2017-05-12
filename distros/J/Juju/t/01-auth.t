#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";

plan skip_all =>
  'must export JUJU_PASS and JUJU_ENDPOINT to enable these tests'
  unless $ENV{JUJU_PASS} && $ENV{JUJU_ENDPOINT};
diag("JUJU Authentication");

use_ok('Juju');

my $juju_pass = $ENV{JUJU_PASS};
my $juju_endpoint = $ENV{JUJU_ENDPOINT};

my $juju_badpass = 'abacadaba';

my $juju = Juju->new(endpoint => $juju_endpoint, password => $juju_pass);
ok($juju->isa('Juju'), 'Is juju instance');
$juju->login;
ok($juju->is_authenticated == 1, "Authenticated properly");

# test failed login
$juju = Juju->new(endpoint => $juju_endpoint, password => $juju_badpass);
dies_ok { $juju->login } "Failed login.";

done_testing();
