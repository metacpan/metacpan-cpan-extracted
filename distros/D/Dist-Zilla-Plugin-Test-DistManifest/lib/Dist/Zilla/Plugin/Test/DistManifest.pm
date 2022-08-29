use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::DistManifest; # git description: v2.000005-6-g278719c
# ABSTRACT: Release tests for the manifest

our $VERSION = '2.000006';

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';

sub register_prereqs
{
    my $self = shift;
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::DistManifest' => 0,
    );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

#pod =head1 SYNOPSIS
#pod
#pod In C<dist.ini>:
#pod
#pod     [Test::DistManifest]
#pod
#pod =for test_synopsis
#pod 1;
#pod __END__
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
#pod following file:
#pod
#pod   xt/release/dist-manifest.t - a standard Test::DistManifest test
#pod
#pod =for Pod::Coverage register_prereqs
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::DistManifest - Release tests for the manifest

=head1 VERSION

version 2.000006

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::DistManifest]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/release/dist-manifest.t - a standard Test::DistManifest test

=for test_synopsis 1;
__END__

=for Pod::Coverage register_prereqs

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-DistManifest>
(or L<bug-Dist-Zilla-Plugin-Test-DistManifest@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-DistManifest@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Marcel Gruenauer Mike Doherty Karen Etheridge Graham Knop Kent Fredric

=over 4

=item *

Marcel Gruenauer <hanekomu@gmail.com>

=item *

Mike Doherty <doherty@cs.dal.ca>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Mike Doherty <mike@mikedoherty.ca>

=item *

Graham Knop <haarg@haarg.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/release/dist-manifest.t ]___
use strict;
use warnings;
use Test::More;

use Test::DistManifest;
manifest_ok();
