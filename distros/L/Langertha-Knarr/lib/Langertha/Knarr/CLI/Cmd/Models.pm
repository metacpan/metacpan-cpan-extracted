package Langertha::Knarr::CLI::Cmd::Models;
our $VERSION = '1.100';
# ABSTRACT: List configured models and their backends
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: knarr models [options]';


option format => (
  is      => 'ro',
  format  => 's',
  short   => 'f',
  doc     => 'Output format: table, json (default: table)',
  default => 'table',
);

sub execute {
  my ($self, $args, $chain) = @_;
  my $main = $chain->[0];
  my $config_file = $main->config;

  unless (-f $config_file) {
    print STDERR "Config file not found: $config_file\n";
    exit 1;
  }

  require Langertha::Knarr::Config;
  require Langertha::Knarr::Router;

  my $config = Langertha::Knarr::Config->new(file => $config_file);
  my $router = Langertha::Knarr::Router->new(config => $config);
  my $models = $router->list_models;

  if ($self->format eq 'json') {
    require JSON::MaybeXS;
    print JSON::MaybeXS->new(pretty => 1, utf8 => 1, convert_blessed => 1)->encode($models);
    return;
  }

  # Table format
  unless (@$models) {
    print "No models configured.\n";
    print "Run 'knarr init' to scan your environment for API keys.\n";
    return;
  }

  my $max_id     = _max_len(map { $_->{id} } @$models);
  my $max_engine = _max_len(map { $_->{engine} } @$models);
  my $max_model  = _max_len(map { $_->{model} } @$models);

  $max_id     = 5  if $max_id < 5;
  $max_engine = 6  if $max_engine < 6;
  $max_model  = 5  if $max_model < 5;

  printf "%-${max_id}s  %-${max_engine}s  %-${max_model}s  %s\n",
    'ID', 'ENGINE', 'MODEL', 'SOURCE';
  printf "%-${max_id}s  %-${max_engine}s  %-${max_model}s  %s\n",
    '-' x $max_id, '-' x $max_engine, '-' x $max_model, '------';

  for my $m (@$models) {
    printf "%-${max_id}s  %-${max_engine}s  %-${max_model}s  %s\n",
      $m->{id}, $m->{engine}, $m->{model}, $m->{source};
  }

  if (my $default = $config->default_engine) {
    print "\nDefault engine: $default->{engine}\n";
  }
}

sub _max_len {
  my $max = 0;
  for (@_) {
    my $l = length($_ // '');
    $max = $l if $l > $max;
  }
  return $max;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::CLI::Cmd::Models - List configured models and their backends

=head1 VERSION

version 1.100

=head1 DESCRIPTION

Implements the C<knarr models> command. Loads the config file, triggers
auto-discovery (if enabled), and prints the full model list as a table or
JSON. Each row shows the model ID, engine class, backend model name, and
whether it was explicitly configured or auto-discovered.

See L<knarr> for option details and L<Langertha::Knarr> for full documentation.

=head1 SEE ALSO

=over

=item * L<knarr> — CLI synopsis and option reference

=item * L<Langertha::Knarr::Router/list_models> — Underlying data source

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
