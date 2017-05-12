#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

package t::App;

use Getopt::Chain::Declare;

start [qw/ a1 b2:s /];

on apple => [qw/ c3 /], sub {
    my $context = shift;

    $context->option( apple => 1 );
};

on qr/green banana (\d+)/ => [], sub {
    my $context = shift;

    $context->option( banana => 1 );
};

no Getopt::Chain::Declare;

package main;

my @arguments = qw/--a1 apple --c3/;
my ($options);

my $app = t::App->new;

ok( $app );

$options = $app->run( [ @arguments ] );

ok( $options->{a1} );
ok( $options->{c3} );
ok( $options->{apple} );

$options = $app->run( [qw/ green banana 10 /] );
ok( $options->{banana} );
