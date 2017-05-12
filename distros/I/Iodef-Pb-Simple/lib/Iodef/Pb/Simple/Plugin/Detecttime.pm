package Iodef::Pb::Simple::Plugin::Detecttime;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
     
    my $dt = $data->{'detecttime'};
    unless($dt){
        require DateTime;
        $dt = DateTime->from_epoch(epoch => time());
        $dt = $dt->ymd().'T'.$dt->hms().'Z';
    }
    unless(ref($dt) eq 'DateTime'){
        $dt = $self->SUPER::normalize_timestamp($dt);
    }
    
    my $incident = @{$iodef->get_Incident()}[0];
    $incident->set_DetectTime($dt);
}

1;