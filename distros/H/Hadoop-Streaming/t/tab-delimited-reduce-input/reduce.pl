#!/usr/bin/env perl

package MyReducer;
use Moo;
with 'Hadoop::Streaming::Reducer';

sub reduce {
    my ($self, $class_name, $values) = @_;

    my %best;

    while ($values->has_next) {
        my ($student, $score) = split /\t/, $values->next, 2;
        my $best_score = $best{score} || 0;
        if ($score > $best_score) {
            %best = (
                score   => $score,
                student => $student,
            );
        }
    }

    my $best_student       = $best{student};
    my $best_student_score = $best{score};
    $self->emit($class_name, "$best_student ($best_student_score)");
}

package main;
MyReducer->run;
