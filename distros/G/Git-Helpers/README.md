# NAME

Git::Helpers - Shortcuts for common Git commands

# VERSION

version 0.000014

# SYNOPSIS

    use Git::Helpers qw( checkout_root remote_url);
    my $root = checkout_root();

    my $remote_url = remote_url('upstream');
    my $https_remote_url = https_remote_url();
    my $travis_url = travis_url();

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

## travis\_url( $remote\_name )

Returns a [travis-ci.org](https://metacpan.org/pod/travis-ci.org) URL for the remote you've requested by name.
Defaults to 'origin'.

    # get Travis URL for remote named "origin"
    my $origin_travis_url = travis_url();

    # get Travis URL for remote named "upstream"
    my $upstream_travis_url = travis_url('upstream');

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2018 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
