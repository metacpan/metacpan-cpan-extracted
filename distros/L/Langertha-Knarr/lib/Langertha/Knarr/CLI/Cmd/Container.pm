package Langertha::Knarr::CLI::Cmd::Container;
our $VERSION = '1.001';
# ABSTRACT: Alias for 'knarr start --from-env' (Docker mode)
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: knarr container [options]';


sub execute {
  my ($self, $args, $chain) = @_;
  print STDERR "[knarr] NOTE: 'knarr container' is now 'knarr start --from-env'\n";
  require Langertha::Knarr::CLI::Cmd::Start;
  my $start = Langertha::Knarr::CLI::Cmd::Start->new(
    from_env => 1,
    host     => '0.0.0.0',
    port     => [],
    workers  => 1,
  );
  $start->execute($args, $chain);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::CLI::Cmd::Container - Alias for 'knarr start --from-env' (Docker mode)

=head1 VERSION

version 1.001

=head1 DESCRIPTION

Deprecated alias for C<knarr start --from-env>. Kept for backwards
compatibility with existing Docker images. All options are forwarded to
L<Langertha::Knarr::CLI::Cmd::Start>.

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
