#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

local $ENV{HOME} = tempdir( CLEANUP => 1 );
chdir $ENV{HOME} or die "Unable to enter test HOME '$ENV{HOME}': $!\n";

my $paths = Developer::Dashboard::PathRegistry->new;
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( paths => $paths, files => $files );
my $indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
$config->save_global(
    {
        collectors => [
            {
                name      => 'p48-status-cache',
                cwd       => 'home',
                code      => 'return 0;',
                indicator => { name => 'p48-status-cache', icon => 'x', priority => 1 },
            },
        ],
    }
);
$indicators->set_indicator( 'p48-user-status', page_status_icon => 'before' );

my $app = Developer::Dashboard::Web::App->new(
    auth     => Developer::Dashboard::Auth->new( paths => $paths, files => $files ),
    config   => $config,
    pages    => Developer::Dashboard::PageStore->new( paths => $paths ),
    prompt   => Developer::Dashboard::Prompt->new( paths => $paths, indicators => $indicators ),
    runtime  => Developer::Dashboard::PageRuntime->new( paths => $paths ),
    sessions => Developer::Dashboard::SessionStore->new( paths => $paths ),
);

my @preseed_skill_entries;
my $preseed_config = $config->merged( skill_config_entries_out => \@preseed_skill_entries );
my $preseed_jobs = $config->indicator_collectors(
    merged_config        => $preseed_config,
    skill_config_entries => \@preseed_skill_entries,
);
$indicators->sync_collectors($preseed_jobs);

my $original_json_encode = \&Developer::Dashboard::Web::App::json_encode;
my $original_json_decode = \&Developer::Dashboard::IndicatorStore::json_decode;
my $original_page_header_payload = \&Developer::Dashboard::IndicatorStore::page_header_payload;
my $original_indicator_collectors = \&Developer::Dashboard::Config::indicator_collectors;
my $status_encodes = 0;
my $status_decodes = 0;
my $payload_builds = 0;
my $indicator_collector_projections = 0;
my $collector_projection_signatures = 0;
my $request = sub {
    my $response = $app->handle(
        path        => '/system/status',
        query       => '',
        remote_addr => '127.0.0.1',
        headers     => { host => '127.0.0.1' },
    );
    is( $response->[0], 200, 'the status endpoint returns success' );
    return $response->[2];
};

{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::json_encode = sub {
        my ($payload) = @_;
        $status_encodes++ if ref($payload) eq 'HASH' && exists $payload->{array} && exists $payload->{hash};
        $collector_projection_signatures++
          if ref($payload) eq 'ARRAY' && @{$payload}
          && ref( $payload->[0] ) eq 'HASH' && exists $payload->[0]{indicator};
        return $original_json_encode->(@_);
    };
    local *Developer::Dashboard::IndicatorStore::json_decode = sub {
        $status_decodes++;
        return $original_json_decode->(@_);
    };
    local *Developer::Dashboard::IndicatorStore::page_header_payload = sub {
        $payload_builds++;
        return $original_page_header_payload->(@_);
    };
    local *Developer::Dashboard::Config::indicator_collectors = sub {
        $indicator_collector_projections++;
        return $original_indicator_collectors->(@_);
    };
    local *Developer::Dashboard::Config::collectors = sub {
        die 'The status payload must request only indicator collector declarations';
    };

    my $first_body  = $request->();
    my $decodes_before_stable_request = $status_decodes;
    my $second_body = $request->();
    is( $second_body, $first_body, 'an unchanged status response is byte-identical' );
    is( $status_encodes, 1, 'a stable status request reuses the serialized response body' );
    is( $payload_builds, 1, 'a stable status request skips rebuilding the in-memory payload' );
    is( $status_decodes - $decodes_before_stable_request, 0,
        'a stable status request validates file metadata without decoding status JSON' );

    $indicators->set_indicator( 'p48-user-status', page_status_icon => 'after' );
    my $decodes_before_changed_request = $status_decodes;
    my $updated_body = $request->();
    isnt( $updated_body, $first_body, 'a persisted status change invalidates the serialized response' );
    like( $updated_body, qr/after/, 'the fresh response contains the updated indicator data' );
    is( $status_encodes, 2, 'a changed indicator is serialized once for the new response' );
    is( $payload_builds, 2, 'a changed indicator rebuilds the in-memory payload' );
    cmp_ok( $status_decodes - $decodes_before_changed_request, '>', 0,
        'a changed status returns through the JSON decode and rebuild path' );
    is( $indicator_collector_projections, 1,
        'unchanged config reuses the minimal indicator-collector projection while status data refreshes' );
    is( $collector_projection_signatures, 1,
        'unchanged watched collector config reuses its precomputed collector-job signature' );
}

my $invalid_cache_signal_payload = $app->_page_status_payload( {}, 1 );
is(
    ref($invalid_cache_signal_payload), 'HASH',
    'a non-scalar freshness signal cannot suppress payload generation'
);

$indicators->set_indicator( 'p48-user-status', alias => 'before-summary-change' );
my $first_prompt_summary = $app->_prompt_summary;
like( $first_prompt_summary, qr/before-summary-change/, 'prompt summary includes the current indicator alias' );
is( $app->_prompt_summary, $first_prompt_summary,
    'prompt summary reuses its cached text only after unchanged indicator validation' );
$indicators->set_indicator( 'p48-user-status', alias => 'after-summary-change' );
my $updated_prompt_summary = $app->_prompt_summary;
like( $updated_prompt_summary, qr/after-summary-change/, 'changed indicator data refreshes prompt summary text' );
unlike( $updated_prompt_summary, qr/before-summary-change/, 'refreshed prompt summary drops the prior alias' );

$indicators->set_indicator( 'p48-user-status', alias => 'stale-before-config-change' );
$app->_prompt_summary;
$config->save_global(
    {
        collectors => [
            {
                name      => 'p48-status-cache',
                cwd       => 'home',
                code      => 'return 0;',
                indicator => { name => 'p48-status-cache', icon => 'config-fresh', priority => 1 },
            },
        ],
    }
);
$request->();
my $summary_after_config_sync = $app->_prompt_summary;
like( $summary_after_config_sync, qr/config-fresh/,
    'status-route collector synchronization invalidates an older prompt summary' );

for my $invalid_signature ( undef, [], '' ) {
    my $ok = eval {
        $indicators->sync_collectors(
            $preseed_jobs,
            collector_jobs_signature => $invalid_signature,
        );
        1;
    };
    ok( !$ok, 'invalid explicit collector-job signatures are rejected' );
    like( $@, qr/collector_jobs_signature must be a non-empty scalar/,
        'invalid collector-job signatures produce an explicit diagnostic' );
}

done_testing;

__END__

=pod

=head1 NAME

668-problem48-status-response-cache.t - test freshness-guarded status-body reuse

=head1 PURPOSE

Verifies that the dashboard may reuse the serialized C</system/status> response
only after collector synchronization proves that the collector configuration,
indicator inventory, and persisted status files are unchanged. The same
freshness contract also gates reuse of the rendered top-chrome prompt summary.

=head1 WHY IT EXISTS

The Problem 48 route profile showed JSON response encoding remained on every
stable request after collector planning and status-file reads were cached.
This test protects a final response-body cache without allowing it to hide a
persisted indicator update. It also ensures that a persisted status change
refreshes the response without needlessly rebuilding the configuration-derived
indicator collector projection. Prompt-summary assertions cover matching
reuse, invalidation after an indicator alias changes, and a status-route
collector sync that changes its configured indicator before the next render.

=head1 WHEN TO USE

Run this test after changing C<Web::App::status_response>, the status payload
builder, or the unchanged-result contract of C<IndicatorStore::sync_collectors>.

=head1 HOW TO USE

  prove -lv t/668-problem48-status-response-cache.t

=head1 WHAT USES IT

The test assembles the same web app and indicator store used by dashboard
workers, then requests C</system/status> repeatedly and updates one stored
indicator between requests. It also verifies a validated config snapshot
reuses its collector-job signature rather than serializing the same collector
projection for every status request.

=head1 EXAMPLES

  d2 docker compose -f /tmp/problem48-networkless.yml run --rm --no-deps dev prove -lv t/668-problem48-status-response-cache.t

The first two requests must return identical bytes with one status-body encode;
after changing a persisted indicator, the next response must contain that new
value and perform one new encode.

=cut
