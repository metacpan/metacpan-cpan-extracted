package Iodef::Pb::Simple::Plugin::Purpose;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
    
    my $purpose = $data->{'purpose'} || 'mitigation';
    
    unless(ref($purpose) eq 'IncidentType::IncidentPurpose'){
        for(lc($purpose)){
            if(/^mitigation$/){
                $purpose = IncidentType::IncidentPurpose::Incident_purpose_mitigation(),
                last;
            }
            if(/^reporting$/){
                $purpose = IncidentType::IncidentPurpose::Incident_purpose_reporting(),
                last;
            }
            if(/^traceback$/){
                $purpose = IncidentType::IncidentPurpose::Incident_purpose_traceback(),
                last;
            }
            ## TODO -- ext-value
            if(/^other$/){
                $purpose = IncidentType::IncidentPurpose::Incident_purpose_other(),
                last;
            }   
        }   
    }    
    my $incident = @{$iodef->get_Incident()}[0];  
    $incident->set_purpose($purpose);
}

1;