package Langertha::Runtime::Metrics::OTLP;
# ABSTRACT: Convert parsed Prometheus records to an OTLP/HTTP (JSON) metrics payload
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use Time::HiRes qw( time );
use JSON::MaybeXS qw( JSON );


has _json => (
  is      => 'ro',
  lazy    => 1,
  default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) },
);

sub build_payload {
  my ( $self, $records, %opts ) = @_;
  croak "build_payload() requires an ArrayRef of records"
    unless ref($records) eq 'ARRAY';

  my $timestamp = $opts{timestamp} // time();
  my $time_nano = sprintf( "%.0f", $timestamp * 1_000_000_000 );

  my %resource_attrs = %{ $opts{resource_attributes} || {} };
  $resource_attrs{'service.name'} //= $opts{service_name}
    if defined $opts{service_name} && length $opts{service_name};

  my $scope_name = $opts{scope_name} // 'langertha';

  my @resource_attributes;
  for my $key ( sort keys %resource_attrs ) {
    push @resource_attributes, $self->_attr($key, $resource_attrs{$key});
  }

  return {
    resourceMetrics => [
      {
        resource => {
          attributes => \@resource_attributes,
        },
        scopeMetrics => [
          {
            scope => { name => $scope_name },
            metrics => [ $self->_build_metrics($records, $time_nano) ],
          },
        ],
      },
    ],
  };
}


sub to_json {
  my ( $self, $records, %opts ) = @_;
  return $self->_json->encode( $self->build_payload($records, %opts) );
}


# Group records into OTLP metrics. Histogram and summary series are
# re-grouped by base name; everything else maps 1:1 to a gauge or sum.
sub _build_metrics {
  my ( $self, $records, $time_nano ) = @_;

  my %histograms;   # base => { buckets => [...], sum => $r, count => $r }
  my %summaries;    # base => { sum => $r, count => $r, quantiles => [...] }
  my @standalone;

  for my $r ( @$records ) {
    my $name = $r->{name};
    my $type = $r->{type} // 'untyped';

    if ( $type eq 'histogram' && $name =~ /^(.*)_bucket$/ ) {
      push @{ $histograms{$1}{buckets} }, $r;
    }
    elsif ( $type eq 'histogram' && $name =~ /^(.*)_sum$/ ) {
      $histograms{$1}{sum} = $r;
    }
    elsif ( $type eq 'histogram' && $name =~ /^(.*)_count$/ ) {
      $histograms{$1}{count} = $r;
    }
    elsif ( $type eq 'summary' && $name =~ /^(.*)_sum$/ ) {
      $summaries{$1}{sum} = $r;
    }
    elsif ( $type eq 'summary' && $name =~ /^(.*)_count$/ ) {
      $summaries{$1}{count} = $r;
    }
    elsif ( $type eq 'summary' && exists $r->{labels}{quantile} ) {
      push @{ $summaries{$name}{quantiles} }, $r;
    }
    else {
      push @standalone, $r;
    }
  }

  my @metrics;
  push @metrics, $self->_standalone_metric($_, $time_nano) for @standalone;
  push @metrics, $self->_histogram_metric($_, $histograms{$_}, $time_nano)
    for sort keys %histograms;
  push @metrics, $self->_summary_metric($_, $summaries{$_}, $time_nano)
    for sort keys %summaries;
  return @metrics;
}

sub _standalone_metric {
  my ( $self, $r, $time_nano ) = @_;
  my $dp = {
    timeUnixNano => $time_nano,
    asDouble     => $r->{value} + 0,
  };
  my $attrs = $self->_labels_to_attrs($r->{labels});
  $dp->{attributes} = $attrs if @$attrs;

  my $type = $r->{type} // 'untyped';
  if ( $type eq 'counter' ) {
    return {
      name => $r->{name},
      sum  => {
        dataPoints              => [ $dp ],
        aggregationTemporality  => 'AGGREGATION_TEMPORALITY_CUMULATIVE',
        isMonotonic             => JSON->true,
      },
    };
  }
  # gauge, untyped, and anything unrecognized → gauge
  return { name => $r->{name}, gauge => { dataPoints => [ $dp ] } };
}

sub _histogram_metric {
  my ( $self, $base, $group, $time_nano ) = @_;

  my @buckets = @{ $group->{buckets} || [] };
  # Sort by the le bound numerically; +Inf sorts last.
  @buckets = sort {
    my ( $av, $bv ) = ( $a->{labels}{le}, $b->{labels}{le} );
    return 1  if $av eq '+Inf';
    return -1 if $bv eq '+Inf';
    ( $av + 0 ) <=> ( $bv + 0 );
  } @buckets;

  # explicitBounds is a repeated double — numeric, not string.
  my @bounds = map { $_->{labels}{le} + 0 } grep { $_->{labels}{le} ne '+Inf' } @buckets;
  my @counts = map { sprintf( "%.0f", $_->{value} ) } @buckets;

  my $dp = {
    timeUnixNano   => $time_nano,
    count          => sprintf( "%.0f", $group->{count}{value} // 0 ),
    sum            => $group->{sum}{value} // 0,
    bucketCounts   => \@counts,
    explicitBounds => \@bounds,
  };
  # Data-point attributes: the label set minus the le bound (usually empty).
  my %labels = %{ $group->{buckets}[0]{labels} || {} };
  delete $labels{le};
  my $attrs = $self->_labels_to_attrs(\%labels);
  $dp->{attributes} = $attrs if @$attrs;

  return {
    name      => $base,
    histogram => {
      dataPoints             => [ $dp ],
      aggregationTemporality => 'AGGREGATION_TEMPORALITY_CUMULATIVE',
    },
  };
}

sub _summary_metric {
  my ( $self, $base, $group, $time_nano ) = @_;

  my $dp = {
    timeUnixNano => $time_nano,
    count        => sprintf( "%.0f", $group->{count}{value} // 0 ),
    sum          => $group->{sum}{value} // 0,
  };
  my @quantiles = sort { $a->{quantile} <=> $b->{quantile} }
    map { { quantile => $_->{labels}{quantile} + 0, value => $_->{value} } }
    @{ $group->{quantiles} || [] };
  $dp->{quantileValues} = \@quantiles if @quantiles;

  my %labels = %{ $group->{sum}{labels} || $group->{count}{labels} || {} };
  delete $labels{quantile};
  my $attrs = $self->_labels_to_attrs(\%labels);
  $dp->{attributes} = $attrs if @$attrs;

  return {
    name    => $base,
    summary => { dataPoints => [ $dp ] },
  };
}

# Prometheus label set → OTLP attribute array. Prometheus label values are
# always strings, so every value is a stringValue.
sub _labels_to_attrs {
  my ( $self, $labels ) = @_;
  my @attrs;
  for my $key ( sort keys %$labels ) {
    push @attrs, { key => $key, value => { stringValue => $labels->{$key} } };
  }
  return \@attrs;
}

# Resource attribute value → OTLP AnyValue. Strings, numbers, and booleans
# are supported; anything else is stringified.
sub _attr {
  my ( $self, $key, $value ) = @_;
  if ( ref $value eq 'JSON::PP::Boolean' || ref $value eq 'JSON::XS::Boolean' ) {
    return { key => $key, value => { boolValue => $value } };
  }
  if ( !ref $value ) {
    if ( $value =~ /^-?\d+(?:\.\d+)?$/ ) {
      return { key => $key, value => { doubleValue => $value + 0 } };
    }
    return { key => $key, value => { stringValue => "$value" } };
  }
  return { key => $key, value => { stringValue => "$value" } };
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Runtime::Metrics::OTLP - Convert parsed Prometheus records to an OTLP/HTTP (JSON) metrics payload

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Runtime::Metrics;
    use Langertha::Runtime::Metrics::OTLP;

    my $records = Langertha::Runtime::Metrics->new->parse($prometheus_body);

    my $otlp = Langertha::Runtime::Metrics::OTLP->new;

    my $payload = $otlp->build_payload($records,
        service_name        => 'vllm',
        resource_attributes => { trace_id => 'trace-123' },
    );

    my $json = $otlp->to_json($records, service_name => 'vllm');

=head1 DESCRIPTION

Serializes the record shape produced by L<Langertha::Runtime::Metrics>
(C<< { name, type, value, labels } >>) into an OpenTelemetry
L<OTLP/HTTP JSON|https://opentelemetry.io/docs/specs/otlp/#json-protobuf-encoding>
metrics payload: C<resourceMetrics> / C<scopeMetrics> / C<metric>. The
payload is a plain HashRef (or JSON string via L</to_json>) ready to POST
to any OTLP/HTTP metrics receiver — an OpenTelemetry Collector, a
Prometheus OTLP receiver, Grafana, or any other backend that speaks
OTLP/HTTP.

B<Type mapping:>

=over 4

=item * C<gauge> / C<untyped> — OTLP C<gauge> data point (C<asDouble>)

=item * C<counter> — OTLP C<sum> with C<isMonotonic =E<gt> true> and
C<aggregationTemporality =E<gt> AGGREGATION_TEMPORALITY_CUMULATIVE>
(Prometheus counters are cumulative monotonic sums)

=item * C<histogram> — the C<_bucket> / C<_sum> / C<_count> series are
re-grouped into a single OTLP C<histogram> metric. Buckets are sorted by
their C<le> bound (C<+Inf> last), C<explicitBounds> excludes C<+Inf>, and
C<bucketCounts> keeps the cumulative counts including the C<+Inf> bucket.

=item * C<summary> — the C<_sum> / C<_count> series plus any
C<{quantile="..."}> series are re-grouped into a single OTLP C<summary>
metric with C<quantileValues>.

=back

B<Langfuse note:> Langfuse does B<not> ingest OTLP metrics. Its
C</api/public/otel> endpoint accepts traces only; a POST to
C</api/public/otel/v1/metrics> is accepted and silently discarded (dummy
route since langfuse/langfuse#6408). The C</api/public/metrics> REST
endpoint is a read-only query API over Langfuse's own trace data, not an
ingestion endpoint. Point this serializer at a real OTLP metrics backend
(Collector, Prometheus, Grafana) — see
L<Langertha::Role::Runtime::MetricsPoll/export_otlp_f> for the exporter
and the sources.

=head2 build_payload

    my $payload = $otlp->build_payload($records, %opts);

Builds the OTLP/HTTP JSON metrics payload HashRef for the given records.
Optional C<%opts>:

=over 4

=item * C<service_name> — convenience for the C<service.name> resource
attribute

=item * C<resource_attributes> — HashRef of extra resource attributes
(e.g. C<< { trace_id => 'trace-123' } >> to attach a trace context)

=item * C<scope_name> — instrumentation scope name (default C<'langertha'>)

=item * C<timestamp> — epoch seconds (default: now); rendered as
C<timeUnixNano> on every data point

=back

=head2 to_json

    my $json = $otlp->to_json($records, %opts);

Same as L</build_payload> but returns the JSON-encoded string, ready to
POST as the request body.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Runtime::Metrics> - The parser that produces the record shape this serializes

=item * L<Langertha::Role::Runtime::MetricsPoll> - Scraper role with L<export_otlp_f|Langertha::Role::Runtime::MetricsPoll/export_otlp_f> that POSTs this payload

=item * L<https://opentelemetry.io/docs/specs/otlp/> - OTLP specification (JSON/protobuf encoding)

=item * L<https://github.com/langfuse/langfuse/issues/6395> - Langfuse: no OTel metrics support (accepted-and-discarded)

=item * L<https://github.com/orgs/langfuse/discussions/10686> - Langfuse maintainer: "no support for OTel Metrics"

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
