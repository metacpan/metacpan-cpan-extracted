#!/usr/bin/perl -w
use 5.010;
use strict;
use warnings;
use autodie;
use Test::Exception;
use Test::More;

use Exobrain;
use Exobrain::Test;
use Exobrain::Beeminder;

my %services = Exobrain::Beeminder->services;
my $exobrain = Exobrain->new;

foreach my $service (values %services) {
    my $class = "Agent::$service";

    lives_ok { $exobrain->_load_component($class) } $class;
}

done_testing;
