# NAME

Git::Helpers - Shortcuts for common Git commands

# VERSION

version 1.000001

# SYNOPSIS

    use Git::Helpers qw(
        checkout_root
        current_branch_name
        https_remote_url
        is_inside_work_tree
        remote_url
    );

    my $dir              = '/path/to/folder/in/git/checkout';
    my $root             = checkout_root($dir);
    my $current_branch   = current_branch_name();
    my $https_remote_url = https_remote_url();
    my $inside_work_tree = is_inside_work_tree();
    my $remote_url       = remote_url('upstream');

## checkout\_root( $dir )

Gives you the root level of the git checkout which you are currently in.
Optionally accepts a directory parameter.  If you provide the directory
parameter, `checkout_root` will temporarily `chdir` to this directory and
find the top level of the repository.

This method will throw an exception if it cannot find a git repository at the
directory provided.

## current\_branch\_name

Returns the name of the current branch.

## https\_remote\_url( $remote\_name, $use\_current\_branch )

This is a browser-friendly URL for the remote, fixed up in such a way that
GitHub (hopefully) doesn't need to redirect your URL.

Turns git@github.com:oalders/git-helpers.git into https://github.com/oalders/git-helpers

Turns https://github.com/oalders/git-helpers.git into https://github.com/oalders/git-helpers

Defaults to using `origin` as the remote if none is supplied.

Defaults to master branch, but can also display current branch.

    my $current_branch_url = https_remote_url( 'origin', 1 );

## ignored\_files( $dir )

Returns an arrayref of files which exist in your checkout, but are ignored by
Git.  Optionally accepts a directory as an argument.  Defaults to ".".

Throws an exception if there has been an error running the command.

## is\_inside\_work\_tree

Returns `true` if `git rev-parse --is-inside-work-tree` returns `true`.
Otherwise returns `false`. This differs slightly from the behaviour of
`--is-inside-work-tree` in real life, since it returns `fatal` rather than
`false` if run outside of a git repository.

## remote\_url( $remote\_name )

Returns a URL for the remote you've requested by name.  Defaults to 'origin'.
Provides you with the exact URL which git returns. Nothing is fixed up for you.

    # defaults to 'origin'
    my $remote_url = remote_url();
    # $remote_url is now possibly something like one of the following:
    # git@github.com:oalders/git-helpers.git
    # https://github.com/oalders/git-helpers.git

    # get URL for upstream remote
    my $upstream_url = remote_url('upstream');

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
