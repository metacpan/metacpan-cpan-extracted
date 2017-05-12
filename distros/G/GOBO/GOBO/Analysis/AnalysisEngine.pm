=head1 NAME

GOBO::Analysis::AnalysisEngine

=head1 SYNOPSIS


=head1 DESCRIPTION


=head2 Rules


=cut

package GOBO::Analysis::AnalysisEngine;
use Moose;
extends 'GOBO::InferenceEngine::GAFInferenceEngine';
use strict;
use GOBO::Statement;
use GOBO::Annotation;
use GOBO::Graph;
use GOBO::Node;
use GOBO::TermNode;
use GOBO::RelationNode;
use Set::Object;

has feature_attribute_vector_map => (is=>'rw', isa=> 'HashRef[Set::Object]', default=>sub{{}});

sub index_annotations {
    my $self = shift;
    my %fvmap = ();
    foreach my $ann (@{$self->graph->annotations}) {
        my $feat = $ann->node;
        my $fid = $feat->id;
        my $fv = $fvmap{$fid};
        if (!$fv) {
            $fv = new Set::Object;
            $fvmap{$fid} = $fv;
        }
        foreach my $n (@{$self->get_inferred_target_nodes($ann->target)}) {
            $fv->insert($n->id);
        }
        $fv->insert($ann->target); # TODO - reflexivity
    }
    $self->feature_attribute_vector_map(\%fvmap);
    return;
}

=head2

Jacard similarity coefficient between two features,
based on their attribute vectors:

 | A1 ∩ A2| / | A1 ∪ A2|

where A1 and A2 are the sets of positive attributes
in F1 and F2 respectively

=cut

sub calculate_simJ {
    my $self = shift;
    my $f1 = shift;
    my $f2 = shift;
    
    my $av1 = $self->feature_attribute_vector_map->{$f1};
    my $av2 = $self->feature_attribute_vector_map->{$f2};
    my $iv = $av1 * $av2;
    my $uv = $av1 + $av2;

    return $iv->size / $uv->size;
}

1;

=head1 SEE ALSO

  bin/go-gaf-inference.pl

=cut
