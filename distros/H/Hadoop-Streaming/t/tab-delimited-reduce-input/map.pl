#!/usr/bin/env perl

package MyMapper;
use Moo;
with 'Hadoop::Streaming::Mapper';

sub map {
    my ($self, $line) = @_;
    my ($date, $student, $class_name, $score) = split /\s+/, $line, 4;
    my $results = join("\t", ($student, $score));
    $self->emit($class_name => $results);
}

package main;
MyMapper->run;
