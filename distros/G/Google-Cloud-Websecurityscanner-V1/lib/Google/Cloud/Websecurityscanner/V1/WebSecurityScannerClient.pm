package Google::Cloud::Websecurityscanner::V1::WebSecurityScannerClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Websecurityscanner::V1::ScanRunWarningTrace;
use Google::Cloud::Websecurityscanner::V1::FindingAddon;
use Google::Cloud::Websecurityscanner::V1::CrawledUrl;
use Google::Cloud::Websecurityscanner::V1::FindingTypeStats;
use Google::Cloud::Websecurityscanner::V1::ScanConfigError;
use Google::Cloud::Websecurityscanner::V1::ScanRunErrorTrace;
use Google::Cloud::Websecurityscanner::V1::Finding;
use Google::Cloud::Websecurityscanner::V1::ScanConfig;
use Google::Cloud::Websecurityscanner::V1::ScanRun;
use Google::Cloud::Websecurityscanner::V1::WebSecurityScanner;
use Google::Cloud::Websecurityscanner::V1::ScanRunLog;

our $VERSION = '0.06';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $auth = $self->credentials;
    if (!defined $auth) {
        $auth = Google::Auth->default();
    } elsif (!eval { $auth->can('get_token') }) {
        croak 'Invalid credentials object: must implement get_token()';
    }
    my $token = $auth->get_token();

    my $target = 'websecurityscanner.googleapis.com:443';
    my $t = $self->transport || 'grpc';

    if (ref($t) && eval { $t->can('call') }) {
        # Already a transport object
    } elsif (lc($t) eq 'rest') {
        my $client = Google::Cloud::REST::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    } else {
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub create_scan_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::CreateScanConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.websecurityscanner.v1.WebSecurityScanner/CreateScanConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'CreateScanConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Websecurityscanner::V1::WebSecurityScannerClient

__END__

=head1 NAME

Google::Cloud::Websecurityscanner::V1::WebSecurityScannerClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::WebSecurityScannerClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Websecurityscanner::V1::WebSecurityScannerClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Websecurityscanner::V1::WebSecurityScannerClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Websecurityscanner::V1::WebSecurityScannerClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/websecurityscanner/v1/crawled_url.proto>

=item * C<googleapis/google/cloud/websecurityscanner/v1/finding.proto>

=item * C<googleapis/google/cloud/websecurityscanner/v1/finding_addon.proto>

=item * C<googleapis/google/cloud/websecurityscanner/v1/finding_type_stats.proto>

=item * C<googleapis/google/cloud/websecurityscanner/v1/scan_config.proto>

=item * C<googleapis/google/cloud/websecurityscanner/v1/scan_config_error.proto>

=item * C<googleapis/google/cloud/websecurityscanner/v1/scan_run.proto>

=item * C<googleapis/google/cloud/websecurityscanner/v1/scan_run_error_trace.proto>

=item * C<googleapis/google/cloud/websecurityscanner/v1/scan_run_log.proto>

=item * C<googleapis/google/cloud/websecurityscanner/v1/scan_run_warning_trace.proto>

=item * C<googleapis/google/cloud/websecurityscanner/v1/web_security_scanner.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Websecurityscanner::V1::WebSecurityScannerClient->new(
        credentials => $auth,   # Optional: Google::Auth object (defaults to ADC)
        transport   => 'grpc', # Optional: 'grpc' (default) or 'rest'
    );

=head1 ATTRIBUTES

=head2 credentials

Returns or accepts the L<Google::Auth> credentials object.

=head2 transport

Returns or accepts the active transport object (L<Google::gRPC::Client> or L<Google::Cloud::REST::Client>).

=head1 METHODS

=head2 METHODS

The following RPC methods are available in this client:

=over 4

=item * B<create_scan_config>

    my $response = $client->create_scan_config(
        parent                   => $parent,
        scan_config              => $scan_config,
    );

Calls the RPC method C<CreateScanConfig> on C<google.cloud.websecurityscanner.v1.WebSecurityScanner>.

Request: L<Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::CreateScanConfigRequest>

Returns: L<Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<scan_config> - L<Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
