package Lemonldap::NG::Portal::Plugins::CrowdSecAgent;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCERTIFICATE
  PE_BADCREDENTIALS
  PE_BADOTP
  PE_CAPTCHAERROR
  PE_MALFORMEDUSER
  PE_OK
  PE_OPENID_BADID
  PE_SAML_SIGNATURE_ERROR
  PE_SENDRESPONSE
  PE_USERNOTFOUND
);

our $VERSION = '2.22.0';

our @ALERTS = (
    PE_USERNOTFOUND,         PE_BADCREDENTIALS,
    PE_BADCERTIFICATE,       PE_MALFORMEDUSER,
    PE_SAML_SIGNATURE_ERROR, PE_OPENID_BADID,
    PE_CAPTCHAERROR,         PE_BADOTP,
);

extends 'Lemonldap::NG::Portal::Main::Plugin';
with 'Lemonldap::NG::Portal::Lib::CrowdSec';

has rule => ( is => 'rw', default => sub { 0 } );

has filters => ( is => 'rw', default => sub { {} } );

# Entrypoint
use constant aroundSub => {

    # Filter function (if crowdsecFilters is set)
    controlUrl => 'controlUrl',

    # Generate alerts for bad credentials
    getUser      => 'sendIpAlerts',
    authenticate => 'sendIpAlerts'
};

sub init {
    my ($self) = @_;
    $self->_init or return 0;
    unless ($self->conf->{crowdsecMachineId}
        and $self->conf->{crowdsecPassword} )
    {
        $self->logger->error(
            'Crowdsec report enabled without machine_id and password');
        return 0;
    }
    $self->rule(
        $self->p->buildRule( $self->conf->{crowdsecAgent}, 'crowdsecAgent' ) );

    if ( $self->conf->{crowdsecFilters} ) {
        if ( -d $self->conf->{crowdsecFilters} ) {
            with 'Lemonldap::NG::Portal::Lib::CrowdSecFilter';
            $self->initializeFilters;
        }
        else {
            $self->logger->error(
                'Crowdsec filter directory not found, ignoring');
        }
    }
    $self->conf->{crowdSecAgentResponseCode} ||= 404;

    return 1;
}

sub sendIpAlerts {
    my ( $self, $sub, $req ) = @_;
    my $ret = $sub->($req);

    if ( !$self->rule->( $req, $req->sessionInfo ) ) {
        $self->logger->debug('Crowdsec-agent disabled for this env');
        return $ret;
    }

    # Nothing to do if config doesn't allow alerts or if auth is OK
    unless ( grep { $_ == $ret } @ALERTS ) {
        $self->logger->debug(
            "Crowdsec-Agent: not an authentication error: code $ret");
        return $ret;
    }
    my $msg = 'Authentication failed: '
      . &Lemonldap::NG::Portal::Main::Constants::portalConsts->{$ret};
    $self->alert( $req->address, $msg,
        { scenario => 'llng/badcredentials', reason => $msg, } )
      ? $self->auditLog(
        $req,
        code    => 200,
        message => "Alert sent to Crowdsec: $msg",
        ip      => $req->address
      )
      : $self->logger->error(
        "Unable to send alert to Crowdsec (was '$msg' for " . $req->address );
    return $ret;
}

sub controlUrl {
    my ( $self, $sub, $req ) = @_;
    my $ret = $sub->($req);
    return $ret if $ret;

    if ( !$self->rule->( $req, $req->sessionInfo ) ) {
        $self->logger->debug('Crowdsec-agent disabled for this env');
        return $ret;
    }

    return $ret unless $self->filters;
    if (    $self->filters->{url}
        and $req->env->{REQUEST_URI} =~ $self->filters->{url} )
    {
        my $msg = 'Bad URI detected: ' . $req->env->{REQUEST_URI};
        $self->alert( $req->address, $msg,
            { scenario => 'llng/urlscan', reason => $msg, } )
          ? $self->auditLog(
            $req,
            code         => 200,
            message      => "Alert sent to Crowdsec: $msg",
            ip           => $req->address,
            uri          => $req->env->{REQUEST_URI},
            matchingPart => $&,
          )
          : $self->logger->error(
            "Unable to send alert to Crowdsec (was '$msg' for "
              . $req->address );

        $req->response(

        # Case "redirection", crowdSecAgentResponseValue is the "location" value
            $self->conf->{crowdSecAgentResponseCode} =~ /^3/
            ? $self->p->sendRawHtml(
                $req,
                $self->conf->{crowdSecAgentResponseValue},
                {
                    code    => $self->conf->{crowdSecAgentResponseCode},
                    headers => [
                        Location => (
                            $self->conf->{crowdSecAgentResponseValue}
                              || 'https://somewhere.else'
                        )
                    ],
                }
              )

            # Case "custom response
            : $self->conf->{crowdSecAgentResponseValue}
            ? $self->p->sendRawHtml(
                $req,
                $self->conf->{crowdSecAgentResponseValue},
                { code => $self->conf->{crowdSecAgentResponseCode} }
              )

            # Case "default Lemon response
            : $self->sendError(
                $req, '', $self->conf->{crowdSecAgentResponseCode}
            )
        );
        return PE_SENDRESPONSE;
    }
    return $ret;
}

1;
