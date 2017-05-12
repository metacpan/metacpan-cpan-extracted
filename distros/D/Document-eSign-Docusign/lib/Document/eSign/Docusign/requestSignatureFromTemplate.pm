package Document::eSign::Docusign::requestSignatureFromTemplate;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Document::eSign::Docusign::requestSignatureFromTemplate - Uses a template to create and send a new envelope.

=head1 VERSION

Version 0.02

=cut

=head1 functions

=head2 requestSignatureFromTemplate($parent, $vars)

    my $response = $ds->requestSignatureFromTemplate(
        {
            accountId => $ds->accountid,
            emailSubject => 'Hello Signer World!',
            emailBlurb => 'Please sign my document.',
            templateId => 'GUID-OF-TEMPLATE-FROM-TEMPLATES',
            templateRoles => [
                {
                    email => 'somebody@somedomain.org',
                    name => 'Joe Somebody',
                    roleName => 'Signer1', # Corresponds to template signer ID.
                }
            ],
            status => 'sent'
        }
    );
    
    print "Got envelopeId: " . $response->{envelopeId} . "\n";
    
For more complicated examples, refer to Docusign's API Documentation. 

=cut

sub new {
    carp("Got sign template request: " . Dumper(@_)) if $_[1]->debug;
    my $class = shift;
    my $main = shift;
    my $vars = shift;
    my $documentfh = shift;
    
    my $self = bless {}, $class;
    
    my $uri = '/envelopes';
        
    my $creds = $main->buildCredentials();
    
    my $response = $main->sendRequest('POST', 'application/json', $creds, $main->baseUrl . $uri, $vars);
    
    return $response;
}


1;
