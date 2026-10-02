package Langertha::Role::ResponseFormat;
# ABSTRACT: Role for an engine where you can specify structured output
our $VERSION = '0.503';
use Moose::Role;
use JSON::MaybeXS qw( decode_json );
use Encode qw( encode_utf8 );

has response_format => (
  isa => 'HashRef',
  is => 'ro',
  predicate => 'has_response_format',
);


sub decode_loose_json {
  my ( $self, $text ) = @_;
  return undef unless defined $text && length $text;

  my $try = sub {
    my ($s) = @_;
    # decode_json (the JSON::MaybeXS utf8 variant) expects bytes, but $s reaches
    # us as a Perl-Unicode string (already-decoded response content). Decoding it
    # directly dies with "Wide character in subroutine entry" on any non-ASCII
    # byte, so UTF-8-encode first -- same convention as ToolCall::_args_kwargs
    # and Role::JSON's decode_json_text. All three strategies route through this
    # closure, so the fence/substring candidates are encoded here too.
    my $r = eval { decode_json( encode_utf8($s) ) };
    return $@ ? undef : $r;
  };

  if ( my $r = $try->($text) ) {
    return $r;
  }
  if ( $text =~ /```(?:json)?\s*(.*?)\s*```/s ) {
    if ( my $r = $try->($1) ) {
      return $r;
    }
  }
  if ( $text =~ /(\{.*\})/s ) {
    my $candidate = $1;
    if ( my $r = $try->($candidate) ) {
      return $r;
    }
    while ( length $candidate > 2 ) {
      my $before = length $candidate;
      $candidate =~ s/\}[^}]*$/\}/ or last;
      # The substitution collapses trailing junk after the final '}' into that
      # '}'. When the candidate already ends at '}' (which the greedy capture
      # above guarantees), it is a no-op that still reports a successful
      # substitution, so `or last` never fires -- an unbalanced candidate such
      # as '{{"a":1}' would spin here forever and wedge the async event loop.
      # Bail the moment the length stops shrinking: the method must terminate
      # (returning undef), never hang. -- karr k161
      last unless length $candidate < $before;
      if ( my $r = $try->($candidate) ) {
        return $r;
      }
    }
  }
  return undef;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ResponseFormat - Role for an engine where you can specify structured output

=head1 VERSION

version 0.503

=head2 decode_loose_json

    my $data = $engine->decode_loose_json($text);

Tolerant JSON decoder for structured-output responses where providers
sometimes wrap the payload in code fences or surrounding prose. Tries:

=over

=item 1. Decode the whole text as JSON.

=item 2. Strip C<```json ... ```> code fences and decode the inner block.

=item 3. Decode the first balanced C<{...}> substring.

=back

Returns the decoded value (typically a HashRef) on success, or C<undef>
if all strategies fail. Override in an engine subclass when a provider
needs a custom strategy (e.g. always-prose-wrapped output).

=head2 response_format

A HashRef specifying the structured output format for the response. The exact
structure depends on the engine. For OpenAI-compatible engines this is typically
C<{ type => 'json_object' }> or a JSON Schema definition. Optional.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Chat> - Chat functionality that uses response format

=item * L<Langertha::Role::OpenAICompatible> - OpenAI-compatible engines that support this role

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
