# NAME

Dist::Zilla::Plugin::EnsureChangesHasContent - Checks Changes for content using CPAN::Changes

# VERSION

version 0.02

# SYNOPSIS

    [EnsureChangesHasContent]
    filename = Changelog

# DESCRIPTION

This is a `BeforeRelease` phase plugin that ensures that the changelog file
_in your distribution_ has at least one change listed for the version you are
releasing.

It is an alternative to [Dist::Zilla::Plugin::CheckChangesHasContent](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckChangesHasContent) that
uses [CPAN::Changes](https://metacpan.org/pod/CPAN::Changes) to parse the changelog file. If your file follows the
format described by [CPAN::Changes::Spec](https://metacpan.org/pod/CPAN::Changes::Spec), then this method of checking for
changes is more reliable than the ad hoc parsing used by
[Dist::Zilla::Plugin::CheckChangesHasContent](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckChangesHasContent).

# CONFIGURATION

This plugin offers one configuration option:

## filename

The filename in the distribution containing the changelog. This defaults to
`Changes`.

# SUPPORT

Bugs may be submitted at [http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-EnsureChangesHasContent](http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-EnsureChangesHasContent) or via email to [bug-dist-zilla-plugin-ensurechangeshascontent@rt.cpan.org](mailto:bug-dist-zilla-plugin-ensurechangeshascontent@rt.cpan.org).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Dist-Zilla-Plugin-EnsureChangesHasContent can be found at [https://github.com/houseabsolute/Dist-Zilla-Plugin-EnsureChangesHasContent](https://github.com/houseabsolute/Dist-Zilla-Plugin-EnsureChangesHasContent).

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
