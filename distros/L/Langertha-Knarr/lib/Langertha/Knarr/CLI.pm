package Langertha::Knarr::CLI;
# ABSTRACT: CLI entry point for Knarr LLM Proxy
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;


our $VERSION = '1.100';

option config => (
  is      => 'ro',
  format  => 's',
  short   => 'c',
  doc     => 'Config file path (default: ./knarr.yaml)',
  default => sub { './knarr.yaml' },
);


option verbose => (
  is      => 'ro',
  short   => 'v',
  doc     => 'Enable verbose logging (or set KNARR_DEBUG=1)',
  default => sub { $ENV{KNARR_DEBUG} ? 1 : 0 },
  negativable => 1,
);


sub execute {
  my ($self) = @_;
  print _banner();
  print "\n";
  print "USAGE\n";
  print "  knarr <command> [options]\n\n";
  print "COMMANDS\n";
  print "  start       Start the proxy server\n";
  print "  init        Scan environment and generate configuration\n";
  print "  models      List configured models and their backends\n";
  print "  check       Validate configuration file\n\n";
  print "GLOBAL OPTIONS\n";
  print "  -c, --config <path>   Config file (default: ./knarr.yaml)\n";
  print "  -v, --verbose         Enable verbose logging\n\n";
  print "QUICK START (Docker)\n";
  print "  docker run -e OPENAI_API_KEY=sk-... -p 8080:8080 raudssus/langertha-knarr\n\n";
  print "QUICK START (Local)\n";
  print "  knarr init > knarr.yaml\n";
  print "  knarr start\n\n";
  print "EXAMPLES\n";
  print "  knarr start                              # Start with ./knarr.yaml\n";
  print "  knarr start -c production.yaml -p 9090   # Custom config and port\n";
  print "  knarr start --from-env                   # Auto-detect from ENV\n";
  print "  knarr start --from-env -p 8080 -p 11434  # ENV config, custom ports\n";
  print "  knarr init > knarr.yaml                   # Generate config\n";
  print "  knarr models                              # List configured models\n";
  print "  knarr check                               # Validate config\n\n";
  print "ENVIRONMENT\n";
  print "  OPENAI_API_KEY        OpenAI API key\n";
  print "  ANTHROPIC_API_KEY     Anthropic API key\n";
  print "  LANGFUSE_PUBLIC_KEY   Langfuse public key (enables tracing)\n";
  print "  LANGFUSE_SECRET_KEY   Langfuse secret key\n";
  print "  LANGFUSE_URL          Langfuse URL (default: https://cloud.langfuse.com)\n";
  print "  KNARR_API_KEY         Proxy authentication key (optional)\n\n";
  print "Version $VERSION | https://github.com/Getty/langertha-knarr\n";
}

sub _banner {
  return <<'BANNER';
         .  *  .
        . _/|_ .          KNARR
     .  /|    |\ .        Langertha LLM Proxy
   ~~~~~|______|~~~~~
   ~~ ~~~~~~~~~~~~~ ~~    Cargo transport for your LLM calls
   ~~~~~~~~~~~~~~~~~~~~
BANNER
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::CLI - CLI entry point for Knarr LLM Proxy

=head1 VERSION

version 1.100

=head1 DESCRIPTION

MooX::Cmd entry point for the C<knarr> CLI. Dispatches to subcommand classes
under C<Langertha::Knarr::CLI::Cmd::*>. When invoked without a subcommand,
prints a banner and usage summary.

For full CLI documentation see L<knarr> and L<Langertha::Knarr>.

=head1 SEE ALSO

=over

=item * L<knarr> — CLI synopsis and option reference

=item * L<Langertha::Knarr> — Full documentation

=item * L<Langertha::Knarr::CLI::Cmd::Start> — C<knarr start>

=item * L<Langertha::Knarr::CLI::Cmd::Init> — C<knarr init>

=item * L<Langertha::Knarr::CLI::Cmd::Models> — C<knarr models>

=item * L<Langertha::Knarr::CLI::Cmd::Check> — C<knarr check>

=back

=head2 --config

Path to the YAML configuration file. Short form: C<-c>. Defaults to
C<./knarr.yaml>. Applies to all subcommands.

=head2 --verbose

Enable verbose logging to stderr. Short form: C<-v>. Applies to all
subcommands.

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
