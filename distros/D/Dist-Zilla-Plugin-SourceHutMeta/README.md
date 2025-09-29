# NAME

Dist::Zilla::Plugin::SourceHutMeta - Automatically include SourceHut meta information in META.yml

# VERSION

version 1.004

# SYNOPSIS

    # in dist.ini

    [SourceHutMeta]

    # to override the homepage

    [SourceHutMeta]
    homepage = http://some.sort.of.url/project/

    # to override the remote repo (defaults to 'origin')
    [SourceHutMeta]
    remote = sr.ht

# DESCRIPTION

Dist::Zilla::Plugin::SourceHutMeta is a [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla) plugin to include SourceHut [https://sr.ht](https://sr.ht) meta
information in `META.yml` and `META.json`.

It automatically detects if the distribution directory is under `git` version control and whether the
`origin` is a SourceHut repository and will set the `repository` and `homepage` meta in `META.yml` to the
appropriate URLs for SourceHut.

Copy/pasted and slightly adapted from [Dist::Zilla::Plugin::GithubMeta](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AGithubMeta)

## ATTRIBUTES

- `remote`

    The SourceHut remote repo can be overridden with this attribute. If not
    provided, it defaults to `origin`.  You can provide multiple remotes to
    inspect.  The first one that looks like a SourceHut remote is used.

- `homepage`

    You may override the `homepage` setting by specifying this attribute. This
    should be a valid URL as understood by [MooseX::Types::URI](https://metacpan.org/pod/MooseX%3A%3ATypes%3A%3AURI).

- `bugtracker`

    Define the URL of the SourceHut "ticket tracking service", aka `todo`, which will be used as the `bugtracker` value in `META.json`. Use the special value `auto` to calculate the bugtracker URL from the repo name. But as SourceHut by default does not provide linking between the code repo (name) and the todo area, you have to make sure that the URL actually exists.

    If not set will use the first author as a `mailto` bugtracker value (because if no value for `bugtracker` is set, metacpan will link to RT).

- `user`

    If given, the `user` parameter overrides the username found in the SourceHut
    repository URL.  This is useful if many people might release from their own
    workstations, but the distribution metadata should always point to one user's
    repo.

- `repo`

    If give, the `repo` parameter overrides the repository name found in the
    SourceHut repository URL.

## METHODS

- `metadata`

    Required by [Dist::Zilla::Role::MetaProvider](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3AMetaProvider)

# SEE ALSO

[Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla), [Dist::Zilla::Plugin::GithubMeta](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AGithubMeta)

# CONTRIBUTING

See file `CONTRIBUTING.md`

# AUTHORS

- Thomas Klausner <domm@plix.at>
- Chris Williams <chris@bingosnet.co.uk>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Thomas Klausner, Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
