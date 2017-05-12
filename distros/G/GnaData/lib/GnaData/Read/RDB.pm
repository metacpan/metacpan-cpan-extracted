=head 1 NAME

GnaData::Load - Base object for GNA Data Load subsystem

=cut
use strict;
package GnaData::Load::RDB;

sub new {
    my $proto = shift;
    my $inref = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    return $self;
}

sub open {
}

sub read {
}

sub close {
}

sub write {
}


