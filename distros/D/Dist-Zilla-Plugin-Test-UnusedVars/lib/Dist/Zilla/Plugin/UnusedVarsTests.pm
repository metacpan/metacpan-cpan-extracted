use strict;
use warnings;

package Dist::Zilla::Plugin::UnusedVarsTests;
# ABSTRACT: (DEPRECATED) Release tests for unused variables

our $VERSION = '2.001001';

use Moose;
use namespace::autoclean;
extends 'Dist::Zilla::Plugin::Test::UnusedVars';

before register_component => sub {
    warnings::warnif('deprecated',
        "!!! [UnusedVarsTests] is deprecated and will be removed in a future release; please use [Test::UnusedVars].\n",
    );
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::UnusedVarsTests - (DEPRECATED) Release tests for unused variables

=head1 VERSION

version 2.001001

=head1 SYNOPSIS

Please use L<Dist::Zilla::Plugin::Test::UnusedVars> instead.

In your F<dist.ini>:

    [Test::UnusedVars]

=head1 DESCRIPTION

THIS MODULE IS DEPRECATED. Please use
L<Dist::Zilla::Plugin::Test::UnusedVars> instead. It may be removed at a
later time (but not before February 2017).

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-UnusedVars>
(or L<bug-Dist-Zilla-Plugin-Test-UnusedVars@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-UnusedVars@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
