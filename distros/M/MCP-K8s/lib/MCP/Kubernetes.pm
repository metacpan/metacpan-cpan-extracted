package MCP::Kubernetes;
# ABSTRACT: MCP Server for Kubernetes (alias for MCP::K8s)
our $VERSION = '0.002';
use Moo;

extends 'MCP::K8s';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Kubernetes - MCP Server for Kubernetes (alias for MCP::K8s)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use MCP::Kubernetes;
  MCP::Kubernetes->run_stdio;

  # Exactly equivalent to:
  use MCP::K8s;
  MCP::K8s->run_stdio;

  # Full OOP usage works identically:
  my $k8s = MCP::Kubernetes->new(
    namespaces => ['default', 'production'],
  );
  $k8s->to_stdio;

=head1 DESCRIPTION

MCP::Kubernetes is L<MCP::K8s>. It's a subclass with no additions — a
longer, more discoverable name on CPAN for the same module.

Every attribute, method, and tool from L<MCP::K8s> works exactly the same:

  MCP::Kubernetes->new(...)      # same as MCP::K8s->new(...)
  MCP::Kubernetes->run_stdio     # same as MCP::K8s->run_stdio
  $obj->isa('MCP::K8s')         # true
  $obj->isa('MCP::Server')      # true — MCP::K8s inherits from MCP::Server

If you're looking for the Kubernetes MCP Server for AI assistants, see
L<MCP::K8s> for the full documentation.

=head1 SEE ALSO

L<MCP::K8s> — Full documentation lives here

L<Kubernetes::REST> — Kubernetes API client

L<IO::K8s> — Kubernetes resource objects

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-mcp-k8s/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
