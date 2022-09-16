package Lemonldap::NG::Portal::Issuer::OpenID;

use strict;
use JSON;
use Mouse;
use Lemonldap::NG::Common::Regexp;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_CONFIRM
  PE_REDIRECT
  PE_BADPARTNER
  PE_OPENID_BADID
  PE_OPENID_EMPTY
  PE_SENDRESPONSE
  PE_OID_SERVICE_NOT_ALLOWED
);

our $VERSION = '2.0.15';

extends 'Lemonldap::NG::Portal::Main::Issuer';

# PROPERTIES

has secret => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return $_[0]->conf->{openIdIssuerSecret}
          || $_[0]->conf->{cipher}->encrypt(0);
    }
);

has listIsWhite => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        ( $_[0]->conf->{openIdSPList} =~ /^(\d);/ )[0] + 0;
    }
);

has spList => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        Lemonldap::NG::Common::Regexp::reDomainsToHost(
            ( $_[0]->conf->{openIdSPList} =~ /^\d;(.*)$/ )[0] );
    }
);

has openidPortal => ( is => 'rw' );

has rule => ( is => 'rw' );

# INITIALIZATION

sub init {
    my ($self) = @_;

    # Parse activation rule
    my $hd = $self->p->HANDLER;
    $self->logger->debug(
        "OpenID rule -> " . $self->conf->{issuerDBOpenIDRule} );
    my $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{issuerDBOpenIDRule} ) );
    unless ($rule) {
        my $error = $hd->tsv->{jail}->error || '???';
        $self->error("Bad OpenID activation rule -> $error");
        return 0;
    }
    $self->{rule} = $rule;

    eval { require Lemonldap::NG::Portal::Lib::OpenID::Server };
    if ($@) {
        $self->error("Unable to load Net::OpenID::Server: $@");
        return 0;
    }
    return 0 unless ( $self->SUPER::init() );
    $self->openidPortal( $self->conf->{portal} . '/' . $self->path . '/' );

    #$openidPortal =~ s#(?<!:)//#/#g;
    return 1;
}

# RUNNING METHOD

# Overwrite _redirect to handle server-to-server queries
sub _redirect {
    my ( $self, $req ) = @_;
    unless ( $req->pdata->{issuerRequestopenidserver} ) {
        my $mode = $req->param('openid.mode');
        unless ($mode) {
            $self->logger->debug('OpenID SP test');
            return $self->p->do( $req, [ sub { PE_OPENID_EMPTY } ] );
        }
        if ( $mode eq 'associate' ) {
            return $self->_openIDResponse( $req,
                $self->openIDServer($req)->_mode_associate() );
        }
        elsif ( $mode eq 'check_authentication' ) {
            return $self->_openIDResponse( $req,
                $self->openIDServer($req)->_mode_check_authentication() );
        }
    }
    return $self->SUPER::_redirect($req);
}

sub run {
    my ( $self, $req ) = @_;

    # Check activation rule
    unless ( $self->rule->( $req, $req->sessionInfo ) ) {
        $self->userLogger->error('OpenID service not authorized');
        return PE_OID_SERVICE_NOT_ALLOWED;
    }

    my $mode = $req->param('openid.mode');
    unless ($mode) {
        $self->logger->debug('OpenID SP test');
        return PE_OPENID_EMPTY;
    }

    unless ( $mode =~ /^checkid_(?:immediate|setup)/ ) {
        $self->logger->error(
            "OpenID error : $mode is not known at this step (issuerForAuthUser)"
        );
        return PE_ERROR;
    }
    my @r = $self->openIDServer($req)->_mode_checkid($mode);
    return $self->_openIDResponse( $req, @r );
}

sub logout {
    return PE_OK;
}

# INTERNAL METHODS

# Create if not done a new Lemonldap::NG::Portal::Lib::OpenID::Server objet
sub openIDServer {
    my ( $self, $req ) = @_;
    return $req->data->{_openidserver} if ( $req->data->{_openidserver} );

    $req->data->{_openidserver} =
      Lemonldap::NG::Portal::Lib::OpenID::Server->new(
        server_secret => sub { return $self->secret },
        args          => sub { $req->param(@_) },
        endpoint_url  => $self->openidPortal,
        setup_url     => $self->openidPortal,
        get_user      => sub {
            return $req->{sessionInfo}
              ->{ $self->conf->{openIdAttr} || $self->conf->{whatToTrace} };
        },
        get_identity => sub {
            my ( $u, $identity ) = @_;
            return $identity unless $u;
            return $self->openidPortal . $u;
        },
        is_identity => sub {
            my ( $u, $identity ) = @_;
            return 0 unless ( $u and $identity );
            if ( $u eq ( split '/', $identity )[-1] ) {
                return 1;
            }
            else {
                $self->{_badOpenIdentity} = 1;
                return 0;
            }
        },
        is_trusted => sub {
            my ( $u, $trust_root, $is_identity ) = @_;
            return 0 unless ( $u and $is_identity );
            my $tmp = $trust_root;
            $tmp =~ s#^http://(.*?)/#$1#;
            if ( $tmp =~ $self->spList xor $self->listIsWhite ) {
                $self->userLogger->warn(
                    "$trust_root is forbidden for openID exchange");
                $req->data->{_openIdForbidden} = 1;
                return 0;
            }
            elsif ( $req->{sessionInfo}->{"_openidTrust$trust_root"} ) {
                $self->logger->debug('OpenID request already trusted');
                return 1;
            }
            elsif ( $req->param("confirm") and $req->param("confirm") == 1 ) {
                $self->p->updatePersistentSession( $req,
                    { "_openidTrust$trust_root" => 1 } );
                return 1;
            }
            elsif ( $req->param("confirm") and $req->param("confirm") == -1 ) {
                $self->p->updatePersistentSession( $req,
                    { "_openidTrust$trust_root" => 0 } );
                return 0;
            }
            else {
                $self->logger->debug('OpenID request not trusted');
                $req->data->{_openIdTrustRequired} = 1;
                return 0;
            }
        },
        extensions => {
            sreg => sub {
                return ( 1, {} ) unless (@_);
                require Lemonldap::NG::Portal::Lib::OpenID::SREG;
                return
                  $self->Lemonldap::NG::Portal::Lib::OpenID::SREG::sregHook(
                    $req, @_ );
            },
        },
      );
    return $req->data->{_openidserver};
}

# Manage Lemonldap::NG::Portal::OpenID::Server responses
# @return Lemonldap::NG::Portal error code
sub _openIDResponse {
    my ( $self, $req, $type, $data ) = @_;

    # Redirect
    if ( $type eq 'redirect' ) {
        $self->logger->debug("OpenID redirection to $data");
        $req->{urldc} = $data;
        return PE_REDIRECT;
    }

    # Setup
    elsif ( $type eq 'setup' ) {
        if (   $req->data->{_openIdTrustRequired}
            or $req->data->{_openIdTrustExtMsg} )
        {

            # TODO
            $req->info(
                $self->loadTemplate(
                    $req,
                    'simpleInfo',
                    params => { trspan => "openidExchange,$data->{trust_root}" }
                )
            );
            $req->info( $req->data->{_openIdTrustExtMsg} )
              if ( $req->data->{_openIdTrustExtMsg} );
            $self->logger->debug('OpenID confirmation');
            foreach ( keys %{ $req->parameters } ) {
                if (/^(?:openid.*|url)$/) {
                    $self->p->setHiddenFormValue( $req, $_, $req->param($_),
                        '', 0 );
                }
            }

            # TODO: understand why this is needed here and not in OIDC
            delete $req->data->{_url};
            return PE_CONFIRM;
        }
        elsif ( $req->data->{_badOpenIdentity} ) {
            $self->userLogger->warn(
"The user $req->{sessionInfo}->{_user} tries to use the id \"$data->{identity}\" on $data->{trust_root}"
            );
            return PE_OPENID_BADID;
        }
        elsif ( $req->data->{_openIdForbidden} ) {
            return PE_BADPARTNER;
        }

        # User has refused sharing its data
        else {
            $self->userLogger->notice(
                $req->{sessionInfo}->{ $self->conf->{whatToTrace} }
                  . ' refused to share its OpenIdentity' );
            return PE_OK;
        }
    }
    elsif ($type) {
        $self->logger->debug("OpenID generated page ($type)");
        $req->response( [ 200, [ 'Content-Type' => $type ], [$data] ] );
    }
    else {
        $req->response(
            $self->p->sendError(
                $req, 'OpenID error ' . $self->openIDServer($req)->err()
            )
        );
    }
    return $req->response;
}
1;
