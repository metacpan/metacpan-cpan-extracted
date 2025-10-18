package Lemonldap::NG::Portal::Plugins::OidcOfflineTokens;

use strict;
use Mouse;
use Date::Parse;
use JSON qw(from_json to_json);
use Time::Local;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_NOTOKEN
  PE_TOKENEXPIRED
  PE_SENDRESPONSE
);

our $VERSION = '2.22.0';

extends qw(Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::OtherSessions
);

use constant name => "OidcOfflineTokens";
has rule => (
    is      => "ro",
    lazy    => 1,
    builder => sub { $_[0]->conf->{portalDisplayOfflineTokens} },
);
with 'Lemonldap::NG::Portal::MenuTab';

has oidc => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]
          ->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::OpenIDConnect'};
    }
);

sub init {
    my ( $self, $req, $session ) = @_;

    $self->addAuthRoute( myoffline => { ':key' => 'delOffline' }, ['DELETE'] );
    unless ( $self->conf->{issuerDBOpenIDConnectActivation} ) {
        $self->logger->error(
            'This plugin can be used only if OIDC server is enabled');
        return 0;
    }
    return 1;
}

sub display {
    my ( $self, $req ) = @_;
    my $activeSessions = [];
    my $sessions       = {};
    my $regex          = qr/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/;

    $self->logger->debug("Reading OidcOfflineTokens");
    my $user = $req->{userData}->{ $self->conf->{whatToTrace} };

    if ($user) {
        $self->logger->debug('Try to retrieve sessions from DB');
        my $moduleOptions;
        if ( $self->conf->{oidcStorage} ) {
            $moduleOptions = $self->conf->{oidcStorageOptions};
            $moduleOptions->{backend} = $self->conf->{oidcStorage};
        }
        else {
            $moduleOptions = $self->conf->{globalStorageOptions};
            $moduleOptions->{backend} = $self->conf->{globalStorage};
        }

        $self->logger->debug("Looking for \"$user\" sessions...");
        $sessions =
          $self->module->searchOn( $moduleOptions, $self->conf->{whatToTrace},
            $user );

        my $other = 0;
        foreach ( keys %$sessions ) {
            unless ( defined( $sessions->{$_}->{_type} )
                && $sessions->{$_}->{_type} eq 'refresh_token'
                && $sessions->{$_}->{_session_kind} eq 'OIDCI' )
            {
                delete $sessions->{$_};
                $other++;
            }
        }
        @$activeSessions = map {
            my $epoch;

            if ( $sessions->{$_}->{_updateTime} ) {
                if ( my ( $y, $mo, $d, $h, $mi, $s ) =
                    $sessions->{$_}->{_updateTime} =~ /$regex/ )
                {
                    $epoch = timelocal( $s, $mi, $h, $d, $mo - 1, $y );
                    $sessions->{$_}->{_updateTime} = $epoch;
                }
                else {
                    delete $sessions->{$_}->{_updateTime};
                }
            }

            {
                id        => $sessions->{$_}->{client_id},
                epoch     => $sessions->{$_}->{_updateTime},
                sessionid => $_
            }
        } keys %$sessions;
    }
    return {
        logo => "wrench",
        name => "OidcOfflineTokens",
        id   => "OidcOfflineTokens",
        html => $self->loadTemplate(
            $req,
            "oidcOfflineTokens",
            params => {
                sessions => to_json($activeSessions),
                js       =>
                  "$self->{p}->{staticPrefix}/common/js/oidcOfflineTokens.js"
            }
        ),
    };
}

sub delOffline {
    my ( $self, $req ) = @_;
    my $id = $req->param('key');
    return $self->p->sendError( $req, 'ID is required', 400 ) unless ($id);
    my $mod;
    if ( $self->conf->{oidcStorage} ) {
        $mod = {
            module  => $self->conf->{oidcStorage},
            options => $self->conf->{oidcStorageOptions}
        };
    }
    else {
        $mod = {
            module  => $self->conf->{globalStorage},
            options => $self->conf->{globalStorageOptions}
        };

    }

    # Get session
    # The hashed store is used if explicitly asked and if session type is
    # SSO or OIDC
    my $session = $self->oidc->getOpenIDConnectSession(
        $id, "refresh_token",
        hashStore => 0

    );
    return $self->p->sendError( $req, 'Session Id does not exist', 400 )
      unless $session->{data};

    # Delete it
    unless ( $req->userData->{ $self->conf->{whatToTrace} } eq
        $session->data->{ $self->conf->{whatToTrace} } )
    {
        return $self->sendError( $req, "Not authorized" );
    }
    $self->logger->debug("Request to delete session $id");
    $session->remove( {
            hashStore => 0
        }
    );

    #TODO : Call BackChannelLogout if needed
    return $self->p->sendJSONresponse( $req, { result => 1 } );
}

1;
