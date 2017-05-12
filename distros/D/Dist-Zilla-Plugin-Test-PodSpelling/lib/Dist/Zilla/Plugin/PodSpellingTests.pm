use strict;
use warnings;
package Dist::Zilla::Plugin::PodSpellingTests;
# ABSTRACT: (DEPRECATED) The old name of the PodSpelling plugin
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '2.007004';

use Moose;
extends 'Dist::Zilla::Plugin::Test::PodSpelling';

# use warnings categories from the caller, not these modules
use Carp ();
local $Carp::Internal{'Class::Load'} = 1;
local $Carp::Internal{'Module::Runtime'} = 1;
warnings::warnif('deprecated',
    '!!! [PodSpellingTests] is deprecated and will be removed in a future release; replace it with [Test::PodSpelling]',
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PodSpellingTests - (DEPRECATED) The old name of the PodSpelling plugin

=head1 VERSION

version 2.007004

=head1 SYNOPSIS

This is a plugin that runs at the L<gather files|Dist::Zilla::Role::FileGatherer> stage,
providing the file:

  xt/author/pod-spell.t - a standard Test::Spelling test

THIS MODULE IS DEPRECATED. Please use
L<Dist::Zilla::Plugin::Test::PodSpelling> instead. it may be removed at a
later time (but not before April 2016).

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Test::PodSpelling>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-PodSpelling>
(or L<bug-Dist-Zilla-Plugin-Test-PodSpelling@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-PodSpelling@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHORS

=over 4

=item *

Caleb Cushing <xenoterracide@gmail.com>

=item *

Marcel Gruenauer <hanekomu@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2010 by Karen Etheridge.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
