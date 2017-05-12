package Document::eSign::Docusign::changeEnvelopeStatus;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Document::eSign::Docusign::changeEnvelopeStatus - Changes an envelope status.

=head1 VERSION

Version 0.02

=cut

=head1 functions

=head2 changeEnvelopeStatus($hashref)

    my $response = $ds->changeEnvelopeStatus(
        {
            accountId => $ds->accountid,
            envelopeId => 'envelopeId',
            status => 'sent' # or voided
        }
    );
    
For more complicated examples, refer to Docusign's API Documentation. 

=cut

sub new {
    carp("Got sign template request: " . Dumper(@_)) if $_[1]->debug;
    my $class = shift;
    my $main = shift;
    my $vars = shift;
    
    my $self = bless {}, $class;
    
    my $uri = '/envelopes/' . $vars->{envelopeId};
        
    my $creds = $main->buildCredentials();
    
    my $response = $main->sendRequest('PUT', 'application/json', $creds, $main->baseUrl . $uri, $vars);
    
    return $response;
}


1;
