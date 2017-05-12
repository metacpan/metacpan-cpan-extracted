[![Build Status](https://travis-ci.org/nnutter/Git-Repository-Plugin-Gerrit.svg?branch=master)](https://travis-ci.org/nnutter/Git-Repository-Plugin-Gerrit)
# NAME

Git::Repository::Plugin::Gerrit - Work with Gerrit-specific features in a Git::Repository

# SYNOPSIS

    use Git::Repository::Plugin::Gerrit;

# DESCRIPTION

Git::Repository::Plugin::Gerrit adds the `find_change` method to a
Git::Repository and injects a `change_id` accessor to Git::Repository::Log.

# METHODS

## find\_change($change\_id)

Search the log of a Git::Repository for the specified [Gerrit Change-Id](https://gerrit-documentation.storage.googleapis.com/Documentation/2.8.5/user-changeid.html).
Returns the corresponding [Git::Repository::Log](https://metacpan.org/pod/Git::Repository::Log) object.

## change\_id

Return the [Gerrit Change-Id](https://gerrit-documentation.storage.googleapis.com/Documentation/2.8.5/user-changeid.html) of a Git::Repository::Log.

# LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Nathaniel Nutter <nnutter@cpan.org>
