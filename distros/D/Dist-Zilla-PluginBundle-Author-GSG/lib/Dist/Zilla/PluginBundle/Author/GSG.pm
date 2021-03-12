package Dist::Zilla::PluginBundle::Author::GSG;

# ABSTRACT: Grant Street Group CPAN dists
use version;
our $VERSION = 'v0.2.0'; # VERSION

use Carp;
use Git::Wrapper;

use Moose;
with qw(
    Dist::Zilla::Role::PluginBundle::Easy
);
use namespace::autoclean;

sub mvp_multivalue_args { qw(
    exclude_filename
    exclude_match
    test_compile_skip
    test_compile_file
    test_compile_module_finder
    test_compile_script_finder
    test_compile_switch
    dont_munge
) }

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

    # We need to reconfigure the MakeMaker Plugin to require
    # a new enough version to support "version ranges".
    # https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/issues/215
    my ($mm)
        = grep { $_->[1] eq 'Dist::Zilla::Plugin::MakeMaker' }
        @{ $self->plugins };

    $mm->[2]->{eumm_version} = '7.1101';

    my $name = $self->name;

    $self->add_plugins(
        'Author::GSG',

        [ 'FileFinder::Filter' => 'MungeableFiles' => {
            finder => [ ':InstallModules', ':PerlExecFiles' ],
            %{ $self->config_slice({ dont_munge => 'skip' }) }
        }],

        'MetaJSON',
        [ 'OurPkgVersion' => {
            finder           => [ "$name/MungeableFiles" ],
            semantic_version => 1,
        } ],
        'Prereqs::FromCPANfile',
        $meta_provides,

        [ 'StaticInstall' => $self->config_slice( {
            static_install_mode    => 'mode',
            static_install_dry_run => 'dry_run',
        } ) ],

        # StaticInstall wants scripts in a script/ ExecDir
        [ 'ExecDir' => { dir => 'script' } ],

        [ 'PodWeaver' => {
            finder             => [ "$name/MungeableFiles" ],
            replacer           => 'replace_with_comment',
            post_code_replacer => 'replace_with_nothing',
            config_plugin      => [ '@Default', 'Contributors' ]
        } ],

        'ReadmeAnyFromPod',
        [ 'ChangelogFromGit::CPAN::Changes' => {
            file_name    => 'CHANGES',
            # Support both old 0.90 versioning and new v1.2.3 semantic versioning formats
            tag_regexp   => '\b(v?\d+\.\d+(?:\.\d+)*)\b',
            copy_to_root => 0,
        } ],

        [ 'Author::GSG::Git::NextVersion' => {
            first_version  => 'v0.0.1',
            version_regexp => '\b(v\d+\.\d+\.\d+)\b',
        } ],

        'Git::Commit',
        'Git::Tag',
        'Git::Push',

        [ 'Git::GatherDir' => $self->config_slice( qw<
            exclude_filename
            exclude_match
            include_dotfiles
        > ) ],

        'GitHub::Meta',
        'Author::GSG::GitHub::UploadRelease',

        [ 'Test::Compile' => $self->config_slice( {
            map {; "test_compile_$_" => $_ } qw<
                filename
                phase
                skip
                file
                fake_home
                needs_display
                fail_on_warning
                bail_out_on_fail
                module_finder
                script_finder
                xt_mode
                switch
            >
        } ) ],

        'Test::ReportPrereqs',
    );

    my ($gather_dir)
        = grep { $_->[1] eq 'Dist::Zilla::Plugin::Git::GatherDir' }
        @{ $self->plugins };

    push @{ $gather_dir->[2]->{exclude_filename} },
        qw< README.md LICENSE.txt >;

    # By default we want to set the github remote,
    # but "subclasses" may not want that, so make them
    # calculate the github_remote themselves.
    $self->payload->{find_github_remote} //=
        $self->name eq '@Author::GSG';

    # Look for the GitHub remote, or fail, if we are supposed to.
    if ( $self->payload->{find_github_remote} ) {
        $self->payload->{github_remote} //= $self->_find_github_remote
            // croak "Unable to find git remote for GitHub";
    }

    $self->_set_github_remote( $self->payload->{github_remote} )
        if defined $self->payload->{github_remote}
        and length $self->payload->{github_remote};
}


sub _set_github_remote {
    my ( $self, $remote ) = @_;

    my @git;
    my @github;

    foreach my $plugin ( @{ $self->plugins } ) {
        if ( $plugin->[1] =~ /GitHub/ ) {
            push @github, $plugin;
        }
        elsif ( $plugin->[1] =~ /Git/ ) {
            push @git, $plugin;
        }
    }

    # All our git/github plugins configure this way, so good enough?
    $_->[2]->{push_to} = [$remote] for @git;
    $_->[2]->{remote}  = $remote   for @github;

    return $remote;
}

sub _find_github_remote {
    my ($self) = @_;

    # If it's a git issue finding the remote,
    # the user can figure it out.
    my @remotes = do { local $@; eval { local $SIG{__DIE__};
        Git::Wrapper->new('.')->remote('-v') } };

    my $remote;

    for (@remotes) {
        my ( $name, $url, $direction )
            = /^ (\P{PosixCntrl}+) \s+ (.*) \s+ \( ([^)]+) \) $/x;

        next unless ( $direction || '' ) eq 'push';

        if ( $url
            =~ m{(?: :// | \@ ) (?: [\w\-\.]+\. )? github\.com [/:] }ix )
        {
            croak "Multiple git remotes found for GitHub" if defined $remote;
            $remote = $name;
        }
    }

    return $remote;
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

package # hide from the CPAN
    Dist::Zilla::Plugin::Author::GSG::Git::NextVersion;
use Moose;
BEGIN { extends 'Dist::Zilla::Plugin::Git::NextVersion' }

before 'provide_version' => sub {
    if ( my $v = $ENV{V} ) {
        $v =~ s/^v//;
        my @v = split /\./, $v;

        Carp::croak "Invalid version '$ENV{V}' in \$ENV{V}"
            if @v > 3 or grep /\D/, @v;

        # perl v5.22+ complain about too many arguments to printf
        $ENV{V} = sprintf "v%d.%d.%d", (@v, 0, 0, 0)[0..2];
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::GSG - Grant Street Group CPAN dists

=head1 VERSION

version v0.2.0

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

    ; The MakeMaker Plugin gets an additional setting
    ; in order to support "version ranges".
    eumm_version = 7.1101

    ; We try to guess which remote to use to talk to GitHub
    ; but you can hardcode a value if necessary
    github_remote = # detected from git if find_github_remote is set

    ; Enabled by default if the PluginBundle name is Author::GSG
    ; This means Filters do not automatically get it set
    find_github_remote = 1

    ; The defaults for author and license come from
    [Author::GSG]

    [ FileFinder::Filter / MungeableFiles ]
    finder => :InstallModules
    finder => :PerlExecFiles
    ; dont_munge = (?^:bin) # can be used multiple times. passed in as "skip"

    [MetaJSON]
    [OurPkgVersion]
    finder = :MungableFiles
    [Prereqs::FromCPANfile]
    [$meta_provides] # defaults to MetaProvides::Package

    [StaticInstall]
    ; mode    from static_install_mode
    ; dry_run from static_install_dry_run

    [ExecDir]
    dir = script    # in addition to bin/ for StaticInstall compatibility

    [PodWeaver]
    finder     = :MungeableFiles
    replacer = replace_with_comment
    post_code_replacer = replace_with_nothing
    config_plugin = [ @Default, Contributors ]

    [ReadmeAnyFromPod]
    [ChangelogFromGit::CPAN::Changes]
    file_name    = CHANGES
    ; Support both old 0.90 versioning and new v1.2.3 semantic versioning formats
    tag_regexp   = \b(v?\d+\.\d+(?:\.\d+)*)\b
    copy_to_root = 0

    [Git::NextVersion] # plus magic to sanitize versions from the environment
    first_version  = v0.0.1
    version_regexp = \b(v\d+\.\d+\.\d+)(?:\.\d+)*\b

    [Git::Commit]
    [Git::Tag]
    [Git::Push]

    [Git::GatherDir]
    ; include_dotfiles
    ; exclude_filename
    ; exclude_match
    exclude_filename = README.md
    exclude_filename = LICENSE.txt

    [GitHub::Meta]
    [GitHub::UploadRelease] # plus magic to work without releasing elsewhere

    [Test::Compile]
    ; test_compile_filename
    ; test_compile_phase
    ; test_compile_skip
    ; test_compile_file
    ; test_compile_fake_home
    ; test_compile_needs_display
    ; test_compile_fail_on_warning
    ; test_compile_bail_out_on_fail
    ; test_compile_module_finder
    ; test_compile_script_finder
    ; test_compile_xt_mode
    ; test_compile_switch

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

The version regexps for both the Changelog and NextVersion
should be open enough to pick up the older style tags we used
as well as incrementing a more strict C<semver>.

=head1 ATTRIBUTES / PARAMETERS

=over

=item github_remote / find_github_remote

Looks in the C<git remote> list for a C<push> remote that matches
C<github.com> (case insensitively) and if we find one,
we pass it to the Git and GitHub Plugins we use.

If no remotes or multiple remotes are found, throws an exception
indicating that you need to add the GitHub remote as described in
L</Cutting a release>.

Trying to find a remote, and failing if it isn't found,
is only enabled if you set C<find_github_remote> to a truthy value.
However, C<find_github_remote> defaults to truthy if the section
name for the PluginBundle is the default, C<@Author::GSG>.

You can disable this, and fall back to each Plugin's default,
by setting C<github_remote> to an empty string.

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

=item include_dotfiles

Passed to L<Dist::Zilla::Plugin::Git::GatherDir/include_dotfiles>.

=item exclude_filename

Passed to L<Dist::Zilla::Plugin::Git::GatherDir/exclude_filename>.

Automatically appends C<README.md> and C<LICENSE.txt> to the list.

=item exclude_match

Passed to L<Dist::Zilla::Plugin::Git::GatherDir/exclude_match>.

=item test_compile_*

    [@Author::GSG]
    test_compile_skip    = ^My::NonCompiling::Module$
    test_compile_xt_mode = 1

All options for L<Dist::Zilla::Plugin::Test::Compile> should be supported
with the C<test_compile_> prefix.

=item dont_munge

    [@Author::GSG]
    dont_munge = (?^:one-off)
    dont_munge = (?^:docs/.*.txt)

Passed to L<Dist::Zilla::Plugin::FileFinder::Filter> as c<skip> for the
C<MungableFiles> plugin.

This plugin gets passed to L<Dist::Zilla::Plugin::OurPkgVersion> and
L<Dist::Zilla::Plugin::PodWeaver> as C<finder> to filter matches.

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

    include $(SHARE_DIR)/Makefile.inc

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

    carton exec -- dzil release

This should calculate the new version number, build a new release tarball,
add a release tag, create the release on GitHub and upload the tarball to it.

You can set the C<V> environment variable to force a specific version,
as described by L<Dist::Zilla::Plugin::Git::NextVersion>.

    V=2.0.0 carton exec -- dzil release

=over

=item Make sure your local checkout has what you want to release

Completing a C<< dzil release >> will commit any changes,
tag the release version to the currently checked out commit,
and push to the remote.

=item Your git remote must be a format GitHub::UploadRelease understands

Either
C<git@github.com:GrantsStreetGroup/$repo.git>,
C<ssh://git@github.com/GrantsStreetGroup/$repo.git>,
or
C<https://github.com/GrantsStreetGroup/$repo.git>.

As shown in the "Fetch URL" from C<git remote -n $remote>,

=item Set C<github.user> and C<github.token>

You can get a GitHub token by following
L<GitHub's instructions|https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line>.

    git config --global github.user  github_login_name
    git config --global github.token token_from_instructions_above

=back

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 - 2021 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
