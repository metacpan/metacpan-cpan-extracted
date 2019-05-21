use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::MinimumVersionTests;
# ABSTRACT: Release tests for minimum required versions

our $VERSION = '2.000009';

use Moose;
extends 'Dist::Zilla::Plugin::Test::MinimumVersion';

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod In C<dist.ini>:
#pod
#pod     [Test::MinimumVersion]
#pod
#pod =cut

before register_component => sub {
    warn '!!! [MinimumVersionTests] is deprecated and will be removed in a future release; replace it with [Test::MinimumVersion]';
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MinimumVersionTests - Release tests for minimum required versions

=head1 VERSION

version 2.000009

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::MinimumVersion]

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-MinimumVersion>
(or L<bug-Dist-Zilla-Plugin-Test-MinimumVersion@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-MinimumVersion@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHORS

=over 4

=item *

Mike Doherty <doherty@cpan.org>

=item *

Marcel Grünauer <marcel@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
