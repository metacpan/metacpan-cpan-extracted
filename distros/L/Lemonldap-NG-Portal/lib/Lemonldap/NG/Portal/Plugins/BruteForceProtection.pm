package Lemonldap::NG::Portal::Plugins::BruteForceProtection;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_WAIT);

our $VERSION = '2.0.1';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INITIALIZATION

use constant afterData => 'run';

sub init {
    my ($self) = @_;
    unless ( $self->conf->{loginHistoryEnabled} ) {
        $self->logger->error(
            '"History" plugin is required for "BruteForceProtection" plugin');
        return 0;
    }
    return 1;
}

# RUNNING METHOD

sub run {
    my ( $self, $req ) = @_;

    my $MaxAge               = $self->conf->{bruteForceProtectionMaxAge} + 1;
    my $countFailed          = 0;
    my @lastFailedLoginEpoch = ();

    # Auth_N-2 failed login epoch
    if ( defined $req->sessionInfo->{_loginHistory}->{failedLogin} ) {
        $countFailed = @{ $req->sessionInfo->{_loginHistory}->{failedLogin} };
    }

    $self->logger->debug(" Number of failedLogin = $countFailed");
    return PE_OK
      if ( $countFailed <= $self->conf->{bruteForceProtectionMaxFailed} );

    foreach ( 0 .. $self->conf->{bruteForceProtectionMaxFailed} - 1 ) {
        if ( defined $req->sessionInfo->{_loginHistory}->{failedLogin}->[$_] ) {
            push @lastFailedLoginEpoch,
              $req->sessionInfo->{_loginHistory}->{failedLogin}->[$_]->{_utime};
        }
    }
    $self->logger->debug("BruteForceProtection enabled");

    # If Auth_N-MaxFailed older than MaxAge -> another try allowed
    $MaxAge =
      $lastFailedLoginEpoch[0] -
      $lastFailedLoginEpoch[ $self->conf->{bruteForceProtectionMaxFailed} - 1 ]
      if $self->conf->{bruteForceProtectionMaxFailed};
    $self->logger->debug(" -> MaxAge = $MaxAge");
    return PE_OK
      if ( $MaxAge > $self->conf->{bruteForceProtectionMaxAge} );

    # Delta between the two last failed logins -> Auth_N - Auth_N-1
    my $delta = 0;
    $delta = time - $lastFailedLoginEpoch[1]
      if defined $lastFailedLoginEpoch[1];
    $self->logger->debug(" -> Delta = $delta");

    # Delta between the two last failed logins < Tempo => wait
    return PE_OK
      unless ( $delta <= $self->conf->{bruteForceProtectionTempo} );

    # Account locked
    return PE_WAIT;
}

1;
