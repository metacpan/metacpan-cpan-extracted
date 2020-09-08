package Lemonldap::NG::Portal::Plugins::Upgrade;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_CONFIRM
  PE_OK
  PE_TOKENEXPIRED
);

our $VERSION = '2.0.9';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INITIALIZATION

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);

sub init {
    my ($self) = @_;
    if ( $self->conf->{forceGlobalStorageUpgradeOTT} ) {
        $self->logger->debug(
            "-> Upgrade tokens will be stored into global storage");
        $self->ott->cache(undef);
    }
    $self->addAuthRoute( upgradesession => 'askUpgrade',     ['GET'] );
    $self->addAuthRoute( upgradesession => 'confirmUpgrade', ['POST'] );
    $self->addAuthRoute( renewsession   => 'askRenew',       ['GET'] );
    $self->addAuthRoute( renewsession   => 'confirmRenew',   ['POST'] );
}

sub askUpgrade {
    my ( $self, $req ) = @_;
    $self->ask( $req, '/upgradesession', 'askToUpgrade', 'upgradeSession' );
}

sub askRenew {
    my ( $self, $req ) = @_;
    $self->ask( $req, '/renewsession', 'askToRenew', 'renewSession' );
}

sub confirmUpgrade {
    my ( $self, $req ) = @_;

    # sfOnlyUpgrade feature can only be used during session renew
    return $self->confirm( $req, $self->conf->{sfOnlyUpgrade} );
}

sub confirmRenew {
    my ( $self, $req ) = @_;
    return $self->confirm($req);
}

# RUNNING METHOD

sub ask {
    my ( $self, $req, $url, $message, $buttonlabel ) = @_;

    # Check if auth is already running
    if ( $req->param('upgrading') or $req->param('kerberos') ) {

        # verify token
        return $self->confirm($req);
    }

    # Display form
    return $self->p->sendHtml(
        $req,
        'upgradesession',
        params => {
            MAIN_LOGO    => $self->conf->{portalMainLogo},
            LANGS        => $self->conf->{showLanguages},
            FORMACTION   => $url,
            PORTALBUTTON => 1,
            MSG          => $message,
            BUTTON       => $buttonlabel,
            CONFIRMKEY   => $self->p->stamp,
            PORTAL       => $self->conf->{portal},
            URL          => $req->param('url'),
        }
    );
}

sub confirm {
    my ( $self, $req, $sfOnly ) = @_;
    my $upg;

    if ( $req->param('kerberos') ) {
        $upg = 1;
    }
    else {
        if ( my $t = $req->param('upgrading') ) {
            if ( $self->ott->getToken($t) ) {
                $upg = 1;
            }
            else {
                return $self->p->do( $req, [ sub { PE_TOKENEXPIRED } ] );
            }
        }
    }
    $req->steps( ['controlUrl'] );
    my $res = $self->p->process($req);
    return $self->p->do( $req, [ sub { $res } ] ) if ($res);
    if ( $upg or $req->param('confirm') == 1 ) {
        $req->data->{noerror} = 1;

        if ($sfOnly) {

            $req->data->{doingSfUpgrade} = 1;

            # Short circuit the first part of login, only do a 2FA step
            return $self->p->do(
                $req,
                [
                    'importHandlerData',      'secondFactor',
                    @{ $self->p->afterData }, $self->p->validSession,
                    @{ $self->p->endAuth },
                ]
            );
        }
        else {
            $self->p->setHiddenFormValue(
                $req,
                upgrading => $self->ott->createToken,
                '', 0
            );    # Insert token
                  # Do a regular login
            # Do a regular login
            return $self->p->login($req);
        }
    }
    else {
        # Go to portal
    }
}

1;
