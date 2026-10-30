package Langertha::Raider::MCP::View;
# ABSTRACT: Internal filtered view of a configured MCP server, for a subagent
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Future;


has server => ( is => 'ro', required => 1 );
has allows => ( is => 'ro', isa => 'CodeRef', required => 1 );


sub initialize { $_[0]->server->start_f }


sub loop { return }

sub list_tools {
  my ( $self ) = @_;
  return $self->server->list_tools->then(sub {
    my ( $tools ) = @_;
    return Future->done([ grep { $self->allows->($_->{name}) } @$tools ]);
  });
}

sub call_tool {
  my ( $self, $name, $args ) = @_;
  return Future->fail('tool '.$name.' is not available to this agent') unless $self->allows->($name);
  return $self->server->call_tool($name, $args);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::MCP::View - Internal filtered view of a configured MCP server, for a subagent

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $view = Langertha::Raider::MCP::View->new(
      server => $mcp->client('github'),
      allows => sub { $_[0] eq 'mcp__github__get_issue' },
    );
    my $tools = await $view->list_tools;    # only get_issue

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

A configured MCP server as a subagent sees it (ADR 0029 E<sect>11): the
same connection (no second process), only the tools L</allows> lets
through. It answers C<initialize>, C<list_tools> and C<call_tool> like
L<Langertha::Raider::MCP::Server>; a call of a tool it hides fails. A
view that hides every tool still takes its place in the engine's
C<mcp_servers>, so the C<engine:N> of the servers after it are those of
the caller.

=head2 server

The L<Langertha::Raider::MCP::Server>. Required.

=head2 allows

C<< sub { my ( $tool_name ) = @_; ... } >>: true for a tool (by the name
the model sees) the view lets through. Required.

=head2 initialize

=head2 list_tools

=head2 call_tool

As L<Langertha::Raider::MCP::Server>, filtered.

=head2 loop

C<undef>: a view is no L<IO::Async::Notifier>, so code that takes its
MCP clients out of the loop when a subagent is done leaves it (and the
caller's connection) alone.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::MCP/views>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

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

L<https://raudssus.de/>

=cut
