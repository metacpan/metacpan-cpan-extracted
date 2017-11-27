##@file
# LinkedIn authentication backend file

##@class
# LinkedIn authentication backend class.
package Lemonldap::NG::Portal::AuthLinkedIn;

use strict;
use Lemonldap::NG::Portal::Simple;
use JSON;
use MIME::Base64 qw/encode_base64 decode_base64/;
use URI::Escape;
use base qw(Lemonldap::NG::Portal::_Browser);

our $VERSION = '1.9.13';

## @apmethod int authInit()
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;

    unless ( $self->{linkedInClientID} and $self->{linkedInClientSecret} ) {
        $self->abort(
            'Bad configuration',
            'linkedInClientID and linkedInClientSecret parameters are required'
        );
    }

    PE_OK;
}

## @apmethod int extractFormInfo()
# Authenticate users by LinkedIn and set user
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self  = shift;
    my $nonce = time;

    # Default values for LinkedIn API
    $self->{linkedInauthorizationEndpoint} ||=
      "https://www.linkedin.com/oauth/v2/authorization";
    $self->{linkedInTokenEndpoint} ||=
      "https://www.linkedin.com/oauth/v2/accessToken";
    $self->{linkedInPeopleEndpoint} ||= "https://api.linkedin.com/v1/people/";

    $self->{linkedInPeopleEndpoint} .=
      "~:(" . $self->{linkedInFields} . ")?format=json";

    # Build redirect_uri
    my $callback_url = $self->url();

    # Use authChoiceParam in redirect URL
    if ( $self->param( $self->{authChoiceParam} ) ) {
        $callback_url .= ( $callback_url =~ /\?/ ? '&' : '?' );
        $callback_url .= $self->{authChoiceParam} . '='
          . uri_escape( $self->param( $self->{authChoiceParam} ) );
    }

    # Check return values
    my $error = $self->param("error");
    my $code  = $self->param("code");
    my $state = $self->param("state");

    # Error
    if ($error) {
        $self->lmLog(
            "Error $error with LinkedIn: " . $self->param("error_description"),
            'error'
        );
        return PE_ERROR;
    }

    # Code
    if ($code) {
        my %form;
        $form{"code"}          = $code;
        $form{"client_id"}     = $self->{linkedInClientID};
        $form{"client_secret"} = $self->{linkedInClientSecret};
        $form{"redirect_uri"}  = $callback_url;
        $form{"grant_type"}    = "authorization_code";

        my $response = $self->ua->post( $self->{linkedInTokenEndpoint},
            \%form, "Content-Type" => 'application/x-www-form-urlencoded' );

        if ( $response->is_error ) {
            $self->lmLog( "Bad authorization response: " . $response->message,
                "error" );
            $self->lmLog( $response->content, 'debug' );
            return PE_ERROR;
        }

        my $content = $response->decoded_content;

        my $json_hash;

        eval { $json_hash = from_json( $content, { allow_nonref => 1 } ); };

        if ($@) {
            $self->lmLog( "Unable to decode JSON $content", "error" );
            return PE_ERROR;
        }

        my $access_token = $json_hash->{access_token};

        $self->lmLog( "Get access token $access_token from LinkedIn", 'debug' );

        my $people_response = $self->ua->get( $self->{linkedInPeopleEndpoint},
            "Authorization" => "Bearer $access_token" );

        if ( $people_response->is_error ) {
            $self->lmLog(
                "Bad authorization response: " . $people_response->message,
                "error" );
            $self->lmLog( $people_response->content, 'debug' );
            return PE_ERROR;
        }

        my $people_content = $people_response->decoded_content;

        eval {
            $json_hash = from_json( $people_content, { allow_nonref => 1 } );
        };
        if ($@) {
            $self->lmLog( "Unable to decode JSON $people_content", "error" );
            return PE_ERROR;
        }

        foreach ( keys %$json_hash ) {
            $self->{linkedInData}->{$_} = $json_hash->{$_};
        }

        $self->{user} = $self->{linkedInData}->{ $self->{linkedInUserField} };

        # Extract state
        if ($state) {
            my $stateSession = $self->getApacheSession( $state, 1 );

            $self->{urldc}       = $stateSession->data->{urldc};
            $self->{checkLogins} = $stateSession->data->{checkLogins};

            $stateSession->remove;
        }

        return PE_OK;
    }

    # No code, redirect to LinkedIn
    else {
        $self->lmLog( 'Redirection to LinkedIn', 'debug' );

        # Store state
        my $stateSession =
          $self->getApacheSession( undef, 1, 0, 'LinkedInState' );

        my $stateInfos = {};
        $stateInfos->{_utime}      = time() + $self->{timeout};
        $stateInfos->{urldc}       = $self->{urldc};
        $stateInfos->{checkLogins} = $self->{checkLogins};

        $stateSession->update($stateInfos);

        my $authn_uri = $self->{linkedInauthorizationEndpoint};
        $authn_uri .= "?response_type=code";
        $authn_uri .= "&client_id=" . uri_escape( $self->{linkedInClientID} );
        $authn_uri .= "&redirect_uri=$callback_url";
        $authn_uri .= "&scope=" . uri_escape( $self->{linkedInScope} );
        $authn_uri .= "&state=" . $stateSession->id;

        $self->{urldc} = $authn_uri;

        $self->lmLog( "Redirect user to " . $self->{urldc}, 'debug' );

        return $self->_subProcess(qw(autoRedirect));

        PE_OK;
    }
}

## @apmethod int setAuthSessionInfo()
# Set authenticationLevel and Twitter attributes.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    $self->{sessionInfo}->{authenticationLevel} = $self->{linkedInAuthnLevel};
    $self->{sessionInfo}->{'_user'} = $self->{user};

    foreach ( keys %{ $self->{linkedInData} } ) {
        $self->{sessionInfo}->{ 'linkedIn_' . $_ } =
          $self->{linkedInData}->{$_};
    }

    PE_OK;
}

## @apmethod int authenticate()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    PE_OK;
}

## @apmethod int authFinish()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authFinish {
    PE_OK;
}

## @apmethod int authLogout()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub authLogout {
    PE_OK;
}

## @apmethod boolean authForce()
# Does nothing
# @return result
sub authForce {
    return 0;
}

## @method string getDisplayType
# @return display type
sub getDisplayType {
    return "logo";
}

1;
