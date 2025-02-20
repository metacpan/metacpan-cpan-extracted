package ICANN::RST::Graph;
# ABSTRACT: an object representing a graph of an RST test plan.
use Encode;
use base qw(GraphViz2);
use utf8;
use strict;

sub new {
    my ($package, @cases) = @_;

    my $self = bless($package->SUPER::new(
        'global' => {
            'directed'  => 1,
        },
        'graph' => {
            'layout'    => 'dot',
            'rankdir'   => 'LR',
        }
    ), $package);

    $self->add_cases(@cases);

    return $self;
}

sub add_cases {
    my ($self, @cases) = @_;

    foreach my $case (@cases) {
        $self->add_case($case);
    }

    for (my $i = 0 ; $i < scalar(@cases) ; $i++) {
        my $case = $cases[$i];

        my @deps = $case->dependencies;

        if (scalar(@deps) < 1 && $i > 0) {
            $self->add_case_edge($cases[$i-1], $case);

        } else {
            foreach my $dep (@deps) {
                $self->add_case_edge($dep, $case);
            }
        }
    }
}

sub add_case_edge {
    my ($self, $from, $to) = @_;
    $self->add_edge(
        'from'  => $from->id,
        'to'    => $to->id,
    );
}

sub add_case {
    my ($self, $case) = @_;

    $self->add_node(
        'name'      => $case->id,
        'href'      => sprintf('#Test-Case-%s', $case->id),
        'tooltip'   => $self->entity_encode($case->summary),
        'shape'     => 'box',
    );
}

sub entity_encode {
    my ($self, $str) = @_;

    return join('', map { sprintf('&#%u;', ord($_)) } split(//, encode("UTF-8", $str)));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::RST::Graph - an object representing a graph of an RST test plan.

=head1 VERSION

version 0.01

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
