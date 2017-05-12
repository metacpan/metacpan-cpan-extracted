package Devel::Monitor::TraceItem;
use strict;
use warnings;

sub new {
    my ($class, $varRef, $source) = @_;
    my $self = {};
    bless($self => $class);
    $self->{_varRef} = $varRef;
    $self->{_source} = $source;
    return $self;
}

sub getVarRef { return shift->{_varRef}; }
sub getSource { 
    my $self = shift;
    if ($self->{_source}) {
        return $self->{_source};
    } else {
        return '';   
    }
}

1;