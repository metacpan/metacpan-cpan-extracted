package Iodef::Pb::Simple::Plugin::Incidentid;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

use Iodef::Pb::Simple qw/iodef_normalize_restriction/;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
  
    my $source          = $data->{'IncidentID'} || $data->{'source'} || 'unknown';
    my $restriction     = $data->{'restriction'} || 'private';
    $restriction        = iodef_normalize_restriction($restriction);
    
    my $id = $data->{'id'};
    
    unless(ref($source) eq 'IncidentIDType'){
        $source = IncidentIDType->new({
            content     => $id,
            name        => $source,
            restriction => $restriction, 
        });
    }
    @{$iodef->get_Incident()}[0]->set_IncidentID($source);
}

1;