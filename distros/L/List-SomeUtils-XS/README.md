# NAME

List::SomeUtils::XS - XS implementation for List::SomeUtils

# VERSION

version 0.53

# DESCRIPTION

There are no user-facing parts here. See [List::SomeUtils](https://metacpan.org/pod/List::SomeUtils) for API details.

You shouldn't have to install this module directly. When you install
[List::SomeUtils](https://metacpan.org/pod/List::SomeUtils), it checks whether your system has a compiler. If it does,
then it adds a dependency on this module so that it gets installed and you
have the faster XS implementation.

This distribution requires [List::SomeUtils](https://metacpan.org/pod/List::SomeUtils) but to avoid a circular
dependency, that dependency is explicitly left out from the this
distribution's metadata. However, without LSU already installed this module
cannot function.

# SEE ALSO

[List::Util](https://metacpan.org/pod/List::Util), [List::AllUtils](https://metacpan.org/pod/List::AllUtils)

# HISTORICAL COPYRIGHT

Some parts copyright 2011 Aaron Crane.

Copyright 2004 - 2010 by Tassilo von Parseval

Copyright 2013 - 2015 by Jens Rehsack

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/List-SomeUtils-XS/issues](https://github.com/houseabsolute/List-SomeUtils-XS/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for List-SomeUtils-XS can be found at [https://github.com/houseabsolute/List-SomeUtils-XS](https://github.com/houseabsolute/List-SomeUtils-XS).

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

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.
