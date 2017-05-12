package GOBO::Indexes::NodeIndex;
use Moose;
use Carp;
use strict;
use GOBO::Node;
use GOBO::Node;
use GOBO::Node;
use GOBO::RelationNode;

has ixN => (is => 'rw', isa => 'HashRef[GOBO::Node]', default=>sub{{}});
has ixLabel => (is => 'rw', isa => 'HashRef[ArrayRef[GOBO::Node]]', default=>sub{{}});

sub create_node {
    my $self = shift;
    my $n = GOBO::Node->new(@_); # TODO - other types
    $self->add_node($n);
    return $n;
}

# TODO - use Set::Object? List::MoreUtils?
sub add_node {
    my $self = shift;
    $self->add_nodes([@_]);
}

# TODO - check for duplicates?
sub add_nodes {
    my $self = shift;
    my $nl = shift;
    foreach my $n (@$nl) {
        my $nid = $n->id;
        $self->ixN->{$n->id} = $n;
    }
    if ($self->ixLabel) {
        foreach my $n (@$nl) {
            my $nid = $n->id;
            push(@{$self->ixLabel->{$n->label}}, $n) if $n->label;
        }
    }
    return;
}

# note that this removes nodes only from the node index;
# links must be removed separately
sub remove_nodes {
    my $self = shift;
    my $nl = shift;
    my $num =  0;
    foreach my $n (@$nl) {
        my $nid = ref($n) ? $n->id : $n;
        delete $self->ixN->{$nid};
        $num++;
    }
    if ($self->ixLabel) {
        foreach my $n (@$nl) {
            my $label = $n->label;
            if ($label) {
                my $unodes = $self->ixLabel->{$label} || [];
                @$unodes = grep {$_->id ne $_->n->id} @$unodes;
            }
        }
    }
    return $num;
}

sub remove_node {
    my $self = shift;
    my $n = shift;
    return $self->remove_nodes([$n]);
}

sub nodes {
    my $self = shift;
    if (@_) {
        # SET
        $self->clear_all;
        $self->add_nodes([@_]);
    }
    # GET
    return [values %{$self->ixN}];
}

sub node_by_id {
    my $self = shift;
    my $x = shift;
    confess("requires argument") unless $x;
    return $self->ixN->{$x};
}

sub nodes_by_label {
    my $self = shift;
    my $x = shift;
    return $self->ixLabel->{$x} || [];
}

sub nodes_by_metaclass {
    my $self = shift;
    my $c = shift;
    if (lc($c) eq 'class') {
        $c = 'GOBO::ClassNode';
    }
    elsif (lc($c) eq 'term') {
        $c = 'GOBO::TermNode';
    }
    elsif (lc($c) eq 'relation') {
        $c = 'GOBO::RelationNode';
    }
    elsif (lc($c) eq 'instance') {
        $c = 'GOBO::InstanceNode';
    }
    else {
        # ok
    }
    return [grep { $_->isa($c) } 
            @{$self->nodes}];
    
}


1;


=head1 NAME

GOBO::Indexes::NodeIndex

=head1 SYNOPSIS

do not use this method directly

=head1 DESCRIPTION

Stores a collection of GOBO::Node objects, optimized for fast
access. In general you should not need to use this directly - use
GOBO::Graph instead, which includes different indexes for links,
annotations etc

=head2 TODO

Currently there are 2 indexes, by node ID (subject) and by primary
label, but in future this may be extended. General search may also be
added.

Eventually it should support any combination of indexing

=head2 Binding to a database

This index is in-memory. It can be extended to be bound to a database
(e.g. the GO Database) or to a Lucene index by overriding the methods

=cut
