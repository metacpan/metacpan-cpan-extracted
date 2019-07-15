package Dist::Zilla::PluginBundle::Author::GSG;

# ABSTRACT: Grant Street Group CPAN dists
our $VERSION = '0.0.12'; # VERSION

use Moose;
with qw(
    Dist::Zilla::Role::PluginBundle::Easy
);
use namespace::autoclean;

sub configure {
    my ($self) = @_;

    my $meta_provides
        = 'MetaProvides::' . ( $self->payload->{meta_provides} || 'Package' );

    $self->add_bundle( 'Filter' => {
        -bundle => '@Basic',
        -remove => [ qw(
            UploadToCPAN
            GatherDir
        ) ]
    } );

    $self->add_plugins(
        'Author::GSG',

        'MetaJSON',
        'OurPkgVersion',
        'Prereqs::FromCPANfile',
        'ReadmeAnyFromPod',
        $meta_provides,

        [   'StaticInstall' => $self->config_slice(
            {   static_install_mode    => 'mode',
                static_install_dry_run => 'dry_run',
            }
        ) ],

        [   'PodWeaver' => {
                replacer           => 'replace_with_comment',
                post_code_replacer => 'replace_with_nothing',
                config_plugin      => [ '@Default', 'Contributors' ]
            }
        ],

        [ 'ChangelogFromGit' => {
            tag_regexp => '^v(\d+\.\d+\.\d+)$'
        } ],

        [ 'Git::NextVersion' => {
            first_version => '0.0.1',
        } ],

        'Git::Commit',
        'Git::Tag',
        'Git::Push',

        'Git::Contributors',
        'Git::GatherDir',

        'GitHub::Meta',
        'Author::GSG::GitHub::UploadRelease',

        'Test::Compile',
        'Test::ReportPrereqs',
    );
}

__PACKAGE__->meta->make_immutable;

package # hide from the CPAN
    Dist::Zilla::Plugin::Author::GSG::GitHub::UploadRelease;
use Moose;
BEGIN { extends 'Dist::Zilla::Plugin::GitHub::UploadRelease' }
with qw(
    Dist::Zilla::Role::Releaser
);

sub release {1} # do nothing, just let the GitHub Uploader do it for us

# TODO: on release, regen README.md in src dir

around 'after_release' => sub {
    my ($orig, $self, @args) = @_;

    my $git_tag_plugin = $self->zilla->plugin_named('@Author::GSG/Git::Tag')
        or $self->log_fatal('Plugin @Author::GSG/Git::Tag not found!');

    # GitHub::UploadRelease looks for the Git::Tag Plugin with this name
    local $git_tag_plugin->{plugin_name} = 'Git::Tag';

    return $self->$orig(@args);
};

sub _get_credentials {
    my ($self, $login_only) = @_;

    my $creds = $self->_credentials;
    # return $creds->{login} if $login_only;

    my $otp;
    $otp = $self->zilla->chrome->prompt_str(
        "GitHub two-factor authentication code for '$creds->{login}'",
        { noecho => 1 },
    ) if $self->prompt_2fa;

    return ( $creds->{login}, $creds->{pass}, $otp );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::GSG - Grant Street Group CPAN dists

=head1 VERSION

version 0.0.12

=head1 SYNOPSIS

Your C<dist.ini> can be as short as this:

    name = Foo-Bar-GSG
    [@Author::GSG]

Which is equivalent to all of this:

Some of which comes from L<Dist::Zilla::Plugin::Author::GSG>.

    name = Foo-Bar-GSG
    author = Grant Street Group <developers@grantstreet.com>
    license = Artistic_2_0
    copyright_holder = Grant Street Group
    copyright_year = # detected from git

    [@Filter]
    -bundle = @Basic
    -remove = UploadToCPAN
    -remove = GatherDir

    # The defaults for author and license come from
    #[Author::GSG]

    [MetaJSON]
    [OurPkgVersion]
    [Prereqs::FromCPANfile]
    [ReadmeAnyFromPod]
    [$meta_provides] # defaults to MetaProvides::Package

    [StaticInstall]
    # mode    from static_install_mode
    # dry_run from static_install_dry_run

    [Pod::Weaver]
    replacer = replace_with_comment
    post_code_replacer = replace_with_nothing
    config_plugin = [ @Default, Contributors ]

    [ChangelogFromGit]
    tag_regexp = ^v(\d+\.\d+\.\d+)$

    [Git::NextVersion]
    first_version = 0.0.1

    [Git::Commit]
    [Git::Tag]
    [Git::Push]

    [Git::Contributors]
    [Git::GatherDir]

    [GitHub::Meta]
    [GitHub::UploadRelease] # plus magic to work without releasing elsewhere

    [Test::Compile]
    [Test::ReportPrereqs]

=head1 DESCRIPTION

This PluginBundle is here to make it easy for folks at GSG to release
public distributions of modules as well as trying to make it easy for
other folks to contribute.

The C<share_dir> for this module includes GSG standard files to include
with open source modules.  Things like a standard Makefile,
a contributing guide, and a MANIFEST.SKIP that should work with this Plugin.
See the L</update> Makefile target for details.

The expected workflow for a module using this code is that after following
the initial setup decribed below, you would manage changes via standard
GitHub flow pull requests and issues.
When ready for a release, you would first C<make update> to update
any included documents, commit those,
and then run C<carton exec dzil release>.
You can set a specific release version with the C<V> environment variable,
as described in the
L<Git::NextVersion Plugin|Dist::Zilla::Plugin::Git::NextVersion> documentation.

=head1 ATTRIBUTES / PARAMETERS

=over

=item meta_provides

    [@Author::GSG]
    meta_provides = Class

The L<MetaProvides|Dist::Zilla::Plugin::MetaProvides> subclass to use.

Defaults to C<Package|Dist::Zilla::Plugin::MetaProvides::Package>.

If you choose something other than the default,
you will need to add an "on develop" dependency to your C<cpanfile>.

=item static_install_mode

Passed to L<Dist::Zilla::Plugin::StaticInstall> as C<mode>.

=item static_install_dry_run

Passed to L<Dist::Zilla::Plugin::StaticInstall> as C<dry_run>.

=back

=head1 Setting up a new dist

=head2 Create your dist.ini

As above, you need the C<name> and C<[@Author::GSG]> bundle,
plus any other changes you need.

=head2 Add Dist::Zilla::PluginBundle::Author::GSG to your cpanfile

    on 'develop' => sub {
        requires 'Dist::Zilla::PluginBundle::Author::GSG';
    };

Doing this in the C<develop> phase will cause the default Makefile
not to install it, which means folks contributing to a module
won't need to install all of the Dist::Zilla dependencies just to
submit some patches, but will be able to run most tests.

=head2 Create a Makefile

It is recommended to keep a copy of the Makefile from this PluginBundle
in your app and update it as necessary, which the target in the included
Makefile will do automatically.

An initial Makefile you could use to copy one out of this PluginBundle
might look like this:

    SHARE_DIR   := $(shell \
        carton exec perl -Ilib -MFile::ShareDir=dist_dir -e \
            'print eval { dist_dir("Dist-Zilla-PluginBundle-Author-GSG") } || "share"' )

    include $(SHARE_DIR)/Makefile

    # Copy the SHARE_DIR Makefile over this one:
    # Making it .PHONY will force it to copy even if this one is newer.
    .PHONY: Makefile
    Makefile: $(SHARE_DIR)/Makefile.inc
    	cp $< $@

Using this example Makefile does require you run C<carton install> after
adding the C<on 'develop'> dependency to your cpanfile as described above.

If you want to override the Makefile included with this Plugin
but still want to use some of the targets in it,
you could replace the C<Makefile> target in this example with your own targets,
and document running the initial C<carton install> manually.

The Makefile that comes in this PluginBundle's C<share_dir> has a many
helpers to make development on a module supported by it easier.

Some of the targets that are included in the Makefile are:

=over

=item test

Makes your your C<local> C<cpanfile.snapshot> is up-to-date and
if not, will run L<Carton> before running C<prove -lfr t>.

=item testcoverage

This target runs your tests under the L<Devel::Cover> C<cover> utility.
However, C<Devel::Cover> is not normally a dependency,
so you will need to add it to the cpanfile temporarily for this target to work.

=item Makefile

Copies the C<Makefile.inc> included in this PluginBundle's C<share_dir>
into your distribution.

This should happen automatically through the magic of C<make>.

=item update

Generates README.md and copies some additional files from this
PluginBundle's C<share_dir> into the repo so that the shared
documents provided here will be kept up-to-date.

=over

=item README.md

This is generated from the post C<Pod::Weaver> documentation of the
main module in the dist.
Requires installing the C<develop> cpanfile dependencies to work.

=item $(CONTRIB)

The files in this variable are copied from this PluginBundle's

Currently includes C<CONTRIBUTING.md> and C<MANIFEST.SKIP>.

=back

=item $(CPANFILE_SNAPSHOT)

Attempts to locate the correct C<cpanfile.snapshot> and
automatically runs C<carton install $(CARTON_INSTALL_FLAGS)> if
it is out of date.

The C<CARTON_INSTALL_FLAGS> are by default C<--without develop>
in order to avoid unnecessarily installing the heavy C<Dist::Zilla>
dependency chain.

=back

=head2 Cutting a release

    carton exec dzil release

This should calculate the new version number, build a new release tarball,
add a release tag, create the release on GitHub and upload the tarball to it.

You can set the C<V> environment variable to force a specific version,
as described by L<Dist::Zilla::Plugin::Git::NextVersion>.

    V=2.0.0 carton exec dzil release

=over

=item Your git remote must be a format GitHub::UploadRelease understands

Either
C<ssh://git@github.com/GrantsStreetGroup/$repo.git>
or
C<https://github.com/GrantsStreetGroup/$repo.git>.

As shown in the "Fetch URL" from C<git remote -n $remote>,

=item Set C<github.user> and either C<github.password> or C<github.token>

You should probably use a token instead of your password,
which you can get by following
L<GitHub's instructions|https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line>.

    git config --global github.user  github_login_name
    git config --global github.token token_from_instructions_above

=back

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 CONTRIBUTORS

=for stopwords Andrew Fresh Mark Flickinger

=over 4

=item *

Andrew Fresh <andrew.fresh@grantstreet.com>

=item *

Mark Flickinger <mark.flickinger@grantstreet.com>

=back

=cut
