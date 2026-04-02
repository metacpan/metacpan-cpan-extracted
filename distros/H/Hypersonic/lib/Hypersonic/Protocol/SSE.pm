package Hypersonic::Protocol::SSE;
use strict;
use warnings;

# Hypersonic::Protocol::SSE - JIT code generation for Server-Sent Events
#
# SSE is a text-based protocol for pushing events from server to client.
# This module generates C code for efficient event formatting.
# Transport uses HTTP/1.1 chunked encoding or HTTP/2 DATA frames.

our $VERSION = '0.12';

=head1 NAME

Hypersonic::Protocol::SSE - Server-Sent Events protocol support

=head1 SYNOPSIS

    use Hypersonic::Protocol::SSE;
    
    # Generate C code for SSE formatting
    Hypersonic::Protocol::SSE->gen_event_formatter($builder);

=head1 DESCRIPTION

Server-Sent Events (SSE) provide a standard for pushing events from a server
to a client over HTTP. This module provides compile-time C code generation
for efficient event formatting.

=head2 SSE Format (RFC 8895)

    event: message
    id: 123
    data: Hello World
    
    event: update
    data: line 1
    data: line 2
    
    : this is a comment/keepalive
    
    retry: 3000

=cut

# Content-Type for SSE
sub content_type { 'text/event-stream' }

# Generate C code for formatting SSE events
sub gen_event_formatter {
    my ($class, $builder) = @_;
    
    $builder->comment('SSE: Format an event into buffer')
      ->comment('Returns bytes written')
      ->line('static size_t format_sse_event(char* buf, size_t buf_size,')
      ->line('                                const char* event_type,')
      ->line('                                const char* data,')
      ->line('                                const char* id) {')
      ->line('    size_t pos = 0;')
      ->blank
      ->comment('Event type (optional)')
      ->if('event_type && event_type[0]')
        ->line('pos += snprintf(buf + pos, buf_size - pos, "event: %s\\n", event_type);')
      ->endif
      ->blank
      ->comment('ID (optional)')
      ->if('id && id[0]')
        ->line('pos += snprintf(buf + pos, buf_size - pos, "id: %s\\n", id);')
      ->endif
      ->blank
      ->comment('Data (required) - handle multiline')
      ->if('data')
        ->line('const char* line_start = data;')
        ->line('const char* p = data;')
        ->while('*p')
          ->if('*p == \'\\n\'')
            ->line('pos += snprintf(buf + pos, buf_size - pos, "data: %.*s\\n",')
            ->line('               (int)(p - line_start), line_start);')
            ->line('line_start = p + 1;')
          ->endif
          ->line('p++;')
        ->endloop
        ->comment('Last line (or only line if no newlines)')
        ->if('line_start <= p && *line_start')
          ->line('pos += snprintf(buf + pos, buf_size - pos, "data: %s\\n", line_start);')
        ->elsif('line_start == data')
          ->comment('Empty string - still need data line')
          ->line('pos += snprintf(buf + pos, buf_size - pos, "data: \\n");')
        ->endif
      ->endif
      ->blank
      ->comment('End of event (blank line)')
      ->if('pos < buf_size')
        ->line('buf[pos++] = \'\\n\';')
      ->endif
      ->blank
      ->line('return pos;')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate C code for keepalive comment
sub gen_keepalive {
    my ($class, $builder) = @_;
    
    $builder->comment('SSE: Format keepalive comment')
      ->line('static size_t format_sse_keepalive(char* buf, size_t buf_size) {')
      ->line('    return snprintf(buf, buf_size, ": keepalive\\n\\n");')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate C code for retry directive
sub gen_retry {
    my ($class, $builder) = @_;
    
    $builder->comment('SSE: Format retry directive')
      ->line('static size_t format_sse_retry(char* buf, size_t buf_size, int ms) {')
      ->line('    return snprintf(buf, buf_size, "retry: %d\\n\\n", ms);')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate C code for custom comment
sub gen_comment {
    my ($class, $builder) = @_;
    
    $builder->comment('SSE: Format comment (can be used for keepalive or metadata)')
      ->line('static size_t format_sse_comment(char* buf, size_t buf_size, const char* text) {')
      ->line('    return snprintf(buf, buf_size, ": %s\\n\\n", text);')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate all SSE C code
sub generate_c_code {
    my ($class, $builder, $opts) = @_;
    
    $class->gen_event_formatter($builder);
    $class->gen_keepalive($builder);
    $class->gen_retry($builder);
    $class->gen_comment($builder);
    
    return $builder;
}

# Perl-side event formatting (for compile-time or fallback)
sub format_event {
    my ($class, %opts) = @_;
    
    my $output = '';
    
    # Event type
    if (defined $opts{type} && $opts{type} ne '') {
        $output .= "event: $opts{type}\n";
    }
    
    # ID
    if (defined $opts{id} && $opts{id} ne '') {
        $output .= "id: $opts{id}\n";
    }
    
    # Data (handle multiline)
    my $data = $opts{data} // '';
    if ($data eq '') {
        # Empty string - still need one data line
        $output .= "data: \n";
    } else {
        for my $line (split /\n/, $data, -1) {
            $output .= "data: $line\n";
        }
    }
    
    # Blank line to end event
    $output .= "\n";
    
    return $output;
}

# Format keepalive
sub format_keepalive {
    return ": keepalive\n\n";
}

# Format retry directive
sub format_retry {
    my ($class, $ms) = @_;
    return "retry: $ms\n\n";
}

# Format comment
sub format_comment {
    my ($class, $text) = @_;
    return ": $text\n\n";
}

1;

__END__

=head1 SSE FORMAT

Each event consists of:

=over 4

=item * C<event: name> - Optional event type (default: "message")

=item * C<id: value> - Optional event ID for reconnection

=item * C<data: payload> - Required event data (can span multiple lines)

=item * Blank line - Terminates the event

=back

Special directives:

=over 4

=item * C<retry: ms> - Sets reconnection delay in milliseconds

=item * C<: comment> - Comment line (ignored by client, used for keepalive)

=back

=head1 AUTHOR

Hypersonic Contributors

=cut
