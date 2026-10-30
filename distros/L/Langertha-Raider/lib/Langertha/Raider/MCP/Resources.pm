package Langertha::Raider::MCP::Resources;
# ABSTRACT: Internal MCP resources of the configured servers: list/read tools and @server:uri mentions
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use JSON::MaybeXS ();
use MCP::Server;


has servers => ( is => 'ro', isa => 'CodeRef', required => 1 );
has loop    => ( is => 'ro', required => 1 );

sub _json { JSON::MaybeXS->new( canonical => 1, utf8 => 0, convert_blessed => 1 ) }

# The connected servers that announced resources.
sub _capable {
  my ( $self ) = @_;
  return grep { $_->status eq 'connected' && $_->has_resources } @{ $self->servers->() };
}

sub _find {
  my ( $self, $name ) = @_;
  return unless defined $name && length $name;
  my ( $s ) = grep { $_->name eq $name || ( defined $_->key && $_->key eq $name ) } @{ $self->servers->() };
  return $s;
}

sub _await {
  my ( $self, $f ) = @_;
  $self->loop->await($f);
  return $f->get;
}


sub list {
  my ( $self, $name ) = @_;
  my @servers = $self->_capable;
  if ( defined $name && length $name ) {
    my $s = $self->_find($name);
    die 'Server "'.$name.'" not found. Available servers: '
      .join( ', ', map { $_->name } @{ $self->servers->() } )."\n" unless $s;
    @servers = grep { $_ == $s } @servers;
  }
  my @out;
  for my $s (@servers) {
    my $items = eval { $self->_await( $s->list_resources_f ) } // [];
    push @out, map { +{ server => $s->name, uri => $_->{uri}, name => $_->{name}, mimeType => $_->{mimeType},
      ( defined $_->{description} ? ( description => $_->{description} ) : () ) } } @$items;
  }
  return \@out;
}


sub read {
  my ( $self, $name, $uri ) = @_;
  my $s = $self->_find($name)
    or die 'Server "'.( $name // '' ).'" not found. Available servers: '
      .join( ', ', map { $_->name } @{ $self->servers->() } )."\n";
  die 'Server "'.$s->name."\" has no resources (not connected or none announced)\n" unless $s->has_resources;
  my $contents = $self->_await( $s->read_resource_f($uri) );
  return join "\n", map {
    defined $_->{text} && !ref $_->{text} ? $_->{text}
      : defined $_->{blob} ? '[binary content: '.int( length( $_->{blob} ) * 3 / 4 ).' bytes'
          .( defined $_->{mimeType} ? ', '.$_->{mimeType} : '' ).'; not shown]'
      : ''
  } @$contents;
}


sub attachments {
  my ( $self, $text ) = @_;
  return unless defined $text && $text =~ /@/ && $self->_capable;
  my ( @out, %seen );
  while ( $text =~ m{(?<![\w@])@([A-Za-z0-9_:.-]+?):([A-Za-z][A-Za-z0-9+.-]*://\S+)}g ) {
    my ( $name, $uri ) = ( $1, $2 );
    my $s = $self->_find($name) // next;
    next unless $s->status eq 'connected' && $s->has_resources;
    my $body;
    for my $try ( $uri, ( $uri =~ /\A(.+?)[.,;:!?)]+\z/ ? $1 : () ) ) {
      next if $seen{ $s->name."\0".$try };
      $body = eval { $self->read( $s->name, $try ) };
      if ( defined $body ) { $uri = $try; last }
    }
    next unless defined $body;
    next if $seen{ $s->name."\0".$uri }++;
    push @out, join "\n",
      '<system-reminder>',
      'Called the read_mcp_resource tool with the following input: '
        .$self->_json->encode({ server => $s->name, uri => $uri }),
      '</system-reminder>',
      '<system-reminder>',
      'Result of calling the read_mcp_resource tool:',
      $body,
      '</system-reminder>';
  }
  return @out;
}


has _tool_server => ( is => 'ro', init_arg => undef, lazy_build => 1 );

sub tool_server { $_[0]->_tool_server }

sub _build__tool_server {
  my ( $self ) = @_;
  my $server = MCP::Server->new( name => 'raider-mcp-resources', version => '1.0' );
  $server->tool(
    name         => 'list_mcp_resources',
    description  => 'Lists available resources from configured MCP servers. Each resource object '
      .'includes a "server" field indicating which server it is from. Use read_mcp_resource to read one.',
    input_schema => {
      type       => 'object',
      properties => { server => { type => 'string', description => 'Optional server name to filter resources by' } },
    },
    code => sub {
      my ( $tool, $in ) = @_;
      my $items = eval { $self->list( ref $in->{server} ? undef : $in->{server} ) };
      return $tool->text_result( ( split /\n/, $@ )[0] // 'cannot list resources', 1 ) unless $items;
      return $tool->text_result('No resources found. MCP servers may still provide tools even if they have no resources.')
        unless @$items;
      return $tool->text_result( $self->_json->encode($items) );
    },
  );
  $server->tool(
    name         => 'read_mcp_resource',
    description  => 'Reads a specific resource from an MCP server, identified by server name and resource URI.',
    input_schema => {
      type       => 'object',
      properties => {
        server => { type => 'string', description => 'The MCP server name' },
        uri    => { type => 'string', description => 'The resource URI to read' },
      },
      required => [qw( server uri )],
    },
    code => sub {
      my ( $tool, $in ) = @_;
      for my $k (qw( server uri )) {
        return $tool->text_result( $k.' is required', 1 ) unless defined $in->{$k} && !ref $in->{$k} && length $in->{$k};
      }
      my $text = eval { $self->read( $in->{server}, $in->{uri} ) };
      return $tool->text_result( ( split /\n/, $@ )[0] // 'cannot read the resource', 1 ) unless defined $text;
      return $tool->text_result($text);
    },
  );
  return $server;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::MCP::Resources - Internal MCP resources of the configured servers: list/read tools and @server:uri mentions

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $res = Langertha::Raider::MCP::Resources->new(
      servers => sub { $mcp->clients },    # the connected-or-not configured servers
      loop    => $loop,
    );
    my $server = $res->tool_server;        # list_mcp_resources, read_mcp_resource
    my @blocks = $res->attachments('Compare @docs:file:///api.md with the code');

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

What raider does with the resources of the configured MCP servers
(ADR 0029 Addendum 1), the way Claude Code does:

=over

=item * The tools C<list_mcp_resources> (Claude Code: C<ListMcpResourcesTool>)
and C<read_mcp_resource> (C<ReadMcpResourceTool>) of L</tool_server>, which
the application mounts when servers are configured. Both read only; a
server that announced no C<resources> capability has none to list.

=item * C<@server:scheme://path> in a prompt (L</attachments>): the
resource is read and attached to the prompt as two C<< <system-reminder> >>
blocks, as a read of C<read_mcp_resource> would show it. The server is named
as in the configuration (a plugin's server C<plugin:NAME:SERVER>) or by the
server part of its tool names. A reference that names no connected server
with resources, or a resource that cannot be read, stays text.

=back

The servers are started by the run (L<Langertha::Raider::MCP/start_f>)
before a prompt is expanded.

=head2 servers

C<< sub { return \@servers } >>: the L<Langertha::Raider::MCP::Server>
objects, asked on every use (they change with C</reload>). Required.

=head2 loop

The L<IO::Async::Loop> awaited on while a tool or an expansion runs.
Required.

=head2 list

    my $items = $res->list;            # all servers
    my $items = $res->list('docs');    # one

Every resource of the connected servers as C<< { server, uri, name,
mimeType, description } >>. Croaks (with the available servers) for a
server name that is not configured.

=head2 read

    my $text = $res->read( 'docs', 'file:///api.md' );

The text of a resource: the C<text> of every content item, a binary item
(C<blob>) as a note with its size and type. Dies with a message for an
unknown server, a server without resources or a failing read.

=head2 attachments

    my @blocks = $res->attachments($prompt);

For each distinct C<@server:scheme://path> of the prompt that names a
connected server with resources and can be read: the two
C<< <system-reminder> >> blocks of an attachment, as one string. The path
ends at whitespace; sentence punctuation at the end is tried off when the
whole does not read.

=head2 tool_server

    my $server = $res->tool_server;

An L<MCP::Server> with C<list_mcp_resources(server?)> and
C<read_mcp_resource(server, uri)>, built once. The first answers with a
JSON list (or a note that there are none), the second with the text of the
resource; failures are error results.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::MCP::Server>

=item * L<Langertha::Raider::MCP>

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
