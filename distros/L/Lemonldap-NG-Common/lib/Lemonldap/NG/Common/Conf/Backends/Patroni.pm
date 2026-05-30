package Lemonldap::NG::Common::Conf::Backends::Patroni;

use strict;
use Lemonldap::NG::Common::Conf::Backends::_DBI;
use Lemonldap::NG::Common::Conf::Backends::CDBI;
our @ISA = ('Lemonldap::NG::Common::Conf::Backends::CDBI');

*store = \&Lemonldap::NG::Common::Conf::Backends::CDBI::store;
*load  = \&Lemonldap::NG::Common::Conf::Backends::CDBI::load;

sub beforeRetry {
    my ($self) = @_;
    require Lemonldap::NG::Common::UserAgent;
    require JSON;
    my $ua = Lemonldap::NG::Common::UserAgent->new($self);
    $ua->timeout( $self->{patroniTimeout} || 3 );
    my $res = 0;

    # Circuit breaker: avoid hammering Patroni API if it's failing
    my $circuitBreakerDelay = $self->{patroniCircuitBreakerDelay} || 30;
    my $skipApiQuery =
      ( $self->{patroniLastFailure}
          && time() - $self->{patroniLastFailure} < $circuitBreakerDelay );

    # Try to query Patroni API (unless circuit breaker is active)
    # URLs are queried in order - put preferred (local) endpoints first
    if ( !$skipApiQuery ) {
        foreach my $patroniUrl ( split /,\s*/, $self->{patroniUrl} ) {
            my $resp = $ua->get($patroniUrl);
            if ( $resp->is_success ) {
                my $c = eval { JSON::from_json( $resp->decoded_content ) };
                if ( $@ or !$c->{members} or ref( $c->{members} ) ne 'ARRAY' ) {
                    print STDERR "Bad response from $patroniUrl: "
                      . $resp->decoded_content . "\n";
                    next;
                }
                my @leaders =
                  grep { $_->{role} eq 'leader' } @{ $c->{members} };

                # Check for split-brain scenario
                if ( @leaders > 1 ) {
                    my $leadersList =
                      join( ', ', map { "$_->{host}:$_->{port}" } @leaders );
                    print STDERR
"Multiple leaders detected (split-brain) from $patroniUrl - Leaders: $leadersList\n";
                    next;
                }

                my ($leader) = @leaders;
                unless ($leader) {
                    print STDERR "No leader found from $patroniUrl: "
                      . $resp->decoded_content . "\n";
                    next;
                }
                unless ( $leader->{host} && $leader->{port} ) {
                    print STDERR
                      "Leader missing host or port from $patroniUrl: "
                      . $resp->decoded_content . "\n";
                    next;
                }

                # Check leader health state
                if ( $leader->{state} && $leader->{state} ne 'running' ) {
                    print STDERR
"Leader not in running state (state=$leader->{state}) from $patroniUrl\n";
                    next;
                }

                # Cache the leader info
                $self->{patroniLastLeader} = {
                    host => $leader->{host},
                    port => $leader->{port},
                    time => time()
                };

                delete $self->{_dbh};
                _updateDbiChain( $self, $leader->{host}, $leader->{port} );

                # Reset circuit breaker on success
                delete $self->{patroniLastFailure};

                $res = 1;
                last;
            }
        }

        # Record failure for circuit breaker
        if ( !$res ) {
            $self->{patroniLastFailure} = time();
        }
    }

    # Fallback to cached leader if available and not too old
    if ( !$res && $self->{patroniLastLeader} ) {
        my $cacheTtl = $self->{patroniCacheTTL} || 60;
        my $age      = time() - $self->{patroniLastLeader}->{time};
        if ( $age < $cacheTtl ) {
            print STDERR
              "Patroni API unavailable, using cached leader (${age}s old)\n";
            delete $self->{_dbh};
            _updateDbiChain(
                $self,
                $self->{patroniLastLeader}->{host},
                $self->{patroniLastLeader}->{port}
            );
            $res = 1;
        }
    }

    return $res;
}

# Update dbiChain with new host and port
sub _updateDbiChain {
    my ( $self, $host, $port ) = @_;

    # Remove existing host/port parameters more robustly
    my $chain = $self->{dbiChain};

   # Remove host=... and port=... (handles both ;-separated and space-separated)
    $chain =~ s/;\s*host=[^;]+//gi;
    $chain =~ s/;\s*port=[^;]+//gi;
    $chain =~ s/\s+host=[^\s;]+//gi;
    $chain =~ s/\s+port=[^\s;]+//gi;

    # Clean up trailing semicolons
    $chain =~ s/;+$//;

    # Add new host and port
    my $separator = ( $chain =~ /:$/ ) ? '' : ';';
    $self->{dbiChain} = "${chain}${separator}host=$host;port=$port";

    return 1;
}

1;
