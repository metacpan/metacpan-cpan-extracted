use v5.26;
use warnings;
use Test2::V1;
use JSON::PP;
use lib 't/lib';
use TestDiscordREST qw(client response);

# Capture diagnostics through a retry using synthetic secrets that must never appear in them.
my @events;
my ( $rest, $http, $clock ) = client( on_diagnostic => sub { push @events, $_[0] } );
my $request_future =
    $rest->request( 'POST', '/webhooks/123/PRIVATE_WEBHOOK_TOKEN', json => { content => 'PRIVATE_CONTENT' } );
$http->respond( response( 429, { retry_after => 1, global => JSON::PP::true } ) );
$clock->advance(1);
$http->respond( response( 200, {} ) );
T2->ok( $request_future->is_done, 'diagnostics do not affect request' );

# Separate logical requests from HTTP attempts and confirm all active capacity was released.
my $stats = $rest->stats;
T2->is( $stats->{request_queued}, 1, 'counts logical requests' );
T2->is( $stats->{http_started}, 2, 'counts attempts' );
T2->is( $stats->{request_retry}, 1, 'counts retries' );
T2->is( $stats->{rate_limit}, 1, 'counts rate limits' );
T2->is( $stats->{pending}, 0, 'no pending work' );
T2->is( $stats->{active}, 0, 'no active work' );
my ($limit) = grep { $_->{type} eq 'rate_limit' } @events;
T2->is(
    { global => $limit->{global}, retry_after => $limit->{retry_after} },
    { global => 1, retry_after => 1 },
    'rate-limit telemetry'
);

# Inspect every emitted event for accidental payload or credential disclosure.
T2->unlike(
    JSON::PP->new->encode( \@events ),
    qr/FAKE_TEST_TOKEN|PRIVATE_/,
    'diagnostics exclude credentials, paths and message bodies'
);

# Snapshots must be detached; cancellation still updates the live counters.
$stats->{http_started} = 999;
T2->is( $rest->stats->{http_started}, 2, 'stats returns an independent snapshot' );
$rest->request( 'GET', '/users/@me' )->cancel;
T2->is( $rest->stats->{request_cancelled}, 1, 'cancellation counted' );
$rest->close;
T2->done_testing;
