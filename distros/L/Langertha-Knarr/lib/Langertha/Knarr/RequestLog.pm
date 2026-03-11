package Langertha::Knarr::RequestLog;
our $VERSION = '0.007';
# ABSTRACT: Local disk logging of proxy requests
use Moo;
use Time::HiRes qw( gettimeofday tv_interval );
use JSON::MaybeXS ();
use File::Spec;
use Log::Any qw( $log );


has config => (
  is       => 'ro',
  required => 1,
);


has log_file => (
  is      => 'lazy',
  builder => '_build_log_file',
);

sub _build_log_file {
  my ($self) = @_;
  return $self->config->log_file;
}


has log_dir => (
  is      => 'lazy',
  builder => '_build_log_dir',
);

sub _build_log_dir {
  my ($self) = @_;
  return $self->config->log_dir;
}


has _enabled => (
  is      => 'lazy',
  builder => '_build__enabled',
);

sub _build__enabled {
  my ($self) = @_;
  return ($self->log_file || $self->log_dir) ? 1 : 0;
}

has _json => (
  is      => 'lazy',
  builder => '_build__json',
);

sub _build__json {
  return JSON::MaybeXS->new(utf8 => 1, convert_blessed => 1);
}

has _json_pretty => (
  is      => 'lazy',
  builder => '_build__json_pretty',
);

sub _build__json_pretty {
  return JSON::MaybeXS->new(utf8 => 1, convert_blessed => 1, pretty => 1, canonical => 1);
}

sub _timestamp {
  my ($s, $us) = gettimeofday;
  my @t = gmtime($s);
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], int($us/1000));
}

sub _file_timestamp {
  my ($s, $us) = gettimeofday;
  my @t = gmtime($s);
  return sprintf("%04d%02d%02d_%02d%02d%02d_%03d",
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], int($us/1000));
}


sub start_request {
  my ($self, %opts) = @_;
  return undef unless $self->_enabled;

  return {
    timestamp => _timestamp(),
    t0        => [gettimeofday],
    model     => $opts{model},
    format    => $opts{format},
    engine    => $opts{engine},
    path      => $opts{path},
    stream    => $opts{stream} ? \1 : \0,
    messages  => $opts{messages},
    params    => $opts{params},
  };
}


sub end_request {
  my ($self, $handle, %opts) = @_;
  return unless $self->_enabled;
  return unless $handle;

  my $duration_ms = int(tv_interval($handle->{t0}) * 1000);

  my $entry = {
    timestamp   => $handle->{timestamp},
    model       => $handle->{model},
    format      => $handle->{format},
    engine      => $handle->{engine},
    path        => $handle->{path},
    stream      => $handle->{stream},
    messages    => $handle->{messages},
    params      => $handle->{params},
    output      => $opts{output},
    usage       => $opts{usage},
    duration_ms => $duration_ms,
    status      => $opts{error} ? 'error' : 'ok',
    error       => $opts{error},
  };

  $self->_write_jsonl($entry) if $self->log_file;
  $self->_write_file($entry, $handle) if $self->log_dir;
}

sub _write_jsonl {
  my ($self, $entry) = @_;
  eval {
    open my $fh, '>>', $self->log_file
      or die "Cannot open log file " . $self->log_file . ": $!";
    flock($fh, 2); # LOCK_EX
    print $fh $self->_json->encode($entry) . "\n";
    close $fh;
  };
  if ($@) {
    $log->warnf("RequestLog write error: %s", $@);
  }
}

sub _write_file {
  my ($self, $entry, $handle) = @_;
  eval {
    my $dir = $self->log_dir;
    unless (-d $dir) {
      require File::Path;
      File::Path::make_path($dir);
    }

    my $model  = $handle->{model}  // 'unknown';
    my $format = $handle->{format} // 'unknown';
    # Sanitize for filename
    $model  =~ s/[^a-zA-Z0-9._-]/_/g;
    $format =~ s/[^a-zA-Z0-9._-]/_/g;

    my $filename = _file_timestamp() . "_${format}_${model}.json";
    my $path = File::Spec->catfile($dir, $filename);

    open my $fh, '>', $path
      or die "Cannot write log file $path: $!";
    print $fh $self->_json_pretty->encode($entry);
    close $fh;
  };
  if ($@) {
    $log->warnf("RequestLog file write error: %s", $@);
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::RequestLog - Local disk logging of proxy requests

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Langertha::Knarr::RequestLog;

    my $rlog = Langertha::Knarr::RequestLog->new(config => $config);

    my $handle = $rlog->start_request(
      model    => 'gpt-4o',
      format   => 'openai',
      engine   => 'Langertha::Engine::OpenAI',
      path     => '/v1/chat/completions',
      stream   => 1,
      messages => \@messages,
      params   => \%params,
    );

    # ... handle request ...

    $rlog->end_request($handle,
      output => $response_text,
      usage  => { input => 100, output => 50, total => 150 },
    );

=head1 DESCRIPTION

Records every proxy request as a JSON log entry on local disk. Supports two
modes: JSONL (one line per request, append to a single file) and per-request
JSON files in a directory.

When both C<log_file> and C<log_dir> are set, both are written. When neither
is set, all methods are no-ops.

Log file/directory are read from the config file's C<logging:> section or
from the C<KNARR_LOG_FILE> and C<KNARR_LOG_DIR> environment variables. The
module strips surrounding quotes from environment variable values.

=head2 config

The L<Langertha::Knarr::Config> object. Required. Provides C<log_file> and
C<log_dir> settings.

=head2 log_file

Path to the JSONL log file. One JSON object per line, suitable for
C<tail -f knarr.jsonl | jq>. Resolved from C<logging.file> in config or
C<KNARR_LOG_FILE> environment variable.

=head2 log_dir

Path to a directory for per-request JSON files. Each request produces a
pretty-printed C<{timestamp}_{format}_{model}.json> file. Resolved from
C<logging.dir> in config or C<KNARR_LOG_DIR> environment variable.

=head2 start_request

    my $handle = $rlog->start_request(
      model    => $model_name,
      format   => 'openai',
      engine   => $engine_class,
      path     => '/v1/chat/completions',
      stream   => 1,
      messages => \@messages,
      params   => \%params,
    );

Begins collecting data for a request. Returns a handle (hashref) that must
be passed to L</end_request>. Returns C<undef> when logging is disabled.

=head2 end_request

    $rlog->end_request($handle,
      output => $response_text,
      usage  => { input => 100, output => 50, total => 150 },
    );

    # On error:
    $rlog->end_request($handle, error => "Something went wrong");

Completes the log entry with output, usage, duration and writes it to disk.
Does nothing when C<$handle> is C<undef> (logging was disabled at start).

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr> — Request logging is wired in for all routes

=item * L<Langertha::Knarr::Config> — Provides C<log_file> and C<log_dir>

=item * L<Langertha::Knarr::Tracing> — Langfuse tracing (complementary)

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
