use strict;
use warnings;
package Dist::Zilla::PluginBundle::Git::VersionManager; # git description: v0.004-3-g00cb62d
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: A plugin bundle that manages your version in git
# KEYWORDS: bundle distribution git version Changes increment

our $VERSION = '0.005';

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

has bump_only_matching_versions => (
    is => 'ro',
    isa => 'Bool',
    init_arg => undef,
    lazy => 1,
    default => sub { $_[0]->payload->{bump_only_matching_versions} },
);

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

has _plugin_requirements => (
    isa => class_type('CPAN::Meta::Requirements'),
    lazy => 1,
    default => sub { CPAN::Meta::Requirements->new },
    handles => {
        _add_minimum_plugin_requirement => 'add_minimum',
        _plugin_requirements_as_string_hash => 'as_string_hash',
    },
);

has plugin_prereq_phase => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { $_[0]->payload->{plugin_prereq_phase} // '' },
);

has plugin_prereq_relationship => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { $_[0]->payload->{plugin_prereq_relationship} // '' },
);

sub configure
{
    my $self = shift;

    die 'you cannot change the distribution version with $V along with bump_only_matching_versions: update the .pm file(s) first'
        if $ENV{V} and $self->bump_only_matching_versions;

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
        # adding this first indicates the start of the bundle in x_Dist_Zilla metadata
        [ 'Prereqs' => 'pluginbundle version' => {
                '-phase' => 'develop', '-relationship' => 'recommends',
                $self->meta->name => $self->VERSION,
            } ],

        # VersionProvider (and a file munger, for the transitional usecase)
        $self->bump_only_matching_versions
            ? [ 'VersionFromMainModule' ]
            : [ 'RewriteVersion::Transitional' => { ':version' => '0.004' } ],

        [ 'MetaProvides::Update' ],

        # After Release
        [ 'CopyFilesFromRelease' => { filename => [ 'Changes' ] } ],
        [ 'Git::Commit'         => 'release snapshot' => {
                ':version' => '2.020',
                allow_dirty => [ $self->commit_files_after_release ],
            } ],
        [ 'Git::Tag' ],

        # for all_matching => 1, we presume the author already has versions set up the way he wants them (and for
        # consistency with the removal of RewriteVersion above), so we do not bother with it;
        # this also lets us specify the minimum necessary version for the feature.
        $self->bump_only_matching_versions
            ? [ 'BumpVersionAfterRelease' => { ':version' => '0.016', all_matching => 1 } ]
            : [ 'BumpVersionAfterRelease::Transitional' => { ':version' => '0.004' } ],

        [ 'NextRelease'         => {
                ':version' => '5.033',
                time_zone => 'UTC',
                format => '%-' . ($self->changes_version_columns - 2) . 'v  %{yyyy-MM-dd HH:mm:ss\'Z\'}d%{ (TRIAL RELEASE)}T',
            } ],
        [ 'Git::Commit'         => 'post-release commit' => {
                ':version' => '2.020',
                allow_dirty => [
                    'Changes',
                    !exists($self->payload->{'BumpVersionAfterRelease::Transitional.munge_makefile_pl'})
                            || $self->payload->{'BumpVersionAfterRelease::Transitional.munge_makefile_pl'}
                        ? 'Makefile.PL' : (),
                    !exists($self->payload->{'BumpVersionAfterRelease::Transitional.munge_build_pl'})
                            || $self->payload->{'BumpVersionAfterRelease::Transitional.munge_build_pl'}
                        ? 'Build.PL' : (),
                ],
                allow_dirty_match => [ '^lib/.*\.pm$' ],
                commit_msg => 'increment $VERSION after %v release'
            } ],
    );

    # add used plugins to desired prereq section
    $self->add_plugins(
        [ 'Prereqs' => 'prereqs for @Git::VersionManager' => {
                '-phase' => $self->plugin_prereq_phase,
                '-relationship' => $self->plugin_prereq_relationship,
              %{ $self->_plugin_requirements_as_string_hash },
          } ],
    ) if $self->plugin_prereq_phase and $self->plugin_prereq_relationship;
}

# capture minimum requirements for used plugins
# TODO: this can be pulled off into a separately-distributed role
around add_plugins => sub
{
    my ($orig, $self, @plugins) = @_;

    my $remove = $self->payload->{ $self->plugin_remover_attribute } // [];

    foreach my $plugin_spec (@plugins = map { ref $_ ? $_ : [ $_ ] } @plugins)
    {
        next if any { $_ eq $plugin_spec->[0] } @$remove;

        # this plugin is provided in the local distribution
        next if $plugin_spec->[0] eq 'MetaProvides::Update';

        # save requirement for (possible) later prereq population
        my $payload = ref $plugin_spec->[-1] ? $plugin_spec->[-1] : {};
        my $plugin = Dist::Zilla::Util->expand_config_package_name($plugin_spec->[0]);
        $self->_add_minimum_plugin_requirement($plugin => $payload->{':version'} // 0);
    }

    return $self->$orig(@plugins);
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Git::VersionManager - A plugin bundle that manages your version in git

=head1 VERSION

version 0.005

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

Modules without C<$VERSION> declarations will have them added for the release, with that change also committed
back to the local repository.

When no custom options are passed, it is equivalent to the following configuration directly in a F<dist.ini>:

    [Prereqs / pluginbundle version]
    -phase = develop
    -relationship = recommends
    Dist::Zilla::PluginBundle::Git::NextVersion = <current installed version>

    [RewriteVersion::Transitional]
    :version = 0.004

    [MetaProvides::Update]

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
    -phase = .. if plugin_prereq_phase specified ..
    -relationship = .. if plugin_prereq_relationship specified ..
    ...all the plugins this bundle uses...

=for Pod::Coverage configure

=head1 OPTIONS / OVERRIDES

=for stopwords CopyFilesFromRelease

=head2 bump_only_matching_versions

If your distribution has many module files, and not all of them have a C<$VERSION> declaration that matches the
main module (and distribution) version, set this option to true. This has two effects that differ from the default
case:

=over 4

=item *

while preparing the build and release, I<no> module C<$VERSION> declarations will be altered to match the distribution version (therefore they must be set to the desired values in advance). Consequently, attempting to alter the distribution version with C<V=...> will result in a fatal error.

=item *

after the release, only module C<$VERSION> declarations that match the release version will see their values incremented. All C<$VERSION>s that do not match will be left alone: you must manage them manually. Likewise, no missing $VERSIONs will be added.

=back

Defaults to false (meaning all modules will have their C<$VERSION> declarations synchronized before release and
incremented after release).

First available in version 0.003.

=head2 commit_files_after_release

File(s), which are expected to exist in the repository directory,
to be committed to git as part of the release commit. Can be used more than once.
When specified, the default is appended to, rather than overwritten.
Defaults to F<Changes>.

Note that you are responsible for ensuring these files are in the repository
(perhaps by using L<[CopyFilesFromRelease]|Dist::Zilla::Plugin::CopyFilesFromRelease>.
Additionally, the file(s) will not be committed if they do not already have git history;
for new files, you should add the C<add_files_in = .> configuration (and use
L<[Git::Check]|Dist::Zilla::Plugin::Git::Check> to ensure that B<only> these files
exist in the repository, not any other files that should not be added.)

=head2 changes_version_columns

An integer that specifies how many columns (right-padded with whitespace) are
allocated in F<Changes> entries to the version string. Defaults to 10.
Unused if C<NextRelease.format = anything> is passed into the configuration.

=for stopwords customizations

=head2 plugin_prereq_phase, plugin_prereq_relationship

If these are set, then plugins used by the bundle (with minimum version requirements) are injected into the
distribution's prerequisites at the specified phase and relationship. By default these options are disabled. If
set, the recommended values are C<develop> and C<suggests>.

First available in version 0.004.

=head2 other customizations

This bundle makes use of L<Dist::Zilla::Role::PluginBundle::PluginRemover> and
L<Dist::Zilla::Role::PluginBundle::Config::Slicer> to allow further customization.
(Note that even though some overridden values are inspected in this class,
they are still overlaid on top of whatever this bundle eventually decides to
pass -- so what is in the F<dist.ini> or in the C<add_bundle> arguments always
trumps everything else.)

Plugins are not loaded until they are actually needed, so it is possible to
C<--force>-install this plugin bundle and C<-remove> some plugins that do not
install or are otherwise problematic (although release functionality will
likely be broken, you should still be able to build the distribution, more or less).

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
