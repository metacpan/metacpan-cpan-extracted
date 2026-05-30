package t::OidcClientHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

# Markers to track hook calls
our $authzCallbackHookCalled = '';
our $authRequestHookCalled   = '';
our $tokenRequestHookCalled  = '';
our $gotIDTokenHookCalled    = '';
our $gotUserInfoHookCalled   = '';

# Store modified values for verification
our $idTokenHookData  = '';
our $userInfoHookData = '';

use constant hook => {
    oidcGotAuthenticationResponse     => 'gotAuthzCallback',
    oidcGenerateAuthenticationRequest => 'genAuthRequest',
    oidcGenerateTokenRequest          => 'genTokenRequest',
    oidcGotIDToken                    => 'gotIDToken',
    oidcGotUserInfo                   => 'gotUserInfo',
};

sub gotAuthzCallback {
    my ( $self, $req, $callback_params ) = @_;

    # Mark that the hook was called
    $authzCallbackHookCalled = 1;

    return PE_OK;
}

sub genAuthRequest {
    my ( $self, $req, $op, $auth_request_params ) = @_;

    # Mark that the hook was called
    $authRequestHookCalled = 1;

    # Add a custom parameter to the authentication request
    $auth_request_params->{custom_auth_param} = "auth_hook_value";

    $auth_request_params->{badjson} .= "h";

    # Make sure claims is received as json and set an additional one
    if ( ref( $auth_request_params->{claims} ) ) {
        $auth_request_params->{claims}->{id_token}->{my_claim} = undef;
    }

    return PE_OK;
}

sub genTokenRequest {
    my ( $self, $req, $op, $token_request_params ) = @_;

    # Mark that the hook was called
    $tokenRequestHookCalled = 1;

    # Add a custom parameter to the token request
    $token_request_params->{custom_token_param} = "token_hook_value";

    return PE_OK;
}

sub gotIDToken {
    my ( $self, $req, $op, $id_token_payload ) = @_;

    # Mark that the hook was called
    $gotIDTokenHookCalled = 1;

    # Store some data from the ID token for verification
    $idTokenHookData = "$op/" . ( $id_token_payload->{sub} // 'no_sub' );

    return PE_OK;
}

sub gotUserInfo {
    my ( $self, $req, $op, $userinfo_content ) = @_;

    # Mark that the hook was called
    $gotUserInfoHookCalled = 1;

    # Store some data from userinfo for verification
    $userInfoHookData = "$op/" . ( $userinfo_content->{sub} // 'no_sub' );

    return PE_OK;
}

# Reset all markers (for use between tests)
sub reset_markers {
    $authzCallbackHookCalled = '';
    $authRequestHookCalled   = '';
    $tokenRequestHookCalled  = '';
    $gotIDTokenHookCalled    = '';
    $gotUserInfoHookCalled   = '';
    $idTokenHookData         = '';
    $userInfoHookData        = '';
}

1;
