package Lemonldap::NG::Portal::Plugins::CrowdSec;

use strict;
use Mouse;
use JSON qw(from_json);
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_SESSIONNOTGRANTED
);

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# Entrypoint
use constant beforeAuth => 'check';

has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {

        # TODO : LWP options to use a proxy for example
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->env_proxy();
        return $ua;
    }
);
has crowdsecUrl => ( is => 'rw' );

sub init {
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
    $self->logger->notice( 'CrowdSec policy is: '
          . ( $self->conf->{crowdsecAction} ? 'reject' : 'warn' ) );
    return 1;
}

sub check {
    my ( $self, $req ) = @_;
    my $ip   = $req->address;
    my $resp = $self->ua->get(
        $self->crowdsecUrl . "/v1/decisions?ip=$ip",
        'Accept'    => 'application/json',
        'X-Api-Key' => $self->conf->{crowdsecKey},
    );
    if ( $resp->is_error ) {
        $self->logger->error( 'Bad CrowdSec response: ' . $resp->message );
        $self->logger->debug( $resp->content );
        return PE_ERROR;
    }
    my $content = $resp->decoded_content;
    if ( !$content or $content eq 'null' ) {
        $self->userLogger->info("$ip isn't known by CrowsSec");
        return PE_OK;
    }
    my $json_hash;
    eval { $json_hash = from_json( $content, { allow_nonref => 1 } ); };
    if ($@) {
        $self->logger->error("Unable to decode CrowdSec response: $content");
        $self->logger->debug($@);
        return PE_ERROR;
    }
    $self->logger->debug("CrowdSec response: $content");

    # Response is "null" when IP is unknown
    if ($json_hash) {

        # CrowdSec may return more than one decision
        foreach my $decision (@$json_hash) {
            if ( $decision->{type} and $decision->{type} eq 'ban' ) {
                $self->userLogger->warn( "$ip banned by CrowdSec ('"
                      . $decision->{scenario}
                      . "' for $decision->{duration})" );
                if ( $self->conf->{crowdsecAction} eq 'reject' ) {
                    $self->userLogger->error("$ip rejected by CrowdSec");
                    return PE_SESSIONNOTGRANTED;
                }
                else {
                    $self->userLogger->error("$ip is banned by CrowdSec");
                    $req->env->{CROWDSEC_REJECT} = 1;
                    return PE_OK;
                }
            }
        }
        $self->userLogger->info("$ip not banned by CrowdSec");
        return PE_OK;
    }
}

1;
