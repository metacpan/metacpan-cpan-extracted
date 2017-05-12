use utf8;
package Dist::Zilla::MintingProfile::Author::Caelum;
BEGIN {
  $Dist::Zilla::MintingProfile::Author::Caelum::AUTHORITY = 'cpan:RKITOVER';
}
{
  $Dist::Zilla::MintingProfile::Author::Caelum::VERSION = '0.08';
}

use strict;
use warnings;
use 5.008001;

use Moose;
use Dist::Zilla::PluginBundle::AVAR 0.28 ();
use Dist::Zilla::Plugin::Git::Init ();
use Dist::Zilla::Plugin::GitHub::Create 0.30 ();
use Dist::Zilla::Plugin::Git::PushInitial ();

with 'Dist::Zilla::Role::MintingProfile::ShareDir';

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::Author::Caelum - Basic Minting Profile for @AVAR

=head1 SYNOPSIS

    dzil setup

    git config --global github.user GitHubLoginName
    git config --global github.password GitHubPassword

    dzil new -P Author::Caelum Your::Dist::Name

    cd Your-Dist-Name

    # edit stuff and commit

    dzil release

=head1 DESCRIPTION

This is a general purpose minting profile for
L<Dist::Zilla::PluginBundle::AVAR>.

It will set up a git repo for you with some boilerplate and prompt you if you
want to create a new L<GitHub|github.com> repo for it.

It creates a basic module for you. It does not use any L<Pod::Weaver> stuff.

It sets up dzil to do all the tagging/versioning/pushing for you (see
L<@AVAR|Dist::Zilla::PluginBundle::AVAR> for more details.)

When you do a C<dzil release>, your module will also be installed with C<cpanm
.> by default.

=head1 SEE ALSO

=over 4

=item * L<Dist::Zilla::PluginBundle::AVAR>

=item * L<Dist::Zilla::Plugin::GitHub::Create>

=back

=head1 AUTHOR

Rafael Kitover <rkitover@cpan.org>

=cut

__PACKAGE__; # End of Dist::Zilla::MintingProfile::Author::Caelum
