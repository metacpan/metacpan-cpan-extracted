package Langertha::Knarr::CLI::Cmd::Start;
our $VERSION = '1.000';
# ABSTRACT: Start the Knarr proxy server
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: knarr start [options]';
use Log::Any qw( $log );
use Log::Any::Adapter;


option port => (
  is      => 'ro',
  format  => 'i',
  short   => 'p',
  doc     => 'Port to listen on (default: from config or 8080)',
);

option host => (
  is      => 'ro',
  format  => 's',
  short   => 'H',
  doc     => 'Host to bind to (default: from config or 127.0.0.1)',
);

option workers => (
  is      => 'ro',
  format  => 'i',
  short   => 'w',
  doc     => 'Number of worker processes (default: 1)',
  default => 1,
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
  Log::Any::Adapter->set('Stderr') if $verbose;

  my $config_file = $main->config;
  my $config;

  require Langertha::Knarr::Config;

  unless (-f $config_file) {
    print STDERR "Config file not found: $config_file\n";
    print STDERR "\n";
    print STDERR "  knarr init > knarr.yaml    Generate a config from your environment\n";
    print STDERR "  knarr container            Auto-start from environment variables (Docker mode)\n";
    print STDERR "\n";
    exit 1;
  }

  $config = Langertha::Knarr::Config->new(file => $config_file);

  my @errors = $config->validate;
  if (@errors) {
    print STDERR "Configuration errors:\n";
    print STDERR "  - $_\n" for @errors;
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

  my $listen_addrs = $config->listen;

  # Override with CLI options if given
  if ($self->port || $self->host) {
    my $h = $self->host // '127.0.0.1';
    my $p = $self->port // 8080;
    $listen_addrs = ["$h:$p"];
  }

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

  # Wrap with tracing decorator when langfuse credentials are configured.
  require Langertha::Knarr::Tracing;
  my $tracing = Langertha::Knarr::Tracing->new( config => $config );
  if ( $tracing->_enabled ) {
    require Langertha::Knarr::Handler::Tracing;
    $handler = Langertha::Knarr::Handler::Tracing->new(
      wrapped => $handler,
      tracing => $tracing,
    );
  }

  # Wrap with request log decorator when log_file or log_dir is configured.
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
    listen  => [ @$listen_addrs ],
    ( $config->has_proxy_api_key ? ( auth_token => $config->proxy_api_key ) : () ),
  );

  print "Starting Knarr on:\n";
  print "  http://$_\n" for @$listen_addrs;
  print "Models: ", scalar(keys %{$config->models}), " configured";
  print ", auto-discover enabled" if $config->auto_discover;
  print "\n";

  $knarr->run;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::CLI::Cmd::Start - Start the Knarr proxy server

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Implements the C<knarr start> command. Loads the config file, validates it,
and starts the Mojolicious server. Exits with an error if the config file is
not found or fails validation.

See L<knarr> for the full option reference and L<Langertha::Knarr> for the
configuration file format.

=head1 SEE ALSO

=over

=item * L<knarr> — CLI synopsis and option reference

=item * L<Langertha::Knarr> — Full documentation

=item * L<Langertha::Knarr::CLI::Cmd::Container> — Zero-config Docker mode

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
