# NAME

Dist::Zilla::Plugin::PurePerlTests - Run all your tests twice, once with XS code and once with pure Perl

# VERSION

version 0.06

# SYNOPSIS

In your `dist.ini`:

    [PurePerlTests]
    env_var = MY_MODULE_PURE_PERL

# DESCRIPTION

This plugin is for modules which ship with a dual XS/pure Perl implementation.

The plugin makes a copy of all your tests when doing release testing (via
`dzil test` or `dzil release`). The copy will set an environment value that
you specify in a `BEGIN` block. You can use this to force your code to not
load the XS implementation.

# CONFIGURATION

This plugin takes one configuration key, "env\_var", which is required.

# SKIPPING TESTS

If you don't want to run the a given test file in pure Perl mode, you can put
a comment like this in your test:

    # no pp test

This must be on a line by itself. This plugin will skip any tests which
contain this comment.

# SUPPORT

Bugs may be submitted through [the RT bug tracker](http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-PurePerlTests)
(or [bug-dist-zilla-plugin-pureperltests@rt.cpan.org](mailto:bug-dist-zilla-plugin-pureperltests@rt.cpan.org)).

I am also usually active on IRC as 'drolsky' on `irc://irc.perl.org`.

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

Dave Rolsky &lt;autarch@urth.org>

# COPYRIGHT AND LICENCE

This software is Copyright (c) 2010 - 2016 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
