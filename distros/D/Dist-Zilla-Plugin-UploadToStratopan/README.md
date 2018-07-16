# NAME

Dist::Zilla::Plugin::UploadToStratopan - Automate Stratopan releases with Dist::Zilla

# SYNOPSIS

In your `dist.ini`:

    [UploadToStratopan]
    repo    = myrepo
    stack   = master
    recurse = 1 ;defaults to 0

# DESCRIPTION

This is a Dist::Zilla releaser plugin which will automatically upload your
completed build tarball to Stratopan.

The module will prompt you for your Stratopan username (NOT email) and password.

Currently, it works by posting the file to Stratopan's "Add" form; when the
Stratopan REST API becomes available, this module will be updated to use it
instead.

# ATTRIBUTES

## agent

The HTTP user agent string to use when talking to Stratopan. The default
is `stratopan-uploader/$VERSION`.

## repo

The name of the Stratopan repository. Required.

## stack

The name of the stack within your repository to which you want to upload. The
default is `master`.

## recurse

Recursively pull all prerequisites too when true, defaults to only uploading
the intented modules

# METHODS

## release

Release the modeule

# AUTHOR

Mike Friedman <friedo@friedo.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mike Friedman

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
