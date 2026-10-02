package Langertha::ServerTool;
# ABSTRACT: Provider-native server-side tool definition, pinned to one wire format
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use Langertha::Tool;


# Wires whose server tools this value object can carry (Phase 1a, k206).
my %SUPPORTED_WIRE = ( responses => 1 );

# Typed client tools that are never server tools, even with unlisted => 1.
my %CLIENT_TYPE = map { $_ => 1 } qw( function custom namespace );

has wire => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has spec => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);


has unlisted => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $params = $class->$orig(@args);
  $params->{spec} = { %{ $params->{spec} } } if ref $params->{spec} eq 'HASH';
  return $params;
};

sub BUILD {
  my ($self) = @_;
  my $wire  = $self->wire;
  my $spec  = $self->spec;
  my $label = $spec->{type} // '';
  croak "Langertha::ServerTool: server tools on the '$wire' wire are not supported yet"
    unless $SUPPORTED_WIRE{$wire};
  croak "Langertha::ServerTool: spec has no type (keys: "
    . ( join( ',', sort keys %$spec ) || '(empty)' ) . ")"
    unless length $label;
  my ( $category, $own_wire ) = Langertha::Tool->classify($spec);
  croak "Langertha::ServerTool: '$label' is a function tool; use Langertha::Tool"
    if $category eq 'function' && $label eq 'function';
  croak "Langertha::ServerTool: '$label' is a client tool, not a server tool"
    if $CLIENT_TYPE{$label} || $category eq 'function';
  croak "Langertha::ServerTool: '$label' is a client-executed built-in ($own_wire), not a server tool"
    if $category eq 'client_builtin';
  croak "Langertha::ServerTool: '$label' belongs to the $own_wire wire, not '$wire'"
    if $category eq 'server' && $own_wire ne $wire;
  return if $category eq 'server' || $self->unlisted;
  croak "Langertha::ServerTool: '$label' is not a known server tool on '$wire'; "
    . "pass unlisted => 1 if the provider runs it";
}

sub type { $_[0]->spec->{type} }


sub from_hash {
  my ( $class, $fmt, $hash ) = @_;
  return $hash if blessed($hash) && $hash->isa(__PACKAGE__);
  return undef unless ref $hash eq 'HASH';
  return undef unless defined $fmt && $SUPPORTED_WIRE{$fmt};
  return undef unless Langertha::Tool->classify( $hash, $fmt ) eq 'server';
  return $class->new( wire => $fmt, spec => $hash );
}


sub to {
  my ( $self, $fmt ) = @_;
  $fmt //= '';
  croak "Langertha::ServerTool: '" . $self->type . "' belongs to the "
    . $self->wire . " wire, not '$fmt'; server tools are provider-native and cannot be translated"
    unless $fmt eq $self->wire;
  my $spec = $self->spec;
  # Remote MCP on the Responses wire: OpenAI defaults require_approval to
  # "always", which answers with an mcp_approval_request the client must
  # confirm, and Langertha has no approval flow (orchestrator ruling Q2 on
  # k206). Checked here, on the one door every emission path goes through --
  # the Responses envelope and Tool->format_list, which sees no engine -- so it
  # is enforced once (k206 review M3). An engine whose provider does not take
  # the field (xAI) strips it in its _server_tool_wire_check hook afterwards.
  if ( $self->type eq 'mcp' && $fmt eq 'responses' ) {
    my $approval = $spec->{require_approval};
    croak "Langertha::ServerTool: remote MCP tool '" . ( $spec->{server_label} // '?' )
      . "' needs require_approval => 'never'; the approval flow is not supported"
      unless defined $approval && !ref $approval && $approval eq 'never';
  }
  return { %$spec };
}


sub check_engine {
  my ( $class, $engine, $tools ) = @_;
  return unless ref $tools eq 'ARRAY';
  return if $engine->supports('server_tools');
  for my $item (@$tools) {
    next unless blessed($item) && $item->isa(__PACKAGE__);
    croak "" . ( ref $engine ) . ": '" . $item->type . "' is a Langertha::ServerTool, "
      . "and this engine does not supports('server_tools')";
  }
  return;
}


sub to_hash {
  my ($self) = @_;
  return {
    wire => $self->wire,
    spec => { %{ $self->spec } },
    ( $self->unlisted ? ( unlisted => 1 ) : () ),
  };
}


sub TO_JSON { shift->to_hash }



__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::ServerTool - Provider-native server-side tool definition, pinned to one wire format

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::ServerTool;

    # Wrap a provider-native server tool for the Responses wire
    my $search = Langertha::ServerTool->new(
        wire => 'responses',
        spec => { type => 'web_search' },
    );

    # Per request, mixed with function tools
    my $response = await $engine->chat_f(
        messages => [ { role => 'user', content => 'Current Perl release?' } ],
        tools    => [ $search, $mcp_tool_hash ],
    );

    # Or once on the engine, for every request (Langertha::Role::ServerTools)
    my $engine = Langertha::Engine::OpenAIResponses->new(
        model        => 'gpt-5.6-luna',
        server_tools => [ { type => 'web_search' } ],
    );

    # Recognise a hash without croaking; undef when it is no server tool
    my $st = Langertha::ServerTool->from_hash( responses => $hash );

=head1 DESCRIPTION

A server-side tool is one the provider runs itself during a single request:
web search, file search, a code interpreter, remote MCP. Its definition is a
provider contract, not a portable function tool -- C<web_search> on the
Responses wire, C<web_search_20250305> on Anthropic and C<google_search> on
Gemini are three different things. So this value object does not translate:
it carries the provider-native hash (L</spec>) verbatim, is keyed by the
C<tool_wire_format> it belongs to (L</wire>), and L</to> refuses every other
wire. It is the server-side sibling of L<Langertha::Tool>, which takes function
tools only.

Which hashes count as server tools is decided by
L<Langertha::Tool/classify>, the one classifier. A type Langertha does not list
yet can still be sent by vouching for it with C<< unlisted => 1 >>.

Supported wires: C<responses> (OpenAI's C</v1/responses>). Anthropic and Gemini
server tools are not supported yet; the constructor croaks for them.

Server-side calls the provider reports back land on
L<Langertha::Response/server_tool_calls> as L<Langertha::ServerToolCall>, never
on L<Langertha::Response/tool_calls>: the client must not execute them. See
ADR 0030.

=head2 wire

The C<tool_wire_format> the tool belongs to (C<responses>). Required.

=head2 spec

The provider-native tool hash, for example
C<< { type => 'mcp', server_label => 'docs', server_url => '...', require_approval => 'never' } >>.
Required. A shallow copy is taken at construction; use L</to> to read it.

=head2 unlisted

Set to C<1> to send a C<type> that Langertha's table does not list yet, when
you know the provider runs it. Function, C<custom> and C<namespace> tools and
known client-executed built-ins are refused even then.

=head2 type

The C<type> of the native hash, for example C<web_search>.

=head2 from_hash

    my $st = Langertha::ServerTool->from_hash( $fmt, $hash );

Returns a C<Langertha::ServerTool> when C<$hash> is a known server tool of the
wire C<$fmt>, else C<undef>. Never croaks and never sniffs: the wire is given,
as for L<Langertha::ToolCall/extract>. A C<Langertha::ServerTool> is returned
unchanged.

=head2 to

    my $hash = $st->to('responses');

Returns a copy of the native hash for the wire the tool belongs to, and croaks
for any other wire. A remote C<mcp> tool on the C<responses> wire also croaks
unless it says C<< require_approval => 'never' >>: the provider default asks
the client to approve each call, and Langertha has no approval flow. The check
lives here so that every path -- an engine request and
L<Langertha::Tool/format_list> alike -- enforces it.

=head2 check_engine

    Langertha::ServerTool->check_engine( $engine, \@tools );

Croaks when C<@tools> holds a C<Langertha::ServerTool> and C<$engine> does not
C<supports('server_tools')>, so the tool never reaches a wire that cannot take
it. L<Langertha::Role::Chat/chat_f> calls it before building a request. Plain
hashes are left alone: a provider-shaped hash still goes out as the engine
sends it today.

=head2 to_hash

Returns C<< { wire, spec } >> (plus C<unlisted> when set).

=head2 TO_JSON

Delegates to L</to_hash>, for JSON encoders with C<convert_blessed>.

=head1 SEE ALSO

=over

=item * L<Langertha::Tool> - function tools, and C<classify>

=item * L<Langertha::ServerToolCall> - a server-side call reported back

=item * L<Langertha::Role::ServerTools> - the engine capability and C<server_tools>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
