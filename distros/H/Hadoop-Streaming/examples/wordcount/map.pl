#!/usr/bin/env perl

package Wordcount::Mapper;
use Moo;
with 'Hadoop::Streaming::Mapper';

sub map {
    my ($self, $line) = @_;

    for (split /\s+/, $line) {
        $self->emit( $_ => 1 );
    }
}

package main;
Wordcount::Mapper->run;
