package Lemonldap::NG::Portal::Plugins::InitializePasswordReset;

use Mouse;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_USERNOTFOUND
  PE_BADCREDENTIALS
);
extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::SMTP
);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
);

our $VERSION = '2.19.0';

# API secret key
has initializePasswordResetSecret => ( is => 'rw' );

# INITIALIZATION

sub init {
    my ($self) = @_;

    # Declare REST route
    $self->addUnauthRoute(
        initializepasswordreset => 'initializePasswordReset',
        [ 'POST', 'GET' ]
    );

    # Get secret parameter
    unless ( $self->conf->{initializePasswordResetSecret} ) {
        $self->logger->error(
"InitializePasswordReset: missing initializePasswordResetSecret parameter"
        );
        return 0;
    }
    $self->initializePasswordResetSecret(
        $self->conf->{initializePasswordResetSecret} );

    return 1;
}

# Handle reset requests
sub initializePasswordReset {
    my ( $self, $req ) = @_;

    my $response_params;
    my $mail_session_id;

    # Get json infos
    my $infos = $req->jsonBodyToObj
      or return $self->p->sendError( $req, undef, 400 );

    my $mail   = $infos->{'mail'};
    my $secret = $infos->{'secret'};

    unless ( $mail and $secret ) {
        $self->logger->error("InitializePasswordReset: missing parameter");
        $response_params->{msg} = "InitializePasswordReset: missing parameter";
        return $self->sendJSONresponse( $req, $response_params, "code" => 400 );
    }

    unless ( "$secret" eq $self->initializePasswordResetSecret ) {
        $self->logger->error("InitializePasswordReset: authentication error");
        $response_params->{msg} =
          "InitializePasswordReset: authentication error";
        return $self->sendJSONresponse( $req, $response_params, "code" => 403 );
    }

    $self->logger->info(
        "InitializePasswordReset: initialize password reset for $mail");

    my $mailPasswordReset = $self->p->loadedModules->{
        'Lemonldap::NG::Portal::Plugins::MailPasswordReset'};
    $req->{user} = $mail;

    if ( $mailPasswordReset->searchUser( $req, 1 ) == PE_OK ) {

        my $mailSession = $mailPasswordReset->getMailSession( $req->{user} );

        unless ($mailSession) {
            $mailSession = $mailPasswordReset->createMailSession($req);
        }

        my $mail_session_id = $mailSession->id;

        $response_params->{"mail_token"} = $mail_session_id;
        $response_params->{"url"}        = $self->p->buildUrl(
            $self->p->passwordResetUrl,
            { mail_token => $mail_session_id }
        );

        return $self->sendJSONresponse( $req, $response_params );
    }
    else {
        $response_params->{msg} =
          "InitializePasswordReset: user $mail not found";
        return $self->sendJSONresponse( $req, $response_params, "code" => 404 );
    }
}

1;
