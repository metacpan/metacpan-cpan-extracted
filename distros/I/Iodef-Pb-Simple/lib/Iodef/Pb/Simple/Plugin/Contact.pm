package Iodef::Pb::Simple::Plugin::Contact;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;

    my $contact = $data->{'Contact'} || $data->{'contact'};

   if(ref($contact) ne 'ContactType'){
        if(ref($contact) ne 'ARRAY'){
            my $contact_email = $data->{'contact_email'} || 'unknown';
            $contact = [ 
                ContactType->new({
                    ContactName => MLStringType->new({
                        lang    => $data->{'lang'},
                        content => $data->{'contact'} || 'unknown',
                    }),
                    Timezone    => $data->{'timezone'},
                    type        => ContactType::ContactType::Contact_type_person(),
                    role        => ContactType::ContactRole::Contact_role_irt(),
                    ContactEmail    => [
                        ContactMeansType->new({
                            content => $contact_email,
                            meaning => 'email',
                        }),
                    ],  
                }),
            ],
        }
    } else {
        $contact = [$contact];
    }
    
    my $incident = @{$iodef->get_Incident()}[0];
    push(@{$incident->{'Contact'}},@$contact);
}
1;
