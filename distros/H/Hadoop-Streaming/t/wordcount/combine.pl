#!/usr/bin/env perl

package WordCount::Combiner;
use Moo;
with qw/Hadoop::Streaming::Combiner/;

sub combine {
    my ($self, $key, $values) = @_;

    my $count = 0;
    while ( $values->has_next ) {
        $count++;
        $values->next;
    }

    $self->emit( $key => $count );
}

package main;
WordCount::Combiner->run;
