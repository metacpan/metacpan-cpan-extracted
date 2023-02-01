# Plugin to remember which authentication method has been chosen,
# and laun it automatically

package Lemonldap::NG::Portal::Plugins::RememberAuthChoice;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_SENDRESPONSE
);

our $VERSION = '2.0.15';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INTERFACE

use constant endAuth    => 'storeRememberedAuthChoice';
use constant beforeAuth => 'checkRememberedAuthChoice';

has rule => ( is => 'rw', default => sub { 0 } );

has rememberCookieName => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{rememberCookieName} // 'llngrememberauthchoice';
    }
);

# Default timeout: 1 year
has rememberCookieTimeout => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{rememberCookieTimeout} // 31536000;
    }
);

sub init {
    my ($self) = @_;

    # Parse activation rule
    $self->rule(
        $self->p->buildRule(
            $self->conf->{rememberAuthChoiceRule},
            'rememberAuthChoiceRule'
        )
    );
    return 0 unless $self->rule;

    return 1;
}

sub storeRememberedAuthChoice {
    my ( $self, $req ) = @_;

    # Get directly authentication choice from sessionInfo
    my $lmAuth = $req->sessionInfo->{_choice};

    # Get rememberauthchoice tick from corresponding hash
    #  * req->pdata for Issuer auth modules (SAML, OIDC,...)
    #  * req->data for direct auth modules (LDAP)
    my $rememberauthchoice =
         $req->pdata->{rememberauthchoice}
      || $req->data->{rememberauthchoice}
      || "";

    if ($lmAuth) {

        # Store cookie to remember the authentication choice
        if ( $rememberauthchoice eq "true" ) {
            $self->logger->warn( "RememberAuthChoice: set cookie "
                  . $self->rememberCookieName
                  . " with authentication choice lmAuth="
                  . $lmAuth );
            $req->addCookie(
                $self->p->cookie(
                    name     => $self->rememberCookieName,
                    value    => $lmAuth,
                    max_age  => $self->rememberCookieTimeout,
                    secure   => $self->conf->{securedCookie},
                    HttpOnly => 0,    # required for cookie to be read by js
                )
            );
        }

        # Remove cookie to forget previous authentication choice
        else {

            $self->logger->warn( "RememberAuthChoice: Remove cookie "
                  . $self->rememberCookieName );

            $req->addCookie(
                $self->p->cookie(
                    name    => $self->rememberCookieName,
                    value   => 0,
                    expires => 'Wed, 21 Oct 2015 00:00:00 GMT',
                    secure  => $self->conf->{securedCookie},
                )
            );
        }
    }

    return PE_OK;
}

sub checkRememberedAuthChoice {
    my ( $self, $req ) = @_;

    # Check if form has been sent with a rememberauthchoice tick
    my $lmAuth             = $req->param('lmAuth')             || "";
    my $rememberauthchoice = $req->param('rememberauthchoice') || "";

    # If so, store rememberauthchoice tick for the endAuth endpoint
    if ($lmAuth) {

        # For authentication method occurring in the same request
        $req->data->{rememberauthchoice} = $rememberauthchoice;

        # For authentication method occurring in a different request
        $req->pdata->{rememberauthchoice} = $rememberauthchoice;
    }

    return PE_OK;
}

1;
