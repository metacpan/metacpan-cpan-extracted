#!/usr/bin/env perl

package Analog::Mapper;
use Moo;
with 'Hadoop::Streaming::Mapper';

sub map {
    my ($self, $line) = @_;

    my @segments = split /\s+/, $line;
    $self->emit($segments[1] => 1); #referrer
}

package main;
Analog::Mapper->run;
