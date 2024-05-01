package Lemonldap::NG::Manager::2ndFA;

use strict;
use utf8;
use Mouse;

use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::PSGI::Constants;
use Lemonldap::NG::Common::Conf::ReConstants;

extends qw(
  Lemonldap::NG::Manager::Plugin
  Lemonldap::NG::Common::Session::REST
  Lemonldap::NG::Common::Conf::AccessLib
);

our $VERSION = '2.18.0';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => '2ndfa.html';
use constant icon         => 'wrench';

sub init {
    my ( $self, $conf ) = @_;

    # Remote Procedure are defined in Lemonldap::NG::Common::Session::REST
    # HTML template
    $self->addRoute( '2ndfa.html', 'sfaView', ['GET'] )

      ->addRoute(
        sfa => { ':sessionType' => 'sfa' },
        ['GET']
      )

      # DELETE 2FA DEVICE
      ->addRoute(
        sfa => { ':sessionType' => { ':sessionId' => 'del2F' } },
        ['DELETE']
      );

    $self->setTypes($conf);
    $self->{multiValuesSeparator} ||= '; ';
    $self->{hiddenAttributes} //= "_password";
    $self->{hiddenAttributes} .= ' _session_id'
      unless $conf->{displaySessionId};

    $self->{regSfaTypes} = [ (
            sort map { s/^Yubikey$/UBK/r } split /[\s,]+/,
            $conf->{available2FSelfRegistration}
        ),
        keys %{ $conf->{sfExtra} || {} },
    ];
    return 1;
}

###################
# II. 2FA METHODS #
###################

sub del2F {

    my ( $self, $req, $session, $skey ) = @_;

    my $mod = $self->getMod($req)
      or return $self->sendError( $req, 'Bad mode', 400 );

    my $params = $req->parameters();
    my $type   = $params->{type}
      or return $self->sendError( $req, 'Missing "type" parameter', 400 );
    my $epoch = $params->{epoch}
      or return $self->sendError( $req, 'Missing "epoch" parameter', 400 );

    $self->logger->debug(
        "Call procedure delete2F with type=$type and epoch=$epoch");
    return $self->delete2F( $req, $session, $skey );
}

########################
# III. DISPLAY METHODS #
########################

sub sfa {
    my ( $self, $req, $session, $skey ) = @_;

    my $mod = $self->getMod($req)
      or return $self->sendError( $req, 'Bad mode', 400 );

    $self->logger->debug("Call procedure get2F");
    return $self->get2F( $req, $session, $skey );
}

sub sfaView {
    my ( $self, $req ) = @_;
    return $self->p->sendHtml(
        $req, "2ndfa",
        params => {
            SFATYPES => [ map { { SFATYPE => $_ } } @{ $self->{regSfaTypes} } ],
        }
    );
}

1;
