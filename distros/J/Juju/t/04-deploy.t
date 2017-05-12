#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

plan skip_all =>
  'must export JUJU_PASS and JUJU_ENDPOINT to enable these tests'
  unless $ENV{JUJU_PASS} && $ENV{JUJU_ENDPOINT};
diag("JUJU Service Deploy");

use_ok('Juju');

my $juju_pass     = $ENV{JUJU_PASS};
my $juju_endpoint = $ENV{JUJU_ENDPOINT};

my $juju = Juju->new(endpoint => $juju_endpoint, password => $juju_pass);
$juju->login;

dies_ok {
    $juju->deploy
}
'Dies if no charm or service name';

$juju->deploy(
    'mysql', 'mysql', 1, "", {}, "",
    sub {
        my $val = shift;
        ok(!defined($val->{Error}), "Deployed mysql service");
    }
);
$juju->deploy(
    'precise/wordpress',
    'wordpress',
    1, "", {}, "",
    sub {
        my $val = shift;
        ok(!defined($val->{Error}), "Deployed precise/wordpress service");
    }
);

$juju->add_relation(
    'mysql',
    'wordpress',
    sub {
        my $val = shift;
        ok(defined($val->{Response}->{Endpoints}->{wordpress}), "Found wordpress endpoint relation");
        ok(defined($val->{Response}->{Endpoints}->{mysql}), "Found mysql endpoint relation");
    }
);

## CLEANUP
diag("Cleaning up machines");
$juju->destroy_relation('wordpress', 'mysql');
$juju->service_destroy('wordpress');
$juju->service_destroy('mysql');
$juju->destroy_service_units(['wordpress/0', 'mysql/0']);
my $status   = $juju->status;
my $machines = [keys %{$status->{Response}->{Machines}}];
foreach my $machine (@{$machines}) {
    if ($machine != 0) {
      ok($juju->destroy_machines([$machine]), "Destroyed machine: $machine");
    }
}

done_testing();
