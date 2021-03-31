# NAME

Dist::Zilla::PluginBundle::Author::JMASLAK - JMASLAK's Plugin Bundle

# VERSION

version 1.210880

# DESCRIPTION

This is Joelle Maslak's plugin bundle, used for her modules.  If you're not
her, you probably want to create your own plugin module because I may modify
this module based on her needs, breaking third party modules that use this.

All of the following are in this module as of v1.181840.

It is somewhat equivilent to:

    [AutoVersion]
    [NextRelease]
    [AutoPrereqs]
    [ConfirmRelease]
    [ContributorCovenant]

    [CopyFilesFromBuild]
    copy = 'README.pod'

    [ExecDir]
    [ExtraTests]
    [GatherDir]
    [GitHub::Meta]
    [License]
    [Manifest]
    [ManifestSkip]
    [Makemaker]
    [MetaJSON]
    [MetaProvides::Package]
    [MetaYAML]
    [PkgVersion]
    [PodSyntaxTests]
    [PodWeaver]
    [PruneCruft]
    [ShareDir]

    [ReadmeAnyFromPod]
    type     = markdown
    filename = README.md

    [Test::ChangesHasContent]
    [Test::EOL]
    [Test::Kwalitee]
    [Test::NoTabs]
    [Test::ReportPrereqs]

    [Test::TrailingSpace]
    filename_regex = '\.($?:ini|pl|pm|t|txt)\z'

    [Test::UnusedVars]
    [Test::UseAllModules]
    [Test::Version]
    [TestRelease]
    [UploadToCPAN]

    [Git::Check]
    allow_dirty = dist.ini
    allow_dirty = Changes
    allow_dirty = README.pod

    [Git::Commit]
    allow_dirty = dist.ini
    allow_dirty = Changes
    allow_dirty = README.pod

    [Git::Push]
    [Git::Tag]

This automatically numbers releases.

This creates a `CODE_OF_CONDUCT.md` from the awesome Contributor Covenant
project, a `Changes` file, a `CONTRIBUTING` file, a `TODO` file,
a `MANIFEST_SKIP` file, an `AUTHOR_PLEDGE` file that indicates CPAN admins
can take ownership should the project become abandoned, and a `.travis.yml`
file that will probably need to be edited.  If these files exist already, they
will not get overwritten.

It also generates a `.mailmap` base file suitable for Joelle, if one does
not already exists.

# USAGE

In your `dist.ini` -

    [@Filter]
    -bundle  = @Author::JMASLAK
    -version = 0.003

The `-version` option should specify the latest version required and tested
with a given package.

# SEE ALSO

Core Dist::Zilla plugins:

Dist::Zilla roles:
[PluginBundle](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3APluginBundle),
[PluginBundle::Easy](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3APluginBundle%3A%3AEasy).

# AUTHOR

Joelle Maslak <jmaslak@antelope.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018,2020-2021 by Joelle Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
