package Langertha::Raider::MCP;
# ABSTRACT: Internal set of the configured MCP servers of one application
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Future;
use Scalar::Util qw( refaddr );
use Langertha::Raider::MCP::Config;
use Langertha::Raider::MCP::Server;
use Langertha::Raider::MCP::View;


has config     => ( is => 'ro', isa => 'Langertha::Raider::MCP::Config', required => 1 );
has loop       => ( is => 'ro', required => 1 );
has kill_grace => ( is => 'ro', isa => 'Num', default => 2 );
has on_status  => ( is => 'ro', isa => 'Maybe[CodeRef]' );
has on_tools_changed => ( is => 'ro', isa => 'Maybe[CodeRef]' );

sub server_class { 'Langertha::Raider::MCP::Server' }


has clients => ( is => 'ro', isa => 'ArrayRef', lazy_build => 1 );


has previous => ( is => 'ro', isa => 'Maybe[Langertha::Raider::MCP]', clearer => '_clear_previous' );

sub _new_client {
  my ( $self, $spec ) = @_;
  my $config = $self->config;
  my $on_status = $self->on_status;
  return $self->server_class->new(
    spec               => $spec,
    loop               => $self->loop,
    startup_timeout_ms => $config->startup_timeout_ms,
    base_env           => $config->env,
    kill_grace         => $self->kill_grace,
    max_output_tokens  => $config->max_output_tokens,
    ( $self->on_tools_changed ? ( on_tools_changed => $self->on_tools_changed ) : () ),
    ( $on_status ? ( on_status => $on_status ) : () ),
  );
}

sub _build_clients {
  my ( $self ) = @_;
  my @clients = map { $self->_new_client($_) } $self->config->startable;
  if (my $previous = $self->previous) {
    my $old = $previous->has_clients ? $previous->clients : [];
    my %reusable = map { $_->fingerprint => $_ } grep { $_->status =~ /\A(?:starting|connected)\z/ } @$old;
    @clients = map { delete $reusable{ $_->fingerprint } // $_ } @clients;
    my %taken = map { ( refaddr $_ ) => 1 } @clients;
    @$old = grep { !$taken{ refaddr $_ } } @$old;
    $self->_clear_previous;
  }
  return \@clients;
}


sub replace {
  my ( $self, $name ) = @_;
  my $clients = $self->clients;
  my ( $i ) = grep { $clients->[$_]->name eq $name } 0 .. $#$clients;
  return unless defined $i;
  my $old = $clients->[$i];
  $clients->[$i] = $self->_new_client($old->spec);
  return ( $old, $clients->[$i] );
}


sub pids {
  my ( $self ) = @_;
  return unless $self->has_clients;
  return grep { defined } map { $_->pid } @{ $self->clients };
}


sub notes {
  my ( $self ) = @_;
  my $config = $self->config;
  my $target = $config->approval_target;
  my $where = !$target ? 'approve it in an interactive raider'
    : $target->{kind} eq 'claude-settings'
      ? 'approve it in an interactive raider, or add it to enabledMcpjsonServers in '.$target->{label}
      : 'approve it in an interactive raider, or add it to mcp_approvals of '.$target->{label};
  return map { 'mcp: server '.$_->{name}.' ('.$_->{source}.') is not approved and stays off; '.$where }
    $config->pending;
}


sub client {
  my ( $self, $name ) = @_;
  my ( $c ) = grep { $_->name eq $name } @{ $self->clients };
  return $c;
}


sub source_servers {
  my ( $self ) = @_;
  my $n = 0;
  return { map { ( 'engine:'.++$n => $_->key ) } @{ $self->clients } };
}


sub views {
  my ( $self, %arg ) = @_;
  my $covers = sub {
    my ( $list, $name ) = @_;
    for my $entry (@{ $list // [] }) {
      next unless defined $entry && !ref $entry && $entry =~ /\Amcp__/;
      return 1 if $entry eq $name;
      ( my $server = $entry ) =~ s/__\*\z//;
      return 1 if $server !~ /\Amcp__.+__/ && index($name, $server.'__') == 0;
    }
    return 0;
  };
  my ( $tools, $denied ) = @arg{qw( tools disallowed )};
  my $allows = sub {
    my ( $name ) = @_;
    return 0 if $covers->($denied, $name);
    return !defined $tools || $covers->($tools, $name) ? 1 : 0;
  };
  return map { Langertha::Raider::MCP::View->new( server => $_, allows => $allows ) } @{ $self->clients };
}


sub start_f {
  my ( $self ) = @_;
  my @f = map { $_->start_f } @{ $self->clients };
  return Future->done unless @f;
  return Future->wait_all(@f)->then_done;
}


sub report {
  my ( $self ) = @_;
  my %client = map { $_->name => $_ } @{ $self->clients };
  return [ map {
    my %row = %$_;
    if (my $c = $client{ $row{name} }) {
      %row = (
        %row,
        status           => $c->status,
        reason           => $c->reason,
        tools            => [ $c->tool_names ],
        protocol_version => $c->protocol_version,
        server_info      => $c->server_info,
        stderr           => [ $c->stderr_tail ],
        warnings         => [ @{ $row{warnings} }, @{ $c->warnings } ],
      );
    }
    else {
      $row{tools} = [];
    }
    \%row;
  } @{ $self->config->servers } ];
}


sub stop_f {
  my ( $self ) = @_;
  return Future->done unless $self->has_clients;
  my @f = map { $_->stop_f } @{ $self->clients };
  return Future->done unless @f;
  return Future->wait_all(@f)->then_done;
}

sub DEMOLISH {
  my ( $self ) = @_;
  return unless $self->has_clients;
  # Also at global destruction: no server process outlives raider.
  $_->kill_now for grep { defined } @{ $self->clients };
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::MCP - Internal set of the configured MCP servers of one application

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $mcp = Langertha::Raider::MCP->new(
      config    => Langertha::Raider::MCP::Config->from_context( $context, config => $config ),
      loop      => $loop,
      on_status => sub { my ( $server ) = @_; ... },
    );
    my @clients = @{ $mcp->clients };     # engine mcp_servers, before raider's own
    my $gate    = $mcp->source_servers;   # { 'engine:1' => 'github', ... }
    await $mcp->start_f;                  # every server, in parallel, never fails
    for my $row (@{ $mcp->report }) { say $row->{name}.': '.$row->{status} }
    await $mcp->stop_f;

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The configured MCP servers of an application (ADR 0029): one
L<Langertha::Raider::MCP::Server> for every server of the
L<Langertha::Raider::MCP::Config> that may start (status C<configured>), in
the model's order. L</start_f> starts them all at once, each bounded by
C<MCP_TIMEOUT>; a server that fails is reported, never fatal.

The clients go to the front of the engine's C<mcp_servers>, so the
C<engine:N> source of their tools is the same N in every engine built from
that list, whatever raider's own servers do; L</source_servers> names them
for the permission gate (L<Langertha::Raider::Permissions/source_servers>).
Their tool names all start with C<mcp__>, which no tool of raider's own
does, so they never shadow one.

=head2 config

The L<Langertha::Raider::MCP::Config>. Required.

=head2 loop

The L<IO::Async::Loop> the servers run on. Required.

=head2 kill_grace

Seconds a stdio server gets between closing stdin, C<TERM> and C<KILL>.
Default 2.

=head2 on_status

C<< sub { my ( $server ) = @_; ... } >>, called whenever a server's status
changes. Optional.

=head2 on_tools_changed

C<< sub { my ( $server ) = @_; ... } >>, called when a server announced
C<notifications/tools/list_changed> (its tools are listed again at once;
L<Langertha::Raider::MCP::Server/list_tools> waits for that). Optional.

=head2 clients

The L<Langertha::Raider::MCP::Server> objects, one per startable server.

=head2 previous

The set this one replaces (C</reload>): a client of it whose server is
configured exactly as before (L<Langertha::Raider::MCP::Server/fingerprint>)
and is starting or connected is taken over instead of started again, and
leaves the old set's L</clients>. What stays there is the old set's to stop
(L</stop_f>). Optional; read when L</clients> is built.

=head2 replace

    my ( $old, $new ) = $mcp->replace('github');

A fresh client for the server of that name, in the same place of
L</clients> (so the same C<engine:N>), for C</mcp reconnect>. Returns the
old client (to be stopped) and the new one (not started), or nothing for
an unknown name.

=head2 pids

The process ids of the running stdio servers (each leads its own process
group).

=head2 notes

    warn "$_\n" for $mcp->notes;

One line per server that waits for an approval nobody can give here (a
one-shot run, machine output, the hall, ACP): it stays off, and the line
says how to approve it (ADR 0029 E<sect>7).

=head2 client

    my $server = $mcp->client('github');

The client of the server with that name, or C<undef>.

=head2 source_servers

    my $map = $mcp->source_servers;   # { 'engine:1' => 'github', 'engine:2' => 'plugin_p_db' }

The tool sources of the clients as L<Langertha::Raider> numbers them when
they lead the engine's C<mcp_servers>, each with the server part of its
tool names, the name C<mcp__SERVER> rules use.

=head2 views

    my @views = $mcp->views( tools => $agent->{tools}, disallowed => $agent->{disallowed} );

The clients as a subagent sees them (L<Langertha::Raider::MCP::View>), one
per client in the same order, so they lead the subagent's engine with the
same C<engine:N> as the caller's (the policy of
L<Langertha::Raider::Permissions/for_subrun> keeps L</source_servers>).
C<tools> is the agent's allowlist (C<undef>: every tool), C<disallowed> its
denylist; an entry names a tool (C<mcp__server__tool>) or a whole server
(C<mcp__server>, C<mcp__server__*>). Names that are not C<mcp__> names
concern raider's own tools and are ignored here.

=head2 start_f

    await $mcp->start_f;

Starts every client in parallel (each bounded by its startup timeout);
done when all have connected or failed. Never fails.

=head2 report

    for my $row (@{ $mcp->report }) { ... }

Every server of the configuration, startable or not, in its order: its
entry of L<Langertha::Raider::MCP::Config/servers> (C<name>, C<scope>,
C<source>, C<transport>, C<approval>, C<warnings>, ...) with C<status> and
C<reason> of the client when there is one (C<configured>, C<starting>,
C<connected>, C<failed>, C<stopped>), its C<tools> (prefixed names),
C<protocol_version>, C<server_info> and C<stderr> (the last lines).

=head2 stop_f

    await $mcp->stop_f;

Stops every client (L<Langertha::Raider::MCP::Server/stop_f>); done when
all are gone.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::MCP::Config>

=item * L<Langertha::Raider::MCP::Server>

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
