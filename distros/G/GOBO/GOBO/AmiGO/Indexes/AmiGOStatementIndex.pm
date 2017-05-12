package GOBO::AmiGO::Indexes::AmiGOStatementIndex;
use Moose;
extends 'GOBO::Indexes::StatementIndex';
with 'GOBO::AmiGO::Indexes::AmiGOWrapper';
use Carp;
use strict;
use GOBO::Statement;
use GOBO::Node;
use GOBO::RelationNode;

sub add_statements {
    my $self = shift;
    my $sl = shift;

    # read only?

    return;
}

sub remove_statements {
    my $self = shift;
    my $sl = shift;

    # read only?

    return;
}

sub statements {
    my $self = shift;
    if (@_) {
        # SET
        $self->clear_all;
        $self->add_statements([@_]);
    }
    # GET
    
    # TODO
}

sub statements_by_node_id {
    my $self = shift;
    my $x = shift;
    my $q = $self->query;

    my $schema = $q->{SCHEMA};
    my $it = $schema->resultset('Term2Term')->search(
        { 'subject.acc' => $x },
        {join => ['subject',
                  'object',
                  'relationship']});
    my @sl = map { $self->convert($_) } $it->all;
    return \@sl;
}

sub statements_by_target_id {
    my $self = shift;
    my $x = shift;
    my $q = $self->query;

    my $schema = $q->{SCHEMA};
    my $it = $schema->resultset('Term2Term')->search(
        { 'object.acc' => $x },
        {join => ['subject',
                  'object',
                  'relationship']});
    my @sl = map { $self->convert($_) } $it->all;
    return \@sl;
}

sub convert {
    my $self = shift;
    my $rs = shift;
    # TODO: use a factory to create GOBO::Statement objs
    return new 
      GOBO::Statement(node=>$rs->subject->acc,
                      relation=>$rs->relationship->acc,
                      target=>$rs->object->acc);
}

1;


=head1 NAME

GOBO::AmiGO::Indexes::StatementIndex

=head1 SYNOPSIS

do not use this method directly

=head1 DESCRIPTION

Overrides GOBO::Indexes::StatementIndex (as used in GOBO::Graph) to
provide direct DB connectivity to the AmiGO/GO Database. Uses the
AmiGO DBIx::Class layer

=cut
