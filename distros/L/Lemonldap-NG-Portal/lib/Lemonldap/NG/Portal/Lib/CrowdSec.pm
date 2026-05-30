package Lemonldap::NG::Portal::Lib::CrowdSec;

use strict;
use Date::Parse;
use Digest::SHA qw(sha256_hex);
use JSON        qw(from_json to_json);
use Mouse::Role;
use POSIX qw(strftime);
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_SESSIONNOTGRANTED
);

our $VERSION = '2.23.0';

our $defaultBanValues = {
    events_count     => 1,
    scenario         => 'llng',
    scenario_version => $VERSION,
    leakspeed        => '1s',
    remediation      => JSON::true,
    simulated        => JSON::false,
    capacity         => 1,
};

has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->agent( 'LLNG-CrowdsecAgent/' . $VERSION );
        $ua->default_headers->header( 'Accept'       => 'application/json' );
        $ua->default_headers->header( 'Content-Type' => 'application/json' );
        return $ua;
    }
);

has token    => ( is => 'rw' );
has tokenExp => ( is => 'rw', default => 0 );

has crowdsecUrl => ( is => 'rw' );

sub _init {
    my ($self) = @_;
    if ( $self->conf->{crowdsecUrl} ) {
        my $tmp = $self->conf->{crowdsecUrl};
        $tmp =~ s#/+$##;
        $self->crowdsecUrl($tmp);
    }
    else {
        $self->logger->warn(
            "crowdsecUrl isn't set, fallback to http://localhost:8080");
        $self->crowdsecUrl('http://localhost:8080');
    }
    return 1;
}

sub bouncer {
    my ( $self, $ip ) = @_;
    my $resp = $self->ua->get(
        $self->crowdsecUrl . "/v1/decisions?ip=$ip",
        'Accept'    => 'application/json',
        'X-Api-Key' => $self->conf->{crowdsecKey},
    );
    if ( $resp->is_error ) {
        $self->logger->error( 'Bad CrowdSec response: ' . $resp->message );
        $self->logger->debug( $resp->content );
        return ( 1, PE_ERROR );
    }
    my $content = $resp->decoded_content;
    if ( !$content or $content eq 'null' ) {
        $self->userLogger->debug("$ip isn't known by CrowdSec");
        return ( 1, PE_OK );
    }
    my $json_hash;
    eval { $json_hash = from_json( $content, { allow_nonref => 1 } ); };
    if ($@) {
        $self->logger->error("Unable to decode CrowdSec response: $content");
        $self->logger->debug($@);
        return ( 1, PE_ERROR );
    }
    $self->logger->debug("CrowdSec response: $content");

    # Response is "null" when IP is unknown
    if ($json_hash) {

        # CrowdSec may return more than one decision
        foreach my $decision (@$json_hash) {
            if ( $decision->{type} and $decision->{type} eq 'ban' ) {
                return ( 0,
                        "$ip banned by CrowdSec ('"
                      . $decision->{scenario}
                      . "' for $decision->{duration})" );
            }
        }
        $self->userLogger->info("$ip not banned by CrowdSec");
        return ( 1, PE_OK );
    }
}

sub ban {
    my $self = shift;
    my ( $ip, $msg, $data ) = @_;
    if ( my $token = $self->getToken ) {
        my $request = HTTP::Request->new(
            POST => $self->crowdsecUrl . '/v1/alerts',
            [
                'Content-Type'  => 'application/json',
                'Authorization' => "Bearer " . $self->token,
            ],
            $self->_banPayload(@_)
        );
        my $resp = $self->ua->request($request);
        unless ( $resp->is_success ) {
            $self->logger->error(
                join ' ',           'Unable to push alert',
                $resp->status_line, $resp->decoded_content
            );
            return;
        }
        $self->logger->notice("Push new Crowdsec alert for $ip: $msg");
        return 1;
    }
    else {
        $self->logger->error('Unable to push Crowdsec decision');
        return;
    }
}

sub alert {
    my $self = shift;
    my ( $ip, $msg, $data ) = @_;

    # No new ban decision for already banned IPs
    my ($notBanned) = $self->bouncer($ip);

    $data ||= {};

    # Use per-scenario maxFailures if provided, otherwise use global config
    my $max = $data->{maxFailures} // $self->conf->{crowdsecMaxFailures};

    # Get both count and previous alerts for enrichment
    my @prevAlerts =
      $self->getAlertsByIp( $ip, $data->{scenario}, $data->{timeWindow} );

    $data->{remediation} =
      ( $max and @prevAlerts >= ( $max - 1 ) and $notBanned )
      ? JSON::true
      : JSON::false;
    $self->logger->debug(
        "Crowdsec alerts count is " . scalar(@prevAlerts) . " for $ip" );
    $data->{reason} ||= 'Reported by LLNG';
    $msg ||= 'Reported by LLNG';

  # Pass previous alerts for enrichment when ban decision is made
  # Only include alerts that contributed to the decision (max - 1), capped at 30
    if ( $data->{remediation} and @prevAlerts ) {
        my $limit = ( $max && $max > 1 ) ? $max - 1 : 30;
        $limit = 30 if $limit > 30;
        if ( @prevAlerts > $limit ) {

            # Take most recent alerts (sorted by start_at desc)
            my @sorted =
              sort { ( $b->{start_at} || '' ) cmp( $a->{start_at} || '' ) }
              @prevAlerts;
            $data->{_prevAlerts} = [ @sorted[ 0 .. $limit - 1 ] ];
        }
        else {
            $data->{_prevAlerts} = \@prevAlerts;
        }
    }

    return $self->ban( $ip, $msg, $data );
}

# Extract context from previous alerts for enrichment
sub _extractAlertContext {
    my ( $self, $prevAlerts ) = @_;
    return unless $prevAlerts and @$prevAlerts;

    my ( @logins, @uris, @timestamps );
    my ( %seen_logins, %seen_uris );

    foreach my $alert (@$prevAlerts) {

        # Extract timestamp
        push @timestamps, $alert->{start_at} if $alert->{start_at};

        # Extract login and uri from events meta
        if ( $alert->{events} and @{ $alert->{events} } ) {
            foreach my $event ( @{ $alert->{events} } ) {
                if ( $event->{meta} and @{ $event->{meta} } ) {
                    foreach my $m ( @{ $event->{meta} } ) {
                        if (    $m->{key} eq 'login'
                            and $m->{value}
                            and !$seen_logins{ $m->{value} }++ )
                        {
                            push @logins, $m->{value};
                        }
                        if (    $m->{key} eq 'uri'
                            and $m->{value}
                            and !$seen_uris{ $m->{value} }++ )
                        {
                            push @uris, $m->{value};
                        }
                    }
                }
            }
        }
    }

    # Sort timestamps chronologically
    @timestamps = sort @timestamps if @timestamps;

    return {
        logins      => \@logins,
        uris        => \@uris,
        first_alert => $timestamps[0],
        last_alert  => $timestamps[-1],
        count       => scalar @$prevAlerts,
    };
}

sub getAlertsByIp {
    my ( $self, $ip, $scenario, $timeWindow ) = @_;
    $scenario ||= $defaultBanValues->{scenario};
    if ( my $token = $self->getToken ) {

        # Use API filters to avoid default 50 alerts limit
        my $url =
            $self->crowdsecUrl
          . '/v1/alerts?scope=ip&value='
          . $ip
          . '&scenario='
          . $scenario;
        my $request = HTTP::Request->new(
            GET => $url,
            [
                'Authorization' => "Bearer " . $self->token,
            ],
        );
        my $resp = $self->ua->request($request);
        unless ( $resp->is_success ) {
            $self->logger->error(
                join ' ',           'Unable to get alerts',
                $resp->status_line, $resp->decoded_content
            );
            return ();
        }
        my $content = $resp->decoded_content;

        # CrowdSec returns "null" when there are no alerts
        if ( !$content or $content eq 'null' ) {
            $self->logger->debug("No alerts found for $ip");
            return ();
        }
        my $alerts = eval { from_json($content) };
        if ($@) {
            $self->logger->error( join ' ', 'Unable to read Crowdsec response:',
                $@, ", $content" );
            return ();
        }

        # Use per-scenario timeWindow if provided, otherwise use global config
        # Default: 900 seconds (15 minutes)
        my $delay     = $timeWindow // $self->conf->{crowdsecBlockDelay} // 900;
        my $timeLimit = time - $delay;

        # API already filters by IP and scenario, just filter by time
        my @ipAlerts =
          grep { str2time( $_->{start_at} ) > $timeLimit } @$alerts;

        # In list context, return both count and alerts for enrichment
        return @ipAlerts;
    }
    else {
        $self->logger->error('Unable to query Crowdsec');
        return ();
    }
}

sub _banPayload {
    my ( $self, $ip, $msg, $data ) = @_;
    $msg  ||= 'Banned by LLNG Crowdsec plugin';
    $data ||= {};

    # Extract and remove internal data
    my $prevAlerts = delete $data->{_prevAlerts};

    foreach my $k ( keys %$defaultBanValues ) {
        $data->{$k} //= $defaultBanValues->{$k};
    }
    my $timestamp = strftime( "%Y-%m-%dT%H:%M:%SZ", gmtime );
    $data->{start_at} ||= $timestamp;
    $data->{stop_at}  ||= $timestamp;
    $data->{source}   ||= { scope => 'ip', value => $ip };
    my $reason = delete( $data->{reason} ) || 'Banned by LLNG';
    my $login  = delete( $data->{login} );
    my $uri    = delete( $data->{uri} );

    # Include login in message for CAPI transmission
    # (events[].meta is NOT forwarded by LAPI to CAPI)
    $msg .= " (login: $login)" if $login;

    $data->{scenario_hash} = sha256_hex( $data->{scenario} );
    my @meta = (
        { key => 'log_type', value => 'llng-auth' },
        { key => 'reason',   value => $reason }
    );
    push @meta, { key => 'login', value => $login } if $login;
    push @meta, { key => 'uri',   value => $uri }   if $uri;

    # Enrich with historical context when ban decision is made
    if ( $data->{remediation} and $prevAlerts ) {
        my $context = $self->_extractAlertContext($prevAlerts);
        if ($context) {
            my @msg_parts;

            # Add historical metadata
            if ( @{ $context->{logins} } ) {
                my $all_logins = join ', ', @{ $context->{logins} };
                push @meta, { key => 'previous_logins', value => $all_logins };

                # Truncate for message display
                my $login_summary =
                  @{ $context->{logins} } <= 3
                  ? $all_logins
                  : join( ', ', @{ $context->{logins} }[ 0 .. 2 ] ) . '...';
                push @msg_parts, "attempted logins: $login_summary";
            }

            if ( @{ $context->{uris} } ) {
                my $all_uris = join ', ', @{ $context->{uris} };
                push @meta, { key => 'previous_uris', value => $all_uris };

                # Truncate for message display
                my $uri_summary =
                  @{ $context->{uris} } <= 3
                  ? $all_uris
                  : join( ', ', @{ $context->{uris} }[ 0 .. 2 ] ) . '...';
                push @msg_parts, "scanned URIs: $uri_summary";
            }

            if ( $context->{count} ) {
                push @meta,
                  {
                    key   => 'previous_alert_count',
                    value => "" . $context->{count}
                  };
            }

            if ( $context->{first_alert} ) {
                push @meta,
                  { key => 'first_alert', value => $context->{first_alert} };
            }

            if ( $context->{last_alert} ) {
                push @meta,
                  { key => 'last_alert', value => $context->{last_alert} };
            }

            # Enrich human-readable message
            if ( $context->{count} ) {
                $msg .= sprintf "; after %d previous alert(s)",
                  $context->{count};
            }
            if (@msg_parts) {
                $msg .= "; " . join( "; ", @msg_parts );
            }
        }
    }

    my $alert = {
        %$data,
        message => $msg,
        events  => [ {
                timestamp => $data->{start_at},
                meta      => \@meta,
                source    => $data->{source},
            }
        ],
    };

    # Add decisions array when remediation is requested
    # This ensures the IP is immediately banned by CrowdSec
    if ( $data->{remediation} ) {
        my $duration =
          $data->{banDuration} || $self->conf->{crowdsecBanDuration} || '4h';
        $alert->{decisions} = [ {
                duration => $duration,
                type     => 'ban',
                scope    => 'ip',
                value    => $ip,
                origin   => 'llng',
                scenario => $data->{scenario},
            }
        ];
    }

    return to_json( [$alert] );
}

sub getToken {
    my ($self) = @_;

    # Use token if available
    return $self->token if $self->token and $self->tokenExp > time + 10;

    # Get new token
    my ( $user, $pwd ) =
      map { $self->conf->{$_} } qw(crowdsecMachineId crowdsecPassword);
    unless ( $user and $pwd ) {
        $self->logger->error('Missing crowdsec credentials, aborting');
        return;
    }
    my $request = HTTP::Request->new(
        POST => $self->crowdsecUrl . '/v1/watchers/login',
        [ 'Content-Type' => 'application/json' ],
        to_json( {
                machine_id => $user,
                password   => $pwd,
            }
        )
    );
    my $resp = $self->ua->request($request);
    unless ( $resp->is_success ) {
        $self->logger->error( join ' ', 'Unable to connect to Crowdsec:',
            $resp->status_line, $resp->decoded_content );
        return;
    }
    my $json = eval { from_json( $resp->decoded_content ) };
    if ( $@ or !$json ) {
        $self->logger->error( join ' ', 'Unable to read Crowdsec response:',
            $@, $resp->decoded_content );
        return;
    }
    $self->tokenExp( str2time( $json->{expire} ) );
    $self->logger->debug("Get Crowdsec token");
    return $self->token( $json->{token} );
}

1;
