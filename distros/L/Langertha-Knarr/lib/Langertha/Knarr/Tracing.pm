package Langertha::Knarr::Tracing;
our $VERSION = '1.102';
# ABSTRACT: Automatic Langfuse tracing per proxy request
use Moo;
use Time::HiRes qw( gettimeofday );
use Carp qw( croak );
use Scalar::Util qw( blessed looks_like_number );
use JSON::MaybeXS ();
use Langertha::Usage;
use MIME::Base64 qw( encode_base64 );
use Log::Any qw( $log );
use Langertha::Knarr::Image;
use HTTP::Request ();
use Net::Async::HTTP;
use IO::Async::Loop;


has config => (
  is       => 'ro',
  required => 1,
);


has _enabled => (
  is      => 'lazy',
  builder => '_build__enabled',
);

sub _build__enabled {
  my ($self) = @_;
  my $lf = $self->config->langfuse;
  my $pub = $lf->{public_key} // _strip_quotes($ENV{LANGFUSE_PUBLIC_KEY});
  my $sec = $lf->{secret_key} // _strip_quotes($ENV{LANGFUSE_SECRET_KEY});
  return ($pub && $sec) ? 1 : 0;
}

has _public_key => (
  is      => 'lazy',
  builder => '_build__public_key',
);

sub _build__public_key {
  my ($self) = @_;
  return $self->config->langfuse->{public_key} // _strip_quotes($ENV{LANGFUSE_PUBLIC_KEY});
}

has _secret_key => (
  is      => 'lazy',
  builder => '_build__secret_key',
);

sub _build__secret_key {
  my ($self) = @_;
  return $self->config->langfuse->{secret_key} // _strip_quotes($ENV{LANGFUSE_SECRET_KEY});
}

has _url => (
  is      => 'lazy',
  builder => '_build__url',
);

has trace_name => (
  is      => 'lazy',
  builder => '_build_trace_name',
);


sub _build_trace_name {
  my ($self) = @_;
  return $self->config->langfuse->{trace_name}
    // _strip_quotes($ENV{LANGFUSE_TRACE_NAME})
    // _strip_quotes($ENV{KNARR_TRACE_NAME})
    // 'knarr-proxy';
}

has transport => (
  is      => 'lazy',
  builder => '_build_transport',
);


sub _build_transport {
  my ($self) = @_;
  return $self->config->langfuse_transport;
}

sub BUILD {
  my ($self) = @_;
  return unless $self->_enabled;
  $self->transport;
  $self->config->langfuse_timeout;
}

sub _build__url {
  my ($self) = @_;
  return $self->config->langfuse->{url} // _strip_quotes($ENV{LANGFUSE_URL}) // _strip_quotes($ENV{LANGFUSE_BASE_URL}) // 'https://cloud.langfuse.com';
}

has _batch => (
  is      => 'rw',
  default => sub { [] },
);

has _json => (
  is      => 'lazy',
  builder => '_build__json',
);

# Strip surrounding quotes from env values (Docker --env-file includes them literally)
sub _strip_quotes {
  my $v = shift;
  return $v unless defined $v;
  $v =~ s/^["']|["']$//g;
  return $v;
}

sub _build__json {
  return JSON::MaybeXS->new(utf8 => 1, convert_blessed => 1);
}

# Encodes structured values into OTLP string attributes. Character output:
# the attribute ends up inside the payload _json encodes to UTF-8 bytes.
has _attr_json => (
  is      => 'lazy',
  builder => '_build__attr_json',
);

sub _build__attr_json {
  return JSON::MaybeXS->new( utf8 => 0, canonical => 1, convert_blessed => 1, allow_nonref => 1 );
}

# A random OTel id of $bytes bytes as lowercase hex (OTLP/JSON sends ids as
# hex, not base64). All zeros is the invalid id, so it is never returned.
sub _hex_id {
  my ($bytes) = @_;
  my $id;
  do { $id = join '', map { sprintf '%02x', int rand 256 } 1 .. $bytes } until $id =~ /[^0]/;
  return $id;
}

# A gettimeofday pair as OTLP's Unix nanoseconds, a decimal string.
sub _unix_nano {
  my ($s, $us) = @_;
  return sprintf '%d%06d000', $s, $us;
}

sub _uuid {
  my @hex = map { sprintf("%04x", int(rand(65536))) } 1..8;
  return join('-',
    $hex[0].$hex[1],
    $hex[2],
    '4'.substr($hex[3], 1),
    sprintf("%x", 8 + int(rand(4))).substr($hex[4], 1),
    $hex[5].$hex[6].$hex[7],
  );
}

sub _timestamp {
  my ($s, $us) = @_ ? @_ : gettimeofday;
  my @t = gmtime($s);
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], int($us/1000));
}

# The instant $start_hires + $delta_seconds, as a gettimeofday pair that
# either transport formats. Turns the deltas an engine measured
# (ttft_seconds / total_seconds on Langertha::Response) into absolute
# Langfuse timestamps anchored to the moment start_trace ran — not to "now",
# which has already moved past the end of the call.
sub _after {
  my ($start_hires, $delta_seconds) = @_;
  return undef unless ref $start_hires eq 'ARRAY' && defined $delta_seconds;
  # Clamp: a negative delta (clock skew, or a provider-reported duration we
  # did not produce) would otherwise report a trip into the past.
  $delta_seconds = 0 if $delta_seconds < 0;
  my ($s, $us) = @$start_hires;
  my $sum = $us + $delta_seconds * 1_000_000;
  return [ $s + int( $sum / 1_000_000 ), int($sum) % 1_000_000 ];
}

# Flatten a Langertha::RateLimit (or an equivalent hashref) into plain
# scalars for the trace metadata. Only the quota fields — the object's raw
# header hash is deliberately left out so response headers never leak into
# Langfuse, and so the payload stays JSON-encodable without convert_blessed.
my @RATE_LIMIT_FIELDS = qw(
  requests_limit requests_remaining requests_reset
  tokens_limit   tokens_remaining   tokens_reset
);

sub _rate_limit_hash {
  my ($rl) = @_;
  return undef unless defined $rl;
  my %out;
  if ( blessed $rl ) {
    for my $f (@RATE_LIMIT_FIELDS) {
      next unless $rl->can($f);
      my $v = $rl->$f;
      $out{$f} = $v if defined $v;
    }
  }
  elsif ( ref $rl eq 'HASH' ) {
    for my $f (@RATE_LIMIT_FIELDS) {
      $out{$f} = $rl->{$f} if defined $rl->{$f};
    }
  }
  return %out ? \%out : undef;
}

# Langfuse's usage details are exclusive buckets, each priced on its own:
# input is the uncached input, prompt-cache reads and writes have their own
# keys (the names Langfuse's own normalizer and model prices use), and total
# is the sum of all of them (k65).
my @CACHE_BUCKETS = qw( input_cached_tokens input_cache_creation );

# Token counts in the keys Langfuse stores: { input, output, total } plus
# the cache buckets that are not zero. Langertha::Usage's canonical
# input_tokens / output_tokens / total_tokens are keys Langfuse's ingestion
# silently drops, leaving the generation at 0 / 0 / 0 (k57). Takes a
# Langertha::Usage, a hashref already in Langfuse's keys (the shape
# end_trace's SYNOPSIS documents), or a provider's own usage hash (OpenAI,
# Anthropic, Ollama), which Langertha::Usage reads. Anything else, an empty
# hash, or one that counts nothing, is no usage at all -- never a zeroed one.
sub _usage_hash {
  my ($u) = @_;
  return undef unless defined $u;
  if ( ref $u eq 'HASH' ) {
    return _langfuse_counts( $u, $u->{total} )
      if grep { defined $u->{$_} } qw( input output total );
    $u = Langertha::Usage->from_hash($u);
  }
  return undef unless blessed($u) && $u->can('input_tokens');
  return _langfuse_counts( { _input_buckets($u), output => $u->output_tokens } );
}

# The input of a Langertha::Usage split into Langfuse's buckets. A core
# that knows the cache counts says how they relate to input_tokens; older
# ones (0.503) keep only the provider's hash, read here for the two wires
# that carry cache counts: OpenAI counts cached_tokens (and
# cache_write_tokens) inside prompt_tokens, Anthropic counts
# cache_read_input_tokens and cache_creation_input_tokens beside
# input_tokens.
sub _input_buckets {
  my ($u) = @_;
  return (
    input                => $u->uncached_input_tokens,
    input_cached_tokens  => $u->cached_tokens,
    input_cache_creation => $u->cache_write_tokens,
  ) if $u->can('uncached_input_tokens');
  my $input = $u->input_tokens;
  my $raw   = $u->can('raw') ? $u->raw : undef;
  return ( input => $input ) unless ref $raw eq 'HASH';
  my $ptd = ref $raw->{prompt_tokens_details} eq 'HASH' ? $raw->{prompt_tokens_details} : undef;
  my $inside = $ptd && grep { defined $ptd->{$_} } qw( cached_tokens cache_write_tokens );
  # Copied out first: map aliases its list, which would add the missing
  # keys to the provider's hash.
  my @counts = $inside
    ? ( $ptd->{cached_tokens}, $ptd->{cache_write_tokens} )
    : ( $raw->{cache_read_input_tokens}, $raw->{cache_creation_input_tokens} );
  my ( $read, $write ) = map { looks_like_number($_) ? int($_) : 0 } @counts;
  if ($inside) {
    $input -= $read + $write;
    $input = 0 if $input < 0;
  }
  return ( input => $input, input_cached_tokens => $read, input_cache_creation => $write );
}

# Langfuse validates the counts as integers: a count that arrived as a
# string would be encoded as a JSON string and the whole event rejected.
# A missing total is the sum of the buckets; a usage that counts nothing
# is none.
sub _langfuse_counts {
  my ( $counts, $total ) = @_;
  my %out = map { $_ => looks_like_number( $counts->{$_} ) ? int( $counts->{$_} ) : 0 }
    qw( input output ), @CACHE_BUCKETS;
  my $sum = 0;
  $sum += $_ for values %out;
  delete $out{$_} for grep { !$out{$_} } @CACHE_BUCKETS;
  $out{total} = looks_like_number($total) ? int($total) : $sum;
  return ( $sum || $out{total} ) ? \%out : undef;
}

# Langfuse v2's usage has no cache buckets: its input is the whole input.
sub _legacy_usage {
  my ($usage) = @_;
  my $input = 0;
  $input += $usage->{$_} // 0 for 'input', @CACHE_BUCKETS;
  return { input => $input, output => $usage->{output}, total => $usage->{total}, unit => 'TOKENS' };
}

# Flatten the response's tool calls into plain hashes for the trace metadata.
# The trace is the detailed view, so it records the full
# { id, name, arguments, synthetic } shape -- the whole point of putting tool
# calls in a trace is seeing which tool ran with which arguments. Langertha
# 0.503's ToolCall carries a TO_JSON (so it would survive flush's
# convert_blessed encode either way), but flattening here keeps the metadata a
# plain structure like usage and rate_limit.
sub _tool_calls_full {
  my ($tcs) = @_;
  return undef unless ref $tcs eq 'ARRAY' && @$tcs;
  my @out;
  for my $tc (@$tcs) {
    if    ( blessed($tc) && $tc->can('to_hash') ) { push @out, $tc->to_hash }
    elsif ( blessed($tc) && $tc->can('TO_JSON') ) { push @out, $tc->TO_JSON }
    elsif ( ref $tc eq 'HASH' )                   { push @out, $tc }
  }
  return @out ? \@out : undef;
}


sub start_trace {
  my ($self, %opts) = @_;
  return undef unless $self->_enabled;

  my @hires    = $opts{start_hires} ? @{ $opts{start_hires} } : gettimeofday;
  my $now      = _timestamp(@hires);
  # Image objects (k33) carry no TO_JSON and would fail the batch encode.
  my $input    = Langertha::Knarr::Image::plain_messages( $opts{messages} );

  # OTel spans are exported once, finished: nothing is sent yet, end_trace
  # builds both spans from what is kept here.
  return {
    trace_id    => _hex_id(16),
    root_id     => _hex_id(8),
    gen_id      => _hex_id(8),
    start_time  => $now,
    start_hires => \@hires,
    otel        => {
      name     => $self->trace_name,
      model    => $opts{model},
      input    => $input,
      metadata => {
        format => $opts{format},
        engine => $opts{engine},
        model  => $opts{model},
        params => $opts{params},
        # Left out when undef, like every other attribute.
        passthrough_fallback => $opts{passthrough_fallback},
      },
    },
  } if $self->transport eq 'otel';

  my $trace_id = _uuid();
  my $gen_id   = _uuid();

  push @{$self->_batch}, {
    id        => _uuid(),
    type      => 'trace-create',
    timestamp => $now,
    body      => {
      id       => $trace_id,
      name     => $self->trace_name,
      input    => $input,
      metadata => {
        format  => $opts{format},
        engine  => $opts{engine},
        model   => $opts{model},
        params  => $opts{params},
        defined $opts{passthrough_fallback}
          ? ( passthrough_fallback => $opts{passthrough_fallback} ) : (),
      },
      tags => ['knarr'],
    },
  };

  push @{$self->_batch}, {
    id        => _uuid(),
    type      => 'generation-create',
    timestamp => $now,
    body      => {
      id        => $gen_id,
      traceId   => $trace_id,
      name      => 'proxy-request',
      model     => $opts{model},
      input     => $input,
      startTime => $now,
    },
  };

  return {
    trace_id    => $trace_id,
    gen_id      => $gen_id,
    start_time  => $now,
    start_hires => \@hires,
  };
}


sub end_trace {
  my ($self, $trace_info, %opts) = @_;
  return unless $self->_enabled;
  return unless $trace_info;

  my @now  = gettimeofday;
  my $now  = _timestamp(@now);
  my $otel = $self->transport eq 'otel';

  if ( $opts{error} && $otel ) {
    push @{$self->_batch}, {
      info   => $trace_info,
      now    => \@now,
      end    => \@now,
      output => $opts{output},
      error  => "$opts{error}",
    };
  } elsif ($opts{error}) {
    push @{$self->_batch}, {
      id        => _uuid(),
      type      => 'generation-update',
      timestamp => $now,
      body      => {
        id            => $trace_info->{gen_id},
        endTime       => $now,
        level         => 'ERROR',
        statusMessage => $opts{error},
      },
    };
  } else {
    my $timing = ( ref $opts{timing} eq 'HASH' ) ? $opts{timing} : undef;

    # Engine-measured deltas win over the proxy's wall clock: they are
    # anchored to the same instant as start_time and exclude our own
    # dispatch/formatting overhead. Without them endTime stays "now".
    my $end_at        = \@now;
    my $completion_at = undef;
    if ( $timing ) {
      my $hires = $trace_info->{start_hires};
      $end_at = _after( $hires, $timing->{total_seconds} ) // $end_at
        if defined $timing->{total_seconds};
      $completion_at = _after( $hires, $timing->{ttft_seconds} )
        if defined $timing->{ttft_seconds};
    }

    my $usage = _usage_hash( $opts{usage} );

    my %metadata;
    $metadata{timing}      = $timing if $timing;
    $metadata{response_id} = $opts{response_id} if defined $opts{response_id};
    $metadata{configured_model} = $opts{configured_model} if defined $opts{configured_model};
    $metadata{thinking}    = $opts{thinking}
      if defined $opts{thinking} && length $opts{thinking};
    if ( my $rl = _rate_limit_hash( $opts{rate_limit} ) ) {
      $metadata{rate_limit} = $rl;
    }
    if ( my $tcs = _tool_calls_full( $opts{tool_calls} ) ) {
      $metadata{tool_calls} = $tcs;
    }

    if ($otel) {
      push @{$self->_batch}, {
        info             => $trace_info,
        now              => \@now,
        end              => $end_at,
        completion_start => $completion_at,
        output           => $opts{output},
        model            => $opts{model},
        usage            => $usage,
        metadata         => \%metadata,
      };
    } else {
      push @{$self->_batch}, {
        id        => _uuid(),
        type      => 'generation-update',
        timestamp => $now,
        body      => {
          id      => $trace_info->{gen_id},
          output  => $opts{output},
          endTime => _timestamp(@$end_at),
          defined $completion_at ? (completionStartTime => _timestamp(@$completion_at)) : (),
          $opts{model} ? (model => $opts{model}) : (),
          # Langfuse v2 reads usage and drops usageDetails; v3 reads both,
          # usageDetails overriding usage.
          $usage       ? (usage        => _legacy_usage($usage),
                          usageDetails => $usage) : (),
          %metadata    ? (metadata => \%metadata) : (),
        },
      };
    }
  }

  push @{$self->_batch}, {
    id        => _uuid(),
    type      => 'trace-create',
    timestamp => $now,
    body      => {
      id     => $trace_info->{trace_id},
      output => $opts{output} // $opts{error},
    },
  } unless $otel;

  $self->flush;
}


has _loop => (
  is      => 'lazy',
  builder => sub { IO::Async::Loop->new },
);

has _http => (
  is      => 'lazy',
  builder => sub {
    my ($self) = @_;
    # Net::Async::HTTP times out at once on 0, so 0 (none) sets no timeout.
    my $timeout = $self->config->langfuse_timeout;
    my $h = Net::Async::HTTP->new( user_agent => 'Langertha-Knarr',
      $timeout ? ( timeout => $timeout ) : () );
    $self->_loop->add($h);
    return $h;
  },
);

sub flush {
  my ($self) = @_;
  return unless $self->_enabled;
  my $batch = $self->_batch;
  return unless @$batch;
  $self->_batch([]);

  my $auth = encode_base64($self->_public_key . ':' . $self->_secret_key, '');
  my $otel = $self->transport eq 'otel';

  # Tracing is observability, not the product. flush runs inside end_trace on
  # the response path — and for streams after the last chunk was written — so
  # an exception here turns an already-answered request into a 500, or leaves
  # a client waiting for an end marker that never comes. The batch was
  # detached from _batch above and is unrecoverable either way, so a failed
  # encode is logged at error level (as loud as any request fault in
  # Langertha::Knarr) and dropped, exactly like the ingestion failures below.
  my $body;
  my $encode_error = do {
    local $@;
    eval {
      $body = $self->_json->encode(
        $otel ? $self->_otlp_request($batch) : { batch => $batch } );
    };
    $@;
  };
  if ($encode_error) {
    $log->errorf("Langfuse batch encode failed, dropping %d event(s): %s",
      scalar @$batch, $encode_error);
    return;
  }

  my $req  = HTTP::Request->new(
    POST => $self->_url . ( $otel ? '/api/public/otel/v1/traces' : '/api/public/ingestion' ),
    [
      'Content-Type'  => 'application/json',
      'Authorization' => 'Basic ' . $auth,
      # Selects Langfuse v4's real-time OTel ingestion (else up to 10 min late).
      $otel ? ( 'x-langfuse-ingestion-version' => '4' ) : (),
    ],
    $body,
  );

  my $f = $self->_http->do_request( request => $req );
  $f->on_done(sub {
    my ($resp) = @_;
    return if $resp->is_success;
    $log->warnf("Langfuse ingestion failed: %s", $resp->status_line);
  });
  $f->on_fail(sub {
    my ($err) = @_;
    $log->warnf("Langfuse flush error: %s", $err);
  });
  $f->retain;
  return;
}

# OTLP/JSON ExportTraceServiceRequest for the traces end_trace finished.
# Enums (span kind, status code) are integers, ids lowercase hex and times
# decimal strings, as the OTLP/JSON encoding prescribes.
sub _otlp_request {
  my ($self, $batch) = @_;
  return {
    resourceSpans => [ {
      resource   => { attributes => [ $self->_otel_attributes( 'service.name' => 'langertha-knarr' ) ] },
      scopeSpans => [ {
        scope => { name => __PACKAGE__, version => $VERSION },
        spans => [ map { $self->_otel_spans($_) } @$batch ],
      } ],
    } ],
  };
}

my %SPAN_KIND    = ( server => 2, client => 3 );
my $STATUS_ERROR = 2;

# The root span (the Langfuse trace) and its generation child for one
# request, from the record end_trace pushed.
sub _otel_spans {
  my ($self, $rec) = @_;
  my $info  = $rec->{info};
  my $o     = $info->{otel};
  my $error = $rec->{error};
  my $start = _unix_nano( @{ $info->{start_hires} } );

  # Langfuse v4 reads trace attributes off every span that carries them.
  my @trace_attrs = (
    $self->_otel_attributes( 'langfuse.trace.name' => $o->{name} ),
    { key => 'langfuse.trace.tags',
      value => { arrayValue => { values => [ { stringValue => 'knarr' } ] } } },
  );
  my $meta = $o->{metadata};
  my $gen_meta = $rec->{metadata} // {};

  # A failed request marks both the trace's span and the generation.
  my @error_attrs = $error ? $self->_otel_attributes(
    'langfuse.observation.level'          => 'ERROR',
    'langfuse.observation.status_message' => $error,
  ) : ();
  my @error_status = $error ? ( status => { code => $STATUS_ERROR, message => $error } ) : ();

  my $root = {
    traceId           => $info->{trace_id},
    spanId            => $info->{root_id},
    name              => $o->{name},
    kind              => $SPAN_KIND{server},
    startTimeUnixNano => $start,
    endTimeUnixNano   => _unix_nano( @{ $rec->{now} } ),
    attributes        => [
      @trace_attrs,
      $self->_otel_attributes(
        'langfuse.observation.type'   => 'span',
        'langfuse.observation.input'  => $o->{input},
        'langfuse.observation.output' => $rec->{output} // $error,
        map { ( 'langfuse.trace.metadata.'.$_ => $meta->{$_} ) } sort keys %$meta,
      ),
      @error_attrs,
    ],
    @error_status,
  };

  my $gen = {
    traceId           => $info->{trace_id},
    spanId            => $info->{gen_id},
    parentSpanId      => $info->{root_id},
    name              => 'proxy-request',
    kind              => $SPAN_KIND{client},
    startTimeUnixNano => $start,
    endTimeUnixNano   => _unix_nano( @{ $rec->{end} } ),
    attributes        => [
      @trace_attrs,
      $self->_otel_attributes(
        'langfuse.observation.type'       => 'generation',
        'langfuse.observation.model.name' => $rec->{model} || $o->{model},
        'langfuse.observation.input'      => $o->{input},
        $error ? () : (
          'langfuse.observation.output'                => $rec->{output},
          'langfuse.observation.completion_start_time' =>
            $rec->{completion_start} ? _timestamp( @{ $rec->{completion_start} } ) : undef,
          'langfuse.observation.usage_details'         => $rec->{usage},
          map { ( 'langfuse.observation.metadata.'.$_ => $gen_meta->{$_} ) } sort keys %$gen_meta,
        ),
      ),
      @error_attrs,
    ],
    @error_status,
  };

  return ( $root, $gen );
}

# OTLP KeyValue list from key/value pairs. An undef value is left out; a
# reference is JSON-encoded into a string, which is how Langfuse takes
# structured input, output, usage and metadata; anything else is a string.
sub _otel_attributes {
  my ($self, @pairs) = @_;
  my @attrs;
  while ( my ( $key, $value ) = splice @pairs, 0, 2 ) {
    next unless defined $value;
    $value = $self->_attr_json->encode($value) if ref $value;
    push @attrs, { key => $key, value => { stringValue => "$value" } };
  }
  return @attrs;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Tracing - Automatic Langfuse tracing per proxy request

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    use Langertha::Knarr::Tracing;

    my $tracing = Langertha::Knarr::Tracing->new(config => $config);

    my $trace_id = $tracing->start_trace(
      model    => 'gpt-5.6-terra',
      engine   => 'Langertha::Engine::OpenAI',
      messages => \@messages,
      params   => \%params,
      format   => 'openai',
    );

    # ... handle request ...

    $tracing->end_trace($trace_id,
      output => $response_text,
      model  => 'gpt-5.6-terra',
      usage  => { input => 100, output => 50, total => 150 },
    );

=head1 DESCRIPTION

Records every proxy request as a Langfuse trace with a nested generation. When
tracing is not configured (no public and secret key), all methods are no-ops.

Two transports carry the trace to Langfuse, selected by L</transport>:
C<ingestion> (the default) posts events to Langfuse's
C</api/public/ingestion> API, C<otel> exports OpenTelemetry spans (see
L</OpenTelemetry transport>). Both record the same content through the
same calls, in one fire-and-forget POST per request that gives up after
L<Langertha::Knarr::Config/langfuse_timeout> seconds (default 15).

Langfuse credentials are read from the config file's C<langfuse:> section or
from the C<LANGFUSE_PUBLIC_KEY>, C<LANGFUSE_SECRET_KEY>, and C<LANGFUSE_URL>
environment variables. The module strips surrounding quotes from environment
variable values, which Docker C<--env-file> sometimes adds literally.

=head2 Timing sources

Knarr has two request paths and they do not measure latency the same way.
The generation's C<startTime> always marks the moment L</start_trace> ran;
what differs is where C<endTime> and C<completionStartTime> come from.

=over

=item * B<Routed, non-streaming> — a L<Langertha> engine produced a
L<Langertha::Response>, so L<Langertha::Knarr::Handler::Tracing> hands the
engine-measured C<timing> hash to L</end_trace>. C<endTime> becomes
C<startTime + total_seconds> and C<completionStartTime> becomes
C<startTime + ttft_seconds>, both anchored to the high-resolution
timestamp L</start_trace> recorded. This is the only path with a real
time-to-first-token, and the durations exclude the proxy's own
formatting overhead.

=item * B<Routed, streaming> — the decorator accumulates deltas and never
sees a response object, so it measures time-to-first-token itself in the
proxy: L<Langertha::Knarr::Handler::Tracing> starts its clock before
opening the upstream stream and stops at the first non-C<undef> delta,
then passes that C<ttft_seconds> to L</end_trace> as C<timing>.
C<completionStartTime> is therefore emitted, but — unlike the
non-streaming path, where the engine measures — this figure is the
proxy's own view and includes its dispatch overhead. C<endTime> stays the
wall-clock moment the stream was exhausted; a stream that yields no delta
(empty or failed) produces no C<timing> and no C<completionStartTime>.

=item * B<Raw passthrough> — bytes are piped 1:1 and never parsed, so no
L<Langertha::Response> exists at all. C<endTime> is again the proxy's own
wall clock at L</end_trace>, which includes network time to the upstream
provider.

=back

Callers that pass no C<timing> therefore keep exactly the previous
behaviour: proxy-measured C<endTime>, no C<completionStartTime>.

=head2 OpenTelemetry transport

With L</transport> C<otel>, each request goes out as one OTLP/HTTP request,
JSON encoded, to C</api/public/otel/v1/traces> under L</config>'s Langfuse
URL, with the same Basic authentication and the
C<x-langfuse-ingestion-version: 4> header (Langfuse's real-time ingestion
path). A span must not be exported twice, so L</start_trace> only records
the start and L</end_trace> builds and sends the finished trace, two spans
under one random trace id:

=over

=item * a root span named after L</trace_name> (kind C<SERVER>) with
C<langfuse.trace.name>, C<langfuse.trace.tags> (C<knarr>),
C<langfuse.trace.metadata.*> (C<format>, C<engine>, C<model>, C<params>,
C<passthrough_fallback>),
and the request messages and the output (or the error) as
C<langfuse.observation.input> / C<langfuse.observation.output>, which
Langfuse shows as the trace's input and output;

=item * its child C<proxy-request> (kind C<CLIENT>), a
C<langfuse.observation.type> C<generation> with
C<langfuse.observation.model.name>, input and output,
C<langfuse.observation.usage_details> (the same buckets the ingestion
path sends as C<usageDetails>, cache reads and writes apart from the
uncached input, see L</end_trace>),
C<langfuse.observation.completion_start_time> and
C<langfuse.observation.metadata.*> (C<timing>, C<response_id>,
C<configured_model>, C<thinking>, C<rate_limit>, C<tool_calls>). A
C<start_hires> given to L</start_trace> is the start of both spans.

=back

An error sets the status of both spans to C<ERROR> with the message, plus
C<langfuse.observation.level> C<ERROR> and
C<langfuse.observation.status_message>, so the trace itself shows as
failed, not only its generation.

Span start and end are the instants the ingestion path reports (see
L</Timing sources>), in Unix nanoseconds. Structured values (messages,
params, usage, metadata hashes) are JSON-encoded into string attributes;
plain strings go as they are, as Langfuse's own SDKs send them.

=head2 config

The L<Langertha::Knarr::Config> object. Required. Provides Langfuse
credentials and C<trace_name>.

=head2 trace_name

The Langfuse trace name applied to all traces. Resolved in priority order from:
C<langfuse.trace_name> in config, C<LANGFUSE_TRACE_NAME> env var,
C<KNARR_TRACE_NAME> env var, or the default C<knarr-proxy>.

=head2 transport

C<ingestion> (default) or C<otel>, from
L<Langertha::Knarr::Config/langfuse_transport> (C<langfuse.transport>, else
C<KNARR_LANGFUSE_TRANSPORT>). An enabled tracer reads it, and
L<Langertha::Knarr::Config/langfuse_timeout>, when it is built, so an
invalid value croaks at startup, not on the first request.

=head2 start_trace

    my $trace_info = $tracing->start_trace(
      model    => $model_name,
      engine   => $engine_class,
      messages => \@messages,
      params   => \%params,
      format   => 'openai',
    );

Creates a new Langfuse trace and generation. Returns a C<$trace_info> hashref
that must be passed to L</end_trace>. Returns C<undef> when tracing is
disabled.

The returned hashref carries C<start_hires>, the C<gettimeofday> pair behind
C<start_time>. L</end_trace> anchors engine-measured durations to it; see
L</Timing sources>.

Two optional arguments:

=over

=item * C<start_hires> -- a C<gettimeofday> pair the trace starts at instead
of now, for a trace opened after the request went out. The raw passthrough
of a model that may still fall back to its engine opens its trace only once
the upstream's status rules that out (see L<Langertha::Knarr/raw_passthrough>).

=item * C<passthrough_fallback> -- the upstream status that sent a raw
passthrough request to its engine instead (C<401>), recorded in the trace's
metadata. L<Langertha::Knarr::Handler::Tracing> passes it from the request.

=back

=head2 end_trace

    $tracing->end_trace($trace_info,
      output => $response_text,
      model  => $model,
      usage  => { input => 100, output => 50, total => 150 },
      timing => { ttft_seconds => 0.25, total_seconds => 1.5 },
      response_id => 'chatcmpl-123',
    );

    # On error:
    $tracing->end_trace($trace_info, error => "Something went wrong");

Closes the generation and trace started by L</start_trace>, then flushes the
batch to Langfuse. Pass C<error> to record a failed generation at level ERROR.
Does nothing when C<$trace_info> is C<undef> (tracing was disabled at start).

Optional metadata carried off a L<Langertha::Knarr::Response>, all skipped
when absent:

=over

=item * C<timing> — HashRef with C<ttft_seconds> / C<total_seconds>. Drives
the generation's C<endTime> and C<completionStartTime> (the Langfuse field
for time-to-first-token) and is recorded verbatim in the metadata, so
provider-native stage durations survive too. See L</Timing sources>.

=item * C<response_id> — the provider's own response id, for correlating a
Langfuse generation with the provider's logs.

=item * C<configured_model> — the model name Knarr answers the client under
when it differs from the C<model> the backend reported (a routed model's
configured name). The generation's C<model> is the reported one; this keeps
the configured one next to it.

=item * C<thinking> — reasoning text the engine split off C<content>. It is
model output that C<output> no longer contains, so the trace is the only
place it survives.

=item * C<rate_limit> — a L<Langertha::RateLimit> (or equivalent hashref).
Flattened to its quota scalars; the raw header hash is not recorded.

=item * C<usage> — a L<Langertha::Usage> (the shape every routed response
carries), a hashref in Langfuse's own keys (C<input> / C<output> / C<total>),
or a provider's usage hash (OpenAI C<prompt_tokens>, Anthropic
C<input_tokens>, Ollama C<prompt_eval_count>, ...), read through
L<Langertha::Usage/from_hash>. Whatever the input, the generation gets the
counts in the only keys Langfuse stores: C<usageDetails> for v3, which
lets it override C<usage>, and C<usage> as C<< { input, output, total,
unit => 'TOKENS' } >> for Langfuse v2, which drops the key it does not
know.

C<usageDetails> holds Langfuse's exclusive buckets, each priced on its own
and C<total> their sum: C<input> is the uncached input, prompt-cache reads
go to C<input_cached_tokens> and cache writes to C<input_cache_creation>
(each only when not zero), and C<output>. Every token lands in exactly one
bucket, whichever way the provider counts: Anthropic reports
C<cache_read_input_tokens> / C<cache_creation_input_tokens> beside
C<input_tokens>, OpenAI's C<prompt_tokens_details.cached_tokens> is part
of C<prompt_tokens> and is taken out of C<input>. v2's C<usage> has no
cache buckets, so its C<input> is the whole input, cache included. A
hashref in Langfuse's keys may carry the two cache buckets itself; its
missing C<total> is the sum of its buckets; a provider's C<total> is
always the sum. Without usage, with an empty hash, or with one that
counts no tokens (an error body, a hash without any count key), neither
key is sent, so Langfuse never records a zeroed usage. The raw
passthrough passes the provider's usage hash it read off a copy of the upstream's answer (see
L<Langertha::Knarr/tracing>).

=item * C<tool_calls> — the response's L<Langertha::ToolCall> list. The trace
is the detailed view, so it records the B<full> tool calls — C<id>, C<name>,
the complete C<arguments> and C<synthetic> — flattened to plain hashes. The
JSONL request log keeps only a trimmed form (see
L<Langertha::Knarr::RequestLog/end_request>).

=back

=head2 flush

    $tracing->flush;

Sends all pending trace events to Langfuse in one POST and clears the
internal buffer: an ingestion batch to C</api/public/ingestion>, or, with
L</transport> C<otel>, an OTLP C<ExportTraceServiceRequest> to
C</api/public/otel/v1/traces>. Called automatically by L</end_trace>. Does
nothing when tracing is disabled or the batch is empty.

Never throws: a batch that cannot be JSON-encoded is logged at error level and
dropped, the same way an ingestion HTTP failure is. L</end_trace> runs on the
request's response path, so a tracing problem must not take the client's
response down with it.

The POST is sent without waiting for it and gives up after
L<Langertha::Knarr::Config/langfuse_timeout> seconds (C<langfuse.timeout>
or C<KNARR_LANGFUSE_TIMEOUT>, default 15, C<0> for none): a Langfuse that
accepts the connection and never answers is logged as a C<Langfuse flush
error> warning, and never holds a request.

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr> — Tracing is wired in automatically for all routes

=item * L<Langertha::Knarr::Config> — Provides Langfuse credentials

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
