package Langertha::Knarr::CLI::Cmd::Init;
our $VERSION = '0.004';
# ABSTRACT: Scan environment and generate Knarr configuration
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: knarr init [options]';


option env_file => (
  is      => 'ro',
  format  => 's@',
  short   => 'e',
  doc     => 'Additional .env file(s) to scan (repeatable)',
  default => sub { [] },
);

option listen => (
  is      => 'ro',
  format  => 's@',
  short   => 'l',
  doc     => 'Listen address(es), repeatable (default: 127.0.0.1:8080 + 127.0.0.1:11434)',
  default => sub { ['127.0.0.1:8080', '127.0.0.1:11434'] },
);

option output => (
  is      => 'ro',
  format  => 's',
  short   => 'o',
  doc     => 'Output file (default: stdout)',
);

sub execute {
  my ($self, $args, $chain) = @_;

  require Langertha::Knarr::Config;

  # Scan default .env locations too
  my @env_files = @{$self->env_file};
  for my $default_file ('.env', '.env.local', "$ENV{HOME}/.env") {
    push @env_files, $default_file if -f $default_file;
  }

  my $found = Langertha::Knarr::Config->scan_env(env_files => \@env_files);

  my $yaml = Langertha::Knarr::Config->generate_config(
    engines => $found,
    listen  => $self->listen,
  );

  if (my $out = $self->output) {
    open my $fh, '>', $out or die "Cannot write $out: $!";
    print $fh $yaml;
    close $fh;
    my $count = scalar keys %$found;
    print STDERR "Generated $out with $count engine(s) found\n";
    print STDERR "Found: ", join(', ', sort keys %$found), "\n" if $count;
  } else {
    print $yaml;
    my $count = scalar keys %$found;
    print STDERR "# Found $count engine(s) from environment\n";
    print STDERR "# Engines: ", join(', ', sort keys %$found), "\n" if $count;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::CLI::Cmd::Init - Scan environment and generate Knarr configuration

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Implements the C<knarr init> command. Scans C<%ENV> and any C<.env> files
for known API key variables (C<.env> and C<.env.local> in the current
directory are always scanned), then generates a complete YAML configuration
and writes it to stdout or a file.

    knarr init > knarr.yaml
    knarr init -e .env.production -o production.yaml

See L<knarr> for full option details, L<Langertha::Knarr::Config/scan_env>
for the env scanning logic, and L<Langertha::Knarr> for the config format.

=head1 SEE ALSO

=over

=item * L<knarr> — CLI synopsis and option reference

=item * L<Langertha::Knarr::Config/scan_env> — API key detection

=item * L<Langertha::Knarr::Config/generate_config> — YAML generation

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
