package ICANN::RST::Plan;
# ABSTRACT: an object representing an RST test plan.
use base qw(ICANN::RST::Base);
use GraphViz2;
use strict;

sub name        { $_[0]->{'Name'} }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }
sub oteOnly     { $_[0]->{'OTE-Only'} }

sub suites {
    my $self = shift;

    my %suites;

    foreach my $suite ($self->spec->suites) {
        foreach my $id (@{$self->{'Test-Suites'}}) {
            $suites{$suite->id} = $suite if ($id eq $suite->id && !defined($suites{$suite->id}));
        }
    }

    return sort { $a->order <=> $b->order } values(%suites);
}

sub cases {
    my $self = shift;

    my %cases;

    foreach my $suite ($self->suites) {
        foreach my $case ($suite->cases) {
            $cases{$case->id} = $case unless (defined($cases{$case->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%cases);
}

sub inputs {
    my $self = shift;

    my %inputs;

    foreach my $suite ($self->suites) {
        foreach my $input ($suite->inputs) {
            $inputs{$input->id} = $input unless (defined($inputs{$input->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%inputs);
}

sub resources {
    my $self = shift;

    my %resources;

    foreach my $suite ($self->suites) {
        foreach my $resource ($suite->resources) {
            $resources{$resource->id} = $resource unless (defined($resources{$resource->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%resources);
}

sub errors {
    my $self = shift;

    my %errors;

    foreach my $suite ($self->suites) {
        foreach my $error ($suite->errors) {
            $errors{$error->id} = $error unless (defined($errors{$error->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%errors);
}

sub graph {
    my $self = shift;

    my $graph = ICANN::RST::Graph->new;

    $graph->add_node(
        'name'  => 'START',
        'shape' => 'box',
    );

    foreach my $suite ($self->suites) {
        $graph->add_node(
            'name'  => $suite->id,
            'shape' => 'box',
        );

        $graph->add_edge(
            'from'  => 'START',
            'to'    => $suite->id,
        );

        $graph->push_subgraph(
            'name' => 'cluster_'.$suite->id,
            'graph' => {'bgcolor' => '#F8F8F8'},
        );

        my @cases = $suite->cases;

        $graph->add_edge(
            'from'  => $suite->id,
            'to'    => $cases[0]->id,
        );

        $graph->add_cases(@cases);

        $graph->pop_subgraph;
    }

    return $graph;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::RST::Plan - an object representing an RST test plan.

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class inherits from L<ICANN::RST::Base> (so it has the C<id()>,
C<order()> and C<spec()> methods).

=head1 METHODS

=head2 name()

The name of the plan.

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the
plan.

=head2 suites()

A list of L<ICANN::RST::Suite> objects used by this plan.

=head2 cases()

A list of L<ICANN::RST::Case> objects used by the suites used by this plan.

=head2 inputs()

A list of L<ICANN::RST::Inputs> objects used by the test cases used by the
suites used by this plan.

=head2 resources()

A list of L<ICANN::RST::Resource> objects relevant to this plan.

=head2 errors()

A list of L<ICANN::RST::Error> objects which may be produced by this plan.

=head2 graph()

Returns a L<ICANN::RST::Graph> object representing the sequence diagram for this
plan.

=head2 oteOnly()

Returns a boolean indicating whether this plan is only available in the OT&E
environment.

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
