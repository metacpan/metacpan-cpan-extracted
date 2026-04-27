package Langertha::Knarr::CLI::Cmd::Start;
our $VERSION = '1.100';
# ABSTRACT: Start the Knarr proxy server
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: knarr start [options]';
use Log::Any qw( $log );
use Log::Any::Adapter;


option port => (
  is      => 'ro',
  format  => 'i@',
  short   => 'p',
  doc     => 'Port(s) to listen on, repeatable (default: 8080 11434)',
  default => sub { [] },
);

option host => (
  is      => 'ro',
  format  => 's',
  short   => 'H',
  doc     => 'Host to bind to (default: 0.0.0.0)',
  default => '0.0.0.0',
);

option workers => (
  is      => 'ro',
  format  => 'i',
  short   => 'w',
  doc     => 'Number of worker processes (default: 1)',
  default => 1,
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
  my $main = $chain->[0];

  my $verbose = $main->verbose;
  Log::Any::Adapter->set('Stderr', log_level => $verbose ? 'trace' : 'warning');

  require Langertha::Knarr::Config;

  my $config_file = $main->config;
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
    _log("Langfuse: enabled -> $lf_url");
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
        upstreams => $upstreams,
        loop      => $loop,
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
  );

  _log("Starting server:");
  for my $addr (@$listen_addrs) {
    _log("  http://$addr");
  }
  _log("");

  $knarr->run;
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

version 1.100

=head1 DESCRIPTION

Implements the C<knarr start> command. Loads the config file, validates it,
and starts the server.

With C<--from-env>, the config is built automatically from environment
variables when no config file is found — this is how the Docker image starts.

See L<knarr> for the full option reference and L<Langertha::Knarr> for the
configuration file format.

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
