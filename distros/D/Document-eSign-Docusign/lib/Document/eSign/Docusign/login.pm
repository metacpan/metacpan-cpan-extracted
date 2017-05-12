package Document::eSign::Docusign::login;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Document::eSign::Docusign::login - Handles the login to Docusign. Should not be used outside of this module.

=head1 VERSION

Version 0.02

=cut

=head1 functions

=head2 new($parent, $vars)

Takes the parent class and a hashref of options as arguments. Performs the login and sets the parent object's internal vars.

=cut

sub new {
    carp("Got login request: " . Dumper(@_)) if $_[1]->debug;
    my $class = shift;
    my $main = shift;
    my $vars = shift;
    my $self = bless {}, $class;
    
    my $uri = '/v2/login_information?';
    
    # Build the portions of the get string as needed.
    
    for ( qw{api_password include_account_id_guid login_settings} ) {
        if (defined $vars->{$_} ) {
            $uri .= $_ . '=' . $vars->{$_};
        }
    }
    
    my $creds = $main->buildCredentials();
    
    my $response = $main->sendRequest('GET', undef, $creds, $main->baseUrl . $uri, undef);
    
    while ( my ( $key, $value ) = each %{$response->{loginAccounts}->[0]} ) {
        eval {$main->$key($value)};
    }
    
    return $self;
}


1;
