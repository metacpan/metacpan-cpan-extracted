package Lemonldap::NG::Portal::Plugins::CheckEntropy;

use strict;
use warnings;
use Mouse;
use Lemonldap::NG::Common::UserAgent;
use MIME::Base64;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_PP_INSUFFICIENT_PASSWORD_QUALITY
);

our $VERSION = '2.19.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

has entropyRequired => (
    is  => 'rw',
    isa => 'Bool',
);

has entropyRequiredLevel => (
    is  => 'rw',
    isa => 'Int',
);

use constant hook => { passwordBeforeChange => 'checkEntropy', };

sub init {
    my ($self) = @_;
    $self->logger->debug('checkEntropy: initialization');

    eval { use Data::Password::zxcvbn qw(password_strength); };
    if ($@) {
        $self->logger->error("Can't load zxcvbn library: $@");
        $self->error("Can't load zxcvbn library: $@");
        return 0;
    }

    # check checkEntropyRequired param
    if ( exists $self->conf->{checkEntropyRequired} ) {
        $self->entropyRequired( $self->conf->{checkEntropyRequired} );

        # check checkEntropyRequiredLevel param
        if ( exists $self->conf->{checkEntropyRequiredLevel} ) {
            $self->entropyRequiredLevel(
                $self->conf->{checkEntropyRequiredLevel} );
        }
        else {
# If entropy is required to pass, then checkEntropyRequiredLevel is required too, this is an error
            if ( $self->entropyRequired ) {
                $self->logger->error(
                    'checkEntropy: missing checkEntropyRequiredLevel parameter'
                );
                return 0;
            }
            else {
                $self->logger->warn(
'checkEntropy: missing checkEntropyRequiredLevel parameter, but entropy is not required to pass. Set checkEntropyRequiredLevel to 0'
                );
                $self->entropyRequiredLevel(0);
            }
        }

    }
    else {
        $self->logger->error(
            'checkEntropy: missing checkEntropyRequired parameter');
        return 0;
    }

    # Declare REST route
    $self->addUnauthRoute(
        checkentropy => '_checkEntropyJSON',
        ['POST']
    );
    $self->addAuthRoute(
        checkentropy => '_checkEntropyJSON',
        ['POST']
    );

    $self->p->addPasswordPolicyDisplay(
        'ppolicy-checkentropy',
        {
            condition => $self->conf->{checkEntropy},
            label     => "checkentropyLabel",
            data      => {
                "CHECKENTROPY_REQUIRED"       => $self->entropyRequired,
                "CHECKENTROPY_REQUIRED_LEVEL" => $self->entropyRequiredLevel,
            },
            customHtml =>
qq'<script type="text/javascript" src="$self->{p}->{staticPrefix}/common/js/entropy.min.js"></script>\n
<link rel="stylesheet" type="text/css" href="$self->{p}->{staticPrefix}/common/css/entropy.min.css">',
            customHtmlAfter =>
qq'<div id="entropybar" class="progress">\n
    <div class="progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"></div>\n
</div>\n
<div id="entropybar-msg" class="alert alert-warning entropyHidden"></div>',
            order => 202,
        }
    );

    return 1;
}

# Check user password against zxcvbn library
# Method called before the password change, blocking if the password is compromised
sub checkEntropy {
    my ( $self, $req, $user, $password, $old ) = @_;

    if ( $self->entropyRequired ) {
        my $entropy =
          $self->_checkEntropy( $req, $password, $self->entropyRequired );
        if (    $entropy->{level}
            and $entropy->{level} >= $self->entropyRequiredLevel )
        {
            return PE_OK;
        }
        else {
            $self->userLogger->warn( "checkEntropy: insufficient entropy: "
                  . "level = "
                  . $entropy->{level}
                  . " but minimal required = "
                  . $self->entropyRequiredLevel );
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
    }
    else {
 # Do not verify new password if checkEntropyRequired parameter has not been set
        return PE_OK;
    }
}

# Check user password against zxcvbn library
# Input : request, new user base64-encoded password 
# Output: JSON response: { "level" => int, "message" => "msg" }
sub _checkEntropyJSON {
    my ( $self, $req, $pass ) = @_;
    my $response_params = {};
    my $password;

    # use password value submitted in form
    # this happens when frontend is testing a new password while user is typing
    my $password_base64 = $req->param('password');
    $self->logger->debug( 'checkEntropy: password taken from submitted form');

    unless ($password_base64) {
        $response_params->{"level"}   = -1;
        $response_params->{"message"} = "missing parameter password";

        $self->userLogger->warn("checkEntropy: missing parameter password");

        return $self->sendJSONresponse( $req, $response_params );
    }
    $password = decode_base64($password_base64);

    my $entropy = password_strength($password);

    $response_params->{"level"} = $entropy->{score};
    $response_params->{"message"} =
      $entropy->{feedback}->{warning} ? $entropy->{feedback}->{warning} : "";

    $self->userLogger->debug( "checkEntropy: level "
          . $response_params->{"level"}
          . " msg: "
          . $response_params->{"message"} );

    return $self->sendJSONresponse( $req, $response_params );
}

# Check user password against zxcvbn library
# Input : request, new user password
# Output: hash response: { "level" => int, "message" => "msg" }
sub _checkEntropy {
    my ( $self, $req, $pass ) = @_;
    my $response_params = {};

    # Password already given, so take it directly
    # this happens at backend side, when really changing the password
    $self->logger->debug( 'checkEntropy: password taken directly');

    my $entropy = password_strength($pass);

    $response_params->{"level"} = $entropy->{score};
    $response_params->{"message"} =
      $entropy->{feedback}->{warning} ? $entropy->{feedback}->{warning} : "";

    $self->userLogger->debug( "checkEntropy: level "
          . $response_params->{"level"}
          . " msg: "
          . $response_params->{"message"} );

    return $response_params;
}

1;
