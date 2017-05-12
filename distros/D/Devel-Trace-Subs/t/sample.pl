#!/usr/bin/perl

use strict;
use warnings;

use Devel::Trace::Subs qw(trace trace_dump);

package One;

sub new {
    my $self = bless {}, shift;
    return $self;
}

sub set {
    my $self = shift;
    $self->{greeting} = shift || 'bye!';
    return $self->get;
}

sub get {
    my $self = shift;
    return $self->{greeting} || '';
}

sub add {
    my $self = shift;
    $self->check;
    $self->{one} = One->new;
}

sub check {
    my $self = shift;
    return 0 if ! $self->{undefined};
}

package main;

my $one = One->new;

$one->add;

$one->{one}->set('hello, world!')
