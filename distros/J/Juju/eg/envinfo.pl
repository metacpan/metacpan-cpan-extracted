#!/usr/bin/env perl

use strict;
use warnings;
use Juju;
use Data::Dumper::Concise;

my $client = Juju->new(
    endpoint => $ENV{JUJU_ENDPOINT},
    password => $ENV{JUJU_PASS}
);
$client->login;
my $status = $client->status;
warn Dumper($status);

my $machines = [keys %{$status->{Response}->{Machines}}];
warn Dumper($machines);

# Easily destroy machines
# foreach my $machine (@{$machines}) {
#   if ($machine != 0) {
#     $client->destroy_machines([$machine]);
#   }
# }
$client->close;
