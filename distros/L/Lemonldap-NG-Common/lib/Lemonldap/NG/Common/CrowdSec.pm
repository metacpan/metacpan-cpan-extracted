package Lemonldap::NG::Common::CrowdSec;

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

our $VERSION = '2.22.0';

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
    my $max   = $self->conf->{crowdsecMaxFailures};
    my $count = $self->getAlertsByIp($ip) || 0;
    $data->{remediation} =
      ( $max and $count >= ( $max - 1 ) and $notBanned )
      ? JSON::true
      : JSON::false;
    $self->logger->debug("Crowdsec alerts count is $count for $ip");
    $data->{reason} ||= 'Reported by LLNG';
    $msg ||= 'Reported by LLNG';
    return $self->ban( $ip, $msg, $data );
}

sub getAlertsByIp {
    my ( $self, $ip, $scenario ) = @_;
    $scenario ||= $defaultBanValues->{scenario};
    if ( my $token = $self->getToken ) {
        my $url     = $self->crowdsecUrl . '/v1/alerts';
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
            return;
        }
        my $alerts = eval { from_json( $resp->decoded_content ) };
        if ( $@ or !$alerts ) {
            $self->logger->error( join ' ', 'Unable to read Crowdsec response:',
                $@, $resp->decoded_content );
            return;
        }
        my $timeLimit = time - ( $self->conf->{crowdsecBlockDelay} || 180 );
        my @ipAlerts =
          grep {
                  $_->{source}->{value} eq $ip
              and $_->{scenario} eq $scenario
              and str2time( $_->{start_at} ) > $timeLimit
          } @$alerts;
        return ( scalar @ipAlerts );
    }
    else {
        $self->logger->error('Unable to push Crowdsec decision');
        return;
    }
}

sub _banPayload {
    my ( $self, $ip, $msg, $data ) = @_;
    $msg ||= 'Banned by LLNG Crowdsec plugin';
    foreach my $k ( keys %$defaultBanValues ) {
        $data->{$k} //= $defaultBanValues->{$k};
    }
    my $timestamp = strftime( "%Y-%m-%dT%H:%M:%SZ", gmtime );
    $data->{start_at} ||= $timestamp;
    $data->{stop_at}  ||= $timestamp;
    $data->{source}   ||= { scope => 'ip', value => $ip };
    my $reason = delete( $data->{reason} ) || 'Banned by LLNG';
    $data->{scenario_hash} = sha256_hex( $data->{scenario} );
    return to_json( [ {
                %$data,
                message => $msg,
                events  => [ {
                        timestamp => $data->{start_at},
                        meta      => [
                            { key => 'log_type', value => 'llng-auth' },
                            { key => 'reason',   value => $reason }
                        ],
                        source => $data->{source},
                    }
                ],
            }
        ]
    );
}

sub getToken {
    my ($self) = @_;

    # Use token if available
    return $self->token if $self->token and $self->tokenExp < time - 10;

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
