package Langertha::ServerToolCall;
# ABSTRACT: Record of one tool call the provider executed itself
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );


has type => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has id => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);


has status => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_status',
);


has data => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);


# Output items of the Responses wire that record a call the provider ran
# (OpenAI create-response reference, spec k206 section 2.1). A client
# tool_search_call (execution => 'client') is client-actionable instead, and
# the walkers croak on it (Langertha::Tool->_croak_on_client_item). Anything
# else unknown is skipped -- values open; it stays on Response.raw.
# x_search_call is xAI's X Search item (docs.x.ai tool-usage-details, k355;
# documentation-derived, not capture-verified).
my %RESPONSES_SERVER_ITEM = map { $_ => 1 } qw(
  web_search_call file_search_call code_interpreter_call image_generation_call
  mcp_call mcp_list_tools shell_call tool_search_call x_search_call
);

sub from_responses {
  my ( $class, $item ) = @_;
  return undef unless ref $item eq 'HASH';
  my $type = $item->{type} // '';
  return undef unless $RESPONSES_SERVER_ITEM{$type};
  return undef if $type eq 'tool_search_call' && ( $item->{execution} // '' ) eq 'client';
  return $class->new(
    type => $type,
    data => $item,
    ( defined $item->{id} && !ref $item->{id} ? ( id => $item->{id} ) : () ),
    ( defined $item->{status} && !ref $item->{status} ? ( status => $item->{status} ) : () ),
  );
}


sub extract {
  my ( $class, $fmt, $data ) = @_;
  croak "Langertha::ServerToolCall: server tool calls on the '" . ( $fmt // '' )
    . "' wire are not supported yet"
    unless ( $fmt // '' ) eq 'responses';
  return () unless ref $data eq 'HASH' && ref $data->{output} eq 'ARRAY';
  return grep { defined } map { $class->from_responses($_) } @{ $data->{output} };
}


sub to_hash {
  my ($self) = @_;
  return {
    type => $self->type,
    id   => $self->id,
    ( $self->has_status ? ( status => $self->status ) : () ),
    data => $self->data,
  };
}


sub TO_JSON { shift->to_hash }



__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::ServerToolCall - Record of one tool call the provider executed itself

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $response = await $engine->chat_f(
        messages => [ { role => 'user', content => 'Current Perl release?' } ],
        tools    => [ { type => 'web_search' } ],
    );

    for my $call ( @{ $response->server_tool_calls // [] } ) {
        say $call->type, ' ', $call->id, ' ', $call->status // '';
        my $item = $call->data;    # the provider's item, verbatim
    }

=head1 DESCRIPTION

A server-side tool call is one the provider ran itself during the request --
a web search, a file search, a remote MCP call. The client has nothing to do
for it, so it is kept apart from L<Langertha::ToolCall>, which means "a call
the client must act on": these records land on
L<Langertha::Response/server_tool_calls>, never on
L<Langertha::Response/tool_calls>, and C<chat_with_tools_f> never executes
them (ADR 0003 Update k206, ADR 0030).

The record is deliberately thin: the wire item type, its id and status, and
the item itself verbatim under L</data>. Inputs and results are not
normalized across providers.

=head2 type

The wire item type, for example C<web_search_call>, C<file_search_call> or
C<mcp_call>. Required.

=head2 id

The provider's item id. Empty when the item carried none.

=head2 status

The item status (for example C<completed>), when the provider sent one. Test
with C<has_status>.

=head2 data

The provider's item, verbatim.

=head2 from_responses

    my $call = Langertha::ServerToolCall->from_responses($output_item);

Builds a record from one Responses C<output[]> item, or returns C<undef> when
the item is not a server-side call.

=head2 extract

    my @calls = Langertha::ServerToolCall->extract( responses => $data );

Returns every server-side call item of a decoded response, in wire order.
Pinned to the wire like L<Langertha::ToolCall/extract>. Only C<responses> is
supported; other wires croak.

=head2 to_hash

Returns C<< { type, id, status?, data } >>.

=head2 TO_JSON

Delegates to L</to_hash>, for JSON encoders with C<convert_blessed>.

=head1 SEE ALSO

=over

=item * L<Langertha::ServerTool> - the server-side tool definition

=item * L<Langertha::Response/server_tool_calls>

=item * L<Langertha::ToolCall> - calls the client must execute

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
