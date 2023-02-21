# NAME

Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes - Generate valid CPAN::Changes Changelogs from git

# VERSION

version 0.230480

# SYNOPSIS

```
[ChangelogFromGit::CPAN::Changes]
; All options from [ChangelogFromGit] plus
group_by_author       = 1 ; default 0
show_author_email     = 1 ; default 0
show_author           = 0 ; default 1
edit_changelog        = 1 ; default 0
```

# ATTRIBUTES

## group\_by\_author

Whether to group commit messages by their author. This is the only way previous
versions did it. Defaults to no, and \[ Anne Author \] is appended to the commit
message.

Defaults to off.

## show\_author\_email

Author email is probably just noise for most people, but turn this on if you
want to show it \[ Anne Author <anne@author.com> \]

Defaults to off.

## show\_author

Whether to show authors at all. Turning this off also
turns off grouping by author and author emails.

Defaults to on.

## `tag_regexp`

A regexp string which will be used to match git tags to find releases. If your
release tags are not compliant with [CPAN::Changes::Spec](https://metacpan.org/pod/CPAN%3A%3AChanges%3A%3ASpec), you can use a
capture group. It will be used as the version in place of the full tag name.

Also takes `semantic`, which becomes `qr{^v?(\d+\.\d+\.\d+)$}`, and
`decimal`, which becomes `qr{^v?(\d+\.\d+)$}`.

Defaults to 'decimal'

## `file_name`

The name of the changelog file.

Defaults to 'Changes'.

## `preamble`

Block of text at the beginning of the changelog.

Defaults to 'Changelog for $dist\_name'

## `copy_to_root`

When true, the generated changelog will be copied into the root folder where it
can be committed (possiby automatically by [Dist::Zilla::Plugin::Git::Commit](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AGit%3A%3ACommit))

Defaults to true.

## `edit_changelog`

When true, the generated changelog will be opened in an editor to allow manual
editing.

Defaults to false.

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

```
perldoc Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes
```

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [https://metacpan.org/release/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes](https://metacpan.org/release/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes)

## Bugs / Feature Requests

Please report any bugs or feature requests through the web interface at [https://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes.git/issues](https://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes.git/issues).
You will be automatically notified of any progress on the request by the system.

## Source Code

The source code is available for from the following locations:

[https://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes.git](https://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes.git)

```
git clone https://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes.git.git
```

# AUTHOR

Ioan Rogers <ioanr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ioan Rogers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
