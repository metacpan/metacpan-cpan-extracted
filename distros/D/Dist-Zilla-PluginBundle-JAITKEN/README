# NAME

Dist::Zilla::PluginBundle::JAITKEN - Build your Dist::Zilla distributions like JAITKEN

# SYNOPSIS

This is the [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) configuration that I use.

It is exactly equivalent to

    [VersionFromModule]
    [NameFromDirectory]

    [AutoPrereqs]

    [MinimumPerl]

    [MetaJSON]

    [ReadmeAnyFromPod]
    type = markdown
    filename = README
    location = build

    [PruneFiles]
    filenames = dist.ini
    filenames = README.markdown

    [GithubMeta]
    issues = 1

    [MinimumPrereqs]
    minimum_year = 2007

    [PrereqsClean]
    minimum_perl = v5.10

    [@Filter]
    -bundle = @Basic
    -remove = Readme

# USAGE

In dist.ini

    [@JAITKEN]

And that's it.

The module needs to be under version control at GitHub
in order for [Dist::Zilla::Plugin::GithubMeta](https://metacpan.org/pod/Dist::Zilla::Plugin::GithubMeta) to extract relevant
info from your local git repo.

# SEE ALSO

[Dist::Zilla](https://metacpan.org/pod/Dist::Zilla), [Dist::Zilla::Role::PluginBundle::Easy](https://metacpan.org/pod/Dist::Zilla::Role::PluginBundle::Easy),
[Dist::Zilla::Plugin::AutoPrereqs](https://metacpan.org/pod/Dist::Zilla::Plugin::AutoPrereqs), [Dist::Zilla::Plugin::GithubMeta](https://metacpan.org/pod/Dist::Zilla::Plugin::GithubMeta),
[Dist::Zilla::Plugin::MetaJSON](https://metacpan.org/pod/Dist::Zilla::Plugin::MetaJSON), [Dist::Zilla::Plugin::MinimumPerl](https://metacpan.org/pod/Dist::Zilla::Plugin::MinimumPerl),
[Dist::Zilla::Plugin::MinimumPrereqs](https://metacpan.org/pod/Dist::Zilla::Plugin::MinimumPrereqs), [Dist::Zilla::Plugin::PrereqsClean](https://metacpan.org/pod/Dist::Zilla::Plugin::PrereqsClean),
[Dist::Zilla::Plugin::PruneFiles](https://metacpan.org/pod/Dist::Zilla::Plugin::PruneFiles), [Dist::Zilla::Plugin::ReadmeAnyFromPod](https://metacpan.org/pod/Dist::Zilla::Plugin::ReadmeAnyFromPod),
[Dist::Zilla::Plugin::VersionFromModule](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromModule), [Dist::Zilla::Plugin::NameFromDirectory](https://metacpan.org/pod/Dist::Zilla::Plugin::NameFromDirectory),
[Dist::Zilla::PluginBundle::Basic](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Basic), [Dist::Zilla::PluginBundle::Filter](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Filter)

# AUTHOR

James Aitken <jaitken@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
