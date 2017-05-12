#!/usr/bin/env perl

use strict;
use warnings;
use Juju;
use Data::Dumper;

$Data::Dumper::Indent = 1;

my $client = Juju->new(
    endpoint => $ENV{JUJU_ENDPOINT},
    password => $ENV{JUJU_PASS}
);
$client->login;
$client->deploy(
    charm        => 'mysql',
    service_name => 'mysql',
    cb           => sub {
        my $val = shift;
        print Dumper($val);
    }
);
$client->deploy(
    charm        => 'precise/wordpress',
    service_name => 'wordpress',
    cb           => sub {
        my $val = shift;
        print Dumper($val);
    }
);
$client->add_relation('mysql', 'wordpress');

$client->close;
