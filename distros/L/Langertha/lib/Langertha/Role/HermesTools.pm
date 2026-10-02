package Langertha::Role::HermesTools;
# ABSTRACT: Hermes-style tool calling via XML tags
our $VERSION = '0.503';
use Moose::Role;
use JSON::MaybeXS;


has hermes_call_tag => (
  is => 'ro',
  isa => 'Str',
  default => 'tool_call',
);


has hermes_response_tag => (
  is => 'ro',
  isa => 'Str',
  default => 'tool_response',
);


has hermes_tool_instructions => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  builder => '_build_hermes_tool_instructions',
);

sub _build_hermes_tool_instructions {
  return "You are a function calling AI model. You may call one or more"
    . " functions to assist with the user query. Don't make assumptions"
    . " about what values to plug into functions.";
}


has hermes_tool_prompt => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  builder => '_build_hermes_tool_prompt',
);

sub _build_hermes_tool_prompt {
  my ( $self ) = @_;
  my $call_tag = $self->hermes_call_tag;
  my $instructions = $self->hermes_tool_instructions;
  return <<"PROMPT";
${instructions}

You are provided with function signatures within <tools></tools> XML tags:
<tools>
%s
</tools>

For each function call, return a JSON object with function name and arguments within <${call_tag}></${call_tag}> XML tags:
<${call_tag}>
{"name": "function_name", "arguments": {"arg1": "value1"}}
</${call_tag}>
PROMPT
}


sub hermes_extract_content {
  my ( $self, $data ) = @_;
  return undef unless $data && $data->{choices} && @{$data->{choices}};
  return $data->{choices}[0]{message}{content};
}


has hermes_schema_prompt => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  builder => '_build_hermes_schema_prompt',
);

sub _build_hermes_schema_prompt {
  return <<'PROMPT';
Answer in JSON that adheres to this JSON schema:
<schema>
%s
</schema>
PROMPT
}


# The hermes wire puts the schema of a json_schema response_format into a
# leading system message as well, as _hermes_tool_messages does with the tools
# (karr k234). Any other response_format leaves the conversation alone.
sub _hermes_schema_messages {
  my ( $self, $conversation, $format ) = @_;
  return $conversation
    unless ref $format eq 'HASH' && ( $format->{type} // '' ) eq 'json_schema'
      && ref $format->{json_schema} eq 'HASH' && ref $format->{json_schema}{schema} eq 'HASH';
  my $prompt = sprintf( $self->hermes_schema_prompt, $self->encode_json_text( $format->{json_schema}{schema} ) );
  return [ { role => 'system', content => $prompt }, @$conversation ];
}

# The hermes wire has no tools / tool_choice / parallel_tool_calls body key:
# the tools ride the system prompt, which cannot force a tool (karr k234,
# ADR 0002). Composing Role::Tools gives the native flags, so this layer-2 rule
# clears them for every hermes engine (NousResearch, AKI native; ADR 0016: two
# consumers from different parents, so the rule lives on the role). Kept:
# tools_hermes, tool_choice_auto (what the prompt says) and tool_choice_none
# (chat_f withholds the tools, k231). The rule keys on the resolved tag, not
# on the composition (karr k251): a tool_wire_format => 'openai' constructor
# override sends the tools natively, so it keeps the native flags from the
# role inventory and loses tools_hermes instead. Deleting only, so the order
# against an engine's own around engine_capabilities or its model corrections
# does not matter.
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  if ( $self->tool_wire_format eq 'hermes' ) {
    delete @{$caps}{qw( tools_native tool_choice_any tool_choice_named parallel_tool_use )};
  }
  else {
    delete $caps->{tools_hermes};
  }
  return $caps;
};

# The tool-format behaviour (format_tools, response_tool_calls,
# extract_tool_call, response_text_content, format_tool_results,
# build_tool_chat_request) is provided by the tag-driven defaults in
# Langertha::Role::Tools for tool_wire_format => 'hermes'. This role now only
# carries the Hermes-specific configuration (tag names + prompt template) those
# defaults read.


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::HermesTools - Hermes-style tool calling via XML tags

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    package Langertha::Engine::MyEngine;
    use Moose;
    extends 'Langertha::Engine::Remote';

    with 'Langertha::Role::Tools';
    with 'Langertha::Role::HermesTools';

    sub _build_tool_wire_format { 'hermes' }

=head1 DESCRIPTION

This role configures Hermes-style tool calling: instead of using an API's
native C<tools> parameter, tool definitions are injected into the system prompt
as C<E<lt>toolsE<gt>> XML and the model responds with C<E<lt>tool_callE<gt>> XML
tags containing JSON. This works with any chat model regardless of native tool
API support.

The behaviour itself lives in the tag-driven defaults of
L<Langertha::Role::Tools> (selected by C<tool_wire_format =E<gt> 'hermes'>). This
role now only carries the Hermes-specific I<configuration> those defaults read:
the call/response tag names (L</hermes_call_tag>, L</hermes_response_tag>), the
prompt template (L</hermes_tool_prompt>), and the response-content extractor
(L</hermes_extract_content>). Compose it alongside L<Langertha::Role::Tools> and
set C<_build_tool_wire_format> to C<'hermes'>.

The C<hermes> wire has no C<tools>, C<tool_choice> or C<parallel_tool_calls>
body key, so the role clears C<tools_native>, C<tool_choice_any>,
C<tool_choice_named> and C<parallel_tool_use> from
L<Langertha::Role::Capabilities/engine_capabilities>; C<tools_hermes>,
C<tool_choice_auto> and C<tool_choice_none> stay.

=head2 hermes_call_tag

    hermes_call_tag => 'function_call'

The XML tag name used for tool calls in the model's output. Both the prompt
template and the response parser use this tag. Defaults to C<tool_call>.

=head2 hermes_response_tag

    hermes_response_tag => 'function_response'

The XML tag name used when sending tool results back to the model. Defaults to
C<tool_response>.

=head2 hermes_tool_instructions

    hermes_tool_instructions => 'You are a helpful assistant that can call functions.'

The instruction text prepended to the Hermes tool system prompt. Customize this
to change the model's behavior without altering the structural XML template. The
default instructs the model to call functions without making assumptions about
argument values.

=head2 hermes_tool_prompt

The full system prompt template used for Hermes tool calling. Must contain a
C<%s> placeholder where the tools JSON will be inserted. Built automatically
from L</hermes_tool_instructions> and L</hermes_call_tag>. Override this only
if you need full control over the prompt structure.

=head2 hermes_extract_content

    my $content = $self->hermes_extract_content($data);

Extracts raw text content from a parsed LLM response for Hermes tool call
parsing. Defaults to OpenAI response format (C<choices[0].message.content>).
Override this method in engines with non-OpenAI response structures.

=head2 hermes_schema_prompt

The system prompt template for Hermes structured output, in the form of the
Hermes function-calling prompt format. Must contain a C<%s> placeholder where
the JSON schema is inserted. L<Langertha::Role::Chat/chat_f> and
L<Langertha::Role::Chat/chat_stream_realtime_f> put it in front of the
conversation for every C<json_schema> C<response_format> on a C<hermes>
engine that takes C<response_format> (including the rewrite of a forced
tool), so a backend that ignores C<response_format> still sees the schema.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Tools> - Base tool calling role

=item * L<Langertha::Engine::NousResearch> - Hermes model engine

=item * L<Langertha::Engine::AKI> - AKI.IO engine using Hermes tools

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
