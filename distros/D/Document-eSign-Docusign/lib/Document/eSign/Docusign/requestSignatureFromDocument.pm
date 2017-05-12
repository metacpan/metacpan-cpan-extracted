package Document::eSign::Docusign::requestSignatureFromDocument;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Document::eSign::Docusign::requestSignatureFromDocument - Uses a pdf document to create and send a new envelope.

=head1 VERSION

Version 0.02

=cut

=head1 functions

=head2 requestSignatureFromDocument($parent, $vars)

Note that the arrayref of file names. This module tries to "DTRT" and
create a multipart post of each document you place in here. However, you may want to
consider the number of pages and resolution of what you are sending. Scanned documents
will be larger and therefore slower. If you have native PDF documents the upload will
be faster. (Not to mention a better presentation to the end signer.) The preceding
path to the documents will be stripped and docusign will only receive the resulting
filename.

    my $response = $ds->requestSignatureFromTemplate(
        {
            emailSubject => 'Hello Signer World!',
            emailBlurb => 'Please sign my document.',
            documents => [
              {
                documentId => 1,
                name => '/path/to/some/file.pdf'
              },
              {
                documentId => 2,
                name => '/path/to/some/otherfile.pdf'
              }
            ],
            recipients => {
                signers => [
                    {
                        email => 'somebody@somedomain.org',
                        name => 'Joe Somebody',
                        recipientId => '1',
                        tabs => {
                            signHereTabs => [
                                {
                                    xPosition => "100",
                                    yPosition => "100",
                                    documentId => 1,
                                    pageNumber => 1
                                }
                            ]
                        }
                    }
                ]
            },
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
   
    my $response = $main->sendRequest('POST', "multipart/form-data;boundary=snipsnip", $creds, $main->baseUrl . $uri, $vars);
    
    return $response;
}


1;
