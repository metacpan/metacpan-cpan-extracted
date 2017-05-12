#!/usr/bin/perl
use Devel::Trace::Subs qw(trace trace_dump); # injected by Devel::Trace::Subs
use strict;
use warnings;

package One;

sub new {
    trace() if $ENV{DTS_ENABLE}; # injected by Devel::Trace::Subs
    my $self = bless {}, shift;
    return $self;
}

sub set
{
    trace() if $ENV{DTS_ENABLE}; # injected by Devel::Trace::Subs
    my $self = shift;
    $self->{greeting} = shift || 'bye!';
    return $self->get;
}

sub get {
    trace() if $ENV{DTS_ENABLE}; # injected by Devel::Trace::Subs
    my $self = shift;
    return $self->{greeting} || '';
}

package Two;

sub new {
    trace() if $ENV{DTS_ENABLE}; # injected by Devel::Trace::Subs
    my $self = bless {}, shift;
    return $self;
}

sub add {
    trace() if $ENV{DTS_ENABLE}; # injected by Devel::Trace::Subs
    my $self = shift;
    $self->check;
    $self->{one} = One->new;
}

sub check {
    trace() if $ENV{DTS_ENABLE}; # injected by Devel::Trace::Subs
    my $self = shift;
    return 0 if ! $self->{undefined};
}

package main;

my $two = Two->new;

$two->add;

$two->{one}->set('hello, world!');

