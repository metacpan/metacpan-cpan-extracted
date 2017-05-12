[![Build Status](https://travis-ci.org/nnutter/Git-Repository-Plugin-Info.svg?branch=master)](https://travis-ci.org/nnutter/Git-Repository-Plugin-Info)
# NAME

Git::Repository::Plugin::Info - Information about a Git::Repository

# SYNOPSIS

    use Git::Repository 'Info';

    my $r = Git::Repository->new();

    $r->is_bare();
    $r->has_tag('some_tag');
    $r->has_branch('some_branch');

# DESCRIPTION

Adds several methods to [Git::Repository](https://metacpan.org/pod/Git::Repository) objects to check if a Git reference
exists.

# METHODS

## is\_bare()

Check if repository is a bare repository.

## has\_ref($ref\_name)

Check if `$ref_name` exists in the [Git::Repository](https://metacpan.org/pod/Git::Repository).

## has\_branch($branch\_name)

Check if a branch named `$branch_name` exists in the [Git::Repository](https://metacpan.org/pod/Git::Repository).

## has\_tag($tag\_name)

Check if tag named `$tag_name` exists in the [Git::Repository](https://metacpan.org/pod/Git::Repository).

# LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Nathaniel Nutter <nnutter@cpan.org>
