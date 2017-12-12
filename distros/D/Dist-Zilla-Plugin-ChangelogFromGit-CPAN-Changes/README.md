# NAME

Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes - Generate valid CPAN::Changes Changelogs from git

# VERSION

version 0.173421

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
release tags are not compliant with [CPAN::Changes::Spec](https://metacpan.org/pod/CPAN::Changes::Spec), you can use a
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
can be committed (possiby automatically by [Dist::Zilla::Plugin::Git::Commit](https://metacpan.org/pod/Dist::Zilla::Plugin::Git::Commit))

Defaults to true.

## `edit_changelog`

When true, the generated changelog will be opened in an editor to allow manual
editing.

Defaults to false.

# BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at [https://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes/issues](https://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes/issues).

# AVAILABILITY

The project homepage is [http://search.cpan.org/dist/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes/](http://search.cpan.org/dist/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes/).

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit [http://www.perl.com/CPAN/](http://www.perl.com/CPAN/) to find a CPAN
site near you, or see [https://metacpan.org/module/Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes/](https://metacpan.org/module/Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes/).

# SOURCE

The development version is on github at [https://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes](https://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes)
and may be cloned from [git://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes.git](git://github.com/ioanrogers/Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes.git)

# AUTHOR

Ioan Rogers <ioanr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ioan Rogers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.
