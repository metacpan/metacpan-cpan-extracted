#!/usr/bin/env perl

package WordCount::Reducer;
use Moo;
with qw/Hadoop::Streaming::Reducer/;

sub reduce {
    my ($self, $key, $values) = @_;

    my $count = 0;
    while ( $values->has_next ) {
        $count++;
        $values->next;
    }

    $self->emit( $key => $count );
}

package main;
WordCount::Reducer->run;
