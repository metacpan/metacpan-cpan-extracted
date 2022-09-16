package Lemonldap::NG::Portal::Plugins::DecryptValue;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_NOTOKEN
  PE_TOKENEXPIRED
  PE_DECRYPTVALUE_SERVICE_NOT_ALLOWED
);

our $VERSION = '2.0.15';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::_tokenRule
);

# INITIALIZATION
has rule => ( is => 'rw', default => sub { 0 } );
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
    $self->addAuthRoute( decryptvalue => 'run', ['POST'] )
      ->addAuthRouteWithRedirect( decryptvalue => 'display', ['GET'] );

    # Parse activation rule
    $self->rule(
        $self->p->buildRule( $self->conf->{decryptValueRule}, 'decryptValue' )
    );
    return $self->rule ? 1 : 0;
}

# RUNNING METHOD
sub display {
    my ( $self, $req ) = @_;

    # Check access rules
    unless ( $self->rule->( $req, $req->userData ) ) {
        $self->userLogger->warn('decryptValue service NOT authorized');
        return $self->p->do( $req,
            [ sub { PE_DECRYPTVALUE_SERVICE_NOT_ALLOWED } ] );
    }

    # Display form
    my $params = {
        MSG    => 'decryptCipheredValue',
        ALERTE => 'alert-warning',
        TOKEN  => (
              $self->ottRule->( $req, {} )
            ? $self->ott->createToken()
            : ''
        )
    };
    return $self->sendJSONresponse( $req, $params ) if ( $req->wantJSON );

    # Display form
    return $self->p->sendHtml( $req, 'decryptvalue', params => $params );
}

sub run {
    my ( $self, $req ) = @_;
    my $msg = my $decryptedValue = '';

    # Check access rules
    unless ( $self->rule->( $req, $req->userData ) ) {
        $self->userLogger->warn('decryptValue service NOT authorized');
        return $self->p->do( $req,
            [ sub { PE_DECRYPTVALUE_SERVICE_NOT_ALLOWED } ] );
    }

    # Check token
    if ( $self->ottRule->( $req, {} ) ) {
        my $token;
        if ( $token = $req->param('token') ) {
            unless ( $self->ott->getToken($token) ) {
                $self->userLogger->warn(
                    'DecryptValue called with an expired/bad token');
                $msg   = PE_TOKENEXPIRED;
                $token = $self->ott->createToken();
            }
        }
        else {
            $self->userLogger->warn('DecryptValue called without token');
            $msg   = PE_NOTOKEN;
            $token = $self->ott->createToken();
        }

        my $params = {
            MSG    => "PE$msg",
            ALERTE => 'alert-warning',
            TOKEN  => $token,
        };
        return $self->p->sendJSONresponse( $req, $params )
          if $req->wantJSON;
        return $self->p->sendHtml( $req, 'decryptvalue', params => $params )
          if $msg;
    }

    my $cipheredValue = $req->param('cipheredValue') || '';
    $self->logger->debug("decryptValue tried with value: $cipheredValue");

    if ($cipheredValue) {
        if (    $self->conf->{decryptValueFunctions}
            and $self->conf->{decryptValueFunctions} =~
            qr/^(?:\w+(?:::\w+)*(?:\s+\w+(?:::\w+)*)*)?$/ )
        {
            foreach ( split( /\s+/, $self->{conf}->{decryptValueFunctions} ) ) {
                $self->userLogger->notice(
                    "Try to decrypt value with function: $_");
                /^([\w:{2}]*?)(?:::)?(?:\w+)$/;
                eval "require $1";
                $self->logger->debug("Unable to load decrypt module: $@")
                  if ($@);
                my $key = $self->conf->{key};
                $decryptedValue = eval "$_" . '($cipheredValue, $key)'
                  unless ($@);
                $self->logger->debug(
                    $@
                    ? "Unable to eval decrypt function: $@"
                    : "Decrypted value = $decryptedValue"
                );
                last if $decryptedValue;
            }
        }
        else {
            $self->userLogger->notice("Malformed decrypt functions")
              if $self->conf->{decryptValueFunctions};
            $self->userLogger->notice(
                "Try to decrypt value with internal LL::NG decrypt function");
            $decryptedValue =
              $self->p->HANDLER->tsv->{cipher}->decrypt($cipheredValue);
            $self->logger->debug(
                $@
                ? "Unable to decrypt value: $@"
                : "Decrypted value = $decryptedValue"
            );
        }
    }

    # Display form
    my $params = {
        MSG       => 'decryptCipheredValue',
        DECRYPTED => (
            $decryptedValue ? $decryptedValue
            : 'notAnEncryptedValue'
        ),
        DALERTE => (
            $decryptedValue ? 'alert-info'
            : 'alert-danger'
        ),
        ALERTE => 'alert-warning',
        TOKEN  => (
            $self->ottRule->( $req, {} ) ? $self->ott->createToken()
            : ''
        )
    };
    return $self->p->sendJSONresponse( $req, $params ) if ( $req->wantJSON );

    # Display form
    return $self->p->sendHtml( $req, 'decryptvalue', params => $params );
}

sub displayLink {
    my ( $self, $req ) = @_;
    return $self->rule->( $req, $req->userData );
}

1;
