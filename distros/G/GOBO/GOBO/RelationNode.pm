package GOBO::RelationNode;
use Moose;
use strict;
extends 'GOBO::Node';
with 'GOBO::Definable';
use Moose::Util::TypeConstraints;

coerce 'GOBO::RelationNode'
    => from 'GOBO::Node'
    => via { bless $_, 'GOBO::RelationNode' }
    => from 'Str'
    => via { my $rel = new GOBO::RelationNode(id=>$_); $rel->post_init;return $rel; };  # TODO -- is there a more elegant way of doing this?

has transitive => ( is=>'rw', isa=>'Bool' );
has symmetric => ( is=>'rw', isa=>'Bool' );
has asymmetric => ( is=>'rw', isa=>'Bool' );
has anti_symmetric => ( is=>'rw', isa=>'Bool' );
has cyclic => ( is=>'rw', isa=>'Bool' );
has reflexive => ( is=>'rw', isa=>'Bool' );
has irreflexive => ( is=>'rw', isa=>'Bool' );
has functional => ( is=>'rw', isa=>'Bool' );
has inverse_functional => ( is=>'rw', isa=>'Bool' );
has metadata_tag => ( is=>'rw', isa=>'Bool' );
has transitive_over => ( is=>'rw', isa=>'GOBO::RelationNode');
has holds_over_chain_list => ( is=>'rw', isa=>'ArrayRef[ArrayRef[GOBO::RelationNode]]' );
has equivalent_to_chain_list => ( is=>'rw', isa=>'ArrayRef[ArrayRef[GOBO::RelationNode]]' );
has domain => ( is=>'rw', isa=>'GOBO::ClassNode');
has range => ( is=>'rw', isa=>'GOBO::ClassNode');

has symmetric_on_instance_level => ( is=>'rw', isa=>'Bool' );
has inverse_of_on_instance_level_list => ( is=>'rw', isa=>'ArrayRef[GOBO::RelationNode]' );

has subrelation_of_list => ( is=>'rw', isa=>'ArrayRef[GOBO::RelationNode]' );
has inverse_of_list => ( is=>'rw', isa=>'ArrayRef[GOBO::RelationNode]' );
has disjoint_from_list => (is => 'rw', isa => 'ArrayRef[GOBO::RelationNode]');
has disjoint_over_list => (is => 'rw', isa => 'ArrayRef[GOBO::RelationNode]');

sub post_init {
    my $self = shift;
    if ($self->is_subsumption) {
        $self->transitive(1);
        $self->reflexive(1);
        $self->anti_symmetric(1);
    }
}


sub unary_property_names { 
    return qw( cyclic reflexive symmetric transitive anti_symmetric irreflexive functional inverse_functional asymmetric);
}

sub is_subsumption {
    return shift->id eq 'is_a';
}

sub propagates_over_is_a {
    return 1; # by default all links propagate over is_a
}

sub add_holds_over_chain {
    my $self = shift;
    if (!$self->holds_over_chain_list) {
        $self->holds_over_chain_list([]);
    }
    push(@{$self->holds_over_chain_list},@_);
}

sub add_equivalent_to_chain {
    my $self = shift;
    if (!$self->equivalent_to_chain_list) {
        $self->equivalent_to_chain_list([]);
    }
    push(@{$self->equivalent_to_chain_list},@_);
}

sub add_disjoint_from {
    my $self = shift;
    $self->disjoint_from_list([]) unless $self->disjoint_from_list([]);
    push(@{$self->disjoint_from_list},@_);
}

sub add_disjoint_over {
    my $self = shift;
    $self->disjoint_over_list([]) unless $self->disjoint_over_list([]);
    push(@{$self->disjoint_over_list},@_);
}

sub add_inverse_of {
    my $self = shift;
    $self->inverse_of_list([]) unless $self->inverse_of_list([]);
    push(@{$self->inverse_of_list},@_);
}

sub add_inverse_of_on_instance_level {
    my $self = shift;
    $self->inverse_of_on_instance_level_list([]) unless $self->inverse_of_on_instance_level_list([]);
    push(@{$self->inverse_of_on_instance_level_list},@_);
}

sub add_subrelation_of {
    my $self = shift;
    $self->subrelation_of_list([]) unless $self->subrelation_of_list([]);
    push(@{$self->subrelation_of_list},@_);
}

=head1 NAME

GOBO::RelationNode

=head1 SYNOPSIS

=head1 DESCRIPTION

An GOBO::Node that acts as a predicate in an GOBO::Statement. Relations can have particular properties such as transitivity that are used by an GOBO::InferenceEngine

=head1 SEE ALSO

http://www.geneontology.org/GO.format.obo-1_3.shtml

http://obofoundry.org/ro

=cut

1;
