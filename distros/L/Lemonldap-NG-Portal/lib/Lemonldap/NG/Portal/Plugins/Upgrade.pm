package Lemonldap::NG::Portal::Plugins::Upgrade;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_CONFIRM
  PE_TOKENEXPIRED
  PE_SENDRESPONSE
);

our $VERSION = '2.21.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

sub forAuthUser { 'handleAuthRequests' }

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
    $self->addAuthRoute( upgradesession => 'askUpgrade', ['GET'] )
      ->addAuthRoute( upgradesession => 'confirmUpgrade', ['POST'] )
      ->addAuthRoute( renewsession   => 'askRenew',       ['GET'] )
      ->addAuthRoute( renewsession   => 'confirmRenew',   ['POST'] );

    return 1;
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

    $req->data->{discardChoiceForCurrentSession} = 1;

    # sfOnlyUpgrade feature can only be used during session renew
    return $self->confirm( $req, $self->conf->{sfOnlyUpgrade} );
}

sub confirmRenew {
    my ( $self, $req ) = @_;
    return $self->confirm($req);
}

# RUNNING METHOD

sub ask {
    my ( $self, $req, $form_action, $message, $buttonlabel ) = @_;

    # Check if auth is already running
    # and verify token
    return $self->confirm($req)
      if ( $req->param('upgrading') or $req->param('kerberos') );

    my $url          = $req->param('url')          || '';
    my $forceUpgrade = $req->param('forceUpgrade') || '';
    my $action       = ( $message =~ /^askTo(\w+)$/ )[0];
    $self->logger->debug(" -> $action required");
    $self->logger->debug(" -> Skip confirmation is enabled")
      if $self->conf->{"skip${action}Confirmation"};

    $url = '' if $self->p->checkXSSAttack('url', $url);
    $forceUpgrade = '' if $self->p->checkXSSAttack('forceUpgrade', $forceUpgrade);

    my $cacheTag = $self->p->cacheTag;
    # Display form
    return $self->p->sendHtml(
        $req,
        'upgradesession',
        params => {
            FORMACTION   => $form_action,
            PORTALBUTTON => 1,
            MSG          => $message,
            BUTTON       => $buttonlabel,
            CONFIRMKEY   => $self->p->stamp,
            FORCEUPGRADE => $forceUpgrade,
            URL          => $url,
            (
                $self->conf->{"skip${action}Confirmation"}
                ? ( CUSTOM_SCRIPT =>
qq'<script type="text/javascript" src="$self->{p}->{staticPrefix}/common/js/autoRenew.min.js?v=$cacheTag"></script>'
                  )
                : ()
            )
        }
    );
}

sub confirm {
    my ( $self, $req, $sfOnly ) = @_;
    my $upg;

    my $old_id = $req->userData->{_session_id};

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
    return $self->p->do( $req, [ sub { $res } ] ) if $res;

    if ( $upg or $req->param('confirm') and $req->param('confirm') == 1 ) {
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
            my $res = $self->p->login($req);

            if ( $old_id and $req->id and $old_id ne $req->id ) {
                $self->p->processHook( $req, 'updateSessionId', $old_id,
                    $req->id );
            }
            return $res;
        }
    }
    else {

        # Go to portal
        $self->logger->debug("Upgrade session did not trigger -> Go to Portal");
        $req->mustRedirect(1);
        return $self->p->do( $req, [ sub { PE_OK } ] );
    }
}

# Takes care of callbacks for external methods (SAML, OIDC...)
sub handleAuthRequests {
    my ( $self, $req ) = @_;
    if (    $self->p->_authentication->can('isCallback')
        and $self->p->_authentication->isCallback($req) )
    {
        $req->id(undef);
        $req->parameters->{'confirm'} = 1;
        $req->response( $self->confirm($req) );
        return PE_SENDRESPONSE;
    }
    return PE_OK;
}

1;
