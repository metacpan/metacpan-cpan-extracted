package Graph::Algorithm::HITS;

use strict;
use 5.008_005;
our $VERSION = '0.02';

use Moo;
use Graph;
use PDL;
use Carp;

has graph => (is => 'ro', required => 1);
has adj_matrix => (is => 'ro', lazy => 1, builder => '_adj_matrix_builder');
has trans_adj => (is => 'ro', lazy => 1, builder => '_trans_adj_builder');
has trans_x_adj => (
    is => 'ro', 
    lazy => 1, 
    default => sub { 
        my $self = shift; 
        $self->trans_adj x $self->adj_matrix;
    }
);

has hub_matrix => (
    is => 'rw', 
    lazy => 1, 
    default => sub { 
        my $self = shift; 
        my $size = $self->graph->vertices; 
        ones 1,$size;
    }
);

has auth_matrix => (
    is => 'rw', 
    lazy => 1, 
    default => sub { 
        my $self = shift; 
        my $size = $self->graph->vertices; 
        ones 1,$size; 
    },
);

sub BUILD {
    my $self = shift;
    # make sure it's directed graph
    unless ($self->graph->is_directed) {
        croak 'Graph needs to be directed';
    }
}

#Create adjacency matrix from graph
sub _adj_matrix_builder {
    my $self = shift;
    my $matrix = [];
    for my $v1 (sort $self->graph->vertices ) {
        my @row = ();
        for my $v2 (sort $self->graph->vertices ){
            if ($v1 eq $v2) {
                push @row, 0;
            }else {
                if ($self->graph->has_edge($v1, $v2)){
                    push @row, 1;
                }else {
                    push @row, 0;
                }
            }
        }
        push @$matrix, \@row;
    }
    return pdl $matrix;
}

#Create transpose adjacency matrix
sub _trans_adj_builder {
    my $self = shift;
    return transpose $self->adj_matrix;
}

sub iterate {
    my ($self, $itr) = @_;
    for (1..$itr) {
        my $m =  $self->trans_x_adj x $self->auth_matrix;
        $self->auth_matrix($m/$self->_get_sum($m));
    }
    my $m = $self->adj_matrix x $self->auth_matrix;
    $self->hub_matrix($m/$self->_get_sum($m));
}

sub _get_sum {
    my ($self, $m) = @_;
    my $result = unpdl $m;
    my $sum=0;
    $sum += shift @$_ for (@$result);
    return $sum;
}

sub get_authority {
    my $self = shift;
    my $ref = unpdl $self->auth_matrix;
    my %result;
    for my $v (sort $self->graph->vertices) {
        $result{$v} = shift @{ shift @$ref };
    }
    return \%result;
}

sub get_hub {
    my $self = shift;
    my $ref = unpdl $self->hub_matrix;
    my %result;
    for my $v (sort $self->graph->vertices) {
        $result{$v} = shift @{ shift @$ref };
    }
    return \%result;
}

1;
__END__

=encoding utf-8

=head1 NAME

Graph::Algorithm::HITS - Anothor HITS algorithm implementation loading L<Graph>

=head1 SYNOPSIS

  use Graph::Algorithm::HITS;
  use Graph;
  my $g = new Graph();
  $g->add_vertices(...);
  $g->add_edges(...);
  # Graph object as input
  my $hits = Graph::Algorithm::HITS(graph => $g);
  $hits->iterate(20); 
  # $auth_vector = { v1 => $auth_score_v1, v2 => $auth_score_v2,,, }
  my $auth_vector = $hits->get_authority();
  # $hub_vector = { $v1 => $hub_score_v1, v2 => $hub_score_v2,,, }
  my $hub_vector = $hits->get_hub();

=head1 DESCRIPTION

Graph::Algorithm::HITS implements HITS algorithm (see L<http://www2002.org/CDROM/refereed/643/node1.html>). There are a couple of HITS algorithm implementations in CPAN though, the reason you would choose this is that the score can be calculated by simply loading from L<Graph> object.

=head1 AUTHOR

Shohei Kameda E<lt>shoheik@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Shohei Kameda

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
