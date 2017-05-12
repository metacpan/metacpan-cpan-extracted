# NAME

Dist::Zilla::PluginBundle::BerryGenomics - Dist::Zilla::PluginBundle for BerryGenomics Bioinformatics Department

# VERSION

version 0.3.2

# SYNOPSIS

in your _dist.ini_:

    [@BerryGenomics]

Details configration:

    [@BerryGenomics]
    installer = MakeMaker ; default is ModuleBuild
    ; valid installers: MakeMaker MakeMaker::IncShareDir ModuleBuild ModuleBuildTiny

    ; ChangelogFromGit
    changelog_filename = Changes ; file_name in ChangelogFromGit
    changelog_wrap = 74   ; wrap_column in ChangelogFromGit, default 120
    exclude_message = ^(Auto|Merge|Forgot)
    version_regexp = ^v?(\d+\.\d+\.\d+)
    skipped_release_count = 2
    max_age = 365         ; default 60
    debug = 0

    ; Git
    allow_dirty = 'FIle1'
    allow_dirty = 'File2'
    commit_msg  =
    release_branch =
    release_message =

# DESCRIPTION

This is plugin bundle is for BerryGenomics.
It is equivalent to:

    ; Basic
    [MetaJSON]
    [MetaYAML]
    [License]
    [ExtraTests]
    [ExecDir]
    [ShareDir]
    [Manifest]
    [ManifestSkip]

    [TestRelease]
    [FakeRelease]

    ; installer
    [ModuleBuild] ; by default

    ; extra
    [InstallGuide]
    [OurPkgVersion]
    [PodWeaver]
    [ReadmeFromPod]
    [PodSyntaxTests]

    ; with params
    [ReadmeAnyFromPod /MarkdownInRoot]
    filename = Readme.md
    [CopyFilesFromBuild]
    copy = LICENSE
    [MetaNoIndex]
    directory = t
    directory = xt
    directory = inc
    directory = share
    directory = eg
    directory = examples

    ; Git
    [Git::GatherDir]
    exclude_filename = dist.ini
    exclude_filename = Changes
    exclude_filename = README.md
    exclude_filename = LICENSE
    include_dotfiles = 1
    [Git::Check]
    allow_dirty = dist.ini
    allow_dirty = Changes
    allow_dirty = README.md
    allow_dirty = LICENSE
    untracked_files = warn
    [Git::Commit]
    allow_dirty = dist.ini
    allow_dirty = Changes
    allow_dirty = README.md
    allow_dirty = LICENSE
    commit_msg = Auto commited by dzil with version %v at %d%n%n%c%n
    [Git::CommitBuild]
    release_branch = %v
    release_message = Release %v of %h (on %b)
    [Git::Tag]
    tag_format = %v
    tag_message = Auto tagged by dzil release(%v)
    [Git::Push]
    remotes_must_exist = 0
    [Git::NextVersion]
    first_version = 0.0.1
    version_by_branch = 1
    version_regexp = ^v?(\d+(\.\d+){0,2})$
    [ChangelogFromGit::CPAN::Changes]
    tag_regexp = semantic
    group_by_author = 1

    ; run
    [Run::BeforeBuild]
    run = git checkout Changes
    [Run::BeforeRelease]
    run = mkdir -p release 2>/dev/null; cp %n-%v.tar.gz release/ -f

    [AutoPrereqs]

# AUTHOR

Huo Linhe &lt;huolinhe@berrygenomics.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Berry Genomics.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
