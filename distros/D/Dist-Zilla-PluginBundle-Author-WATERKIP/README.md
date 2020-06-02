# SYNOPSIS

In your `dist.ini`:

    [@Author::WATERKIP]

# DESCRIPTION

This is a [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla) plugin bundle. It is somewhat equal to the
following `dist.ini`:

    [Git::GatherDir]
    exclude_filename = .dockerignore
    exclude_filename = .gitlab-ci.yml
    exclude_filename = Dockerfile
    exclude_filename = docker-compose.override.yml
    exclude_filename = docker-compose.yml

    [PromptIfStale 'stale modules, build']
    phase = build
    module = ... ; lookup syntax

    [PruneCruft]
    [ManifestSkip]
    [MetaYAML]
    [MetaJSON]

    [License]
    filename = LICENSE

    [ReadmeFromPod]
    type = markdown
    readme = README.md

    [ExecDir]
    [ShareDir]
    [MakeMaker]
    [Manifest]
    [TestRelease]
    [PodWeaver]

    [Git::Contributors]
    order_by = commits

    [ContributesFile]
    filename = CONTRIBUTORS

    [AutoPrereqs]
    skip = ^perl$, utf8, warnings, strict, overload

    [Prereqs::AuthorDeps]
    [MinimumPerl]
    configure_finder = :NoFiles

    [MetaProvides::Package]

    [Encoding]
    encoding = bytes
    match = \.ico$
    match = \.docx?$
    match = \.zip$
    match = \.ztb$ ; Mintlab specific
    match = \.pdf$
    match = \.odt$

    [CPANFile]

    [CopyFilesFromBuild::Filtered]
    copy = cpanfile, Makefile.pl, CONTRIBUTORS, LICENSE, README.md

    [Git::Check 'initial check']
    allow_dirty = dist.ini; only if airplane mode is set

    [Git::CheckFor::MergeConflicts]
    [Git::Remote::Check]
    branch = master
    remote_branch = master

    [Git::CheckFor::CorrectBranch]
    release_branch = master

    [CheckPrereqsIndexed]

    [Repository]
    [ConfirmRelease]

    [CopyFilesFromRelease]
    filename = cpanfile, Makefile.pl, CONTRIBUTORS, LICENSE, README.md

    [@TestingMania]
    disable = Test::Perl::Critic
    disable = Test::Portability::Files
    disable = Test::Portability

    [@Git::VersionManager]
    RewriteVersion::Transitional.global = 1
    RewriteVersion::Transitional.fallback_version_provider = Git::NextVersion
    RewriteVersion::Transitional.version_regexp = ^v([\d._]+)(-TRIAL)?$

    commit_files_after_release = Changes LICENSE README.md

    release snapshot.add_files_in = .
    release snapshot.commit_msg = %N-%v%t%n%n%c

    Git::Tag.tag_message = v%v%t

    BumpVersionAfterRelease::Transitional.global = 1

    NextRelease.time_zone = UTC
    NextRelease.format = %-8v  %{yyyy-MM-dd HH:mm:ss\'Z\'}d%{ (TRIAL RELEASE)}T'

# METHODS

## configure

Configure the author plugin

## commit\_files\_after\_release

Commit files after a release

## release\_option

Define the release options. Choose between:

`cpan` or `stratopan`. When fake release is used, this overrides these two options

## build\_network\_plugins

Builder for network plugins

# SEE ALSO

I took inspiration from [Dist::Zilla::PluginBundle::Author::ETHER](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APluginBundle%3A%3AAuthor%3A%3AETHER)
