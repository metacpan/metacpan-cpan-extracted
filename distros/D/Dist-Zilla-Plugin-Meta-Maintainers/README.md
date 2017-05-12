# NAME

Dist::Zilla::Plugin::Meta::Maintainers - Generate an x\_maintainers section in distribution metadata

# VERSION

version 0.01

# SYNOPSIS

    [Meta::Maintainers]
    maintainer = Dave Rolsky <autarch@urth.org>
    maintainer = Jane Schmane <jschmane@example.com>

# DESCRIPTION

This plugin adds an `x_maintainers` key in the distribution's metadata. This
will end up in the `META.json` and `META.yml` files, and may also be useful
for things like [Pod::Weaver](https://metacpan.org/pod/Pod::Weaver) plugins.

# SUPPORT

Bugs may be submitted at [http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Meta-Maintainers](http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Meta-Maintainers) or via email to [bug-dist-zilla-plugin-meta-maintainers@rt.cpan.org](mailto:bug-dist-zilla-plugin-meta-maintainers@rt.cpan.org).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Dist-Zilla-Plugin-Meta-Maintainers can be found at [https://github.com/houseabsolute/Dist-Zilla-Plugin-Meta-Maintainers](https://github.com/houseabsolute/Dist-Zilla-Plugin-Meta-Maintainers).

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
