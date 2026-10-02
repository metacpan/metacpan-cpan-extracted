package Langertha::Result;
# ABSTRACT: Reserved namespace — the result value object moved to Langertha::Raider::Result
our $VERSION = '0.503';
use strict;
use warnings;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Result - Reserved namespace — the result value object moved to Langertha::Raider::Result

=head1 VERSION

version 0.503

=head1 DESCRIPTION

Reserved namespace placeholder. The result value object that used to live here
(C<final> / C<question> / C<pause> / C<abort>, boolean-true-because-it-exists) was
extracted to the L<langertha-raider|https://metacpan.org/dist/langertha-raider>
distribution, where it is self-contained as L<Langertha::Raider::Result>. Nothing
in Langertha core uses this package; it is retained only so the C<Langertha::Result>
namespace stays indexed under the Langertha distribution on CPAN.

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
