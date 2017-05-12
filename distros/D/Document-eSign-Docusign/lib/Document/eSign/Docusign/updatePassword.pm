package Document::eSign::Docusign::updatePassword;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Document::eSign::Docusign::updatePassword - Used to change a user's password.

=head1 VERSION

Version 0.02

=cut

=head1 functions

=head2 updatePassword($varshashref)

Depending on the account settings, you may be required to supply 0 - 3 question and answer pairs.

    my $response = $ds->updatePassword(
        {
            currentPassword => 'OldUserPassword',
            email => 'user@somedomain.com',
            newPassword => 'NewUserPassword',
            forgottenPasswordInfo => {
                forgottenPasswordQuestion1 => 'Some question.',
                forgottenPasswordAnswer1   => 'Some answer.',
                forgottenPasswordQuestion2 => 'Some question.',
                forgottenPasswordAnswer2   => 'Some answer.',
                forgottenPasswordQuestion3 => 'Some question.',
                forgottenPasswordAnswer3   => 'Some answer.',
            }
        }
    );
    
=cut

sub new {
    carp("Got login request: " . Dumper(@_)) if $_[1]->debug;
    my $class = shift;
    my $main = shift;
    my $vars = shift;
    my $self = bless {}, $class;
    
    my $uri = '/v2/login_information/password';
    
    # Build the portions of the get string as needed.
    
    my $creds = $main->buildCredentials();
    
    my $response = $main->sendRequest('PUT', 'application/json', $creds, $main->defaultUrl . $uri, $vars);
    
    return $response;
}


1;
