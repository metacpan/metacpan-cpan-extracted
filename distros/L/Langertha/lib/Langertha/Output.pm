package Langertha::Output;
our $VERSION = '0.400';
# ABSTRACT: Response output transformation helpers
use strict;
use warnings;
use Carp ();
use Langertha::Output::Tools;

Carp::carp(
  "Langertha::Output is a backwards-compatibility facade. New code should use "
  . "Langertha::ToolCall directly."
);

sub extract_from_raw {
  shift;
  return Langertha::Output::Tools->extract_from_raw(@_);
}

sub parse_hermes_calls_from_text {
  shift;
  return Langertha::Output::Tools->parse_hermes_calls_from_text(@_);
}

sub to_openai_tool_calls {
  shift;
  return Langertha::Output::Tools->to_openai_tool_calls(@_);
}

sub to_anthropic_tool_use_blocks {
  shift;
  return Langertha::Output::Tools->to_anthropic_tool_use_blocks(@_);
}

sub to_ollama_tool_calls {
  shift;
  return Langertha::Output::Tools->to_ollama_tool_calls(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Output - Response output transformation helpers

=head1 VERSION

version 0.400

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
