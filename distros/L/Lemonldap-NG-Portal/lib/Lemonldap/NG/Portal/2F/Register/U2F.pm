# Self U2F registration
package Lemonldap::NG::Portal::2F::Register::U2F;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use MIME::Base64 qw(encode_base64url decode_base64url);

our $VERSION = '2.17.0';

extends qw(
  Lemonldap::NG::Portal::2F::Register::Base
  Lemonldap::NG::Portal::Lib::U2F
);
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION
has logo     => ( is => 'rw', default => 'u2f.png' );
has prefix   => ( is => 'rw', default => 'u' );
has template => ( is => 'ro', default => 'u2fregister' );
has welcome  => ( is => 'ro', default => 'u2fWelcome' );

sub init {
    my ($self) = @_;
    return 0 unless ( $self->Lemonldap::NG::Portal::Lib::U2F::init() );
    return ( $self->Lemonldap::NG::Portal::2F::Register::Base::init() );
}

# RUNNING METHODS

# Main method
sub run {
    my ( $self, $req, $action ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };
    return $self->p->sendError( $req, 'PE82', 400 )
      unless $user;

    if ( $action eq 'register' ) {

        # Read existing 2F device(s)
        my @alldevices = $self->find2fDevicesByType( $req, $req->userData );
        my $challenge  = $self->crypter->registrationChallenge;
        $self->logger->debug(
            $self->prefix . "2f: registration challenge ($challenge)" );
        return [
            200,
            [
                'Content-Type'   => 'application/json',
                'Content-Length' => length($challenge),
            ],
            [$challenge]
        ];
    }

    elsif ( $action eq 'registration' ) {
        my ( $resp, $challenge );
        $self->logger->debug( $self->prefix . '2f: registration response' );
        return $self->p->sendError( $req, 'Missing registration parameter',
            400 )
          unless ( $resp = $req->param('registration')
            and $challenge = $req->param('challenge') );

        $self->logger->debug( $self->prefix
              . "2f: get registration data ($resp)\nget challenge ($challenge)"
        );
        eval { $challenge = from_json($challenge)->{challenge} };
        if ($@) {
            $self->userLogger->error(
                $self->prefix . "2f: bad challenge ($@)" );
            return $self->p->sendError( $req, 'Bad challenge', 400 );
        }
        my $c = $self->crypter;
        if ( $c->setChallenge($challenge) ) {
            my ( $keyHandle, $userKey ) = $c->registrationVerify($resp);
            if ( $keyHandle and $userKey ) {
                my $keyName =
                  $self->checkNameSfa( $req, $self->type,
                    $req->param('keyName') );
                return $self->p->sendError( $req, 'badName', 200 )
                  unless $keyName;
                if (
                    $self->add2fDevice(
                        $req,
                        $req->userData,
                        {
                            _userKey   => encode_base64url( $userKey, '' ),
                            _keyHandle => $keyHandle,
                            type       => $self->type,
                            name       => $keyName,
                            epoch      => time()
                        }
                    )
                  )
                {
                    return [
                        200,
                        [
                            'Content-Type'   => 'application/json',
                            'Content-Length' => 12,
                        ],
                        ['{"result":1}']
                    ];
                }
                else {
                    $self->logger->debug(
                        $self->prefix . "2f: unable to add device" );
                    return $self->p->sendError( $req, 'serverError' );
                }
            }
        }
        my $err = Crypt::U2F::Server::Simple::lastError();
        $self->userLogger->warn(
            $self->prefix . "2f: registration failed ($err)" );
        return $self->p->sendError( $req, $err, 200 );
    }

    elsif ( $action eq 'verify' ) {
        $self->logger->debug(
            $self->prefix . '2f: verification challenge request' );
        my ( $err, $error ) = $self->loadUser($req);

        return $self->p->sendError( $req, "U2F error: $error", 200 )
          if ( $err == -1 );
        return $self->p->sendError( $req, "noU2FKeyFound" ) if ( $err == 0 );

        # Get a challenge (from first key)
        my $data = eval {
            from_json( $req->data->{crypter}->[0]->authenticationChallenge );
        };
        if ($@) {
            $self->logger->error( Crypt::U2F::Server::u2fclib_getError() );
            return $self->p->sendError( $req, "U2F error: $error", 200 );
        }

        # Get registered keys
        my @rk =
          map { { keyHandle => $_->{keyHandle}, version => $data->{version} } }
          @{ $req->data->{crypter} };

        # Serialize data
        $data = to_json( {
                challenge      => $data->{challenge},
                appId          => $data->{appId},
                registeredKeys => \@rk
            }
        );
        return [
            200,
            [
                'Content-Type'   => 'application/json',
                'Content-Length' => length($data),
            ],
            [$data]
        ];
    }

    elsif ( $action eq 'signature' ) {
        $self->logger->debug( $self->prefix . '2f: verification response' );
        my ( $challenge, $resp, $crypter );
        return $self->p->sendError( $req, 'Missing signature parameter', 400 )
          unless ( $challenge = $req->param('challenge')
            and $resp = $req->param('signature') );

        my ( $err, $error ) = $self->loadUser($req);
        return $self->p->sendError( $req, "U2F loading error: $error" )
          if ( $err == -1 );
        return $self->p->sendError( $req, "noU2FKeyFound" ) if ( $err == 0 );

        $self->logger->debug(
            $self->prefix . "2f: get verify response ($resp)" );
        my $data = eval { JSON::from_json($resp) };
        if ($@) {
            $self->logger->error( $self->prefix . "2f: response error ($@)" );
            return $self->p->sendError( $req, "U2FAnswerError" );
        }

        $crypter = $_
          foreach grep { $_->{keyHandle} eq $data->{keyHandle} }
          @{ $req->data->{crypter} };

        unless ($crypter) {
            $self->logger->debug( $self->prefix . '2f: device not found' );
            return $self->p->sendError( $req, "U2FKeyUnregistered" );
        }

        if ( not $crypter->setChallenge($challenge) ) {
            $self->logger->error(
                $@ ? $@ : Crypt::U2F::Server::Simple::lastError() );
            return $self->p->sendError( $req, 'serverError' );
        }

        my $res = ( $crypter->authenticationVerify($resp) ? 1 : 0 );
        return [
            200,
            [ 'Content-Type' => 'application/json', 'Content-Length' => 12, ],
            [qq'{"result":$res}']
        ];
    }

    elsif ( $action eq 'delete' ) {

        # Check if unregistration is allowed
        return $self->p->sendError( $req, 'notAuthorized', 400 )
          unless $self->userCanRemove;

        my $epoch = $req->param('epoch')
          or return $self->p->sendError( $req,
            $self->prefix . '2f: "epoch" parameter is missing', 400 );
        if ( $self->del2fDevice( $req, $req->userData, $self->type, $epoch ) ) {
            return [
                200,
                [
                    'Content-Type'   => 'application/json',
                    'Content-Length' => 12,
                ],
                ['{"result":1}']
            ];
        }
        $self->logger->error( $self->prefix . '2f: device not found' );
        return $self->p->sendError( $req, '2FDeviceNotFound', 400 );
    }

    else {
        $self->logger->error( $self->prefix . "2f: unknown action ($action)" );
        return $self->p->sendError( $req, 'unknownAction', 400 );
    }
}

sub loadUser {
    my ( $self, $req ) = @_;
    my ( $kh, $uk, @crypters );

    # Read existing 2FDevices
    my @u2fs = $self->find2fDevicesByType( $req, $req->userData, $self->type );

    # Manage multi u2f keys
    if (@u2fs) {
        foreach (@u2fs) {
            $kh = $_->{_keyHandle};
            $uk = $_->{_userKey};
            my $c = $self->crypter( keyHandle => $kh, publicKey => $uk );
            if ($c) {
                $self->logger->debug("kh & uk -> OK");
                push @crypters, $c;
            }
            else {
                $self->logger->error(
                    'U2F error: ' . Crypt::U2F::Server::u2fclib_getError() );
            }
        }
        return -1 unless @crypters;

        $req->data->{crypter} = \@crypters;
        return 1;
    }
    else {
        $self->userLogger->info( $self->prefix . '2f: user not registered' );
        return 0;
    }
}

1;
