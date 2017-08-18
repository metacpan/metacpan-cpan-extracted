use strict;
use warnings;
package Dist::Zilla::PluginBundle::Git::VersionManager;
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: A plugin bundle that manages your version in git
# KEYWORDS: bundle distribution git version Changes increment

# no version yet until this module is in its own distribution

use Moose;
with
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
    'Dist::Zilla::Role::PluginBundle::Config::Slicer';

use List::Util 1.45 qw(any uniq);
use Dist::Zilla::Util;
use Moose::Util::TypeConstraints qw(subtype where class_type);
use CPAN::Meta::Requirements;
use namespace::autoclean;

has changes_version_columns => (
    is => 'ro', isa => subtype('Int', where { $_ > 0 && $_ < 20 }),
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{changes_version_columns} // 10 },
);

has commit_files_after_release => (
    isa => 'ArrayRef[Str]',
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{commit_files_after_release} // [] },
    traits => ['Array'],
    handles => { commit_files_after_release => 'elements' },
);

around commit_files_after_release => sub {
    my $orig = shift; my $self = shift;
    sort(uniq($self->$orig(@_), 'Changes'));
};

sub mvp_multivalue_args { qw(commit_files_after_release) }

has _develop_requires => (
    isa => class_type('CPAN::Meta::Requirements'),
    lazy => 1,
    default => sub { CPAN::Meta::Requirements->new },
    handles => {
        _add_minimum_develop_requires => 'add_minimum',
        _develop_requires_as_string_hash => 'as_string_hash',
    },
);

sub configure
{
    my $self = shift;

    my $fallback_version_provider =
        $self->payload->{'RewriteVersion::Transitional.fallback_version_provider'}
            // 'Git::NextVersion';  # TODO: move this default to an attribute; be careful of overlays

    # allow override of any config option for the fallback_version_provider plugin
    # by specifying it as if it was used directly
    # i.e. Git::NextVersion.foo = ... in dist.ini is rewritten in the payload as
    # RewriteVersion::Transitional.foo = ... so it can override defaults passed in by the caller
    # (a wrapper plugin bundle.)
    foreach my $fallback_key (grep { /^$fallback_version_provider\./ } keys %{ $self->payload })
    {
        (my $new_key = $fallback_key) =~ s/^$fallback_version_provider(?=\.)/RewriteVersion::Transitional/;
        $self->payload->{$new_key} = delete $self->payload->{$fallback_key};
    }

    $self->add_plugins(
        # VersionProvider (and a file munger, for the transitional usecase)
        [ 'RewriteVersion::Transitional' => { ':version' => '0.004' } ],

        [ 'MetaProvides::Update' ],

        # After Release
        [ 'CopyFilesFromRelease' => { filename => [ 'Changes' ] } ],
        [ 'Git::Commit'         => 'release snapshot' => {
                ':version' => '2.020',
                allow_dirty => [ $self->commit_files_after_release ],
            } ],
        [ 'Git::Tag'            => {} ],
        [ 'BumpVersionAfterRelease::Transitional' => { ':version' => '0.004' } ],
        [ 'NextRelease'         => { ':version' => '5.033', time_zone => 'UTC', format => '%-' . ($self->changes_version_columns - 2) . 'v  %{yyyy-MM-dd HH:mm:ss\'Z\'}d%{ (TRIAL RELEASE)}T' } ],
        [ 'Git::Commit'         => 'post-release commit' => {
                ':version' => '2.020',
                allow_dirty => [ 'Changes' ],
                allow_dirty_match => [ '^lib/.*\.pm$' ],
                commit_msg => 'increment $VERSION after %v release'
            } ],
    );

    # ensure that additional optional plugins are declared in prereqs
    $self->add_plugins(
        [ 'Prereqs' => 'prereqs for @Git::VersionManager' =>
        { '-phase' => 'develop', '-relationship' => 'requires',
          %{ $self->_develop_requires_as_string_hash } } ]
    );
}

# determine develop prereqs
around add_plugins => sub
{
    my ($orig, $self, @plugins) = @_;

    my $remove = $self->payload->{ $self->plugin_remover_attribute } // [];

    foreach my $plugin_spec (@plugins = map { ref $_ ? $_ : [ $_ ] } @plugins)
    {
        next if any { $_ eq $plugin_spec->[0] } @$remove;

        # this plugin is provided in the local distribution
        next if $plugin_spec->[0] eq 'MetaProvides::Update';

        # record develop prereq
        my $payload = ref $plugin_spec->[-1] ? $plugin_spec->[-1] : {};
        my $plugin = Dist::Zilla::Util->expand_config_package_name($plugin_spec->[0]);
        $self->_add_minimum_develop_requires($plugin => $payload->{':version'} // 0);
    }

    return $self->$orig(@plugins);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Git::VersionManager - A plugin bundle that manages your version in git

=head1 VERSION

version 0.128

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Author::You], or other config entries...

    [@Git::VersionManager]
    [Git::Push]

Or, in your plugin bundle's C<configure> method:

    $self->add_plugin(...);
    $self->add_bundle('@Git::VersionManager' => \%options)
    $self->add_plugin('Git::Push');

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin bundle that manages the version of your distribution, and the C<$VERSION> of the
modules within it. The current version (of the release in question) is determined from C<our $VERSION = ...>
declarations in the code (or from the C<V> environment variable), the F<Changes> file is updated and committed as a
release commit to C<git>, which is then tagged, and then the C<$VERSION> in code is then incremented and then that
change is committed.  The default options used for the plugins are carefully curated to work together, but all
can be customized or overridden (see below).

It is equivalent to the following configuration directly in a F<dist.ini>:

    [RewriteVersion::Transitional]
    :version = 0.004

    [CopyFilesFromRelease / copy Changes]
    filename = Changes

    [Git::Commit / release snapshot]
    :version = 2.020
    allow_dirty = Changes
    allow_dirty = ... anything else passed in 'commit_files_after_release'

    [Git::Tag]

    [BumpVersionAfterRelease::Transitional]
    :version = 0.004

    [NextRelease]
    :version = 5.033
    time_zone = UTC
    format = %-8v  %{yyyy-MM-dd HH:mm:ss'Z'}d%{ (TRIAL RELEASE)}T

    [Git::Commit / post-release commit]
    :version = 2.020
    allow_dirty = Changes
    allow_dirty_match = ^lib/.*\.pm$
    commit_msg = increment $VERSION after %v release

    [Prereqs / prereqs for @Git::VersionManager]
    -phase = develop
    -relationship = requires
    ...all the plugins this bundle uses...

=head1 OPTIONS / OVERRIDES

=for stopwords CopyFilesFromRelease

=head2 commit_files_after_release

File(s), which are expected to exist in the repository directory,
to be committed to git as part of the release commit. Can be used more than once.
When specified, the default is appended to, rather than overwritten.
Defaults to F<Changes>.

Note that you are responsible for ensuring these files are in the repository
(perhaps by using L<[CopyFilesFromRelease]|Dist::Zilla::Plugin::CopyFilesFromRelease>.
Additionally, the file(s) will not be committed if they do not already have git history;
for new files, you should add the C<add_files_in = .> configuration (and use
L<[Git::Check]|Dist::Zilla::Plugin::Git::Check> to ensure that <B>only<B> these files
exist in the repository, not any other files that should not be added.)

=head2 changes_version_columns

An integer that specifies how many columns (right-padded with whitespace) are
allocated in F<Changes> entries to the version string. Defaults to 10.
Unused if C<NextRelease.format = anything> is passed into the configuration.

=for stopwords customizations

=head2 other customizations

This bundle makes use of L<Dist::Zilla::Role::PluginBundle::PluginRemover> and
L<Dist::Zilla::Role::PluginBundle::Config::Slicer> to allow further customization.
(Note that even though some overridden values are inspected in this class,
they are still overlaid on top of whatever this bundle eventually decides to
pass - so what is in the F<dist.ini> or in the C<add_bundle> arguments always
trumps everything else.)

Plugins are not loaded until they are actually needed, so it is possible to
C<--force>-install this plugin bundle and C<-remove> some plugins that do not
install or are otherwise problematic (although release functionality will
likely be broken, you should still be able to build the distribution, more or less).

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-ETHER>
(or L<bug-Dist-Zilla-PluginBundle-Author-ETHER@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-ETHER@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
