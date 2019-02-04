use strict;
use warnings;
package Dist::Zilla::MintingProfile::Author::TABULO;
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: Mint distributions like TABULO does
# BASED_ON: Dist::Zilla::MintingProfile::Author::ETHER

our $VERSION = '0.198';
# AUTHORITY

use Moose;
with 'Dist::Zilla::Role::MintingProfile' => { -version => '5.047' };
use File::ShareDir;
use Path::Tiny;
use Carp;
use namespace::autoclean;

sub profile_dir
{
    my ($self, $profile_name) = @_;

    die 'minting requires perl 5.014' unless "$]" >= 5.013002;

    my $dist_name = 'Dist-Zilla-PluginBundle-Author-TABULO';

    my $profile_dir = path(File::ShareDir::dist_dir($dist_name))->child('profiles', $profile_name);

    return $profile_dir if -d $profile_dir;

    confess "Can't find profile $profile_name via $self: it should be in $profile_dir";
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::Author::TABULO - Mint distributions like TABULO does

=head1 VERSION

version 0.198

=head1 SYNOPSIS

    dzil new -P Author::TABULO -p github Foo::Bar

or:

    #!/bin/bash
    newdist() {
        local dist=$1
        local module=`perl -we"print q{$dist} =~ s/-/::/r"`
        pushd ~/git
        dzil new -P Author::TABULO -p github $module
        cd $dist
    }
    newdist Foo-Bar

=head1 DESCRIPTION

This is a minting profile used for TABULO's distributions.
Like his dzil plugin-bundle, the starting point of this profile was ETHER's.

Since TABULO initially forked the whole thing from ETHER's,
most of the documentation you see here actually come from her originally, ...

Thank you ETHER!

=head2 WARNING

Please note that, although this module needs to be on CPAN for obvious reasons,
it is really intended to be a collection of personal preferences, which are
expected to be in great flux, at least for the time being.

Therefore, please do NOT base your own distributions on this one, since anything
can change at any moment without prior notice, while I get accustomed to dzil
myself and form those preferences in the first place...
Absolutely nothing in this distribution is guaranteed to remain constant or
be maintained at this point. Who knows, I may even give up on dzil altogether...

You have been warned.

=head2 DESCRIPTION (at last)

The new distribution is packaged with L<Dist::Zilla> using
L<Dist::Zilla::PluginBundle::Author::TABULO>.

Profiles available are:

=over 4

=item *

C<github>

Creates a distribution hosted on L<github|http://github.com>, with hooks to determine the
module version and other metadata from git. Issue tracking is disabled, as RT
is selected as the bugtracker in the distribution's metadata (via the plugin
bundle).

You will be prompted to create a repository on github immediately; if you
decline, you must create one manually before you do your first C<push>.

=item *

C<default>

Presently the same as C<github>. Available since version 0.087.

=back

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::PluginBundle::Author::TABULO>

=item *

L<Pod::Weaver::PluginBundle::Author::TABULO>

=item *

L<Dist::Zilla::MintingProfile::Author::ETHER> (ETHER's original bundle)

=back

=head1 BASED ON

This distribution is based on L<Dist::Zilla::MintingProfile::Author::ETHER> by
Karen Etheridge L<cpan:ETHER>.

Thank you ETHER!

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-TABULO>
(or L<bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-TABULO@rt.cpan.org>).

=head1 AUTHOR

Tabulo <tabulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tabulo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
