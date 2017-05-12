package Document::eSign::Docusign::getRecipientTabs;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Document::eSign::Docusign::getRecipientTabs - This retrieves information about the tabs associated with a recipien

=head1 VERSION

Version 0.04

=cut

=head1 functions

=head2 getRecipientTabs($parent, $vars)

    my $response = $ds->getRecipientTabs(
        {
            accountId => $ds->accountid,
            envelopeId => '1883aef4-82fe-4c36-a9ec-13dd63520df9',
            recipientId => '1',
        }
    );
    
    print "Got Tabs: " . $response->{Tabs} . "\n";
    
=cut

sub new {
    carp( "Got recipient tabs request: " . Dumper(@_) ) if $_[1]->debug;
    my $class = shift;
    my $main  = shift;
    my $vars  = shift;

    my $self = bless {}, $class;

    my $uri =
        q{/envelopes/}
      . $vars->{envelopeId}
      . q{/recipients/}
      . $vars->{recipientId}
      . q{/tabs};

    my $creds = $main->buildCredentials();

    my $response =
      $main->sendRequest( 'GET', undef, $creds, $main->baseUrl . $uri, $vars );

    return $response;
}

1;
