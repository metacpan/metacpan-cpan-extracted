package Langertha::Knarr::Input;
our $VERSION = '0.007';
# ABSTRACT: Primary input normalization API for Knarr
use strict;
use warnings;
use Langertha::Input;

sub normalize_tools {
  shift;
  return Langertha::Input->normalize_tools(@_);
}

sub to_openai_tools {
  shift;
  return Langertha::Input->to_openai_tools(@_);
}

sub to_anthropic_tools {
  shift;
  return Langertha::Input->to_anthropic_tools(@_);
}

sub normalize_tool_choice {
  shift;
  return Langertha::Input->normalize_tool_choice(@_);
}

sub to_openai_tool_choice {
  shift;
  return Langertha::Input->to_openai_tool_choice(@_);
}

sub to_anthropic_tool_choice {
  shift;
  return Langertha::Input->to_anthropic_tool_choice(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Input - Primary input normalization API for Knarr

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
