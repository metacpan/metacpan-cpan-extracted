package Lemonldap::NG::Portal::Plugins::BruteForceProtection;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_WAIT);

our $VERSION = '2.0.8';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INITIALIZATION
use constant afterSub => { storeHistory => 'run' };

has lockTimes => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] }
);

has maxAge => (
    is  => 'rw',
    isa => 'Int'
);

sub init {
    my ($self) = @_;
    if ( $self->conf->{disablePersistentStorage} ) {
        $self->logger->error(
'"BruteForceProtection" plugin enabled WITHOUT persistent session storage"'
        );
        return 0;
    }
    unless ( $self->conf->{loginHistoryEnabled} ) {
        $self->logger->error(
            '"BruteForceProtection" plugin enabled WITHOUT "History" plugin');
        return 0;
    }
    unless ( $self->conf->{failedLoginNumber} >
        $self->conf->{bruteForceProtectionMaxFailed} )
    {
        $self->logger->error( 'failedLoginNumber('
              . $self->conf->{failedLoginNumber}
              . ') must be higher than bruteForceProtectionMaxFailed('
              . $self->conf->{bruteForceProtectionMaxFailed}
              . ')' );
        return 0;
    }
    if ( $self->conf->{bruteForceProtectionIncrementalTempo} ) {
        my $lockTimes = @{ $self->lockTimes } =
          sort { $a <=> $b }
          map { $_ < $self->conf->{bruteForceProtectionMaxLockTime} ? $_ : () }
          grep { /\d+/ }
          split /\s+/, $self->conf->{bruteForceProtectionLockTimes};

        unless ($lockTimes) {
            @{ $self->lockTimes } = ( 5, 15, 60, 300, 600 );
            $lockTimes = 5;
        }
        
        if ( $lockTimes > $self->conf->{failedLoginNumber} ) {
            $self->logger->warn( 'Number of incremental lock time values ('
                  . "$lockTimes) is higher than failed logins history ("
                  . $self->conf->{failedLoginNumber}
                  . ')' );
            splice @{ $self->lockTimes }, $self->conf->{failedLoginNumber};
            $lockTimes = $self->conf->{failedLoginNumber};
        }

        my $sum = $self->conf->{bruteForceProtectionMaxAge} * ( 1 + $self->conf->{failedLoginNumber} - $lockTimes );
        $sum += $_ foreach @{ $self->lockTimes };
        $self->maxAge($sum);
    }
    else {
        $self->maxAge( $self->conf->{bruteForceProtectionMaxAge} );
    }
    return 1;
}

# RUNNING METHOD
sub run {
    my ( $self, $req ) = @_;
    my $now         = time;
    my $countFailed = my @failedLogins =
      map { ( $now - $_->{_utime} ) < $self->maxAge ? $_ : () }
      @{ $req->sessionInfo->{_loginHistory}->{failedLogin} };
    $self->logger->debug( ' Failed login maxAge = ' . $self->maxAge );
    $self->logger->debug(
        " Number of failed login(s) to take into account = $countFailed");

    if ( $self->conf->{bruteForceProtectionIncrementalTempo} ) {
        my $lastFailedLoginEpoch = $failedLogins[0]->{_utime} || undef;

        return PE_OK unless $lastFailedLoginEpoch;

        my $delta = $now - $lastFailedLoginEpoch;
        $self->logger->debug(" -> Delta = $delta");
        my $waitingTime = $self->lockTimes->[ $countFailed - 1 ]
          || $self->conf->{bruteForceProtectionMaxLockTime};
        $self->logger->debug(" -> Waiting time = $waitingTime");
        unless ( $delta > $waitingTime ) {
            $self->logger->debug("BruteForceProtection enabled");
            $req->lockTime($waitingTime);
            return PE_WAIT;
        }
        return PE_OK;
    }

    return PE_OK
      if ( $countFailed <= $self->conf->{bruteForceProtectionMaxFailed} );

    my @lastFailedLoginEpoch = ();
    my $MaxAge               = $self->maxAge + 1;

    # Auth_N-2 failed login epoch
    foreach ( 0 .. $self->conf->{bruteForceProtectionMaxFailed} - 1 ) {
        push @lastFailedLoginEpoch,
          $req->sessionInfo->{_loginHistory}->{failedLogin}->[$_]->{_utime}
          if ( $req->sessionInfo->{_loginHistory}->{failedLogin}->[$_] );
    }

    # If Auth_N-MaxFailed older than MaxAge -> another try allowed
    $MaxAge =
      $lastFailedLoginEpoch[0] -
      $lastFailedLoginEpoch[ $self->conf->{bruteForceProtectionMaxFailed} - 1 ]
      if $self->conf->{bruteForceProtectionMaxFailed};
    $self->logger->debug(" -> MaxAge = $MaxAge");

    return PE_OK
      if ( $MaxAge > $self->maxAge );

    # Delta between the two last failed logins -> Auth_N - Auth_N-1
    my $delta =
      defined $lastFailedLoginEpoch[1] ? $now - $lastFailedLoginEpoch[1] : 0;
    $self->logger->debug(" -> Delta = $delta");

    # Delta between the two last failed logins < Tempo => wait
    return PE_OK
      unless ( $delta <= $self->conf->{bruteForceProtectionTempo} );

    # Account locked
    $self->logger->debug("BruteForceProtection enabled");
    $req->lockTime( $self->conf->{bruteForceProtectionTempo} );
    return PE_WAIT;
}

1;
