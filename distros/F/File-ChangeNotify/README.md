# NAME

File::ChangeNotify - Watch for changes to files, cross-platform style

# VERSION

version 0.29

# SYNOPSIS

    use File::ChangeNotify;

    my $watcher =
        File::ChangeNotify->instantiate_watcher
            ( directories => [ '/my/path', '/my/other' ],
              filter      => qr/\.(?:pm|conf|yml)$/,
            );

    if ( my @events = $watcher->new_events() ) { ... }

    # blocking
    while ( my @events = $watcher->wait_for_events() ) { ... }

# DESCRIPTION

This module provides an API for creating a
[File::ChangeNotify::Watcher](https://metacpan.org/pod/File::ChangeNotify::Watcher) subclass that will work on your
platform.

Most of the documentation for this distro is in
[File::ChangeNotify::Watcher](https://metacpan.org/pod/File::ChangeNotify::Watcher).

# METHODS

This class provides the following methods:

## File::ChangeNotify->instantiate\_watcher(...)

This method looks at each available subclass of
[File::ChangeNotify::Watcher](https://metacpan.org/pod/File::ChangeNotify::Watcher) and instantiates the first one it can
load, using the arguments you provided.

It always tries to use the [File::ChangeNotify::Watcher::Default](https://metacpan.org/pod/File::ChangeNotify::Watcher::Default)
class last, on the assumption that any other class that is available
is a better option.

## File::ChangeNotify->usable\_classes()

Returns a list of all the loadable [File::ChangeNotify::Watcher](https://metacpan.org/pod/File::ChangeNotify::Watcher) subclasses
except for [File::ChangeNotify::Watcher::Default](https://metacpan.org/pod/File::ChangeNotify::Watcher::Default), which is always usable.

# SUPPORT

Bugs may be submitted at [http://rt.cpan.org/Public/Dist/Display.html?Name=File-ChangeNotify](http://rt.cpan.org/Public/Dist/Display.html?Name=File-ChangeNotify) or via email to [bug-file-changenotify@rt.cpan.org](mailto:bug-file-changenotify@rt.cpan.org).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for File-ChangeNotify can be found at [https://github.com/houseabsolute/File-ChangeNotify](https://github.com/houseabsolute/File-ChangeNotify).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Aaron Crane <arc@cpan.org>
- H. Merijn Branch <h.m.brand@xs4all.nl>
- Karen Etheridge <ether@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 - 2018 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.
