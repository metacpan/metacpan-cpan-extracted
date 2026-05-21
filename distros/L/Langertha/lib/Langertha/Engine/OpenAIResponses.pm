package Langertha::Engine::OpenAIResponses;
# ABSTRACT: OpenAI Responses API (reasoning models like gpt-5.5-pro)
our $VERSION = '0.502';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS;
use Langertha::ToolCall;
use Langertha::Tool;

extends 'Langertha::Engine::OpenAI';


override 'chat_operation_id' => sub {
    return 'createResponse';
};

sub chat_request {
    my ( $self, $messages, %extra ) = @_;

    # Normalize tool_choice to Responses format
    if ( exists $extra{tool_choice} && defined $extra{tool_choice} ) {
        if ( my $tc = Langertha::ToolChoice->from_hash( $extra{tool_choice} ) ) {
            $extra{tool_choice} = $tc->to_responses;
        }
    }

    # If tools passed in MCP format (inputSchema camelCase), format them
    # to Responses flat format. If already formatted (has 'type' key), pass through.
    if ( exists $extra{tools} && ref $extra{tools} eq 'ARRAY' ) {
        my @tools = @{$extra{tools}};
        if ( @tools && ref $tools[0] eq 'HASH' && !exists $tools[0]{type} ) {
            $extra{tools} = $self->format_tools(\@tools);
        }
    }

    # parallel_tool_use -> parallel_tool_calls (only when tools present)
    if ( !exists $extra{parallel_tool_calls}
        && exists $extra{tools}
        && $self->can('has_parallel_tool_use') && $self->has_parallel_tool_use ) {
        $extra{parallel_tool_calls} = $self->parallel_tool_use ? JSON->true : JSON->false;
    }

    # Build input array: strip system messages (go to instructions instead)
    my @input;
    for my $msg (@$messages) {
        next if ( $msg->{role} // '' ) eq 'system';
        push @input, $self->_normalize_input_item($msg);
    }

    my @request_args = (
        defined $self->chat_model ? ( model => $self->chat_model ) : (),
        $self->has_system_prompt ? ( instructions => $self->system_prompt ) : (),
        scalar(@input) ? ( input => \@input ) : (),
        $self->get_response_size ? ( max_tokens => $self->get_response_size ) : (),
        ( $self->can('has_response_format') && $self->has_response_format )
            ? ( response_format => $self->response_format )
            : (),
        $self->has_temperature ? ( temperature => $self->temperature ) : (),
        stream => JSON->false,
        %extra,
    );

    return $self->generate_request(
        $self->chat_operation_id,
        sub { $self->chat_response(shift) },
        @request_args,
    );
}

sub _normalize_input_item {
    my ( $self, $msg ) = @_;
    # Pass through for now — expand if Responses gains multimodal content blocks
    return $msg;
}

sub chat_response {
    my ( $self, $response ) = @_;
    my $data = $self->parse_response($response);

    my ( $text, @tc_data, $finish_reason, $thinking );

    for my $item ( @{ $data->{output} // [] } ) {
        next unless ref($item) eq 'HASH';
        my $type = $item->{type} // '';

        if ( $type eq 'reasoning' ) {
            # Collect reasoning summary if present
            my $summary = $item->{summary}[0]{text} // '';
            $thinking //= $summary if length $summary;
        }
        elsif ( $type eq 'message' ) {
            $finish_reason = ( $item->{status} // '' ) eq 'completed' ? 'stop' : ( $item->{status} // '' );

            for my $block ( @{ $item->{content} // [] } ) {
                my $block_type = $block->{type} // '';
                if ( $block_type eq 'output_text' ) {
                    $text .= ( $block->{text} // '' );
                }
                elsif ( $block_type eq 'function_call' ) {
                    push @tc_data, $block;
                }
            }
        }
        elsif ( $type eq 'function_call' ) {
            # Real Responses API emits function_call as a top-level output[]
            # item carrying name/arguments/call_id directly on the item.
            push @tc_data, $item;
            $finish_reason //= 'tool_calls';
        }
    }

    # Normalize usage to chat-style (Goldmine expects prompt_tokens/completion_tokens)
    my $usage = $data->{usage} // {};
    my $normalized_usage = {
        prompt_tokens     => $usage->{input_tokens},
        completion_tokens => $usage->{output_tokens},
        total_tokens      => $usage->{total_tokens},
    };
    if ( my $rt = $usage->{output_tokens_details}{reasoning_tokens} ) {
        $normalized_usage->{completion_tokens_details} = { reasoning_tokens => $rt };
    }

    my @tcs = map { $self->_parse_function_call($_) } @tc_data;

    return Langertha::Response->new(
        content       => $text // '',
        raw           => $data,
        $data->{id}      ? ( id => $data->{id} )      : (),
        $data->{model}   ? ( model => $data->{model} ) : (),
        defined $finish_reason ? ( finish_reason => $finish_reason ) : (),
        usage         => $normalized_usage,
        @tcs ? ( tool_calls => \@tcs ) : (),
        defined $thinking ? ( thinking => $thinking ) : (),
    );
}

sub _parse_function_call {
    my ( $self, $block ) = @_;
    my $args = $block->{arguments} // '{}';
    $args = $self->decode_json_text($args) if $args && !ref $args;
    return Langertha::ToolCall->new(
        name      => ( $block->{name} // '' ),
        arguments => ( ref($args) eq 'HASH' ? $args : {} ),
        id        => ( $block->{call_id} // '' ),
    );
}

sub response_tool_calls {
    my ( $self, $data ) = @_;
    my @calls;
    for my $item ( @{ $data->{output} // [] } ) {
        next unless ref($item) eq 'HASH';
        my $type = $item->{type} // '';
        if ( $type eq 'function_call' ) {
            push @calls, $item;
        }
        elsif ( $type eq 'message' ) {
            for my $block ( @{ $item->{content} // [] } ) {
                next unless ( $block->{type} // '' ) eq 'function_call';
                push @calls, $block;
            }
        }
    }
    return \@calls;
}

sub extract_tool_call {
    my ( $self, $tc ) = @_;
    my $args = $tc->{arguments};
    $args = $self->decode_json_text($args) if $args && !ref $args;
    return ( $tc->{name}, $args );
}

sub format_tools {
    my ( $self, $mcp_tools ) = @_;
    # Responses API uses flat tool objects — no {type:'function',function:{...}} wrapper
    return [
        map {
            {
                type        => 'function',
                name        => $_->{name},
                description => $_->{description},
                parameters  => $_->{input_schema} // $_->{inputSchema} // $_->{parameters},
            },
        } @$mcp_tools
    ];
}

sub format_tool_results {
    my ( $self, $data, $results ) = @_;
    # Responses API: tool results go into a new input item, not back into messages
    return [
        map {
            my $r = $_;
            {
                role => 'tool',
                call_id => $r->{tool_call}{call_id} // $r->{tool_call}{id} // '',
                content => $self->json->encode( $r->{result}{content} ),
            },
        } @$results
    ];
}

sub response_text_content {
    my ( $self, $data ) = @_;
    my $text = '';
    for my $item ( @{ $data->{output} // [] } ) {
        next unless ref($item) eq 'HASH';
        next unless ( $item->{type} // '' ) eq 'message';
        for my $block ( @{ $item->{content} // [] } ) {
            $text .= ( $block->{text} // '' ) if ( $block->{type} // '' ) eq 'output_text';
        }
    }
    return $text;
}

sub stream_format { return undef }  # Streaming not supported

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::OpenAIResponses - OpenAI Responses API (reasoning models like gpt-5.5-pro)

=head1 VERSION

version 0.502

=head1 SYNOPSIS

    use Langertha::Engine::OpenAIResponses;

    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => $ENV{OPENAI_API_KEY},
        model   => 'gpt-5.5-pro',   # reasoning-only model
    );

    my $response = $engine->simple_chat('Hello');
    print $response;

=head1 DESCRIPTION

Provides access to OpenAI's Responses API endpoint (C<POST /v1/responses>)
for reasoning-only models like C<gpt-5.5-pro>, C<o3-pro>, and future
C<-pro> SKUs that are not available on the Chat Completions endpoint
(C</v1/chat/completions>).

Unlike L<Langertha::Engine::OpenAI> which calls C</v1/chat/completions>, this
engine calls C</v1/responses> with the Responses API's own request/response
shape. The Responses API uses:

=over 4

=item * C<input> instead of C<messages>

=item * C<instructions> for system prompt (top-level, not in input array)

=item * Flat tool objects C<{type, name, description, parameters}> instead
of C<{type, function, function: {...}}>

=item * C<output[]> array with type discriminators (C<message>, C<reasoning>,
C<function_call>) instead of C<choices[]>

=item * C<input_tokens>/C<output_tokens> instead of
C<prompt_tokens>/C<completion_tokens>

=item * C<output_tokens_details.reasoning_tokens> instead of
C<completion_tokens_details.reasoning_tokens>

=back

This engine returns a L<Langertha::Response> that is shape-compatible with
the chat path, so existing consumers (including Goldmine's C<complete>
method) work without modification. Reasoning tokens are normalized to
C<completion_tokens_details.reasoning_tokens> for cost lookup compatibility.

=head2 Function call output shape

The Responses API emits C<function_call> in two different positions
depending on model and request shape:

=over 4

=item * B<Top-level> C<output[]> item:
C<< { type =E<gt> 'function_call', call_id =E<gt> 'call_abc', name =E<gt> 'foo',
arguments =E<gt> '{...}' } >>. This is what real reasoning models (e.g.
C<gpt-5.5-pro>) return for forced C<tool_choice>.

=item * B<Nested> inside a message item:
C<< output[type='message'].content[type='function_call'] >>. Historically
seen in streaming / older fixtures.

=back

C<chat_response>, C<response_tool_calls> and L<Langertha::ToolCall/extract>
walk both shapes. Streaming is not supported.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::OpenAI> - Chat Completions endpoint (for non-reasoning models)

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::ToolCall> - Tool call extraction from Responses format

=item * L<Langertha::ToolChoice/to_responses> - Responses tool_choice serialization

=item * L<Langertha::Tool/to_responses> - Responses tool serialization

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
