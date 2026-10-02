package App::Raider;
# ABSTRACT: Reserved namespace — the CLI entry point moved to Langertha::Raider::CLI
our $VERSION = '0.503';

use strict;
use warnings;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Raider - Reserved namespace — the CLI entry point moved to Langertha::Raider::CLI

=head1 VERSION

version 0.503

=head1 DESCRIPTION

Reserved namespace placeholder. The CLI entry point that used to live here (the
application class behind the C<raider> command) was renamed and now lives in
L<Langertha::Raider::CLI> in the
L<Langertha-Raider|https://metacpan.org/dist/Langertha-Raider> distribution, which
replaces the former App-Raider distribution. Nothing uses this package; it is
retained only so the C<App::Raider> namespace stays indexed to a dead stub on CPAN.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

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
