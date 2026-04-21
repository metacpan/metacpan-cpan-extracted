package Langertha::Role::Tools;
# ABSTRACT: Role for MCP tool calling support
our $VERSION = '0.402';
use Moose::Role;
use Future::AsyncAwait;
use Carp qw( croak );
use JSON::MaybeXS;
use Log::Any qw( $log );

with 'Langertha::Role::ParallelToolUse';


has mcp_servers => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [] },
);


has tool_max_iterations => (
  is => 'ro',
  isa => 'Int',
  default => 10,
);


sub build_tool_chat_request {
  my ( $self, $conversation, $formatted_tools, %extra ) = @_;
  return $self->chat_request($conversation, tools => $formatted_tools, %extra);
}


async sub chat_with_tools_f {
  my ( $self, @messages ) = @_;

  croak "No MCP servers configured" unless @{$self->mcp_servers};

  # Gather tools from all MCP servers
  my ( @all_tools, %tool_server_map );
  for my $mcp (@{$self->mcp_servers}) {
    my $tools = await $mcp->list_tools;
    for my $tool (@$tools) {
      $tool_server_map{$tool->{name}} = $mcp;
      push @all_tools, $tool;
    }
  }

  my $formatted_tools = $self->format_tools(\@all_tools);
  my $conversation = $self->chat_messages(@messages);

  $log->debugf("[%s] chat_with_tools_f: %d tools from %d MCP servers, max_iterations=%d",
    ref $self, scalar @all_tools, scalar @{$self->mcp_servers}, $self->tool_max_iterations);

  for my $iteration (1..$self->tool_max_iterations) {
    $log->debugf("[%s] Tool loop iteration %d/%d",
      ref $self, $iteration, $self->tool_max_iterations);

    my $request = $self->build_tool_chat_request($conversation, $formatted_tools);
    my $response = await $self->_async_http->do_request(request => $request);

    unless ($response->is_success) {
      die "".(ref $self)." tool chat request failed: ".$response->status_line;
    }

    my $data = $self->parse_response($response);
    my $tool_calls = $self->response_tool_calls($data);

    # No tool calls means the LLM is done — return final text
    unless (@$tool_calls) {
      my $text = $self->response_text_content($data);
      if ($self->think_tag_filter) {
        ($text) = $self->filter_think_content($text);
      }
      return $text;
    }

    # Execute each tool call via the appropriate MCP server
    my @results;
    for my $tc (@$tool_calls) {
      my ( $name, $input ) = $self->extract_tool_call($tc);

      $log->debugf("[%s] Calling tool: %s", ref $self, $name);

      my $mcp = $tool_server_map{$name}
        or die "Tool '$name' not found on any MCP server";

      my $result = await $mcp->call_tool($name, $input)->else(sub {
        my ( $error ) = @_;
        Future->done({
          content => [{ type => 'text', text => "Error calling tool '$name': $error" }],
          isError => JSON::MaybeXS->true,
        });
      });

      push @results, { tool_call => $tc, result => $result };
    }

    # Append assistant message and tool results to conversation
    push @$conversation, $self->format_tool_results($data, \@results);
  }

  die "Tool calling loop exceeded ".$self->tool_max_iterations." iterations";
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Tools - Role for MCP tool calling support

=head1 VERSION

version 0.402

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::MCP;
    use Future::AsyncAwait;

    my $loop = IO::Async::Loop->new;

    # Set up an MCP server with tools
    my $mcp = Net::Async::MCP->new(server => $my_mcp_server);
    $loop->add($mcp);
    await $mcp->initialize;

    # Create engine with MCP servers (native tool calling)
    my $engine = Langertha::Engine::Anthropic->new(
        api_key     => $ENV{ANTHROPIC_API_KEY},
        model       => 'claude-sonnet-4-6',
        mcp_servers => [$mcp],
    );

    my $response = await $engine->chat_with_tools_f(
        'Use the available tools to answer my question'
    );

    # Hermes tool calling (for APIs without native tool support)
    my $engine = Langertha::Engine::AKI->new(
        api_key     => $ENV{AKI_API_KEY},
        mcp_servers => [$mcp],
    );

=head1 DESCRIPTION

This role adds MCP (Model Context Protocol) tool calling support to Langertha
engines. It provides the L</chat_with_tools_f> method which implements the full
async tool-calling loop:

=over 4

=item 1. Gather available tools from all configured MCP servers

=item 2. Send a chat request with tool definitions to the LLM

=item 3. If the LLM returns tool calls, execute them via MCP

=item 4. Feed tool results back to the LLM and repeat

=item 5. When the LLM returns final text, return it

=back

Engines must provide implementations for five methods that handle
engine-specific tool format conversion: C<format_tools>,
C<response_tool_calls>, C<extract_tool_call>, C<format_tool_results>, and
C<response_text_content>. Native API engines (OpenAI, Anthropic, Gemini, etc.)
implement these directly. Engines without native tool support compose
L<Langertha::Role::HermesTools> which provides implementations using XML tags.

=head2 mcp_servers

    mcp_servers => [$mcp1, $mcp2]

ArrayRef of L<Net::Async::MCP> instances to use as tool providers. Defaults to
an empty ArrayRef. At least one server must be configured before calling
L</chat_with_tools_f>.

=head2 tool_max_iterations

    tool_max_iterations => 20

Maximum number of tool-calling round trips before aborting with an error.
Defaults to C<10>. Increase for complex multi-step tool workflows.

=head2 build_tool_chat_request

    my $request = $self->build_tool_chat_request($conversation, $formatted_tools);

Builds an HTTP request for a tool-calling chat turn. The default implementation
passes tools as an API parameter via C<chat_request>. Overridden by
L<Langertha::Role::HermesTools> to inject tools into the system prompt instead.

=head2 chat_with_tools_f

    my $response = await $engine->chat_with_tools_f(@messages);

Async tool-calling chat loop. Accepts the same message arguments as
L<Langertha::Role::Chat/simple_chat>. Gathers tools from all L</mcp_servers>,
sends the request, executes any tool calls returned by the LLM, and repeats
until the LLM returns a final text response or L</tool_max_iterations> is
exceeded. Returns a L<Future> that resolves to the final text response.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::HermesTools> - Hermes-style tool calling via XML tags

=item * L<Langertha::Role::Chat> - Chat role this is built on top of

=item * L<Langertha::Raider> - Autonomous agent with persistent history using tools

=item * L<Net::Async::MCP> - MCP client used as tool provider

=item * L<Langertha::Engine::Anthropic> - Engine with native tool support

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

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
