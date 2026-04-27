package Langertha::Role::ResponseFormat;
# ABSTRACT: Role for an engine where you can specify structured output
our $VERSION = '0.500';
use Moose::Role;
use JSON::MaybeXS qw( decode_json );

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
    my $r = eval { decode_json($s) };
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
      $candidate =~ s/\}[^}]*$/\}/ or last;
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

version 0.500

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
