package Document::eSign::Docusign::getEnvelopeRecipients;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Document::eSign::Docusign::getEnvelopeRecipients - This retrieves information about the recipients of an envelope.

=head1 VERSION

Version 0.04

=cut

=head1 functions

=head2 getEnvelopeRecipients($parent, $vars)

    my $response = $ds->getEnvelopeRecipients(
        {
            accountId => $ds->accountid,
            envelopeId => '1883aef4-82fe-4c36-a9ec-13dd63520df9', # Found in getListOfEnvelopesInFolders
        }
    );
    
    print "Got envelopeId: " . $response->{envelopeId} . "\n";
    
=cut

sub new {
    carp( "Got envelope recipients: " . Dumper(@_) ) if $_[1]->debug;
    my $class = shift;
    my $main  = shift;
    my $vars  = shift;

    my $self = bless {}, $class;

    my $uri = q{/envelopes/} . $vars->{envelopeId} . q{/recipients};

    my $creds = $main->buildCredentials();

    my $response =
      $main->sendRequest( 'GET', undef, $creds, $main->baseUrl . $uri, $vars );

    return $response;
}

1;
