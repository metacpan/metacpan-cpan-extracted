[![Build Status](https://travis-ci.org/nnutter/Git-Repository-Plugin-Hooks.svg?branch=master)](https://travis-ci.org/nnutter/Git-Repository-Plugin-Hooks)
# NAME

Git::Repository::Plugin::Hooks - Work with hooks in a Git::Repository

# SYNOPSIS

    use Git::Repository 'Hooks';

    my $r = Git::Repository->new();
    $r->install_hook('my-hook-file', 'pre-receive');

# DESCRIPTION

Git::Repository::Plugin::Hooks adds the `install_hook` and `hook_path`
methods to a Git::Repository.

# METHODS

## install\_hook($source, $target)

Install a `$target`, e.g. 'pre-receive', hook into the repository.

## hook\_path($target)

Returns the path to a hook of the type specified by `$target`.  See `man
githooks` for examples, e.g. `pre-commit`.

# LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Nathaniel Nutter <nnutter@cpan.org>
