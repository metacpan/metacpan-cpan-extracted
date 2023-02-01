package Lemonldap::NG::Portal::Plugins::CheckHIBP;

use strict;
use warnings;
use Mouse;
use Digest::SHA qw( sha1_hex );
use Lemonldap::NG::Common::UserAgent;
use MIME::Base64;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_PP_INSUFFICIENT_PASSWORD_QUALITY
);

our $VERSION = '2.0.15.1';

extends 'Lemonldap::NG::Portal::Main::Plugin';

has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->env_proxy();
        return $ua;
    }
);

has apiURL => (
    is  => 'rw',
    isa => 'Str',
);

has hibpRequired => (
    is  => 'rw',
    isa => 'Bool',
);

use constant hook => { passwordBeforeChange => 'checkHIBP', };

sub init {
    my ($self) = @_;
    $self->logger->debug('checkHIBP: initialization');

    if ( $self->conf->{checkHIBPURL} ) {
        $self->apiURL( $self->conf->{checkHIBPURL} );
    }
    else {
        $self->logger->error('checkHIBP: missing checkHIBPURL parameter');
        return 0;
    }

    if ( exists $self->conf->{checkHIBPRequired} ) {
        $self->hibpRequired( $self->conf->{checkHIBPRequired} );
    }
    else {
        $self->logger->error('checkHIBP: missing checkHIBPRequired parameter');
        return 0;
    }

    # Declare REST route
    $self->addUnauthRoute(
        checkhibp => '_checkHIBP',
        ['GET']
    );
    $self->addAuthRoute(
        checkhibp => '_checkHIBP',
        ['GET']
    );

    return 1;
}

# Check user password against an URL listing compromised passwords
# Method called before the password change, blocking if the password is compromised
sub checkHIBP {
    my ( $self, $req, $user, $password, $old ) = @_;

    if ( $self->hibpRequired ) {
        my $res = &_checkHIBP( $self, $req, $password, $self->hibpRequired );
        if ( $res->{code} == 0 ) {
            return PE_OK;
        }
        else {
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
    }
    else {
     # don't verify new password if checkHIBPRequired parameter has not been set
        return PE_OK;
    }
}

# Check user password against an URL listing compromised passwords
# Input : new user password, flag noJSONResponse
# Output: JSON response, including a code.
# code = 0 = success
# code > 0 = error
sub _checkHIBP {
    my ( $self, $req, $pass, $noJSONResponse ) = @_;

    my $response_params = {};

    my $password;

    # password already given, so take it directly
    if ($pass) {
        $password = $pass;
    }
    else {
        # use password value submitted in form
        my $password_base64 = $req->param('password');

        unless ($password_base64) {
            $response_params->{"code"}    = 1;
            $response_params->{"message"} = "missing parameter password";
            return $noJSONResponse
              ? $response_params
              : $self->sendJSONresponse( $req, $response_params );
        }
        $password = decode_base64($password_base64);
    }

    my $digestFull = sha1_hex($password);   # compute sha1 hash of new password
    my $digestPrefix = substr $digestFull, 0,
      5;    # take only 5 first characters of the hash

    # Prepare connection to blacklist URL
    my $reqAPI;
    $reqAPI = HTTP::Request->new( "GET", $self->apiURL . $digestPrefix );
    $reqAPI->header( 'Content-type' => 'text/html' );
    $reqAPI->header( 'User-Agent'   => 'libwww-perl/6.05 (LemonLDAPNG)' );

    my $response = $self->ua->request($reqAPI);

    my $debugstr =
        'checkHIBP: requesting ['
      . $reqAPI->as_string . '] : '
      . $response->status_line;

    $self->logger->debug($debugstr);

    my $digest;
    if ( $response->is_success || $response->is_info ) {

        # Parse compromised keys
        foreach ( split( /[\r\n]/, $response->content ) ) {

            # Exclude empty lines
            if ( $_ ne "" ) {
                $digest = lc("$digestPrefix$_");
                $self->logger->debug(
"checkHIBP: Check if new password matches compromised password $digest"
                );
                if ( $digest =~ /$digestFull/i ) {
                    my ( $dig, $num ) = split( /:/, $digest );
                    $self->userLogger->warn(
                        "checkHIBP: password $dig compromised $num times");

                    $response_params->{"code"} = 2;
                    $response_params->{"message"} =
                      "password $dig compromised $num times";
                    return $noJSONResponse
                      ? $response_params
                      : $self->sendJSONresponse( $req, $response_params );
                }
            }

        }

    }
    else {
        $self->logger->error(
            "checkHIBP: error while requesting " . $self->apiURL );
        $self->logger->error( "checkHIBP: " . $response->status_line );

        $response_params->{"code"} = 1;
        $response_params->{"message"} =
          "error while requesting " . $self->apiURL;
        return $noJSONResponse
          ? $response_params
          : $self->sendJSONresponse( $req, $response_params );
    }

    $self->logger->info("checkHIBP: password $digestFull is not compromised");

    $response_params->{"code"}    = 0;
    $response_params->{"message"} = "password $digestFull not compromised";
    return $noJSONResponse
      ? $response_params
      : $self->sendJSONresponse( $req, $response_params );
}

1;
