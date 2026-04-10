package Langertha::Knarr::Session;
# ABSTRACT: Per-conversation state for a Knarr server
our $VERSION = '1.000';
use Moose;
use Time::HiRes qw( time );


has id => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has messages => (
  is => 'rw',
  isa => 'ArrayRef',
  default => sub { [] },
);

has metadata => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { {} },
);

has handler_state => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { {} },
);

has created_at => (
  is => 'ro',
  isa => 'Num',
  default => sub { time() },
);

has last_active => (
  is => 'rw',
  isa => 'Num',
  default => sub { time() },
);

sub touch { $_[0]->last_active( time() ) }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Session - Per-conversation state for a Knarr server

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Per-conversation state object that Knarr passes to handlers. Sessions
are created on demand by the Knarr core (one per unique session id
seen in incoming requests) and reused across multiple turns. Handlers
that need to remember state across turns store it in
L</handler_state>; for example L<Langertha::Knarr::Handler::Raider>
caches its per-session L<Langertha::Raider> instance there.

=head2 id

Required. The unique session id, typically supplied by the client via
the C<x-session-id> header or extracted from a protocol-specific field.

=head2 messages

ArrayRef of message hashes, free-form for handlers that want to keep
their own conversation history (most don't — Raider keeps its own).

=head2 metadata

HashRef for arbitrary per-session tags. Handlers and middlewares can
read or write this without coordinating with each other.

=head2 handler_state

HashRef where decorator handlers can stash per-session state without
colliding with each other. Convention: key by handler class name.

=head2 created_at

Numeric epoch seconds when the session was first seen.

=head2 last_active

Numeric epoch seconds, updated by L</touch> on every request.

=head2 touch

Updates L</last_active> to the current time. Called by the Knarr core
on every dispatch.

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
