package Langertha::Knarr::CLI::Cmd::Start;
our $VERSION = '1.102';
# ABSTRACT: Start the Knarr proxy server
use Moo;
with 'Langertha::Knarr::CLI::Role::GlobalOptions';
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: knarr start [options]';
use Log::Any qw( $log );
use Log::Any::Adapter;


option port => (
  is      => 'ro',
  format  => 'i@',
  short   => 'p',
  doc     => 'Port(s) to listen on, on the -H host; repeatable, replaces the config listen: (default: the config listen:, which defaults to 127.0.0.1:8080 and 127.0.0.1:11434)',
  default => sub { [] },
);

option host => (
  is      => 'ro',
  format  => 's',
  short   => 'H',
  doc     => 'Host the -p ports bind to, no effect without -p (default: 0.0.0.0)',
  default => '0.0.0.0',
);

option workers => (
  is      => 'ro',
  format  => 'i',
  short   => 'w',
  doc     => 'Number of worker processes; more than 1 forks that many, supervised and restarted by this process (default: the config workers:, else KNARR_WORKERS, else 1, no fork)',
  predicate => 'has_workers',
);

option from_env => (
  is      => 'ro',
  doc     => 'Build config from environment variables when no config file found',
  default => 0,
);

option trace_name => (
  is      => 'ro',
  format  => 's',
  short   => 'n',
  doc     => 'Langfuse trace name (default: knarr-proxy, or KNARR_TRACE_NAME env)',
  predicate => 'has_trace_name',
);

option log_file => (
  is      => 'ro',
  format  => 's',
  doc     => 'JSONL log file path (or KNARR_LOG_FILE env)',
  predicate => 'has_log_file',
);

option log_dir => (
  is      => 'ro',
  format  => 's',
  doc     => 'Directory for per-request JSON log files (or KNARR_LOG_DIR env)',
  predicate => 'has_log_dir',
);

sub execute {
  my ($self, $args, $chain) = @_;

  my $verbose = $self->verbose_enabled($chain);
  Log::Any::Adapter->set('Stderr', log_level => $verbose ? 'trace' : 'warning');

  require Langertha::Knarr::Config;

  my $config_file = $self->config_file($chain);
  my $config;

  if (-f $config_file) {
    $config = Langertha::Knarr::Config->new(file => $config_file);
    my @errors = $config->validate;
    if (@errors) {
      _err("Configuration errors:");
      _err("  - $_") for @errors;
      exit 1;
    }
    _log("Config: loaded from $config_file");
  } elsif ($self->from_env) {
    _log("Config: auto-detecting from environment variables");
    $config = Langertha::Knarr::Config->from_env(include_test => 0);
  } else {
    print STDERR "Config file not found: $config_file\n";
    print STDERR "\n";
    print STDERR "  knarr init > knarr.yaml        Generate a config from your environment\n";
    print STDERR "  knarr start --from-env         Auto-detect config from environment variables\n";
    print STDERR "\n";
    exit 1;
  }

  my $workers = $self->_workers($config);

  # Inject CLI trace_name into config
  if ($self->has_trace_name) {
    $config->data->{langfuse} //= {};
    $config->data->{langfuse}{trace_name} = $self->trace_name;
  }

  # Inject CLI logging options into config
  if ($self->has_log_file || $self->has_log_dir) {
    $config->data->{logging} //= {};
    $config->data->{logging}{file} = $self->log_file if $self->has_log_file;
    $config->data->{logging}{dir}  = $self->log_dir  if $self->has_log_dir;
  }

  # Build listen addresses
  my $listen_addrs;
  my $h = $self->host;
  my @ports = @{ $self->port };

  if (@ports) {
    $listen_addrs = [ map { "$h:$_" } @ports ];
  } elsif (my $cfg_listen = $config->listen) {
    $listen_addrs = $cfg_listen;
  } else {
    $listen_addrs = [ "$h:8080", "$h:11434" ];
  }

  # Startup banner
  _log("Knarr LLM Proxy starting...");
  _log("");

  # Log discovered engines and models
  my $models = $config->models;
  my $model_count = scalar keys %$models;
  if ($model_count) {
    _log("Engines: $model_count provider(s) configured");
    _log("");
    for my $name (sort keys %$models) {
      my $m = $models->{$name};
      my $line = "  $name";
      $line .= " => $m->{engine}";
      $line .= " / $m->{model}" if $m->{model};
      if ($m->{api_key_env}) {
        $line .= " (key from \$$m->{api_key_env})";
      }
      _log($line);
    }
    _log("");
  } else {
    _log("Engines: none (passthrough only mode)");
  }

  if ($config->auto_discover) {
    _log("Auto-discover: enabled (will query provider model lists)");
  }

  if ($config->default_engine) {
    _log("Default engine: $config->{data}{default}{engine}");
  }

  # Passthrough status
  my $pt = $config->passthrough;
  if (keys %$pt) {
    my @fmts;
    for my $fmt (sort keys %$pt) {
      push @fmts, "$fmt -> $pt->{$fmt}";
    }
    _log("Passthrough: " . join(', ', @fmts));
  } else {
    _log("Passthrough: disabled");
  }

  # Langfuse tracing status
  my $lf_pub = $config->langfuse->{public_key} // _strip_quotes($ENV{LANGFUSE_PUBLIC_KEY});
  my $lf_sec = $config->langfuse->{secret_key} // _strip_quotes($ENV{LANGFUSE_SECRET_KEY});
  my $lf_url = $config->langfuse->{url} // _strip_quotes($ENV{LANGFUSE_URL}) // _strip_quotes($ENV{LANGFUSE_BASE_URL}) // 'https://cloud.langfuse.com';
  if ($lf_pub && $lf_sec) {
    _log("Langfuse: enabled -> $lf_url (" . $config->langfuse_transport . ")");
  } else {
    _log("Langfuse: disabled (set LANGFUSE_PUBLIC_KEY + LANGFUSE_SECRET_KEY to enable)");
  }

  # Proxy auth status
  if ($config->has_proxy_api_key) {
    _log("Proxy auth: enabled (KNARR_API_KEY)");
  } else {
    _log("Proxy auth: open (set KNARR_API_KEY to require authentication)");
  }

  # Request logging status
  my $log_file = $config->log_file;
  my $log_dir  = $config->log_dir;
  if ($log_file || $log_dir) {
    my @parts;
    push @parts, "file: $log_file" if $log_file;
    push @parts, "dir: $log_dir"   if $log_dir;
    _log("Logging: " . join(', ', @parts));
  } else {
    _log("Logging: disabled (set KNARR_LOG_FILE or KNARR_LOG_DIR to enable)");
  }

  _log("");

  # Build server
  require Langertha::Knarr;
  require Langertha::Knarr::Router;
  require Langertha::Knarr::Handler::Router;
  require IO::Async::Loop;

  my $loop = IO::Async::Loop->new;
  my $router = Langertha::Knarr::Router->new( config => $config );

  my $passthrough;
  if ( my $upstreams = $config->passthrough ) {
    if ( %$upstreams ) {
      require Langertha::Knarr::Handler::Passthrough;
      $passthrough = Langertha::Knarr::Handler::Passthrough->new(
        upstreams     => $upstreams,
        loop          => $loop,
        timeout       => $config->upstream_timeout,
        stall_timeout => $config->upstream_stall_timeout,
      );
    }
  }

  my $handler = Langertha::Knarr::Handler::Router->new(
    router => $router,
    ( $passthrough ? ( passthrough => $passthrough ) : () ),
  );

  require Langertha::Knarr::Tracing;
  my $tracing = Langertha::Knarr::Tracing->new( config => $config );
  if ( $tracing->_enabled ) {
    require Langertha::Knarr::Handler::Tracing;
    $handler = Langertha::Knarr::Handler::Tracing->new(
      wrapped => $handler,
      tracing => $tracing,
    );
  }

  require Langertha::Knarr::RequestLog;
  my $rlog = Langertha::Knarr::RequestLog->new( config => $config );
  if ( $rlog->_enabled ) {
    require Langertha::Knarr::Handler::RequestLog;
    $handler = Langertha::Knarr::Handler::RequestLog->new(
      wrapped     => $handler,
      request_log => $rlog,
    );
  }

  my $knarr = Langertha::Knarr->new(
    handler => $handler,
    loop    => $loop,
    listen  => $listen_addrs,
    router  => $router,
    ( $passthrough ? ( raw_passthrough => $passthrough ) : () ),
    ( $tracing->_enabled ? ( tracing => $tracing ) : () ),
    ( $config->has_proxy_api_key ? ( auth_token => $config->proxy_api_key ) : () ),
    ( defined $config->public_url ? ( public_url => $config->public_url ) : () ),
    ( defined $config->ollama_compat_version
      ? ( ollama_compat_version => $config->ollama_compat_version ) : () ),
    protocol_args => $config->protocol_args,
    workers       => $workers,
  );

  _log("Starting server:");
  for my $addr (@$listen_addrs) {
    _log("  http://$addr");
  }
  _log("Workers: $workers") if $workers > 1;
  _log("");

  $knarr->run;
}

# The worker count: -w, else the config's workers: / KNARR_WORKERS (k51).
# A bad value stops start here, before the banner and before any bind.
sub _workers {
  my ($self, $config) = @_;
  if ( $self->has_workers ) {
    return $self->workers if $self->workers >= 1;
    _err("-w/--workers must be 1 or more, got " . $self->workers);
    exit 1;
  }
  my $workers = eval { $config->workers };
  return $workers if defined $workers;
  ( my $err = $@ ) =~ s/ at \S+ line \d+\.?\n?\z//;
  _err($err);
  exit 1;
}

sub _log { print STDERR "[knarr] $_[0]\n" }
sub _err { print STDERR "[knarr] ERROR: $_[0]\n" }

sub _strip_quotes {
  my $v = shift;
  return $v unless defined $v;
  $v =~ s/^["']|["']$//g;
  return $v;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::CLI::Cmd::Start - Start the Knarr proxy server

=head1 VERSION

version 1.102

=head1 DESCRIPTION

Implements the C<knarr start> command. Loads the config file, validates it,
and starts the server.

With C<--from-env>, the config is built automatically from environment
variables when no config file is found — this is how the Docker image starts.

The listen addresses come from C<-p> when given (each port on C<-H>,
default C<0.0.0.0>), otherwise from the config's C<listen:>, which defaults
to C<127.0.0.1:8080> and C<127.0.0.1:11434>. C<-H> alone changes nothing.

C<-w>/C<--workers> I<N> (else the config's C<workers:> or C<KNARR_WORKERS>,
default C<1>; a value below C<1> stops C<start> before the banner) serves
from N processes: Knarr binds
the listen addresses, runs auto-discovery and the capability probe once,
then forks N workers that accept on the same sockets, and supervises them
-- a worker that exits is restarted, C<SIGTERM>/C<SIGINT> stops them all.
Sessions (a Raider conversation) live in one worker and are not routed
back to it. See L<Langertha::Knarr/workers> and L<Langertha::Knarr/run>.

See L<knarr> for the full option reference and L<Langertha::Knarr::Config>
for the configuration file format.

=head1 SEE ALSO

=over

=item * L<knarr> — CLI synopsis and option reference

=item * L<Langertha::Knarr> — Full documentation

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
