package GOBO::InstanceNode;
use Moose;
use strict;
extends 'GOBO::Node';
with 'GOBO::Identified';

has types => (is=>'rw', isa=>'ArrayRef[GOBO::ClassNode]');

sub add_type {
    my $self = shift;
    $self->types([]) unless $self->types([]);
    push(@{$self->types},@_);
}


1;
