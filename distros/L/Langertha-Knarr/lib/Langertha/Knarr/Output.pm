package Langertha::Knarr::Output;
our $VERSION = '0.007';
# ABSTRACT: Primary output normalization API for Knarr
use strict;
use warnings;
use Langertha::Output;

sub extract_from_raw {
  shift;
  return Langertha::Output->extract_from_raw(@_);
}

sub parse_hermes_calls_from_text {
  shift;
  return Langertha::Output->parse_hermes_calls_from_text(@_);
}

sub to_openai_tool_calls {
  shift;
  return Langertha::Output->to_openai_tool_calls(@_);
}

sub to_anthropic_tool_use_blocks {
  shift;
  return Langertha::Output->to_anthropic_tool_use_blocks(@_);
}

sub to_ollama_tool_calls {
  shift;
  return Langertha::Output->to_ollama_tool_calls(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Output - Primary output normalization API for Knarr

=head1 VERSION

version 0.007

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
