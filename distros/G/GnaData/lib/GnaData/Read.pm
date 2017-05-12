=head 1 NAME

GnaData::Read - Base object for GNA Data Load subsystem

=cut

package GnaData::Read;

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
