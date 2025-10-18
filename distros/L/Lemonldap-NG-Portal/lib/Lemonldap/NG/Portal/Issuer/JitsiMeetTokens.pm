package Lemonldap::NG::Portal::Issuer::JitsiMeetTokens;

use strict;
use URI;
use Mouse;
use JSON;
use MIME::Base64 qw/decode_base64url encode_base64url/;
use Crypt::JWT   qw(encode_jwt);
use Digest::SHA  qw(sha256_hex);
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::RSA;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_REDIRECT
  PE_UNAUTHORIZEDPARTNER
  PE_ERROR
  PE_OK
);

our $VERSION = '2.22.0';

extends 'Lemonldap::NG::Portal::Main::Issuer';
with 'Lemonldap::NG::Portal::Lib::Key';

has rule => ( is => 'rw' );

has jitsi_default_server => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        $_[0]->conf->{jitsiDefaultServer};
    }
);

has jitsi_appid => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        $_[0]->conf->{jitsiAppId};
    }
);

has jitsi_expiration => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        $_[0]->conf->{jitsiExpiration} || "300";
    }
);

has jitsi_signing_alg => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        $_[0]->conf->{jitsiSigningAlg} || "HS256";
    }
);

has jitsi_appsecret => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        $_[0]->conf->{jitsiAppSecret};
    }
);

has jitsi_id_attribute => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        $_[0]->conf->{jitsiIdAttribute} || $_[0]->conf->{whatToTrace};
    }
);

has jitsi_name_attribute => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        $_[0]->conf->{jitsiNameAttribute} || "cn";
    }
);
has jitsi_mail_attribute => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        $_[0]->conf->{jitsiMailAttribute} || "mail";
    }
);

sub init {
    my ($self) = @_;

    my $compiled_rule =
      $self->p->buildRule( $self->conf->{issuerDBJitsiMeetTokensRule},
        "Jitsi JWT issuer rule" );
    return 0 if !$compiled_rule;

    return 0 unless $self->SUPER::init();

    $self->addUnauthRoute( $self->path() => { asap => "asap" }, ['GET'] );
    $self->addAuthRoute( $self->path() => { asap => "asap" }, ['GET'] );
    $self->rule($compiled_rule);
    return 1;

}

sub asap {
    my ( $self, $req, @path ) = @_;

    my $filename = $path[0];

    my $hash = $filename =~ s/\.pem$//r;

    for my $key_id ( split( /\s*,\s*/, $self->conf->{jitsiSigningKey} ) ) {
        my $key = $self->get_public_key($key_id);
        if (    $key
            and $key->{external_id}
            and $hash eq sha256_hex( $key->{external_id} ) )
        {
            return $self->_sendAsap( $req, $key->{public} );
        }
    }

    return $self->p->sendError( $req, "Unknown key id hash", 404 );
}

sub _sendAsap {
    my ( $self, $req, $pem ) = @_;

    my $res;

    # Try to parse as RSA key
    eval {
        my $pubkey = Crypt::OpenSSL::RSA->new_public_key($pem);
        $res = $pubkey->get_public_key_x509_string;
    };
    my $parse_pubkey_error = $@;

    if ( !$res ) {

        # Try to parse as X.509 cert
        eval {
            my $x509 = Crypt::OpenSSL::X509->new_from_string( $pem,
                Crypt::OpenSSL::X509::FORMAT_PEM );
            my $pub  = $x509->pubkey;
            my $type = $x509->pubkey_type;
            if ( ($type) eq "rsa" ) {
                my $pubkey = Crypt::OpenSSL::RSA->new_public_key($pub);
                $res = $pubkey->get_public_key_x509_string;
            }
            else {
                die "Unsupported pubkey type $type";
            }
        };
    }
    my $parse_cert_error = $@;

    if ($res) {
        return [
            200,
            [
                'Content-Type'   => 'application/x-pem-file',
                'Content-Length' => length($res),
                $req->spliceHdrs,
            ],
            [$res]
        ];
    }
    else {
        $self->logger->error(
                "Could not parse public key as RSA ($parse_pubkey_error)"
              . " or X.509 ($parse_cert_error)" );
        return $self->p->sendError( $req, "Unsupported public key format",
            500 );
    }
}

sub run {
    my ( $self, $req, @path ) = @_;

    # Check activation rule
    unless ( $self->rule->( $req, $req->sessionInfo ) ) {
        $self->userLogger->error('Jitsi JWT service not authorized');
        return PE_UNAUTHORIZEDPARTNER;
    }

    if ( $path[0] eq "login" ) {
        return $self->jitsi($req);
    }
    return PE_OK;
}

# Nothing to do here for now
sub logout {
    return PE_OK;
}

sub jitsi {
    my ( $self, $req ) = @_;
    my $room = $req->param('room');

    if ( !$self->jitsi_default_server ) {
        $self->logger->error("Jitsi Server URL not set in configuration");
        return PE_ERROR;
    }
    if ( !$self->jitsi_appid ) {
        $self->logger->error("Jitsi Application ID not set in configuration");
        return PE_ERROR;
    }
    if ( !$room ) {
        $self->logger->error("Missing room parameter");
        return PE_ERROR;
    }

    my $payload = {
        iss     => $self->p->buildUrl(),
        room    => $room,
        exp     => ( time + $self->jitsi_expiration ),
        sub     => '*',
        aud     => $self->jitsi_appid,
        context => {
            user => {
                id => $req->userData->{ $self->jitsi_id_attribute },
                (
                    $self->jitsi_name_attribute
                    ? ( name => $req->userData->{ $self->jitsi_name_attribute }
                      )
                    : ()
                ),
                (
                    $self->jitsi_mail_attribute
                    ? ( email =>
                          $req->userData->{ $self->jitsi_mail_attribute } )
                    : ()
                ),
                affiliation => "owner"
            }
        }
    };
    my $server;
    my $u = URI->new_abs( $room, URI->new( $self->jitsi_default_server ) );

    my @extra_headers;
    my $key;
    if ( $self->jitsi_signing_alg =~ /^HS/ ) {
        if ( !$self->jitsi_appsecret ) {
            $self->logger->error(
                "Jitsi Application secret not set in configuration");
            return PE_ERROR;
        }
        $key = $self->jitsi_appsecret;

    }
    else {
        my ($key_id) = split( /\s*,\s*/, $self->conf->{jitsiSigningKey} );
        if ( !$key_id ) {
            $self->logger->error("jitsiSigningKey is not set");
            return PE_ERROR;
        }

        my $pkey = $self->get_private_key($key_id);
        if ( !$pkey ) {
            $self->logger->error("Jitsi signing key $key_id was not found");
            return PE_ERROR;
        }

        if ( !$pkey->{external_id} ) {
            $self->logger->error(
                    "Jitsi signing key does not have an identified."
                  . " You must set oidcServiceKeyIdSig" );
            return PE_ERROR;
        }
        @extra_headers = ( kid => $pkey->{external_id} );
        my $private = $pkey->{private};
        $key = \$private;
    }

    my $jwt = eval {
        encode_jwt(
            payload       => to_json($payload),
            alg           => $self->jitsi_signing_alg,
            key           => $key,
            extra_headers => { typ => "JWT", @extra_headers },
        );
    };
    if ($@) {
        $self->logger->error("Could not encode JWT: $@");
        return $self->p->doPE( $req, PE_ERROR );
    }

    $u->query_form( jwt => $jwt );
    $req->urldc( $u->as_string );
    return PE_REDIRECT;
}

1;
