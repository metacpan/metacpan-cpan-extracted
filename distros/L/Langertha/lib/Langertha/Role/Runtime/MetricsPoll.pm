package Langertha::Role::Runtime::MetricsPoll;
# ABSTRACT: Async Prometheus /metrics scraper for self-hosted engines
our $VERSION = '0.503';
use Moose::Role;
use Future::AsyncAwait;
use Log::Any qw( $log );
use URI;
use Carp qw( croak );
use HTTP::Request;

use Langertha::Runtime::Metrics;

requires qw(
  json
  url
);

# poll_metrics_f decodes the scraped body through Role::HTTP's bounded decoder
# (karr k346), so this role needs Role::HTTP composed too. Every composer today
# (vLLM, SGLang, LlamaCpp) has it via Engine::OpenAIBase; require the attribute
# so a future MetricsPoll-only composer fails at composition, not at runtime.
requires 'response_max_bytes';


sub metrics_url {
  my ( $self ) = @_;
  croak "metrics_url requires a url attribute" unless $self->has_url;
  my $uri = URI->new($self->url);
  my $path = $uri->path;
  # Strip trailing slashes and then a trailing /v1 segment so we get the
  # bare server root before appending /metrics. /v1 is the OpenAI-compatible
  # base; /metrics lives at the root for vLLM, SGLang, llama.cpp. A prefix
  # the server is mounted under (a proxy's /vllm) stays (k306).
  $path =~ s{/+\z}{};
  $path =~ s{/v1\z}{};
  $uri->path($path . '/metrics');
  return $uri->as_string;
}


sub _croak {
  my ($msg) = @_;
  croak($msg);
}

# The _async_http backend (and its _async_loop) come from
# Langertha::Role::AsyncHTTP (composed below): injected client >
# Net::Async::HTTP > synchronous LWP fallback. The sync wrappers
# (poll_metrics / export_otlp) block with ->get, which drives the pending
# future's own loop and never creates one, so the sync fallback runs
# without an event loop.
with 'Langertha::Role::AsyncHTTP';

async sub poll_metrics_f {
  my ( $self, @prefixes ) = @_;

  my $url = $self->metrics_url;
  $log->debugf("[%s] scraping %s", ref($self), $url);

  my $request = HTTP::Request->new(GET => $url);

  my $response = await $self->_async_do_request_f(
    request => $request,
  );

  unless ( $response->is_success ) {
    $log->errorf("[%s] /metrics fetch failed: %s",
      ref($self), $response->status_line);
    _croak("".(ref($self))." /metrics fetch failed: ".$response->status_line);
  }

  # Bounded Content-Encoding decode (karr k346): a self-hosted /metrics endpoint
  # (or a proxy in front of it) is not trusted to be well-behaved, so a gzip
  # body inflates under response_max_bytes (Role::HTTP) or is refused with the
  # too-big croak rather than expanding unbounded in memory.
  my $body = $self->_bounded_decoded_content($response) // $response->content;
  return Langertha::Runtime::Metrics->new
    ->parse_and_filter($body, @prefixes);
}


sub poll_metrics {
  my ( $self, @prefixes ) = @_;
  # Synchronous variant. ->get is loop-agnostic: a pending future from
  # Net::Async::HTTP (or an injected client on the caller's own loop) is an
  # IO::Async::Future — or whatever Future subclass that client uses — and
  # its await() drives the loop it belongs to; Future::AsyncAwait builds
  # the returned future from the first pending one it awaited. On the sync
  # fallback the future is already complete. No private loop is created.
  return $self->poll_metrics_f(@prefixes)->get;
}


# The OTLP serializer stays a lazy load, but the require lives in this plain
# sub and never in an async sub's own frame: with a coderef in @INC, perl
# localizes $INC around the hook call, and Future::AsyncAwait (0.71, perl
# 5.38+) aborts the process when it suspends a frame that still holds that
# savestack entry (karr k193, t/48_async_require_inc_hook.t). The local is
# unwound when this sub returns, before export_otlp_f awaits.
sub _otlp_json {
  my ( $records, %opts ) = @_;
  require Langertha::Runtime::Metrics::OTLP;
  return Langertha::Runtime::Metrics::OTLP->new->to_json($records, %opts);
}

async sub export_otlp_f {
  my ( $self, $records, %opts ) = @_;
  my $endpoint = $opts{endpoint}
    // _croak("export_otlp_f requires an endpoint option");

  my $body = _otlp_json($records, %opts);

  my @headers = ( 'Content-Type' => 'application/json' );
  push @headers, %{ $opts{headers} || {} };

  my $request = HTTP::Request->new( POST => $endpoint, \@headers, $body );

  $log->debugf("[%s] exporting %d records to %s",
    ref($self), scalar(@$records), $endpoint);

  my $response = await $self->_async_do_request_f(
    request => $request,
  );

  unless ( $response->is_success ) {
    $log->errorf("[%s] OTLP export failed: %s",
      ref($self), $response->status_line);
    _croak("".(ref($self))." OTLP export failed: ".$response->status_line);
  }

  return $response;
}


sub export_otlp {
  my ( $self, $records, %opts ) = @_;
  # Synchronous variant; ->get drives the future's own loop (see
  # poll_metrics).
  return $self->export_otlp_f($records, %opts)->get;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Runtime::MetricsPoll - Async Prometheus /metrics scraper for self-hosted engines

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::vLLM;

    my $vllm = Langertha::Engine::vLLM->new(
        url => 'http://localhost:8000/v1',
    );

    # Async — preferred for live systems
    my $records = await $vllm->poll_metrics_f;
    # Returns: [ { name => 'vllm:num_requests_running', type => 'gauge',
    #              value => 3, labels => { model_name => 'Qwen/...' } }, ... ]

    # Sync wrapper
    my $records = $vllm->poll_metrics;

=head1 DESCRIPTION

Composes onto self-hosted engines that expose a Prometheus
C<GET /metrics> endpoint at the server's C<url> attribute. The role
scrapes the body, parses it via L<Langertha::Runtime::Metrics>, and
returns the parsed ArrayRef. No filtering is applied by default —
pass a prefix to L</poll_metrics_f($prefix)> or filter with
L<Langertha::Runtime::Metrics/filter_prefix> downstream.

The parsed records can be exported to any OTLP/HTTP metrics receiver
(OpenTelemetry Collector, Prometheus, Grafana) via
L</export_otlp_f> / L</export_otlp>, which serialize them with
L<Langertha::Runtime::Metrics::OTLP>. B<Langfuse does not ingest OTLP
metrics> — see L</export_otlp_f> for the details and sources.

The endpoint path is derived by stripping the trailing C</v1> (or
any trailing slash) from C<url>, then appending C</metrics>. Engines
whose C<url> is e.g. C<http://localhost:8000/v1> therefore hit
C<http://localhost:8000/metrics> — matching the convention used by
vLLM, SGLang, and llama.cpp's built-in server.

B<Authentication:> None. These are local servers; no C<api_key>
header is sent. If a deployment sits behind auth, layer it on
externally (proxy or L<Langertha::Role::HTTP/generate_http_request>
extension).

B<Ollama> is intentionally B<not> composed with this role:
Ollama's runtime stats live at C</api/ps> in JSON, not
C</metrics> in Prometheus text. See
L<Langertha::Runtime::Metrics::EngineContract> for the wire
contract and the follow-up karr ticket tracked alongside that
document for the JSON-to-Prometheus adapter work.

=head2 metrics_url

    my $url = $engine->metrics_url;

Derives the C</metrics> URL from the engine's C<url> attribute by
stripping trailing slashes and a trailing C</v1> path segment, then
appending C</metrics>. Any other path prefix is kept, so
C<http://host/vllm/v1> and C<http://host/vllm> both give
C<http://host/vllm/metrics>. Returns the full URL as a string.

=head2 poll_metrics_f

    my $records = await $engine->poll_metrics_f;
    my $vllm    = await $engine->poll_metrics_f('vllm:');

Async scrape. Returns a Future that resolves to the ArrayRef of
parsed L<Langertha::Runtime::Metrics> records. Optional prefix
arguments OR-filter the parser output (see
L<Langertha::Runtime::Metrics/parse_and_filter>).

Croaks on a non-success HTTP response.

=head2 poll_metrics

    my $records = $engine->poll_metrics;

Synchronous scrape. Returns the ArrayRef of records or croaks on HTTP
failure. It blocks on L</poll_metrics_f> with C<< ->get >>, which drives
the loop the pending future belongs to: the engine's L<IO::Async::Loop> on
the L<Net::Async::HTTP> backend, or the loop of an injected C<_async_http>
client. On the synchronous L<Langertha::Request::SyncHTTP> fallback the
future is already complete, so no event loop is created
(L<Langertha::Role::AsyncHTTP>).

Use this only when no event loop is already running. Inside an
async context prefer L</poll_metrics_f>.

=head2 export_otlp_f

    my $response = await $engine->export_otlp_f($records,
        endpoint            => 'http://localhost:4318/v1/metrics',
        headers             => { Authorization => 'Basic ...' },
        service_name        => 'vllm',
        resource_attributes => { trace_id => 'trace-123' },
    );

Async export. Serializes the parsed records (the ArrayRef from
L</poll_metrics_f>) into an OTLP/HTTP JSON metrics payload via
L<Langertha::Runtime::Metrics::OTLP> and POSTs it to C<endpoint>.
Returns the L<HTTP::Response>. Croaks on a non-success HTTP response.

C<%opts> are passed through to
L<Langertha::Runtime::Metrics::OTLP/build_payload> (C<service_name>,
C<resource_attributes>, C<scope_name>, C<timestamp>) plus:

=over 4

=item * C<endpoint> — required. The OTLP/HTTP metrics receiver URL, e.g.
C<http://localhost:4318/v1/metrics> (OpenTelemetry Collector), a
Prometheus OTLP receiver, or Grafana.

=item * C<headers> — optional HashRef of extra request headers (e.g.
C<Authorization> for a protected receiver).

=back

B<Langfuse note:> Langfuse does B<not> ingest OTLP metrics. Its
C</api/public/otel> endpoint accepts traces only; a POST to
C</api/public/otel/v1/metrics> is accepted and silently discarded (dummy
route since langfuse/langfuse#6408), and C</api/public/metrics> is a
read-only query API over Langfuse's own trace data. Point this exporter
at a real OTLP metrics backend (Collector, Prometheus, Grafana). Sources:
L<https://github.com/langfuse/langfuse/issues/6395> and
L<https://github.com/orgs/langfuse/discussions/10686>.

=head2 export_otlp

    my $response = $engine->export_otlp($records, endpoint => '...');

Synchronous export. Returns the L<HTTP::Response> or croaks on HTTP
failure. Like L</poll_metrics> it blocks on L</export_otlp_f> with
C<< ->get >>, driving the pending future's own loop; on the synchronous
L<Langertha::Request::SyncHTTP> fallback the future is already complete,
so no event loop is created (L<Langertha::Role::AsyncHTTP>).

Use this only when no event loop is already running. Inside an
async context prefer L</export_otlp_f>.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Runtime::Metrics> - The parser this role drives

=item * L<Langertha::Runtime::Metrics::OTLP> - OTLP/HTTP JSON serializer used by L</export_otlp_f>

=item * L<Langertha::Runtime::Metrics::EngineContract> - Per-engine wire contract

=item * L<Langertha::Engine::vLLM> - vLLM self-hosted engine (composes this role)

=item * L<Langertha::Engine::SGLang> - SGLang self-hosted engine (composes this role)

=item * L<Langertha::Engine::LlamaCpp> - llama.cpp server engine (composes this role)

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
