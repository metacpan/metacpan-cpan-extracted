# NAME

Dist::Zilla::PluginBundle::MAXMIND - MAXMIND's plugin bundle

# VERSION

version 0.80

# SYNOPSIS

    name    = My-Module
    author  = Dave Rolsky <autarch@urth.org>
    license = Artistic_2_0
    copyright_holder = Dave Rolsky

    [@MAXMIND]
    dist = My-Module
    ; Fefault is MakeMaker - or set it to ModuleBuild
    make_tool = MakeMaker
    ; These files won't be added to tarball
    exclude_files = ...
    ; Default is MAXMIND
    authority = MAXMIND
    ; Passed to AutoPrereqs - can be repeated
    prereqs_skip = ...
    ; Passed to Test::Pod::Coverage::Configurable if set
    pod_coverage_also_private = ...
    ; Passed to Test::Pod::Coverage::Configurable if set - can be repeated
    pod_coverage_class = ...
    ; Passed to Test::Pod::Coverage::Configurable if set - can be repeated
    pod_coverage_skip = ...
    ; Passed to Test::Pod::Coverage::Configurable if set - can be repeated
    pod_coverage_trustme = ...
    ; For pod spelling test - can be repeated
    stopwords = ...
    ; Can also put them in a separate file
    stopwords_file = ..
    ; Defaults to false
    use_github_homepage = 0
    ; Defaults to false
    use_github_issues = 0

# DESCRIPTION

This is the [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugin bundle I use for my distributions. Don't use
this directly for your own distributions, but you may find it useful as a
source of ideas for building your own bundle.

This bundle uses [Dist::Zilla::Role::PluginBundle::PluginRemover](https://metacpan.org/pod/Dist::Zilla::Role::PluginBundle::PluginRemover) and
[Dist::Zilla::Role::PluginBundle::Config::Slicer](https://metacpan.org/pod/Dist::Zilla::Role::PluginBundle::Config::Slicer) so I can remove or
configure any plugin as needed.

This is more or less equivalent to the following `dist.ini`:

    ; Picks one of these - defaults to MakeMaker
    [MakeMaker]
    [ModuleBuild]

    [Git::GatherDir]
    ; Both are configured by setting exclude_files for the bundle. Simple
    ; values like "./foo/bar.pl" are treated as filenames, others like
    ; "*\.jnk$" are treated as a regex.
    exclude_filenames = ...
    exclude_match     = ...

    [ManifestSkip]
    [License]
    [ExecDir]
    [ShareDir]
    [Manifest]
    [CheckVersionIncrement]
    [TestRelease]
    [ConfirmRelease]
    [UploadToCPAN]
    ; Opens up the main module and finds a $VERSION
    [MAXMIND::VersionProvider]

    [Authority]
    ; Configured by setting authority for the bundle
    authority  = ...
    do_munging = 0

    [AutoPrereqs]
    ; Configured by setting skip_prereqs for the bundle
    skip = ...

    [CopyFilesFromBuild]
    copy = Build.PL
    copy = CONTRIBUTING.md
    copy = LICENSE
    copy = Makefile.PL
    copy = README.md
    copy = cpanfile
    copy = ppport.h

    [GitHub::Meta]
    ; Configured by setting use_github_issues for the bundle
    bugs = 0
    ; Configured by setting use_github_homepage for the bundle
    homepage = 0

    [MetaResources]
    homepage = http://metacpan.org/release/My-Module
    ; RT bits are omitted if use_github_issue is true
    bugtracker.web  = http://rt.cpan.org/Public/Dist/Display.html?Name=My-Module
    bugtracker.mail = bug-My-Module@rt.cpan.org

    [MetaProvides::Pckage]
    meta_noindex = 1

    [Meta::Contributors]
    [Meta::Config]
    [MetaJSON]
    [MetaYAML]

    [NextRelease]
    ; Width is configured by setting next_release_width for the bundle
    format = %-8v %{yyyy-MM-dd}d%{ (TRIAL RELEASE)}T

    ; Scans the test files for use of Test2 and picks either
    [Prereqs / Test::More with Test2]
    -phase = test
    -type  = requires
    Test::More = 1.302015

    ; If the distro doesn't use Test2
    [Prereqs / Test::More with subtest]
    -phase = test
    -type  = requires
    Test::More = 0.96

    [Prereqs / Modules for use with tidyall]
    -phase = develop
    -type  = requires
    Code::TidyAll::Plugin::Test::Vars = 0.02
    Parallel::ForkManager'            = 1.19
    Perl::Critic                      = 1.126
    Perl::Tidy                        = 20160302
    Test::Vars                        = 0.009

    [Prereqs / Test::Version which fixes https://github.com/plicease/Test-Version/issues/7]
    -phase = develop
    -type  = requires
    Test::Version = 2.05

    [PromptIfStale]
    phase  = build
    module = Dist::Zilla::PluginBundle::MAXMIND

    [PromptIfStale]
    phase = release
    check_all_plugins = 1
    check_all_prereqs = 1
    check_authordeps  = 1
    skip = Dist::Zilla::Plugin::MAXMIND::CheckChangesHasContent
    skip = Dist::Zilla::Plugin::MAXMIND::Contributors
    skip = Dist::Zilla::Plugin::MAXMIND::Git::CheckFor::CorrectBranch
    skip = Dist::Zilla::Plugin::MAXMIND::License
    skip = Dist::Zilla::Plugin::MAXMIND::TidyAll
    skip = Dist::Zilla::Plugin::MAXMIND::VersionProvider
    skip = Pod::Weaver::PluginBundle::MAXMIND

    [Test::Pod::Coverage::Configurable]
    ; Configured by setting pod_coverage_class for the bundle
    class = ...
    ; Configured by setting pod_coverage_skip for the bundle
    skip = ...
    ; Configured by setting pod_coverage_trustme for the bundle
    trustme = ...

    [Test::PodSpelling]
    ; Configured by setting stopwords and/or stopwords_file for the bundle
    stopwods = ...

    [PodSyntaxTests]

    [RunExtraTests]
    [MojibakeTests]
    [Test::CleanNamespaces]
    [Test::CPAN::Changes]
    [Test::CPAN::Meta::JSON]
    [Test::EOL]
    [Test::NoTabs]
    [Test::Portability]
    [Test::Synopsis]

    [Test::TidyAll]
    verbose = 1
    jobs    = 4
    minimum_perl = 5.010

    [Test::Compile]
    xt_mode = 1

    [Test::ReportPrereqs]
    verify_prereqs = 1

    [Test::Version]
    is_strict = 1

    ; Generates/updates a .mailmap file
    [MAXMIND::Contributors]
    [Git::Contributors]

    [SurgicalPodWeaver]
    ; See Pod::Weaver::PluginBundle::MAXMIND in this same distro for more info
    config_plugin = @MAXMIND

    ; Nasty hack so I can pass config from the dist.ini to the Pod::Weaver
    ; bundle. Currently used so I can set
    ; "MAXMIND::WeaverConfig.include_donations_pod = 0" in a dist.ini file.
    [MAXMIND::WeaverConfig]

    [ReadmeAnyFromPod / README.md in build]
    type     = markdown
    filename = README.md
    location = build
    phase    = build

    [GenerateFile::FromShareDir / Generate CONTRIBUTING.md]
    -dist     = Dist-Zilla-PluginBundle-MAXMIND
    -filename = CONTRIBUTING.md
    ; This is determined by looking through the distro for .xs files.
    has_xs    = ...

    [InstallGuide]
    [CPANFile]

    ; Only added if the distro has .xs files
    [PPPort]

    ; Like the default License plugin except that it defaults to Artistic 2.0.
    ; Also, if the copyright_year for the bundle is not this year, it passes
    ; something like "2014-2016" to Software::License.
    [MAXMIND::License]

    [CheckPrereqsIndexed]

    ; More or less like Dist::Zilla::Plugin::CheckChangesHasContent but uses
    ; CPAN::Changes to parse the Changes file.
    [MAXMIND::CheckChangesHasContent]

    ; Just like Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch except that
    ; it allows releases from any branch for TRIAL
    ; releases. https://github.com/RsrchBoy/dist-zilla-pluginbundle-git-checkfor/issues/24
    [MAXMIND::Git::CheckFor::CorrectBranch]

    [Git::CheckFor::MergeConflicts]

    ; Generates/updates tidyall.ini, perlcriticrc, and perltidyrc
    [MAXMIND::TidyAll]

    ; The allow_dirty list is basically all of the generated or munged files
    ; in the distro, including:
    ;     Build.PL
    ;     CONTRIBUTING.md
    ;     Changes
    ;     LICENSE
    ;     Makefile.PL
    ;     README.md
    ;     cpanfile
    ;     ppport.h
    ;     tidyall.ini
    [Git::Check]
    allow_dirty = ...

    [Git::Commit / Commit generated files]
    allow_dirty = ...

    [Git::Tag]
    [Git::Push]

    [BumpVersionAfterRelease]

    [Git::Commit / Commit version bump]
    allow_dirty_match = .+
    commit_msg        = Bump version after release

    [Git::Push / Push version bump]

# SUPPORT

Bugs may be submitted through [https://github.com/maxmind/Dist-Zilla-PluginBundle-MAXMIND/issues](https://github.com/maxmind/Dist-Zilla-PluginBundle-MAXMIND/issues).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Dave Rolsky <drolsky@maxmind.com>
- Greg Oschwald <goschwald@maxmind.com>
- Mark Fowler <mark@twoshortplanks.com>
- Olaf Alders <oalders@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky and MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
