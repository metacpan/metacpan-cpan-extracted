[![Build Status](https://travis-ci.org/ivanwills/Group-Git.png)](https://travis-ci.org/ivanwills/Group-Git)
[![Coverage Status](https://coveralls.io/repos/ivanwills/Group-Git/badge.svg?branch=master)](https://coveralls.io/r/ivanwills/Group-Git?branch=master)

# Group-Git

The `group-git` tool allows you perform operations on many git
repositories at once. For example updating many repositores with the latest
upstream code:

```bash
$ group-git pull
```

Would update all git repositories in the current directory.

Several `git` comands have some extras such as `status` which adds the
`--quiet` parameter which will suppress output for repositories with not
changes.

There are also tool to help with various git repository servers such as

* Github
* Bitbucket Server (nee Stash)
* Gitosis

## Repository Helpers

These helpers allow you to store your credentials in a `group-git.yml`
configuration file and will find all repositories you have access to. If you
use the `group-git pull` command it will automatically clone any repository
not currently downloaded for you.

## Tagging repositories

You can also tag repositories to limit opperations to a subset of available
repositories. There are 3 ways to tag repositories:

* Add a tag file(s) to the root of the repository (eg `.my-tag.tag>)
* Use a tagger library, `Group::Git` comes with two, remore and local which
determine if the repository has a remote or not.
* The Bitbucket server helper will tag repositories with their project.

## Extending with your own commands

`Group::Git` looks for commands in the perl modules path `Group::Git::Cmd`
and it look in the path for any command in the form of `group-git-cmd` or
`git-cmd` as well as supoorting all the built in git commands. If you want
perform an operation you can write your own script put it your path and
`Group::Git` will find it execute it the same was git would.

# INSTALLATION

To install this module from CPAN:

```bash
$ capnm Group::Git
# or if you don't have the cpanm command
$ cpan Group::Git
```

Or from source run the following commands:

```
# with cpanm
$ cpanm .
# without
$ perl Build.PL
$ ./Build
$ ./Build test
$ ./Build install
```

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Group::Git

You can also look for information at:

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Group-Git

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Group-Git

    CPAN Ratings
        http://cpanratings.perl.org/d/Group-Git

    Search CPAN
        http://search.cpan.org/dist/Group-Git/

    Source Code
        git://github.com/ivanwills/Group-Git.git

# COPYRIGHT AND LICENCE

Copyright (C) 2013-2016 Ivan Wills

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
