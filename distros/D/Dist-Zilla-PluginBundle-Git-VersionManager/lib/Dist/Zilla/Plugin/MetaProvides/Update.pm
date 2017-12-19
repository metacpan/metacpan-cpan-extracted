use strict;
use warnings;
package Dist::Zilla::Plugin::MetaProvides::Update;
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: A plugin to fix "provides" metadata after [RewriteVersion] modified $VERSION declarations

our $VERSION = '0.003';

use Moose;
with 'Dist::Zilla::Role::FileMunger';
use Moose::Util 'find_meta';
use namespace::autoclean;

sub munge_files
{
    my $self = shift;

    # re-calculate 'provides' metadata and copy it back to distmeta.

    my $zilla = $self->zilla;
    return if not find_meta($zilla)->find_attribute_by_name('distmeta')->has_value($zilla);
    my $distmeta = $zilla->distmeta;

    # if there is no provides metadata, then there is nothing to do (yet). Maybe we ran too soon?
    return if not $distmeta->{provides};

    # find the plugin that does Dist::Zilla::Role::MetaProvider::Provider
    # die if we can't find one -- *something* populated $distmeta->{provides}!

    my @provides_plugins = grep { $_->does('Dist::Zilla::Role::MetaProvider::Provider') } @{$zilla->plugins};
    $self->log_fatal('failed to find any Dist::Zilla::Role::MetaProvider::Provider plugins -- what populated provides?!') if not @provides_plugins;

    foreach my $new_metadata (map { $_->metadata } @provides_plugins)
    {
        foreach my $module (keys %{$new_metadata->{provides}})
        {
            $self->log_fatal('could not find provides entry for %s in original distmeta; did plugin add it in the wrong phase?')
                if not exists $distmeta->{provides}{$module};

            if ($distmeta->{provides}{$module}{file} ne $new_metadata->{provides}{$module}{file})
            {
                $self->log([ 'filename for module %s has changed (%s to %s) -- provides plugin is running too late',
                    $module, $distmeta->{provides}{$module}{file}, $new_metadata->{provides}{$module}{file} ]);
                $distmeta->{provides}{$module}{file} = $new_metadata->{provides}{$module}{file};
            }

            # if version has disappeared, die
            if (not exists $new_metadata->{provides}{$module}{version})
            {
                $self->log_fatal([ 'metaprovides version for %s has disappeared!', $module ])
                    if exists $distmeta->{provides}{$module}{version};
            }
            # if version has been added or changed, warn and update.
            else
            {
                # new version exists.
                # if old did not exist, add it and log.
                if (not exists $distmeta->{provides}{$module}{version})
                {
                    $self->log([ '$VERSION for %s has been added (as %s): fixing provides metadata',
                            $module, $new_metadata->{provides}{$module}{version} ]);
                    $distmeta->{provides}{$module}{version} = $new_metadata->{provides}{$module}{version};
                }
                # if old did exist, check equality.
                elsif ($distmeta->{provides}{$module}{version} ne $new_metadata->{provides}{$module}{version})
                {
                    $self->log([ '$VERSION for %s has been changed from %s to %s: fixing provides metadata',
                            $module, $distmeta->{provides}{$module}{version}, $new_metadata->{provides}{$module}{version} ]);
                    $distmeta->{provides}{$module}{version} = $new_metadata->{provides}{$module}{version};
                }
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=for stopwords FileMunging MetaProvider OurPkgVersion PkgVersion PodWeaver RewriteVersion

=head1 NAME

Dist::Zilla::Plugin::MetaProvides::Update - A plugin to fix "provides" metadata after [RewriteVersion] modified $VERSION declarations

=head1 VERSION

version 0.003

=head1 SYNOPSIS

In your F<dist.ini> (or a plugin bundle that effectively does the same thing):

    [MetaProvides::*]   ; e.g. ::Class, ::Package, ::FromFile
    ...
    [RewriteVersion]
    [MetaProvides::Update]

=head1 DESCRIPTION

=for Pod::Coverage munge_files

This plugin is a hack and hopefully will soon be made redundant.  It is bundled along with a (the?)
bundle that needs it, but can also be used with other bundles if such a need is identified.

This plugin is meant to be run after all other file mungers, but most particularly after
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>.  Because plugin bundles contain many plugins,
it can be difficult or impossible to arrange the order of plugins and bundles in F<dist.ini> such that
all ordering constraints are correctly satisfied.

The specific ordering problem that this plugin is correcting for is this:

=over 4

=item *

a plugin runs in the FileMunging phase that requires metadata (in my case, I typically see this with L<[PodWeaver]|Dist::Zilla::Plugin::PodWeaver>)

=item *

this prompts MetaProvider plugins to run, one of which populates L<"provides" metadata|CPAN::Meta::Spec/provides>

=item *

all F<.pm> files in the distribution are scanned and their C<$VERSION> declarations are extracted

=item *

a subsequent FileMunging plugin adds or mutates these C<$VERSION> declarations

=item *

now the "provides" metadata is incorrect.

=back

Incorrect "provides" metadata is a big deal, because this metadata is treated as authoritative by PAUSE and can
result in incorrect package indexing.

There are many C<$VERSION>-mutating plugins, such as:

=over 4

=item *

L<[PkgVersion]|Dist::Zilla::Plugin::PkgVersion>

=item *

L<[OurPkgVersion]|Dist::Zilla::Plugin::OurPkgVersion>

=item *

L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion> (and its derivative, L<[RewriteVersion::Transitional]|Dist::Zilla::Plugin::RewriteVersion::Transitional>)

=back

Careful ordering of plugins can be used to avoid this issue: as long as the plugin that populates "provides"
metadata appears in the configuration B<after> the plugin that mutates C<$VERSION>, everything works correctly.  In
L<my author bundle|Dist::Zilla::PluginBundle::Author::ETHER>, I would prefer to list
L<[RewriteVersion::Transitional]|Dist::Zilla::Plugin::RewriteVersion::Transitional> at the very beginning of the
plugin list, to ensure module files are munged before any other plugins inspect them.
However, correct ordering may no longer be possible if plugins are added from sub-bundles.  I ran
into this exact scenario when writing L<[@Git::VersionManager]|Dist::Zilla::PluginBundle::Git::VersionManager> --
all the plugins (except for L<[RewriteVersion::Transitional]|Dist::Zilla::Plugin::RewriteVersion::Transitional>)
are after-release plugins, and need to run after other after-release plugins that the user may be using, so this
likely results in the placement of the "provides" metadata-populating plugin as before these plugins.

My hacky (and hopefully temporary) solution is this plugin which runs after the C<$VERSION> declaration is mutated,
and hunts for the previous "provides" metadata-populating plugin and re-runs it, to update the metadata. Ideally,
that plugin should do this itself as late as possible (such as in the Prereq Source phase), after all file munging is
complete.

=head1 SEE ALSO

=over 4

=item *

L<MetaProvides issue #8: warn when $VERSIONs are extracted from files too soon|https://github.com/kentnl/Dist-Zilla-Plugin-MetaProvides/issues/8>

=item *

L<[@Git::VersionManager]|Dist::Zilla::PluginBundle::Git::VersionManager>

=item *

L<Dist::Zilla::Role::MetaProvider::Provider>

=item *

L<[MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Git-VersionManager>
(or L<bug-Dist-Zilla-PluginBundle-Git-VersionManager@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Git-VersionManager@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
