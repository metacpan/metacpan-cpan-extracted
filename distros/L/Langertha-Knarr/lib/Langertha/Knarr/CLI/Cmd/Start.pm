package Langertha::Knarr::CLI::Cmd::Start;
our $VERSION = '0.004';
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

  my $listen_addrs = $config->listen;

  # Override with CLI options if given
  if ($self->port || $self->host) {
    my $h = $self->host // '127.0.0.1';
    my $p = $self->port // 8080;
    $listen_addrs = ["$h:$p"];
  }

  require Langertha::Knarr;
  my $app = Langertha::Knarr->build_app(config => $config);

  my @listen_urls = map { "http://$_" } @$listen_addrs;

  print "Starting Knarr on:\n";
  print "  $_\n" for @listen_urls;
  print "Models: ", scalar(keys %{$config->models}), " configured";
  print ", auto-discover enabled" if $config->auto_discover;
  print "\n";

  my $daemon = Mojo::Server::Daemon->new(
    app    => $app,
    listen => \@listen_urls,
  );
  $daemon->workers($self->workers) if $daemon->can('workers');
  $daemon->run;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::CLI::Cmd::Start - Start the Knarr proxy server

=head1 VERSION

version 0.004

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

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
