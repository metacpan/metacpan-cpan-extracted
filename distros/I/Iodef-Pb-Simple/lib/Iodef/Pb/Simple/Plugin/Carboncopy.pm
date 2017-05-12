package Iodef::Pb::Simple::Plugin::Carboncopy;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;

    return unless($data->{'carboncopy'});
    my @contacts = split(/,/,$data->{'carboncopy'});
    
    my $restriction = $data->{'carboncopy_restriction'} || 'private';
    $restriction = $self->restriction_normalize($restriction);
    
    foreach my $contact (@contacts){
        next if(ref($contact) eq 'ContactType');
        $contact = ContactType->new({
            ContactName => MLStringType->new({
                    lang    => $data->{'lang'}  || 'EN',
                    content => $contact         || 'unknown',
                }),
            Timezone    => $data->{'timezone'} || 'UTC',
            type        => ContactType::ContactType::Contact_type_organization(),
            role        => ContactType::ContactRole::Contact_role_cc(),
            restriction => $restriction,
        });
    }

    my $incident = @{$iodef->get_Incident()}[0];
    push(@{$incident->{'Contact'}},@contacts);
}
1;
