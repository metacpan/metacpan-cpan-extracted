# Self U2F registration
package Lemonldap::NG::Portal::2F::Register::U2F;

use strict;
use Mouse;
use JSON qw(from_json to_json);

our $VERSION = '2.0.4';

extends 'Lemonldap::NG::Portal::Main::Plugin',
  'Lemonldap::NG::Portal::Lib::U2F';

# INITIALIZATION

has prefix => ( is => 'rw', default => 'u' );

has template => ( is => 'ro', default => 'u2fregister' );

has logo => ( is => 'rw', default => 'u2f.png' );

sub init {
    my ($self) = @_;
    return 0 unless $self->SUPER::init;
    return 1;
}

# RUNNING METHODS

# Main method
sub run {
    my ( $self, $req, $action ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };
    unless ($user) {
        return $self->p->sendError( $req,
            'No ' . $self->conf->{whatToTrace} . ' found in user data', 500 );
    }

    if ( $action eq 'register' ) {

        # Read existing 2FDevices
        $self->logger->debug("Looking for 2F Devices ...");
        my $_2fDevices;
        if ( $req->userData->{_2fDevices} ) {
            $_2fDevices = eval {
                from_json( $req->userData->{_2fDevices},
                    { allow_nonref => 1 } );
            };
            if ($@) {
                $self->logger->error("Corrupted session (_2fDevices): $@");
                return $self->p->sendError( $req, "Corrupted session", 500 );
            }
        }

        else {
            $self->logger->debug("No 2F Device found");
            $_2fDevices = [];
        }

        # Check if user can register one more 2F device
        my $size    = @$_2fDevices;
        my $maxSize = $self->conf->{max2FDevices};
        $self->logger->debug("Registered 2F Device(s) : $size / $maxSize");
        if ( $size >= $maxSize ) {
            $self->userLogger->error("Max number of 2F devices is reached !!!");
            return $self->p->sendError( $req, 'maxNumberof2FDevicesReached',
                400 );
        }

        my $challenge = $self->crypter->registrationChallenge;
        $self->logger->debug("Register challenge: $challenge");
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
        $self->logger->debug('Registration response');
        unless ($resp = $req->param('registration')
            and $challenge = $req->param('challenge') )
        {
            return $self->p->sendError( $req, 'Missing registration parameter',
                400 );
        }
        $self->logger->debug("Get registration data $resp");
        $self->logger->debug("Get challenge $challenge");
        eval { $challenge = from_json($challenge)->{challenge} };
        if ($@) {
            $self->userLogger->error("Bad challenge: $@");
            return $self->p->sendError( $req, 'Bad challenge', 400 );
        }
        my $c = $self->crypter;
        if ( $c->setChallenge($challenge) ) {
            my ( $keyHandle, $userKey ) = $c->registrationVerify($resp);
            if ( $keyHandle and $userKey ) {

                # Read existing 2FDevices
                $self->logger->debug("Looking for 2F Devices ...");
                my $_2fDevices;
                if ( $req->userData->{_2fDevices} ) {
                    $_2fDevices = eval {
                        from_json(
                            $req->userData->{_2fDevices},
                            { allow_nonref => 1 }
                        );
                    };
                    if ($@) {
                        $self->logger->error(
                            "Corrupted session (_2fDevices): $@");
                        return $self->p->sendError( $req, "Corrupted session",
                            500 );
                    }
                }

                else {
                    $self->logger->debug("No 2F Device found");
                    $_2fDevices = [];
                }

                my $keyName = $req->param('keyName');
                my $epoch   = time();

     # Set default name if empty, check characters and truncate name if too long
                $keyName ||= $epoch;
                unless ( $keyName =~ /^[\w]+$/ ) {
                    $self->userLogger->error('U2F name with bad character(s)');
                    return $self->p->sendError( $req, 'badName', 200 );
                }
                $keyName =
                  substr( $keyName, 0, $self->conf->{max2FDevicesNameLength} );
                $self->logger->debug("Key name : $keyName");

                push @{$_2fDevices},
                  {
                    type       => 'U2F',
                    name       => $keyName,
                    _userKey   => $self->encode_base64url( $userKey, '' ),
                    _keyHandle => $keyHandle,
                    epoch      => $epoch
                  };
                $self->logger->debug(
                    "Append 2F Device : { type => 'U2F', name => $keyName }");
                $self->p->updatePersistentSession( $req,
                    { _2fDevices => to_json($_2fDevices) } );
                $self->userLogger->notice(
                    "U2F key registration of $keyName succeeds for $user");

                return [
                    200,
                    [
                        'Content-Type'   => 'application/json',
                        'Content-Length' => 12,
                    ],
                    ['{"result":1}']
                ];
            }
        }
        my $err = Crypt::U2F::Server::Simple::lastError();
        $self->userLogger->warn("U2F Registration failed: $err");
        return $self->p->sendError( $req, $err, 200 );
    }

    elsif ( $action eq 'verify' ) {
        $self->logger->debug('Verification challenge req');
        my ( $err, $error ) = $self->loadUser($req);
        if ( $err == -1 ) {
            return $self->p->sendError( $req, "U2F error: $error", 200 );
        }
        elsif ( $err == 0 ) {
            return $self->p->sendError( $req, "noU2FKeyFound" );
        }

        # Get a challenge (from first key)
        my $data = eval {
            from_json( $req->data->{crypter}->[0]->authenticationChallenge );
        };

        if ($@) {
            $self->logger->error( Crypt::U2F::Server::u2fclib_getError() );
            return $self->p->sendError( $req, "U2F error: $error", 200 );
        }

        # Get registered keys
        my @rk;
        foreach ( @{ $req->data->{crypter} } ) {
            my $k = push @rk,
              { keyHandle => $_->{keyHandle}, version => $data->{version} };
        }

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
        $self->logger->debug('Verification response');
        my ( $challenge, $resp );
        unless ($challenge = $req->param('challenge')
            and $resp = $req->param('signature') )
        {
            return $self->p->sendError( $req, 'Missing signature parameter',
                400 );
        }
        my ( $err, $error ) = $self->loadUser($req);
        if ( $err == -1 ) {
            return $self->p->sendError( $req, "U2F loading error: $error",
                500 );
        }
        elsif ( $err == 0 ) {
            return $self->p->sendError( $req, "noU2FKeyFound" );
        }

        $self->logger->debug("Get verify response $resp");
        my $data = eval { JSON::from_json($resp) };
        if ($@) {
            $self->logger->error("U2F response error: $@");
            return $self->p->sendError( $req, "U2FAnswerError" );
        }
        my $crypter;
        foreach ( @{ $req->data->{crypter} } ) {
            $crypter = $_ if ( $_->{keyHandle} eq $data->{keyHandle} );
        }
        unless ($crypter) {
            $self->userLogger->error("Unregistered U2F key");
            return $self->p->sendError( $req, "U2FKeyUnregistered" );
        }

        if ( not $crypter->setChallenge($challenge) ) {
            $self->logger->error(
                $@ ? $@ : Crypt::U2F::Server::Simple::lastError() );

            return $self->p->sendError( $req, "U2FServerError" );
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
        unless ( $self->conf->{u2fUserCanRemoveKey} ) {
            return $self->p->sendError( $req, 'notAuthorized', 200 );
        }

        my $epoch = $req->param('epoch')
          or return $self->p->sendError( $req, '"epoch" parameter is missing',
            400 );

        # Read existing 2FDevices
        $self->logger->debug("Looking for 2F Devices ...");
        my $_2fDevices;
        if ( $req->userData->{_2fDevices} ) {
            $_2fDevices = eval {
                from_json( $req->userData->{_2fDevices},
                    { allow_nonref => 1 } );
            };
            if ($@) {
                $self->logger->error("Corrupted session (_2fDevices): $@");
                return $self->p->sendError( $req, "Corrupted session", 500 );
            }
        }
        else {
            $self->logger->debug("No 2F Device found");
            $_2fDevices = [];
        }

        # Delete U2F device
        @$_2fDevices = grep { $_->{epoch} ne $epoch } @$_2fDevices;
        $self->logger->debug(
            "Delete 2F Device : { type => 'U2F', epoch => $epoch }");
        $self->p->updatePersistentSession( $req,
            { _2fDevices => to_json($_2fDevices) } );
        $self->userLogger->notice('U2F key unregistration succeed');
        return [
            200,
            [ 'Content-Type' => 'application/json', 'Content-Length' => 12, ],
            ['{"result":1}']
        ];
    }
    else {
        $self->logger->error("Unknown U2F action -> $action");
        return $self->p->sendError( $req, 'unknownAction', 400 );
    }

}

sub loadUser {
    my ( $self, $req ) = @_;
    $self->logger->debug("Loading user U2F Devices ...");

    # Read existing 2FDevices
    $self->logger->debug("Looking for 2F Devices ...");
    my ( $kh, $uk, $_2fDevices );
    my @u2fs = ();

    if ( $req->userData->{_2fDevices} ) {
        $_2fDevices = eval {
            from_json( $req->userData->{_2fDevices}, { allow_nonref => 1 } );
        };
        if ($@) {
            $self->logger->error("Corrupted session (_2fDevices): $@");
            return $self->p->sendError( $req, "Corrupted session", 500 );
        }
    }
    else {
        $self->logger->debug("No 2F Device found");
        $_2fDevices = [];
    }

    # Reading existing U2F keys
    foreach (@$_2fDevices) {
        $self->logger->debug("Looking for registered U2F key(s) ...");
        if ( $_->{type} eq 'U2F' ) {
            unless ( $_->{_userKey} and $_->{_keyHandle} ) {
                $self->logger->error(
'Missing required U2F attributes in storage ($session->{_2fDevices})'
                );
                next;
            }
            $self->logger->debug( "Found U2F key -> _userKey = "
                  . $_->{_userKey}
                  . "/ _keyHandle = "
                  . $_->{_keyHandle} );
            $_->{_userKey} = $self->decode_base64url( $_->{_userKey} );
            push @u2fs, $_;
        }
    }

    # Manage multi u2f keys
    my @crypters;
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
        unless (@crypters) {
            return -1;
        }
        $req->data->{crypter} = \@crypters;
        return 1;
    }
    else {
        $self->userLogger->info("U2F : user not registered");
        return 0;
    }
}

1;
