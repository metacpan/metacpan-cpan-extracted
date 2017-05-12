package Iodef::Pb::Simple::Plugin::Relatedactivity;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

use Iodef::Pb::Simple qw/iodef_normalize_restriction/;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
  
    my $altid = $data->{'RelatedActivity'} || $data->{'relatedid'};
    return unless($altid);
    
    my $restriction = iodef_normalize_restriction($data->{'relatedid_restriction'}) || RestrictionType::restriction_type_private();
    
    unless(ref($altid) eq 'RelatedActivityType' || ref($altid) eq 'ARRAY'){
        $altid = RelatedActivityType->new({
            IncidentID  => [
                IncidentIDType->new({
                    content     => $altid,
                    instance    => '',
                    name        => '',
                    restriction => $restriction,
                }),
            ],
            restriction => $restriction,
        });
    }
    
    my $incident = @{$iodef->get_Incident()}[0];
    $incident->set_RelatedActivity($altid);
}

1;