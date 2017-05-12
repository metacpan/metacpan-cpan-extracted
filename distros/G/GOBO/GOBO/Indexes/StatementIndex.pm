package GOBO::Indexes::StatementIndex;
use Moose;
use Carp;
use strict;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::Node;
use GOBO::RelationNode;

has ixN => (is => 'rw', isa => 'HashRef[ArrayRef[GOBO::LinkStatement]]', default=>sub{{}});
has ixT => (is => 'rw', isa => 'HashRef[ArrayRef[GOBO::LinkStatement]]', default=>sub{{}});

sub clear_all {
    my $self = shift;
    $self->ixN({});
    $self->ixT({});
    return;
}

sub create_statement {
    my $self = shift;
    my $s = GOBO::LinkStatement->new(@_); # TODO - other types
    $self->add_statement($s);
    return $s;
}

# TODO - use Set::Object? List::MoreUtils?
sub add_statement {
    my $self = shift;
    $self->add_statements([@_]);
}

# TODO - check for duplicates?
sub add_statements {
    my $self = shift;
    my $sl = shift;
    foreach my $s (@$sl) {
        confess("no subject in $s") unless $s->node;
        my $nid = $s->node->id;
        push(@{$self->ixN->{$nid}}, $s);
        if ($s->isa("GOBO::LinkStatement")) {
            my $tid = $s->target->id;
            push(@{$self->ixT->{$tid}}, $s);
        }
    }
    return;
}

sub remove_statement {
    my $self = shift;
    $self->remove_statements([@_]);
}

sub remove_statements {
    my $self = shift;
    my $sl = shift;
    foreach my $s (@$sl) {
        my $nid = $s->node->id;
        # TODO - Set::Object?
        my $arr = $self->ixN->{$nid};
        @$arr = grep {!$s->equals($_)} @$arr;
        if ($s->isa("GOBO::LinkStatement")) {
            my $tid = $s->target->id;
            my $arr = $self->ixT->{$tid};
            @$arr = grep {!$s->equals($_)} @$arr;
        }
    }
    return;
}

sub statements {
    my $self = shift;
    if (@_) {
        # SET
        $self->clear_all;
        $self->add_statements(@_);
    }
    # GET
    return [map { @$_ } values %{$self->ixN}];
}

sub statements_by_node_id {
    my $self = shift;
    my $x = shift;
    confess("requires argument") unless $x;
    return $self->ixN->{$x} || [];
}

sub statements_by_target_id {
    my $self = shift;
    my $x = shift;
    return $self->ixT->{$x} || [];
}

sub matching_statements {
    my $self = shift;
    my $s = shift;
    my $sl;
    if ($s->node) {
        $sl = $self->statements_by_node_id($s->node->id);
    }
    elsif ($s->target) {
        $sl = $self->statements_by_target_id($s->target->id);
    }
    else {
        $sl = $self->statements;
    }

    my $rel = $s->relation;
    if ($rel) {
        $sl = [grep {$_->relation && $_->relation->id eq $rel->id} @$sl];
    }
    return $sl;
}

sub referenced_nodes {
    my $self = shift;
    my @nids = keys %{$self->ixN};
    # ixN maps node IDs to lists of statements;
    # take the distinct node IDs, the return the
    # node object from the first statement in each
    return 
        [map {
            $self->ixN->{$_}->[0]->node;
         } @nids];
}

1;


=head1 NAME

GOBO::Indexes::StatementIndex

=head1 SYNOPSIS

do not use this method directly

=head1 DESCRIPTION

Stores a collection of GOBO::Statement objects, optimized for fast
access. In general you should not need to use this directly - use
GOBO::Graph instead, which includes different indexes for links,
annotations etc

=head2 TODO

Currently there are 2 indexes, by node (subject) and by target. There
are a limited amount of query options.

Eventually it should support any combination of S-R-T indexing, and
any kind of S-R-T access

We also want a NodeIndex

=head2 Binding to a database

This index is in-memory. It can be extended to be bound to a database
(e.g. the GO Database) by overriding the methods

=cut
