use strict;
use warnings;

package Dist::Zilla::Plugin::PortabilityTests;
# ABSTRACT: (DEPRECATED) Release tests for portability

our $VERSION = '2.001000';

use Moose;
extends 'Dist::Zilla::Plugin::Test::Portability';

before register_component => sub {
    warnings::warnif('deprecated',
        "!!! [PortabilityTests] is deprecated and will be removed in a future release; replace it with [Test::Portability].\n",
    );
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PortabilityTests - (DEPRECATED) Release tests for portability

=head1 VERSION

version 2.001000

=for test_synopsis BEGIN { die "SKIP: synopsis isn't perl code" }

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::Portability]

=head1 DESCRIPTION

THIS MODULE IS DEPRECATED. Please use
L<Dist::Zilla::Plugin::Test::Portability> instead. It may be removed at a
later time (but not before February 2017).

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-Portability>
(or L<bug-Dist-Zilla-Plugin-Test-Portability@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-Portability@rt.cpan.org>).

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
