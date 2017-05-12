package Iodef::Pb::Simple::Plugin::Eventdata;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;

    return unless($data->{'EventData'});
    
    my $incident = @{$iodef->get_Incident()}[0];
    push(@{$incident->{'EventData'}},$data->{'EventData'});   
}

1;