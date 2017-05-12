#!/usr/bin/env perl

## The "runner" script defines how the stats are collected
use strict;
use warnings;
my $name = $ARGV[0];
die "please provide a name as the first commandline param" unless $name;

$| = 1;
use Measure::Everything::Adapter;
Measure::Everything::Adapter->set( 'InfluxDB::File', file => 'test.msr' );

my $app = SomeApp->new( { name => $name } );
use Time::HiRes qw(usleep);

my $target = 10_000;
for my $i ( 1 .. $target ) {
    $app->do($i);
    usleep(50);
    print "$i/$target\n" if ( $i % 1000 ) == 0;
}


## A module that wants to write some stats
package SomeApp;
use Measure::Everything qw($stats);

sub new {
    my $class = shift;
    my $args  = shift;
    return bless $args, $class;
}

sub do {
    my $self  = shift;
    my $count = shift;
    $stats->write( 'counter', $count, { name => $self->{name} } );
}

1;
