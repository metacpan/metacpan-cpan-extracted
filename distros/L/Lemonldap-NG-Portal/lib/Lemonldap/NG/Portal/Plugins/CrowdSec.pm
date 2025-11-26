package Lemonldap::NG::Portal::Plugins::CrowdSec;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_SESSIONNOTGRANTED
);

our $VERSION = '2.22.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';
with 'Lemonldap::NG::Portal::Lib::CrowdSec';

# Entrypoint
use constant beforeAuth => 'checkIpStatus';

has rule => ( is => 'rw', default => sub { 0 } );

sub init {
    my ($self) = @_;
    $self->_init or return 0;

    # Parse activation rule
    unless ( $self->conf->{crowdsecKey} ) {
        $self->logger->error('Missing Crowdsec Bouncer key');
        return 0;
    }
    $self->logger->info(
        'CrowdSec policy is: ' . ( $self->conf->{crowdsecAction} || 'warn' ) );
    $self->rule( $self->p->buildRule( $self->conf->{crowdsec}, 'crowdsec' ) );
    return 1;
}

sub checkIpStatus {
    my ( $self, $req ) = @_;
    if ( !$self->rule->( $req, $req->sessionInfo ) ) {
        $self->logger->debug('Crowdsec disabled for this env');
        return PE_OK;
    }
    my $ip = $req->address;
    my ( $ok, $err ) = $self->bouncer($ip);

    # bouncer() answer $ok=0 only when Crowdsec response rejects the given IP
    return PE_OK if ( $ok and $err and $self->conf->{crowdsecIgnoreFailures} );

    # When $ok==0, $err contains the Crowdsec decision
    unless ($ok) {
        if ( $self->conf->{crowdsecAction} eq 'reject' ) {
            $self->auditLog(
                $req,
                code    => 403,
                message => $err,
                ip      => $ip,
            );
            return PE_SESSIONNOTGRANTED;
        }
        else {
            $self->auditLog(
                $req,
                code    => 200,
                message => "$err (ignored)",
                ip      => $ip,
            );
            $req->env->{CROWDSEC_REJECT} = 1;
            return PE_OK;
        }
    }
    return $err ? $err : PE_OK;
}

1;
