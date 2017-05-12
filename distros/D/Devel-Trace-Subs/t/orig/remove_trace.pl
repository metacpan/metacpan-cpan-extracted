#!/usr/bin/perl
use strict;
use warnings;

package One;

sub new {
    my $self = bless {}, shift;
    return $self;
}

sub set
{
    my $self = shift;
    $self->{greeting} = shift || 'bye!';
    return $self->get;
}

sub get {
    my $self = shift;
    return $self->{greeting} || '';
}

package Two;

sub new {
    my $self = bless {}, shift;
    return $self;
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

my $two = Two->new;

$two->add;

$two->{one}->set('hello, world!');

