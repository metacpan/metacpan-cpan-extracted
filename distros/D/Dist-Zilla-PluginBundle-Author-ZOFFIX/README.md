# NAME

Dist::Zilla::PluginBundle::Author::ZOFFIX - A plugin bundle for distributions built by ZOFFIX

# SYNOPSIS

In your `dist.ini`:

    [@Author::ZOFFIX]

# DESCRIPTION

This is a [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugin bundle. It is heavily based on
[Dist::Zilla::PluginBundle::Author::ETHER](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Author::ETHER)
and is approximately equivalent to the following `dist.ini`:

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

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/Dist-Zilla-PluginBundle-Author-ZOFFIX](https://github.com/zoffixznet/Dist-Zilla-PluginBundle-Author-ZOFFIX)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/Dist-Zilla-PluginBundle-Author-ZOFFIX/issues](https://github.com/zoffixznet/Dist-Zilla-PluginBundle-Author-ZOFFIX/issues)

If you can't access GitHub, you can email your request
to `bug-Dist-Zilla-PluginBundle-Author-ZOFFIX at rt.cpan.org`

# AUTHOR

Zoffix Znet <zoffix at cpan.org>
([http://zoffix.com/](http://zoffix.com/), [http://haslayout.net/](http://haslayout.net/))

# LICENSE

This software is copyright (c) 2014 by Zoffix Znet <zoffix at cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
