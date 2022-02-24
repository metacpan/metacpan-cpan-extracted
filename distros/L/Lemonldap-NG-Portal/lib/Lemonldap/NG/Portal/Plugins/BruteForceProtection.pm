package Lemonldap::NG::Portal::Plugins::BruteForceProtection;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_WAIT
);

our $VERSION = '2.0.14';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INITIALIZATION
use constant afterSub => { setPersistentSessionInfo => 'run' };

has lockTimes => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] }
);
has maxAge => (
    is  => 'rw',
    isa => 'Int'
);
has maxFailed => (
    is  => 'rw',
    isa => 'Int'
);

sub init {
    my ($self) = @_;
    $self->maxFailed( abs $self->conf->{bruteForceProtectionMaxFailed} );

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

    unless ( $self->conf->{failedLoginNumber} >= $self->maxFailed ) {
        $self->logger->error( 'Number of failed logins history ('
              . $self->conf->{failedLoginNumber}
              . ') must be higher than allowed failed logins attempt ('
              . $self->maxFailed
              . ')' );
        return 0;
    }

    my $maxAge = $self->conf->{bruteForceProtectionMaxAge} || 300;
    if ( $self->conf->{bruteForceProtectionIncrementalTempo} ) {
        my $lockTimes = @{ $self->lockTimes } =
          sort { $a <=> $b }
          map {
            $_ =~ s/\D//;
            abs $_ < $self->conf->{bruteForceProtectionMaxLockTime}
              ? abs $_
              : ()
          }
          grep /\d+/,
          split /\s*,\s*/, $self->conf->{bruteForceProtectionLockTimes};

        unless ($lockTimes) {
            @{ $self->lockTimes } = ( 15, 30, 60, 300, 600 );
            $lockTimes = 5;
        }

        for ( my $i = 1 ; $i < $self->maxFailed ; $i++ ) {
            unshift @{ $self->lockTimes }, 0;
            $lockTimes++;
        }

        unless ( $lockTimes <= $self->conf->{failedLoginNumber} ) {
            $self->logger->warn( 'Number failed logins history ('
                  . $self->conf->{failedLoginNumber}
                  . ') must be higher than incremental lock time values plus allowed failed logins attempt ('
                  . "$lockTimes)" );
            splice @{ $self->lockTimes }, $self->conf->{failedLoginNumber};
            $lockTimes = $self->conf->{failedLoginNumber};
        }

        my $sum =
          $maxAge * ( 1 + $self->conf->{failedLoginNumber} - $lockTimes );
        $sum += $_ foreach @{ $self->lockTimes };
        $self->maxAge($sum);
    }
    else {
        $self->maxAge( $maxAge * ( 1 + $self->maxFailed ) );
    }

    return 1;
}

# RUNNING METHOD
sub run {
    my ( $self, $req ) = @_;
    my $now         = time;
    my $countFailed = my @failedLogins =
      map { ( $now - $_->{_utime} ) <= $self->maxAge ? $_ : () }
      @{ $req->sessionInfo->{_loginHistory}->{failedLogin} };
    $self->logger->debug( ' -> Failed login maxAge = ' . $self->maxAge );
    $self->logger->debug(
        "Number of failed login(s) to take into account = $countFailed");
    my $lastFailedLoginEpoch = $failedLogins[0]->{_utime} || undef;

    if ( $self->conf->{bruteForceProtectionIncrementalTempo} ) {
        return PE_OK unless $lastFailedLoginEpoch;

        # Delta between current attempt and last failed login
        my $delta = $now - $lastFailedLoginEpoch;
        $self->logger->debug(" -> Delta = $delta");

        # Time to wait
        my $waitingTime = $self->lockTimes->[ $countFailed - 1 ]
          // $self->conf->{bruteForceProtectionMaxLockTime};

        # Reach last tempo. Stop to increase waiting time
        if ( $countFailed >= scalar @{ $self->lockTimes } ) {
            $self->userLogger->warn(
                "BruteForceProtection: Last lock time has been reached");
            $self->logger->debug("Force waitingTime to last value");
            $waitingTime =
              $self->lockTimes->[ scalar @{ $self->lockTimes } - 1 ];
        }
        $self->logger->debug(" -> Waiting time = $waitingTime");

        # Delta < waitingTime => wait
        if ( $waitingTime && $delta < $waitingTime ) {
            $self->userLogger->warn("BruteForceProtection enabled");
            $req->authResult(PE_WAIT);

            # Do not store failed login if last tempo or max tempo is reached
            $self->p->registerLogin( $req, $req->{user} )
              if ( $waitingTime < $self->conf->{bruteForceProtectionMaxLockTime}
                && $waitingTime <
                $self->lockTimes->[ scalar @{ $self->lockTimes } - 1 ] );
            $req->lockTime( $waitingTime - $delta );
            return PE_WAIT;
        }
        return PE_OK;
    }

    return PE_OK
      if ( $countFailed < $self->maxFailed );

    # Delta between current attempt and last failed login
    my $delta = $lastFailedLoginEpoch ? $now - $lastFailedLoginEpoch : 0;
    $self->logger->debug(" -> Delta = $delta");

    # Delta < Tempo => wait
    return PE_OK
      unless ( $delta < $self->conf->{bruteForceProtectionTempo}
        && $countFailed );

    # Account locked
    $self->userLogger->warn("BruteForceProtection enabled");
    $self->logger->debug(
        " -> Waiting time = $self->{conf}->{bruteForceProtectionTempo}");
    $req->lockTime( $self->conf->{bruteForceProtectionTempo} - $delta );
    return PE_WAIT;
}

1;
