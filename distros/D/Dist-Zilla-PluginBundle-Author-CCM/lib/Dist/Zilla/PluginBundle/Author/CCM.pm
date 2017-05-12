package Dist::Zilla::PluginBundle::Author::CCM;
# ABSTRACT: A plugin bundle for distributions built by CCM
# KEYWORDS: dzil author bundle distribution tool


use 5.014;
use warnings;
use strict;

our $VERSION = '0.007'; # VERSION

use Dist::Zilla::Util;
use Moose;
use namespace::autoclean;


has authority => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->payload->{'Authority.authority'} // $self->payload->{authority} // 'cpan:CCM';
    },
);


has installer => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->payload->{installer} || 'MakeMaker' },
);


has airplane => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $ENV{DZIL_AIRPLANE} // shift->payload->{airplane} // 0 },
);


has no_upload => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $ENV{DZIL_NO_UPLOAD} // shift->payload->{no_upload} // 0 },
);


sub configure {
    my $self = shift;

    my @copy_from_build     = qw(LICENSE);
    my @network_plugins     = qw(Git::Push Test::Pod::No404s UploadToCPAN);
    my @gather_exclude      = (@copy_from_build, qw(README.md));
    my @gather_prune        = qw(dist.ini);
    my @no_index            = qw(eg share shares t xt);
    my @allow_dirty         = (@copy_from_build, qw(.travis.yml Changes LICENSE README.md));
    my @git_remotes         = qw(github origin);
    my @check_files         = qw(:InstallModules :ExecFiles :TestFiles :ExtraTestFiles);
    my $perl_version_target = '5.10.1';
    my $perl_version        = '5.24 5.22 5.20 5.18 5.16 5.14';
    my $perl_version_build  = $perl_version . ' 5.12 5.10 -5.8';

    if ($self->no_upload) {
        say '[@Author::CCM] WARNING! WARNING! WARNING! *** You are in no_upload mode!! ***';
    }

    if (!$self->payload->{'TravisYML.support_builddir'}) {
        # swap perl_version and perl_version_build because DZP::TravisYML got it backwards!
        # https://github.com/SineSwiper/Dist-Zilla-TravisCI/pull/40

        my $tmp = $self->payload->{'TravisYML.perl_version_build'};
        if (defined $self->payload->{'TravisYML.perl_version'}) {
            $self->payload->{'TravisYML.perl_version_build'} = $self->payload->{'TravisYML.perl_version'}
        }
        else {
            delete $self->payload->{'TravisYML.perl_version_build'};
        }
        if (defined $tmp) {
            $self->payload->{'TravisYML.perl_version'} = $tmp;
        }
        else {
            delete $self->payload->{'TravisYML.perl_version'};
        }

        ($perl_version, $perl_version_build) = ($perl_version_build, $perl_version);
    }

    my @plugins = (

        # VERSION
        ['Git::NextVersion'],
        ['ReversionOnRelease' => {prompt => 1}],

        # GATHER
        ['Git::GatherDir' => {exclude_filename  => [@gather_exclude]}],
        ['PruneCruft'],
        ['PruneFiles' => {filename => [@gather_prune]}],

        ['CopyFilesFromBuild' => {copy => [@copy_from_build]}],
        ['ExecDir'],

        # PREREQS
        ['AutoPrereqs'],
        -f 'cpanfile' ? ['Prereqs::FromCPANfile'] : (),
        ['Prereqs::AuthorDeps'],

        # TESTS
        ['MetaTests'],
        ['Test::CPAN::Changes'],
        ['PodCoverageTests'],
        ['PodSyntaxTests'],
        ['Test::Pod::No404s'],
        ['Test::Compile'],
        ['Test::MinimumVersion' => {max_target_perl => $perl_version_target}],
        ['Test::EOL' => {finder => [@check_files]}],
        ['Test::NoTabs' => {finder => [@check_files]}],
        ['Test::Perl::Critic'],
        ['Test::Portability'],
        ['Test::CleanNamespaces'],
        ['Test::ReportPrereqs'],

        # METADATA
        ['Authority' => {authority => $self->authority, do_munging => 0}],
        ['MetaJSON'],
        ['MetaYAML'],
        ['MetaNoIndex' => {directory => [@no_index]}],
        ['MetaProvides::Package'],
        ['Keywords'],
        ['Git::Contributors' => {order_by => 'commits'}],
        ['GithubMeta' => {remote => [@git_remotes], issues => 1}],

        # MUNGE
        ['PodWeaver' => {config_plugin => '@Author::CCM'}],
        ['OverridePkgVersion'],

        # GENERATE FILES
        ['License'],
        ['ReadmeAnyFromPod' => 'RepoReadme' => {filename => 'README.md', location => 'root', type => 'markdown', phase => 'release'}],
        ['ReadmeAnyFromPod' => 'DistReadme' => {filename => 'README', location => 'build', type => 'text'}],
        ['TravisYML' => {build_branch => '/^(dist|build\/.*)$/', perl_version => $perl_version, perl_version_build => $perl_version_build}],
        ['Manifest'],
        ['ManifestSkip'],

        $self->installer,     # e.g. MakeMaker

        # RELEASE
        ['NextRelease'],
        ['CheckChangesHasContent'],
        ['Git::Check' => {allow_dirty => [@allow_dirty], untracked_files => 'ignore'}],
        ['RunExtraTests'],
        ['TestRelease'],
        # ['ConfirmRelease'],
        $self->no_upload ? ['FakeRelease'] : ['UploadToCPAN'],
        ['Git::Commit' => {allow_dirty => [@allow_dirty], commit_msg => 'Release %N %v%t%n%n%c'}],
        ['Git::CommitBuild' => {branch => '', release_branch => 'dist', release_message => 'Version %v%t'}],
        ['Git::Tag' => {tag_message => 'Version %v%t%n%n%c'}],
        $self->no_upload ? () : ['Git::Push' => {push_to => 'origin master +master:refs/heads/release +dist', remotes_must_exist => 0}],

    );

    if ($self->airplane) {
        my %network_plugins = map { Dist::Zilla::Util->expand_config_package_name($_) => 1 } @network_plugins;

        @plugins = grep { !$network_plugins{Dist::Zilla::Util->expand_config_package_name(ref eq 'ARRAY' ? $_->[0] : $_)} } @plugins;
        push @plugins, 'BlockRelease';
    }

    push @plugins, 'ConfirmRelease';

    $self->add_plugins(@plugins);
}

with 'Dist::Zilla::Role::PluginBundle::Easy';
with 'Dist::Zilla::Role::PluginBundle::PluginRemover';
with 'Dist::Zilla::Role::PluginBundle::Config::Slicer';

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::CCM - A plugin bundle for distributions built by CCM

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    # In your dist.ini file:
    [@Author::CCM]

=head1 DESCRIPTION

You probably don't want to use this.

    ; VERSION
    [Git::NextVersion]
    [ReversionOnRelease]
    prompt              = 1

    ; GATHER
    [Git::GatherDir]
    exclude_filename    = LICENSE
    exclude_filename    = README.md
    [PruneCruft]
    [PruneFiles]
    filename            = dist.ini

    [CopyFilesFromBuild]
    copy                = LICENSE
    [ExecDir]

    ; PREREQS
    [AutoPrereqs]
    [Prereqs::FromCPANfile]     ; if a cpanfile exists in root
    [Prereqs::AuthorDeps]

    ; TESTS
    [MetaTests]
    [Test::CPAN::Changes]
    [PodCoverageTests]
    [PodSyntaxTests]
    [Test::Pod::No404s]
    [Test::Compile]
    [Test::MinimumVersion]
    max_target_perl     = 5.10.1
    [Test::EOL]
    [Test::NoTabs]
    [Test::Perl::Critic]
    [Test::Portability]
    [Test::CleanNamespaces]
    [Test::ReportPrereqs]

    ; METADATA
    [Authority]
    do_munging          = 0
    [MetaJSON]
    [MetaYAML]
    [MetaNoIndex]
    directory           = eg
    directory           = share
    directory           = shares
    directory           = t
    directory           = xt
    [MetaProvides::Package]
    [Keywords]
    [Git::Contributors]
    order_by            = commits
    [GithubMeta]
    issues              = 1

    ; MUNGE
    [PodWeaver]
    config_plugin       = @Author::CCM
    [OverridePkgVersion]

    ; GENERATE FILES
    [License]
    [ReadmeAnyFromPod]
    filename            = README.md
    locaton             = root
    type                = markdown
    phase               = release
    [ReadmeAnyFromPod]
    filename            = README
    location            = build
    type                = text
    [TravisYML]
    build_branch        = /^(dist|build\/.*)$/
    [Manifest]
    [ManifestSkip]

    [MakeMaker]                 ; override with the "installer" attribute

    ; RELEASE
    [NextRelease]
    [CheckChangesHasContent]
    [Git::Check]
    [RunExtraTests]
    [TestRelease]
    [ConfirmRelease]
    [UploadToCPAN]              ; disable with the "no_upload" attribute
    [Git::Commit]
    commit_msg          = Release %N %v%t%n%n%c
    [Git::CommitBuild]
    branch              =
    release_branch      = dist
    release_message     = Version %v%t
    [Git::Tag]
    tag_message         = Version %v%t%n%n%c
    [Git::Push]
    push_to             = origin master +master:refs/heads/release +dist
    remotes_must_exist  = 0

=head1 ATTRIBUTES

=head2 authority

Specify the release authority. Defaults to C<cpan:CCM>.

=head2 installer

Specify which installer to use, such as:

=over 4

=item *

C<MakeMaker> (default)

=item *

C<MakeMaker::Custom>

=back

=head2 airplane

Disable plugins that use the network, and prevent releasing.

=head2 no_upload

Do not upload to CPAN or git push.

=head1 METHODS

=head2 configure

Required by L<Dist::Zilla::Role::PluginBundle::Easy>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla>

=item *

L<Dist::Zilla::PluginBundle::Author::ETHER>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/Dist-Zilla-PluginBundle-Author-CCM/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
