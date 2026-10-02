package Langertha::Knarr::CLI::Cmd::Container;
our $VERSION = '1.102';
# ABSTRACT: Alias for 'knarr start --from-env -p 8080 -p 11434' (Docker mode)
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: knarr container [options]';
use Langertha::Knarr::CLI::Cmd::Start;


sub execute {
  my ($self, $args, $chain) = @_;
  print STDERR "[knarr] NOTE: 'knarr container' is now 'knarr start --from-env -p 8080 -p 11434'\n";
  $self->start_command->execute($args, $chain);
}

# The start command this alias runs: the Docker image's own (k46).
sub start_command {
  my ($self) = @_;
  return Langertha::Knarr::CLI::Cmd::Start->new(
    from_env => 1,
    host     => '0.0.0.0',
    port     => [ 8080, 11434 ],
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::CLI::Cmd::Container - Alias for 'knarr start --from-env -p 8080 -p 11434' (Docker mode)

=head1 VERSION

version 1.102

=head1 DESCRIPTION

Deprecated alias for C<knarr start --from-env -p 8080 -p 11434>, the
Docker image's own command. Kept for backwards compatibility with existing
Docker setups that still run C<knarr container>. It takes no options of its
own (C<-p> and the other C<start> options are refused; the global
C<-c>/C<-v> before the subcommand still apply) and always listens on
C<0.0.0.0:8080> and C<0.0.0.0:11434>. For other ports use
C<knarr start --from-env -p ...>.

=head2 start_command

    my $start = $container->start_command;

The L<Langertha::Knarr::CLI::Cmd::Start> object C<execute> runs:
C<--from-env> on C<0.0.0.0> ports C<8080> and C<11434>, with the worker
count of the config's C<workers:> or C<KNARR_WORKERS>.

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
