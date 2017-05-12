package Dist::Zilla::PluginBundle::Author::ZOFFIX;

our $VERSION = '1.001008'; # VERSION

use Moose;
with (
  'Dist::Zilla::Role::PluginBundle::Easy',
  'Dist::Zilla::Role::PluginBundle::PluginRemover',
  'Dist::Zilla::Role::PluginBundle::Config::Slicer',
);

=for Pod::Coverage configure

=cut

sub configure {
    my $self = shift;

    $self->add_plugins(
        'OurPkgVersion',
        'Pod::Spiffy',
        [
            PromptIfStale => {
                check_all_plugins => 1,
                check_all_prereqs => 1,
                skip              => [qw/
                    strict  warnings  base
                    ExtUtils::MakeMaker  IPC::Open3  File::Copy
                /],
            }
        ],
        qw/GatherDir
        PruneCruft
        ManifestSkip
        MetaYAML
        License
        Readme
        ExecDir
        ShareDir
        MakeMaker
        Manifest
        AutoPrereqs
        MetaConfig
        Prereqs::AuthorDeps
        MinimumPerl
        MetaProvides::Package
        InstallGuide/,
        [
            ReadmeAnyFromPod => {
                type     => 'markdown',
                filename => 'README.md',
            },
        ],
        qw/Test::Compile
        Test::DistManifest
        Test::EOL
        Test::Version
        Test::Kwalitee
        MetaTests
        Test::CPAN::Meta::JSON
        MojibakeTests
        Test::NoTabs
        PodCoverageTests
        PodSyntaxTests
        Test::Portability
        Test::Synopsis
        Test::UnusedVars
        Test::Pod::LinkCheck
        Test::CPAN::Changes
        Test::PodSpelling
        CheckSelfDependency
        CheckPrereqsIndexed/,
        [
            'Test::MinimumVersion' => {
                max_target_perl => '5.008008',
            },
        ],
        [
            'Git::NextVersion' => {
                first_version => '1.001001',
                version_regexp => '^v(.+)$',
            },
        ],
        [
            AutoMetaResources => {
                'bugtracker.github' => 'user:zoffixznet',
                'bugtracker.mailto' => 'cpan@zoffix.com',
                'repository.github' => 'user:zoffixznet',
                homepage => 'http://metacpan.org/release/%{dist}',
            },
        ],
        [
            CopyFilesFromRelease => {
                filename => [qw/README.md/],
            },
        ],
        'TestRelease',
        [
            InstallRelease => {
                install_command => 'cpanm .',
            },
        ],
        qw/ConfirmRelease
        Git::Check
        Git::Commit
        Git::Tag
        Git::Push
        UploadToCPAN/,
    );
}


q|
99 little bugs in the code
99 bugs in the code
patch one down, compile it around
117 bugs in the code
|;

__END__

=encoding utf8

=head1 NAME

Dist::Zilla::PluginBundle::Author::ZOFFIX - A plugin bundle for distributions built by ZOFFIX

=head1 SYNOPSIS

In your C<dist.ini>:

    [@Author::ZOFFIX]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin bundle. It is heavily based on
L<Dist::Zilla::PluginBundle::Author::ETHER>
and is approximately equivalent to the following C<dist.ini>:

    [OurPkgVersion]
    [Pod::Spiffy]

    [PromptIfStale]
    check_all_plugins = 1
    check_all_prereqs = 1
    skip              = strict
    skip              = warnings
    skip              = base
    skip              = ExtUtils::MakeMaker
    skip              = IPC::Open3
    skip              = File::Copy

    [GatherDir]
    [PruneCruft]
    [ManifestSkip]
    [MetaYAML]
    [License]
    [Readme]
    [ExecDir]
    [ShareDir]
    [MakeMaker]
    [Manifest]

    [ReadmeAnyFromPod]
    type = markdown
    filename = README.md

    [Test::Compile]
    [Test::DistManifest]
    [Test::EOL]
    [Test::Version]
    [Test::Kwalitee]
    [MetaTests]
    [Test::CPAN::Meta::JSON]
    [Test::MinimumVersion]
    max_target_perl = 5.008008

    [MojibakeTests]
    [Test::NoTabs]
    [PodCoverageTests]
    [PodSyntaxTests]
    [Test::Portability]
    [Test::Synopsis]
    [Test::UnusedVars]
    [Test::Pod::LinkCheck]
    [Test::CPAN::Changes]
    [Test::PodSpelling]

    [Git::NextVersion]
    first_version = 1.001001
    version_regexp = ^v(.+)$

    [AutoPrereqs]

    [MetaConfig]

    [Prereqs::AuthorDeps]
    [MinimumPerl]

    [MetaProvides::Package]

    [GithubMeta]

    [AutoMetaResources]
    bugtracker.github = user:zoffixznet
    repository.github = user:zoffixznet
    homepage = http://metacpan.org/release/%{dist}

    [InstallGuide]

    [CheckSelfDependency]
    [CheckPrereqsIndexed]

    [CopyFilesFromRelease]
    filename = README.md

    [TestRelease]

    [InstallRelease]
    install_command = cpanm .

    [ConfirmRelease]

    [Git::Check]
    [Git::Commit]
    [Git::Tag]
    [Git::Push]

    [UploadToCPAN]

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Dist-Zilla-PluginBundle-Author-ZOFFIX>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Dist-Zilla-PluginBundle-Author-ZOFFIX/issues>

If you can't access GitHub, you can email your request
to C<bug-Dist-Zilla-PluginBundle-Author-ZOFFIX at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

This software is copyright (c) 2014 by Zoffix Znet <zoffix at cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut