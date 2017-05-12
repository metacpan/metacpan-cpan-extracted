use strict;
package Dist::Zilla::PluginBundle::Author::MAXHQ;
# ABSTRACT: MAXHQ's default Dist::Zilla configuration
$Dist::Zilla::PluginBundle::Author::MAXHQ::VERSION = '3.3.3';
#pod =encoding UTF-8
#pod
#pod =head1 SYNOPSIS
#pod
#pod Put following into your C<My-Module/dist.ini>:
#pod
#pod     [@Author::MAXHQ]
#pod     GatherDir.exclude_match = ^[^\/\.]+\.txt$
#pod     PodWeaver.replacer = replace_with_nothing
#pod     ReadmeAnyFromPod = no
#pod
#pod =head2 DESCRIPTION
#pod
#pod The bundles' behaviour can be altered by the following options:
#pod
#pod =for :list
#pod * C<GatherDir.exclude_match> - a regex specifying which files or directories to
#pod   ignore (they are not processed and thus not added to the distribution tarball).
#pod   This option can be specified several times for different regexes.
#pod * C<PodWeaver.replacer> - Which replacer to use for POD sections.
#pod   See L<Pod::Elemental::PerlMunger>.
#pod   Currently possible values: "replace_with_nothing",
#pod   "replace_with_comment" (default), "replace_with_blank"
#pod
#pod =head1 OVERVIEW
#pod
#pod Currently this plugin bundle is equivalent to:
#pod
#pod     #
#pod     # Include files tracked by Git with some exceptions
#pod     #
#pod     [Git::GatherDir]
#pod     exclude_match = ^cpanfile$
#pod     exclude_match = ^cpanfile.snapshot$
#pod     exclude_match = \A[^\/]+\.ini\Z
#pod     exclude_match = \A[^\/]+\.tar\.gz\Z
#pod     exclude_match = ^\.build\b
#pod     exclude_match = ^\.git\b
#pod     exclude_match = ^\.svn\b
#pod     exclude_match = ^extlib\b
#pod     exclude_match = ^local\b
#pod     exclude_match = ^CVS\b
#pod     include_dotfiles = 1
#pod
#pod     [PruneCruft]
#pod     [ExecDir]
#pod     dir = bin
#pod
#pod     [ShareDir]
#pod     dir = share/dist/My-Module
#pod
#pod     #
#pod     # Conversion and replacements
#pod     #
#pod     [Authority]
#pod
#pod     [PkgVersion]
#pod     die_on_existing_version = 1
#pod     die_on_line_insertion   = 1
#pod
#pod     [NextRelease]
#pod     format = '%-9v %{yyyy-MM-dd}d'
#pod
#pod     [PreviousVersion::Changelog]
#pod     [NextVersion::Semantic]
#pod     major = *NEW FEATURES, *API CHANGES
#pod     minor = +ENHANCEMENTS
#pod     revision = REVISION, BUG FIXES, DOCUMENTATION
#pod     numify_version = 1
#pod     format = %d.%03d%03d
#pod
#pod     [PodWeaver]
#pod     config_plugin = @Author::MAXHQ
#pod     replacer      = replace_with_comment
#pod
#pod     #
#pod     # Prerequisites
#pod     #
#pod     [Prereqs::FromCPANfile]
#pod     [Prereqs::AuthorDeps]
#pod     [AutoPrereqs]
#pod
#pod     [Prereqs / MAXHQ]
#pod     -phase = runtime
#pod     -relationship = requires
#pod     Pod::Elemental::Transformer::List = 0.102000
#pod
#pod     [Prereqs / MAXHQ-DEV]
#pod     -phase = devlop
#pod     -relationship = requires
#pod     Pod::Coverage::TrustPod = 0.100003
#pod
#pod     [RemovePrereqs]
#pod     remove = strict
#pod
#pod     [CheckSelfDependency]
#pod
#pod     #
#pod     # Auto generation --- meta info
#pod     #
#pod     [Authority]
#pod     do_munging = 0
#pod     [MetaProvides::Package]
#pod     [MetaConfig]
#pod
#pod     #
#pod     # Auto generation --- generate files
#pod     #
#pod     [ModuleBuild]
#pod     [MetaYAML]
#pod     [MetaJSON]
#pod     [Manifest]
#pod     [License]
#pod     [ReadmeAnyFromPod]
#pod     [CPANFile]
#pod
#pod     [MetaNoIndex]
#pod     directory = t
#pod     directory = xt
#pod     directory = inc
#pod     directory = share
#pod     directory = eg
#pod     directory = examples
#pod
#pod     #
#pod     # Auto generation --- tests
#pod     #
#pod     [Test::Inline]
#pod     [RunExtraTests]
#pod     [Test::Perl::Critic]
#pod     [PodSyntaxTests]
#pod     [Test::Pod::Coverage::Configurable]
#pod     [Test::Pod::No404s]
#pod     [Test::Pod::LinkCheck]
#pod     [Test::EOL]
#pod     [Test::NoTabs]
#pod
#pod     #
#pod     # Copy files back into project dir
#pod     #
#pod     [CopyFilesFromBuild]
#pod     copy = cpanfile
#pod
#pod     #
#pod     # Release
#pod     #
#pod     [TestRelease]
#pod
#pod     [Git::Check]
#pod     allow_dirty => cpanfile
#pod
#pod     [Git::Commit]
#pod     allow_dirty => cpanfile
#pod     allow_dirty => Changes
#pod     commit_msg = Release %v%n%n%c
#pod
#pod     [Git::Tag]
#pod     tag_format  = %v
#pod     ;# make a lightweight tag
#pod     tag_message =
#pod     [Git::Push]
#pod
#pod     [ConfirmRelease]
#pod
#pod =cut

use Moose;

# choose the easy way of configuring a plugin bundle
with 'Dist::Zilla::Role::PluginBundle::Easy';



#pod =for Pod::Coverage mvp_multivalue_args
#pod
#pod =cut
#
#"If you want a configuration option that takes more than one value, you'll need
#to mark it as multivalue arg by having its name returned by
#C<mvp_multivalue_args>."
#
#Queried by L<Dist::Zilla>.
#
sub mvp_multivalue_args { return qw(GatherDir.exclude_match) }

#pod =for Pod::Coverage _warn
#pod
#pod =cut
sub _warn {
    my $name = __PACKAGE__;
    $name =~ s/^Dist::Zilla::PluginBundle:://;
    warn sprintf("[%s] %s\n", $name, join("", @_));
}

#pod =method add_plugins_if_wanted
#pod
#pod Adds the given plugins unless there is a configuration option given to the
#pod plugin bundle that tells not to use it.
#pod
#pod E.g. plugin 'PruneCruft' is used unless the following is given:
#pod
#pod     [@Author::MAXHQ]
#pod     PruneCruft = no
#pod
#pod =cut
sub add_plugins_if_wanted {
    my ($self, @plugin_specs) = @_;

    my @plugin_specs_filtered = ();
    foreach my $this_spec (@plugin_specs) {
        my $moniker = ref $this_spec ? $this_spec->[0] : $this_spec;
         # skip plugin if told by user
        if (grep { $moniker =~ /^\Q$_\E$/ && $self->payload->{$_} =~ /^no$/i } keys %{$self->payload}) {
            _warn("Skipping plugin $moniker");
            next;
        }
        # otherwise add to list
        push @plugin_specs_filtered, $this_spec;
    }
    $self->add_plugins(@plugin_specs_filtered);
}

#pod =for Pod::Coverage configure
#pod
#pod =cut
#
#Required by role L<Dist::Zilla::Role::PluginBundle::Easy>.
#
#Configures the plugins of this bundle.
#
sub configure {
    my $self = shift;

    # build this array by merging...
    my @exclude_matches = (
        # ...the parameter (or an empty ref)
        @{ $self->payload->{'GatherDir.exclude_match'} || [] },
        # ...with the default options (exclude certain files at top level)
        # note: cpanfile is parsed by [Prereqs::FromCPANfile] and the release version created
        # note: each subdir is matched separately, i.e. not the whole file path
        qw(
            ^cpanfile$
            ^cpanfile.snapshot$
            ^(?!(dist|weaver)\.ini)\w+\.ini$
            ^\w+\.tar\.gz$
            ^extlib$
            ^local$
            ^\.build$
            ^\.git$
            ^\.svn$
            ^CVS$
        )
    );

    my $build_myself = $self->payload->{build_myself};

    $self->add_plugins_if_wanted(
        #
        # Files included
        #
        ['Git::GatherDir' => {                 # skip files on top level
            exclude_match => [ @exclude_matches ],
            include_dotfiles => 1, # needed e.g. for ".devdir",
        }],
        'PruneCruft',                     # prune stuff you probably don't want

        ['ExecDir' => {                   # install contents of bin/ as executable
            dir => 'bin',
        }],
        'ShareDir::ProjectDistDir',       # include all files in /share/dist/My-Dist

        #
        # Conversion and replacements
        #
        ['PkgVersion' => {                # insert version number in first blank line
            die_on_existing_version => 1,
            die_on_line_insertion   => 1,
        }],
        ['NextRelease' => {               # replace {{$NEXT}} in "Changes" file with new version and
            format => '%-9v %{yyyy-MM-dd}d', # date (MUST be included before NextVersion::Semantic)
        }],
        'PreviousVersion::Changelog',     # fetch previous version from changelog
                                          # alternatively run: V=0.00100 dzil release
        ['NextVersion::Semantic' => {     # generate next version based on type of changes
            major => '*NEW FEATURES, *API CHANGES',
            minor => '+ENHANCEMENTS',
            revision => 'REVISION, BUG FIXES, DOCUMENTATION',
            format => '%d.%3d.%3d',
        }],
        # Please note that * and ! are mainly there to enforce correct ordering
        # as CPAN::Changes::Release (used in NextVersion::Semantic) just sorts
        # groups alphabetically

        # weave your Pod together from configuration and Dist::Zilla
        # (turns "# ABSTRACT" into POD, processes =method and short lists etc.)
        # To exclude files from PodWeaver see: http://blogs.perl.org/users/polettix/2011/11/distzilla-podweaver-and-bin.html
        ['PodWeaver' => {
            config_plugin => '@Author::MAXHQ',
            replacer      =>
                $self->payload->{'PodWeaver.replacer'}
                || 'replace_with_comment', # replace original POD with comments to preserve line numbering

        }],

        #
        # Prerequisites
        #
        !$build_myself
            ? 'Prereqs::FromCPANfile'     # use prereqs from "cpanfile"
            : ['Prereqs' => { 'Dist::Zilla::Plugin::Prereqs::FromCPANfile' => 0 }], # add manually because [MAXHQ::BundleDepsDeep] wont see it
        'AutoPrereqs',                    # collect prereqs from modules
        ['RemovePrereqs' => {
            'remove' => [ qw( strict warnings ) ],
        }],

        'CheckSelfDependency',            # Make sure no packages of this dist ended up in the prerequisites list

        #
        # Auto generation --- meta info
        #
        ['Authority' => {                 # Add authority
            'do_munging' => 0,
        }],
        'MetaProvides::Package',          # specify provided packages in META.* instead of letting PAUSE figure them out
        'MetaConfig',                     # add Dist::Zilla info to META.*

        #
        # Auto generation --- generate files
        #
        'ModuleBuildTiny',                # add Build.PL that will use Module::Build::Tiny to install the distribution
        'Manifest',                       # add Manifest (list of all files)
        'MetaYAML',                       # add META.yml (supports CPAN::Meta::Spec v1.4)
        'MetaJSON',                       # add META.json (supports CPAN::Meta::Spec v2.0 upwards)
        'CPANFile',                       # add "cpanfile"
        'License',                        # add LICENSE
        'ReadmeAnyFromPod',               # add README (with dist's name, version, abstract, license)
        ['MetaNoIndex' => {               # prevent CPAN from indexing these files (taken from https://metacpan.org/pod/Dist::Zilla::PluginBundle::Starter)
            'directory' => [ qw( t xt inc share eg examples ) ],
            $build_myself                 # don't index private modules of this bundle
                ? ( 'package' => [ qw(
                    Dist::Zilla::Plugin::ShareDir::ProjectDistDir
                    Dist::Zilla::Plugin::MAXHQ::BundleDepsDeep
                ) ] )
                : (),
        }],

        #
        # Auto generation --- tests
        #
        'Test::Inline',                   # generate .t files from inline test code (POD)

        # auto-generate various tests
        'RunExtraTests',
        'Test::Perl::Critic',
        'Test::Pod::Coverage::Configurable',
        'PodSyntaxTests',
        'Test::Pod::No404s',
        'Test::Pod::LinkCheck',
        'Test::EOL',
        'Test::NoTabs',

        #
        # Replacement of files in project dir
        #
        [ 'CopyFilesFromBuild' => {     # copy cpanfile back into project dir
            'copy' => 'cpanfile',
        }],

        #
        # Release
        #
        'TestRelease',                    # test before releasing

        ['Git::Check' => {                # check for dirty files etc.
            'allow_dirty' => 'cpanfile',  # ignore cpanfile because we copy it back from release
        }],
        ['Git::Commit' => {
            'allow_dirty' => [
                'cpanfile',  # add cpanfile because we copy it back from release
                'Changes',   # add Changes because it's modified by [NextRelease]
            ],
            'commit_msg' => 'Release %v%n%n%c',
        }],
        ['Git::Tag' => {
            'tag_format' => '%v',
            'tag_message' => '',          # make a lightweight tag
        }],
        'Git::Push',

        'ConfirmRelease',                 # ask for confirmation before releasing

        # almost at the end to capture all other plugins
        $build_myself ? 'MAXHQ::BundleDepsDeep' : (),
        # after [MAXHQ::BundleDepsDeep] so that dependencies are not copied to phase "runtime"
        'Prereqs::AuthorDeps',            # "adds Dist::Zilla and the result of "dzil
                                          # authordeps" to the 'develop' phase prerequisite list"
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

{
    package Dist::Zilla::Plugin::ShareDir::ProjectDistDir;
    # ABSTRACT: install "ShareDir" content and make other modules happy
$Dist::Zilla::Plugin::ShareDir::ProjectDistDir::VERSION = '3.3.3';
    # fullfill File::ShareDir::ProjectDistDir strict mode and be compatible with Module::Build::Tiny

    use Moose;
    use namespace::autoclean;

    with 'Dist::Zilla::Role::FileMunger';
    with 'Dist::Zilla::Role::ShareDir';

    use File::Spec;

    # FileMunger plugins are executed before ShareDir plugins, so the ShareDir
    # code below will see the already moved files.

    # In contrast to Dist::Zilla::Plugin::ShareDir we use this for the munger
    has dir => (
        is     => 'ro',
        isa    => 'Str',
        lazy => 1,
        default => sub {
            my ($self) = @_;
            return File::Spec->catfile('share', 'dist', $self->zilla->name);
        },
    );

    #
    # ShareDir code
    #
    sub find_files { # Required by Dist::Zilla::Role::ShareDir
        my ($self) = @_;
        return [
            grep { index($_->name, "share/") == 0 } @{ $self->zilla->files }
        ];
    }

    sub share_dir_map {
        my ($self) = @_;
        my $files = $self->find_files;
        return unless @$files;
        return { dist => "share" };
    }

    #
    # FileMunger code
    #
    # Moves files from share/dist/My-Dist to share/ to comply with Module::Build::Tiny
    sub munge_files {
        my ($self) = @_;
        for my $file (@{ $self->zilla->files }) {
            my @dirs = File::Spec->splitdir($file->name);
            # process files under share/
            next unless $dirs[0] eq "share";
            # if the sharedir equals $self->dir (i.e. share/dist/My-Dist per default)
            if (File::Spec->catdir(@dirs[0..2]) eq $self->dir) {

                splice(@dirs, 1, 2);
                $file->name( File::Spec->catdir(@dirs) );
            }
        }
    }

    __PACKAGE__->meta->make_immutable;
}

{
    package Dist::Zilla::Plugin::MAXHQ::BundleDepsDeep;
    # ABSTRACT: register all needed plugins in a bundle as runtime requirements
$Dist::Zilla::Plugin::MAXHQ::BundleDepsDeep::VERSION = '3.3.3';
use Moose;
    use namespace::autoclean;

    with 'Dist::Zilla::Role::PrereqSource';

    use Module::Metadata;
    use Distribution::Metadata;

    sub register_prereqs {
        my ($self) = @_;

        my $req = $self->zilla->prereqs; # class Dist::Zilla::Prereqs
        my $cpan_req = $req->cpan_meta_prereqs; # class CPAN::Meta::Prereqs

        #
        # Add all "develop" phase prerequisites as "runtime" prerequisites
        # because they might have been injected by plugins (and we assume all
        # plugins of the pluginbundle will be used later, so the prerequisites
        # are needed.
        #
        $self->log("Copying plugins from phase 'develop' to 'runtime'");
        my $devreq = $cpan_req->requirements_for('develop', 'requires'); # class CPAN::Meta::Requirements
        my $devreq_str = $devreq->as_string_hash;
        $self->zilla->register_prereqs(
            {
                phase => 'runtime',
                type  => 'requires',
            },
            %$devreq_str,
        );

        #
        # Add all active plugins as runtime requirements
        # (if not already there with a version number)
        #
        $self->log("Registering currently used plugins as 'runtime' requirements");

        # Try to find list of Dist::Zilla's own packages
        my $dzil_meta = Distribution::Metadata->new_from_module("Dist::Zilla");
        my $dzil_pkg = {};
        if ($dzil_meta->install_json) {
            $self->log("Excluding packages of Dist::Zilla distribution");
            $dzil_pkg = $dzil_meta->install_json_hash->{provides};
        }

        # list of active plugins with currently installed versions
        my $plugins = {
            map {
                my $mod = $_;
                $mod = "Dist::Zilla" if $dzil_pkg->{$mod};
                my $meta = Module::Metadata->new_from_module($mod);
                $mod => $meta ? $meta->version->stringify : 0
            }
            map { ref } # get class name
            @{$self->zilla->plugins} # RJBS mentions that this attribute might go away!
        };

        my $runreq = $cpan_req->requirements_for('runtime', 'requires'); # class CPAN::Meta::Requirements
        my $runreq_str = $runreq->as_string_hash;

        # add plugins as runtime requirements unless they're already defined
        my $plugin_prereqs = {};
        for my $module (sort keys %$plugins) {
            my $ver = $runreq_str->{$module};
            next if $ver;  # don't overwrite specs coming from elsewhere
            $plugin_prereqs->{$module} = $plugins->{$module};
        }
        $self->zilla->register_prereqs(
            {
                phase => 'runtime',
                type  => 'requires',
            },
            %$plugin_prereqs,
        );
    }

    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::Author::MAXHQ - MAXHQ's default Dist::Zilla configuration

=head1 VERSION

version 3.3.3

=head1 SYNOPSIS

Put following into your C<My-Module/dist.ini>:

    [@Author::MAXHQ]
    GatherDir.exclude_match = ^[^\/\.]+\.txt$
    PodWeaver.replacer = replace_with_nothing
    ReadmeAnyFromPod = no

=head2 DESCRIPTION

The bundles' behaviour can be altered by the following options:

=over 4

=item *

C<GatherDir.exclude_match> - a regex specifying which files or directories to ignore (they are not processed and thus not added to the distribution tarball). This option can be specified several times for different regexes.

=item *

C<PodWeaver.replacer> - Which replacer to use for POD sections. See L<Pod::Elemental::PerlMunger>. Currently possible values: "replace_with_nothing", "replace_with_comment" (default), "replace_with_blank"

=back

=head1 OVERVIEW

Currently this plugin bundle is equivalent to:

    #
    # Include files tracked by Git with some exceptions
    #
    [Git::GatherDir]
    exclude_match = ^cpanfile$
    exclude_match = ^cpanfile.snapshot$
    exclude_match = \A[^\/]+\.ini\Z
    exclude_match = \A[^\/]+\.tar\.gz\Z
    exclude_match = ^\.build\b
    exclude_match = ^\.git\b
    exclude_match = ^\.svn\b
    exclude_match = ^extlib\b
    exclude_match = ^local\b
    exclude_match = ^CVS\b
    include_dotfiles = 1

    [PruneCruft]
    [ExecDir]
    dir = bin

    [ShareDir]
    dir = share/dist/My-Module

    #
    # Conversion and replacements
    #
    [Authority]

    [PkgVersion]
    die_on_existing_version = 1
    die_on_line_insertion   = 1

    [NextRelease]
    format = '%-9v %{yyyy-MM-dd}d'

    [PreviousVersion::Changelog]
    [NextVersion::Semantic]
    major = *NEW FEATURES, *API CHANGES
    minor = +ENHANCEMENTS
    revision = REVISION, BUG FIXES, DOCUMENTATION
    numify_version = 1
    format = %d.%03d%03d

    [PodWeaver]
    config_plugin = @Author::MAXHQ
    replacer      = replace_with_comment

    #
    # Prerequisites
    #
    [Prereqs::FromCPANfile]
    [Prereqs::AuthorDeps]
    [AutoPrereqs]

    [Prereqs / MAXHQ]
    -phase = runtime
    -relationship = requires
    Pod::Elemental::Transformer::List = 0.102000

    [Prereqs / MAXHQ-DEV]
    -phase = devlop
    -relationship = requires
    Pod::Coverage::TrustPod = 0.100003

    [RemovePrereqs]
    remove = strict

    [CheckSelfDependency]

    #
    # Auto generation --- meta info
    #
    [Authority]
    do_munging = 0
    [MetaProvides::Package]
    [MetaConfig]

    #
    # Auto generation --- generate files
    #
    [ModuleBuild]
    [MetaYAML]
    [MetaJSON]
    [Manifest]
    [License]
    [ReadmeAnyFromPod]
    [CPANFile]

    [MetaNoIndex]
    directory = t
    directory = xt
    directory = inc
    directory = share
    directory = eg
    directory = examples

    #
    # Auto generation --- tests
    #
    [Test::Inline]
    [RunExtraTests]
    [Test::Perl::Critic]
    [PodSyntaxTests]
    [Test::Pod::Coverage::Configurable]
    [Test::Pod::No404s]
    [Test::Pod::LinkCheck]
    [Test::EOL]
    [Test::NoTabs]

    #
    # Copy files back into project dir
    #
    [CopyFilesFromBuild]
    copy = cpanfile

    #
    # Release
    #
    [TestRelease]

    [Git::Check]
    allow_dirty => cpanfile

    [Git::Commit]
    allow_dirty => cpanfile
    allow_dirty => Changes
    commit_msg = Release %v%n%n%c

    [Git::Tag]
    tag_format  = %v
    ;# make a lightweight tag
    tag_message =
    [Git::Push]

    [ConfirmRelease]

=head1 METHODS

=head2 add_plugins_if_wanted

Adds the given plugins unless there is a configuration option given to the
plugin bundle that tells not to use it.

E.g. plugin 'PruneCruft' is used unless the following is given:

    [@Author::MAXHQ]
    PruneCruft = no

=encoding UTF-8

=for Pod::Coverage mvp_multivalue_args

=for Pod::Coverage _warn

=for Pod::Coverage configure

=head1 AUTHOR

Jens Berthold <jens.berthold@jebecs.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jens Berthold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
