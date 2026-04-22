package Langertha::Role::ParallelToolUse;
# ABSTRACT: Role for an engine that supports parallel tool calling control
our $VERSION = '0.404';
use Moose::Role;

has parallel_tool_use => (
  is => 'ro',
  isa => 'Bool',
  predicate => 'has_parallel_tool_use',
);

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $params = $class->$orig(@args);

  return $params if exists $params->{parallel_tool_use};

  if ( exists $params->{parallel_tool_calls} ) {
    $params->{parallel_tool_use} = delete $params->{parallel_tool_calls} ? 1 : 0;
  }
  elsif ( exists $params->{disable_parallel_tool_use} ) {
    $params->{parallel_tool_use} = delete $params->{disable_parallel_tool_use} ? 0 : 1;
  }

  return $params;
};



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ParallelToolUse - Role for an engine that supports parallel tool calling control

=head1 VERSION

version 0.404

=head2 parallel_tool_use

    parallel_tool_use => 1   # allow multiple tool calls per assistant turn
    parallel_tool_use => 0   # restrict to one tool call per turn

Canonical boolean controlling whether the model may emit multiple tool calls
in a single assistant turn. Translated per-engine to the provider's native
parameter:

=over 4

=item * OpenAI-compatible engines send C<parallel_tool_calls> in the request.

=item * Anthropic-compatible engines send C<< disable_parallel_tool_use => !parallel_tool_use >>
in the C<tool_choice> block.

=back

For convenience the constructor also accepts the provider-native names as
aliases and normalizes them:

    # all three are equivalent
    ->new( parallel_tool_use         => 0 )
    ->new( parallel_tool_calls       => 0 )  # OpenAI name
    ->new( disable_parallel_tool_use => 1 )  # Anthropic name (inverted)

If unset the provider default is used (typically parallel enabled).

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::ToolChoice> - Canonical tool_choice conversion

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
