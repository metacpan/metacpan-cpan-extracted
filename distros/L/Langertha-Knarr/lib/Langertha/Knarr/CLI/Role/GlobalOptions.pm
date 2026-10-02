package Langertha::Knarr::CLI::Role::GlobalOptions;
our $VERSION = '1.102';
# ABSTRACT: Accept knarr's global -c/-v options after the subcommand too
use Moo::Role;
use MooX::Options;


option config => (
  is        => 'ro',
  format    => 's',
  short     => 'c',
  doc       => 'Config file path (default: ./knarr.yaml)',
  predicate => 'has_config',
);


option verbose => (
  is        => 'ro',
  short     => 'v',
  doc       => 'Enable verbose logging (or set KNARR_DEBUG=1)',
  negatable => 1,
  predicate => 'has_verbose',
);


sub config_file {
  my ( $self, $chain ) = @_;
  return $self->has_config ? $self->config : $chain->[0]->config;
}


sub verbose_enabled {
  my ( $self, $chain ) = @_;
  return $self->has_verbose ? $self->verbose : $chain->[0]->verbose;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::CLI::Role::GlobalOptions - Accept knarr's global -c/-v options after the subcommand too

=head1 VERSION

version 1.102

=head1 DESCRIPTION

L<MooX::Cmd> hands every argument before the subcommand name to
L<Langertha::Knarr::CLI> and every argument after it to the subcommand, so
the global C<-c>/C<--config> and C<-v>/C<--verbose> options would only work
in front of the subcommand (C<knarr -c prod.yaml start>). Composing this
role into a subcommand declares the same two options there as well, so the
documented form C<knarr start -c prod.yaml -v> works too.

A value given after the subcommand wins over one given before it. Commands
read the effective values through L</config_file> and L</verbose_enabled>,
never through the global object directly.

=head2 --config

Same as the global C<-c>/C<--config>, accepted after the subcommand.

=head2 --verbose

Same as the global C<-v>/C<--verbose>, accepted after the subcommand.
C<--no-verbose> switches it off again, also against C<KNARR_DEBUG=1>.

=head2 config_file

    my $file = $self->config_file($chain);

Returns the config file path: the subcommand's own C<--config> when given,
otherwise the global one from the first element of the L<MooX::Cmd> command
chain (which carries the C<./knarr.yaml> default).

=head2 verbose_enabled

    Log::Any::Adapter->set( 'Stderr',
      log_level => $self->verbose_enabled($chain) ? 'trace' : 'warning' );

Returns whether verbose logging is on: the subcommand's own
C<--verbose>/C<--no-verbose> when given, otherwise the global setting.

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
