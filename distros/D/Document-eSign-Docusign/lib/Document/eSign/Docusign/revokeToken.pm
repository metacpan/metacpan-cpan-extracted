package Document::eSign::Docusign::revokeToken;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Document::eSign::Docusign::revokeToken - Revokes an OAUTH2 token.

=head1 VERSION

Version 0.02

=cut

=head1 functions

=head2 revokeToken($varshashref)

    my $response = $ds->revokeToken(
        {
            token => 'tokenstring'
        }
    );
    
=cut

sub new {
    carp("Got token request: " . Dumper(@_)) if $_[1]->debug;
    my $class = shift;
    my $main = shift;
    my $vars = shift;
    my $self = bless {}, $class;
    
    my $uri = '/v2/oauth2/revoke';
    
    # Build the portions of the get string as needed.
    
    my $creds = $main->buildCredentials();
    
    my $response = $main->sendRequest('POST', 'application/json', $creds, $main->defaultUrl . $uri, $vars);
    
    return $response;
}


1;
