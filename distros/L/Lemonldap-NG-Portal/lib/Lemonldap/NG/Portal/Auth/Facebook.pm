package Lemonldap::NG::Portal::Auth::Facebook;

use strict;
use Mouse;
use URI::Escape;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR PE_BADCREDENTIALS);
use utf8;

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Main::Auth';

# INITIALIZATION

sub init {
    my $self = shift;
    eval { require Net::Facebook::Oauth2; };
    if ($@) {
        $self->error("Unable to load Net::Facebook::Oauth2: $@");
        return 0;
    }
    my $ret = 1;
    foreach my $arg (qw(facebookAppId facebookAppSecret)) {
        unless ( $self->conf->{$arg} ) {
            $ret = 0;
            $self->error("Parameter $arg is required");
        }
    }
    return $ret;
}

# RUNNING METHODS

sub extractFormInfo {
    my ( $self, $req ) = @_;
    my $fb = $self->fb($req);

    # 1. Check Facebook responses

    # 1.1 Good responses
    if ( my $code = $req->param('code') ) {
        $self->logger->debug("Get code $code from Facebook");
        my $access_token;
        eval { $access_token = $fb->get_access_token( code => $code ); };
        if ($@) {
            $self->logger->error("Error while getting access token: $@");
            return PE_ERROR;
        }
        if ($access_token) {
            $req->{sessionInfo}->{_facebookToken} = $access_token;

     # Get mandatory fields (see https://developers.facebook.com/tools/explorer)
            my @fields = ( $self->conf->{facebookUserField} );

            # Search all wanted fields
            push @fields,
              map { /^(\w+)$/ ? ($1) : () }
              values %{ $self->conf->{facebookExportedVars} };

            my $data;

            # When a field is not granted, Facebook returns only an error
            # without real explanation. So here we try to reduce query until
            # having a valid response
            while (@fields) {
                $data = $fb->get(
                    'https://graph.facebook.com/me',
                    { fields => join( ',', @fields ) }
                )->as_hash;
                unless ( ref $data ) {
                    $self->logger->error("Unable to get any Facebook field");
                    return PE_ERROR;
                }
                if ( $data->{error} ) {
                    my $tmp = pop @fields;
                    $self->logger->warn(
"Unable to get some Facebook fields ($data->{error}->{message}). Retrying without $tmp"
                    );
                }
                else {
                    last;
                }
            }
            unless (@fields) {
                $self->logger->error("Unable to get any Facebook field");
                return PE_ERROR;
            }

            # Parse received data
            foreach ( keys %$data ) {
                utf8::encode $data->{$_};
                $self->logger->debug( "Facebook data $_: " . $data->{$_} );
            }

            # Field to trace user
            unless ( $data->{ $self->conf->{facebookUserField} } ) {
                $self->logger->error('Unable to get Facebook id');
                return PE_ERROR;
            }
            $req->user( $data->{ $self->conf->{facebookUserField} } );
            $req->data->{_facebookData} = $data;
            $req->{sessionInfo}->{_facebookData} = $data;

            # Force redirection to avoid displaying Oauth data
            $req->mustRedirect(1);
            return PE_OK;
        }
        return PE_BADCREDENTIALS;
    }

    # 1.2 Bad responses
    if ( my $error_code = $req->param('error_code') ) {
        my $error_message = $req->param('error_message');
        $self->userLogger->error(
            "Facebook error code $error_code: $error_message");
        return PE_ERROR;
    }

    # 2. Else redirect user to Facebook login page:

    # Build Facebook redirection
    # TODO: use a param to use "publish_stream" or not
    my $check_url = $fb->get_authorization_url(
        scope   => [ 'public_profile', 'email' ],
        display => 'page',
    );
    $req->urldc($check_url);
    $self->logger->debug( "Redirect user to " . $req->{urldc} );
    $req->continue(1);
    $req->steps( [] );

    return PE_OK;
}

sub authenticate {
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{authenticationLevel} =
      $self->conf->{facebookAuthnLevel};
    return PE_OK;
}

sub authFinish {
    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

sub getDisplayType {
    return "logo";
}

sub fb {
    my ( $self, $req ) = @_;
    my $conf = $self->{conf};
    my $fb;
    my $sep = '?';
    my $ret = $conf->{portal};

    eval {
        $fb = Net::Facebook::Oauth2->new(
            application_id     => $conf->{facebookAppId},
            application_secret => $conf->{facebookAppSecret},
            callback           => $ret,
        );
    };
    $self->logger->error($@) if ($@);

    return $fb;
}

1;
