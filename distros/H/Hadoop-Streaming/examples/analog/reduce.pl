#!/usr/bin/env perl

package Analog::Reducer;
use Moo;
with 'Hadoop::Streaming::Reducer';

sub reduce {
    my ($self, $key, $values) = @_;

    my $count = 0;
    while ($values->has_next) {
        $count++;
        $values->next;
    }
    $self->emit($key, $count);
}

package main;
Analog::Reducer->run;
