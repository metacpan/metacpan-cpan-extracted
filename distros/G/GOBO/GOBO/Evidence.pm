package GOBO::Evidence;
use Moose;
use strict;
extends 'GOBO::Node';

has type => (is=>'rw', isa=>'GOBO::ClassNode', coerce=>1);
has supporting_entities => (is=>'rw', isa=>'ArrayRef[GOBO::Node]');

sub with_str {
    return join('|',@{shift->supporting_entities || []});
}

sub as_string {
    my $self = shift;
    return $self->type . '-' . $self->with_str;
}

1;
