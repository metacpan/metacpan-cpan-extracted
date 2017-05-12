#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use DDP;

plan skip_all =>
  'must export JUJU_PASS and JUJU_ENDPOINT to enable these tests'
  unless $ENV{JUJU_PASS} && $ENV{JUJU_ENDPOINT};
diag("JUJU Machine administration");

use_ok('Juju');

my $juju_pass     = $ENV{JUJU_PASS};
my $juju_endpoint = $ENV{JUJU_ENDPOINT};

my $juju = Juju->new(endpoint => $juju_endpoint, password => $juju_pass);
$juju->login;

dies_ok {$juju->add_machine } "Dies on no params";

$juju->add_machine(
    'trusty', {}, "", "", "",
    sub {
        my $val     = shift->{Response};
        my $machine = $val->{Machines}->[0];
        ok(!defined($machine->{Error}), "Add machine worked.");
    }
);

done_testing();
