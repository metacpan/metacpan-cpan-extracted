package Iodef::Pb::Simple::Plugin::Restriction;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
    
    my $restriction = $data->{'restriction'} || 'private';
    
    unless(ref($restriction) eq 'RestrictionType'){
        $restriction = $self->restriction_normalize($restriction);
    }
    my $incident = @{$iodef->get_Incident()}[0];  
    $incident->set_restriction($restriction);
}

1;
