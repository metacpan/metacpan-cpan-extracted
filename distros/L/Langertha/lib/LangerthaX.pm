package LangerthaX;
# ABSTRACT: Bring your own viking!
our $VERSION = '0.401';
use strict;
use warnings;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LangerthaX - Bring your own viking!

=head1 VERSION

version 0.401

=head1 DESCRIPTION

The C<LangerthaX> namespace is the conventional home for third-party
extensions to L<Langertha>. If you are building a module that extends or
integrates with Langertha but does not belong in the core distribution,
publish it under C<LangerthaX::>.

For custom engines, publish under C<LangerthaX::Engine::*>. L<Langertha>
resolves configured engine names against both C<Langertha::Engine::*> and
C<LangerthaX::Engine::*>.

=head1 SEE ALSO

=over

=item * L<Langertha> - The core Langertha distribution

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

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
