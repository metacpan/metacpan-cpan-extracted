package JQ::Lite::Evaluator;

use strict;
use warnings;

sub new {
    my ($class, %opts) = @_;
    die 'runtime is required' unless $opts{runtime};
    return bless { runtime => $opts{runtime} }, $class;
}

sub evaluate {
    my ($self, $ast, @inputs) = @_;
    die 'expected Pipeline AST' unless $ast && $ast->type eq 'Pipeline';

    my @results = @inputs;
    for my $filter ($ast->filters) {
        @results = $self->{runtime}->evaluate_filter($filter, \@results);
    }

    return @results;
}

1;
