# Self TOTP registration
package Lemonldap::NG::Portal::2F::Register::TOTP;

use strict;
use Mouse;
use JSON qw(from_json to_json);

our $VERSION = '2.0.8';

extends 'Lemonldap::NG::Portal::Main::Plugin', 'Lemonldap::NG::Common::TOTP';

# INITIALIZATION

has prefix => ( is => 'rw', default => 'totp' );

has template => ( is => 'ro', default => 'totp2fregister' );

has logo => ( is => 'rw', default => 'totp.png' );

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->conf->{formTimeout} );
        return $ott;
    }
);

sub init {
    return 1;
}

sub run {
    my ( $self, $req, $action ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };
    unless ($user) {
        return $self->p->sendError( $req,
            'No ' . $self->conf->{whatToTrace} . ' found in user data', 500 );
    }

    # Verification that user has a valid TOTP app
    if ( $action eq 'verify' ) {

        # Get form token
        my $token = $req->param('token');
        unless ($token) {
            $self->userLogger->warn(
                "TOTP registration: register try without token for $user");
            return $self->p->sendError( $req, 'noTOTPFound', 400 );
        }

        # Verify that token exists in DB (note that "keep" flag is set to
        # permit more than 1 try during token life
        unless ( $token = $self->ott->getToken( $token, 1 ) ) {
            $self->userLogger->notice(
                "TOTP registration: token expired for $user");
            return $self->p->sendError( $req, 'PE82', 400 );
        }

        # Token is valid, so we have the master key proposed
        # ($token->{_totp2fSecret})

        # Now check TOTP code to verify that user has a valid TOTP app
        my $code     = $req->param('code');
        my $TOTPName = $req->param('TOTPName');
        my $epoch    = time();

     # Set default name if empty, check characters and truncate name if too long
        $TOTPName ||= $epoch;
        unless ( $TOTPName =~ /^[\w]+$/ ) {
            $self->userLogger->error('TOTP name with bad character(s)');
            return $self->p->sendError( $req, 'badName', 200 );
        }
        $TOTPName =
          substr( $TOTPName, 0, $self->conf->{max2FDevicesNameLength} );
        $self->logger->debug("TOTP name : $TOTPName");

        unless ($code) {
            $self->userLogger->info('TOTP registration: empty validation form');
            return $self->p->sendError( $req, 'missingCode', 200 );
        }

        my $r = $self->verifyCode(
            $self->conf->{totp2fInterval},
            $self->conf->{totp2fRange},
            $self->conf->{totp2fDigits},
            $token->{_totp2fSecret}, $code
        );
        if ( $r == -1 ) {
            return $self->p->sendError( $req, 'serverError', 500 );
        }

        # Invalid try is returned with a 200 code. Javascript will read error
        # and propose to retry
        elsif ( $r == 0 ) {
            $self->userLogger->notice(
                "TOTP registration: invalid TOTP for $user");
            return $self->p->sendError( $req, 'badCode', 200 );
        }
        $self->logger->debug('TOTP code verified');

        # Now code is verified, let's store the master key in persistent data

        my $secret = '';

        # Reading existing 2FDevices
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

        # Reading existing TOTP
        my @totp2f = grep { $_->{type} eq "TOTP" } @$_2fDevices;
        unless (@totp2f) {
            $self->logger->debug("No TOTP Device found");

            # Set default value
            push @totp2f, { _secret => '' };
        }

        # Loading TOTP secret
        $self->logger->debug("Reading TOTP secret if exists ...");
        $secret = $_->{_secret} foreach (@totp2f);

        if ( $token->{_totp2fSecret} eq $secret ) {
            return $self->p->sendError( $req, 'totpExistingKey', 200 );
        }

        ### USER CAN ONLY REGISTER ONE TOTP ###
        # Delete TOTP previously registered
        my @keep = ();
        while (@$_2fDevices) {
            my $element = shift @$_2fDevices;
            $self->logger->debug("Looking for TOTP to delete ...");
            push @keep, $element unless ( $element->{type} eq "TOTP" );
        }

        # Check if user can register one more device
        my $size    = @keep;
        my $maxSize = $self->conf->{max2FDevices};
        $self->logger->debug("Nbr 2FDevices = $size / $maxSize");
        if ( $size >= $maxSize ) {
            $self->userLogger->warn("Max number of 2F devices is reached");
            return $self->p->sendError( $req, 'maxNumberof2FDevicesReached',
                400 );
        }

        # Store TOTP secret
        push @keep,
          {
            type    => 'TOTP',
            name    => $TOTPName,
            _secret => $token->{_totp2fSecret},
            epoch   => $epoch
          };

        $self->logger->debug(
            "Append 2F Device : { type => 'TOTP', name => $TOTPName }");
        $self->p->updatePersistentSession( $req,
            { _2fDevices => to_json( \@keep ) } );
        $self->userLogger->notice(
            "TOTP registration of $TOTPName succeeds for $user");
        return [
            200,
            [ 'Content-Type' => 'application/json', 'Content-Length' => 12, ],
            ['{"result":1}']
        ];
    }

    # Get or generate master key
    elsif ( $action eq 'getkey' ) {
        my $nk     = 0;
        my $secret = '';

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

        # Looking for TOTP
        my @totp2f = grep { $_->{type} eq "TOTP" } @$_2fDevices;
        unless (@totp2f) {
            $self->logger->debug("No TOTP found");

            # Set default value
            push @totp2f, { _secret => '' };
        }

        # Loading TOTP secret
        $self->logger->debug("Reading TOTP secret if exists ...");
        $secret = $_->{_secret} foreach (@totp2f);

        if ( ( $req->param('newkey') and $self->conf->{totp2fUserCanChangeKey} )
            or not $secret )
        {
            $secret = $self->newSecret;
            $self->logger->debug("Generating new secret = $secret");
            $nk = 1;
        }

        elsif ( $req->param('newkey') ) {
            return $self->p->sendError( $req, 'notAuthorized', 200 );
        }

        elsif ( $self->conf->{totp2fDisplayExistingSecret} ) {
            $self->logger->debug("User secret = $secret");
        }

        else {
            return $self->p->sendError( $req, 'totpExistingKey', 200 );
        }

        # Secret is stored in a token: we choose to not accept secret returned
        # by Ajax request to avoid some attacks
        my $token = $self->ott->createToken( {
                _totp2fSecret => $secret,
            }
        );

        my $issuer;
        unless ( $issuer = $self->conf->{totp2fIssuer} ) {
            $issuer = $self->conf->{portal};
            $issuer =~ s#^https?://([^/:]+).*$#$1#;
        }

        # QR-code will be generated by a javascript, here we just send data
        return $self->p->sendJSONresponse(
            $req,
            {
                secret   => $secret,
                token    => $token,
                portal   => $issuer,
                user     => $user,
                newkey   => $nk,
                digits   => $self->conf->{totp2fDigits},
                interval => $self->conf->{totp2fInterval}
            }
        );
    }

    # Delete TOTP
    elsif ( $action eq 'delete' ) {

        # Check if unregistration is allowed
        return $self->p->sendError( $req, 'notAuthorized', 400 )
          unless $self->conf->{totp2fUserCanRemoveKey};

        my $epoch = $req->param('epoch')
          or return $self->p->sendError( $req, '"epoch" parameter is missing',
            400 );

        # Read existing 2FDevices
        $self->logger->debug("Loading 2F Devices ...");
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

        # Delete TOTP 2F device
        my $TOTPName;
        foreach (@$_2fDevices) {
            $TOTPName = $_->{name} if $_->{epoch} eq $epoch;
        }
        @$_2fDevices = grep { $_->{epoch} ne $epoch } @$_2fDevices;
        $self->logger->debug(
"Delete 2F Device : { type => 'TOTP', epoch => $epoch, name => $TOTPName }"
        );
        $self->p->updatePersistentSession( $req,
            { _2fDevices => to_json($_2fDevices) } );
        $self->userLogger->notice(
            "TOTP $TOTPName unregistration succeeds for $user");
        return [
            200,
            [ 'Content-Type' => 'application/json', 'Content-Length' => 12, ],
            ['{"result":1}']
        ];
    }
    else {
        $self->logger->error("Unknown TOTP action -> $action");
        return $self->p->sendError( $req, 'unknownAction', 400 );
    }
}

1;
