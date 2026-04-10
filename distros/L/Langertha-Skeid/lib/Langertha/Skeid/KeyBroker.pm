package Langertha::Skeid::KeyBroker;
our $VERSION = '0.002';
# ABSTRACT: Pluggable API key resolution for Skeid nodes
use Moo;
use Carp qw(croak);
use namespace::clean;

sub resolve_key {
  my ($self, $ref) = @_;
  croak ref($self) . " must implement resolve_key()";
}

sub needs_refresh { 0 }

sub refresh { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::KeyBroker - Pluggable API key resolution for Skeid nodes

=head1 VERSION

version 0.002

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

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
