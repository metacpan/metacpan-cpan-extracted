#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git; # git description: v2.041-5-g07880cd
# ABSTRACT: Update your git repository after release

our $VERSION = '2.042';

use Dist::Zilla 2.100880;    # Need mvp_multivalue_args in Plugin role
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git - Update your git repository after release

=head1 VERSION

version 2.042

=head1 DESCRIPTION

This set of plugins for L<Dist::Zilla> can do interesting things for
module authors using Git (L<https://git-scm.com>) to track their work.

You need Git 1.5.4 or later to use these plugins.  Some plugins
require a more recent version of Git for certain features.

=head2 The @Git Bundle

The most commonly used plugins are part of the
L<@Git bundle|Dist::Zilla::PluginBundle::Git>.  They are:

=over 4

=item * L<Git::Check|Dist::Zilla::Plugin::Git::Check>

Before a release, check that the repo is in a clean state
(you have committed your changes).

=item * L<Git::Commit|Dist::Zilla::Plugin::Git::Commit>

After a release, commit updated files.

=item * L<Git::Tag|Dist::Zilla::Plugin::Git::Tag>

After a release, tag the just-released version.

=item * L<Git::Push|Dist::Zilla::Plugin::Git::Push>

After a release, push the released code & tag to your public repo.

=back

=head2 Non-Bundled Plugins

The other plugins in this distribution are not included in the @Git
bundle, either because they conflict with L<Dist::Zilla>'s
L<@Basic bundle|Dist::Zilla::PluginBundle::Basic> or because they
have more specialized uses.

=over 4

=item * L<Git::CommitBuild|Dist::Zilla::Plugin::Git::CommitBuild>

Commits the released files to a separate branch of your repo.

=item * L<Git::GatherDir|Dist::Zilla::Plugin::Git::GatherDir>

A replacement for Dist::Zilla's standard
L<GatherDir|Dist::Zilla::Plugin::GatherDir> plugin that gathers
files based on whether they are tracked by Git (conflicts with @Basic
because that includes GatherDir).

=item * L<Git::Init|Dist::Zilla::Plugin::Git::Init>

Can be used in a minting profile
(L<http://dzil.org/tutorial/minting-profile.html>)
to initialize and configure your Git repo automatically
when you do S<C<dzil new>>.

=item * L<Git::NextVersion|Dist::Zilla::Plugin::Git::NextVersion>

Calculates the version number of your distribution from your Git tags
using L<Version::Next>.

=back

=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Git>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Git>

=item * Mailing-list (same as L<Dist::Zilla>)

L<http://www.listbox.com/subscribe/?list_id=139292>

=item * Git repository

L<http://github.com/madsen/dist-zilla-plugin-git>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Git>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Git>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Git>
(or L<bug-Dist-Zilla-Plugin-Git@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Git@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Jerome Quelin

=head1 CONTRIBUTORS

=for stopwords Christopher J. Madsen Jérôme Quelin Karen Etheridge Kent Fredric Yanick Champoux Ricardo Signes David Golden Mike Friedman Graham Knop Chris Weyl Stephen R. Scaffidi Randy Stauner Barr Apocalypse Doherty Nigel Metheringham Olivier Mengué Tatsuhiko Miyagawa Tuomas Jormola Alessandro Ghedini Brian Phillips Steinbrunner Geoffrey Broadwell Harley Pig Jesse Luehrs Brendan Byrd Alexandr Ciornii Matt Follett Michael Schout

=over 4

=item *

Christopher J. Madsen <perl@cjmweb.net>

=item *

Jérôme Quelin <jquelin@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

David Golden <dagolden@cpan.org>

=item *

Mike Friedman <friedo@friedo.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=item *

Stephen R. Scaffidi <sscaffid@akamai.com>

=item *

Randy Stauner <randy@magnificent-tears.com>

=item *

Graham Barr <gbarr@pobox.com>

=item *

Apocalypse <perl@0ne.us>

=item *

Mike Doherty <doherty@cs.dal.ca>

=item *

Nigel Metheringham <nigel.metheringham@dev.intechnology.co.uk>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=item *

Tuomas Jormola <tj@solitudo.net>

=item *

Alessandro Ghedini <al3xbio@gmail.com>

=item *

Brian Phillips <bphillips@digitalriver.com>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Geoffrey Broadwell <geoffb@corp.sonic.net>

=item *

Harley Pig <harleypig@gmail.com>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Brendan Byrd <Perl@ResonatorSoft.org>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Matt Follett <matt.follett@gmail.com>

=item *

Michael Schout <mschout@gkg.net>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
