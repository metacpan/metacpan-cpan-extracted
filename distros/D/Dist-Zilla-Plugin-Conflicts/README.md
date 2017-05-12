# NAME

Dist::Zilla::Plugin::Conflicts - Declare conflicts for your distro

# VERSION

version 0.19

# SYNOPSIS

In your `dist.ini`:

    [Conflicts]
    Foo::Bar = 0.05
    Thing    = 2

# DESCRIPTION

This module lets you declare conflicts on other modules (usually dependencies
of your module) in your `dist.ini`.

Declaring conflicts does several thing to your distro.

First, it generates a module named something like
`Your::Distro::Conflicts`. This module will use [Dist::CheckConflicts](https://metacpan.org/pod/Dist::CheckConflicts) to
declare and check conflicts. The package name will be obscured from PAUSE by
putting a newline after the `package` keyword.

All of your runtime prereqs will be passed in the `-also` parameter to
[Dist::CheckConflicts](https://metacpan.org/pod/Dist::CheckConflicts).

Second, it adds code to your `Makefile.PL` or `Build.PL` to load the
generated module and print warnings if conflicts are detected.

Finally, it adds the conflicts to the `META.json` and/or `META.yml` files
under the "x\_breaks" key.

# USAGE

Using this module is simple, add a "\[Conflicts\]" section and list each module
you conflict with:

    [Conflicts]
    Module::X = 0.02

The version listed is the last version that _doesn't_ work. In other words,
any version of `Module::X` greater than 0.02 should work with this release.

The special key `-script` can also be set, and given the name of a script to
generate, as in:

    [Conflicts]
    -script   = bin/foo-conflicts
    Module::X = 0.02

This script will be installed with your module, and can be run to check for
currently installed modules which conflict with your module. This allows users
an easy way to fix their conflicts - simply run a command such as
`foo-conflicts | cpanm` to bring all of your conflicting modules up to date.

**Note:** Currently, this plugin only works properly if it is listed in your
`dist.ini` _after_ the plugin which generates your `Makefile.PL` or
`Build.PL`. This is a limitation of [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) that will hopefully be
addressed in a future release.

# SEE ALSO

- [Dist::CheckConflicts](https://metacpan.org/pod/Dist::CheckConflicts)
- [Dist::Zilla::Plugin::Breaks](https://metacpan.org/pod/Dist::Zilla::Plugin::Breaks)
- [Dist::Zilla::Plugin::Test::CheckBreaks](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::CheckBreaks)

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html)

# SUPPORT

Please report any bugs or feature requests to
`bug-dist-zilla-plugin-conflicts@rt.cpan.org`, or through the web interface
at [http://rt.cpan.org](http://rt.cpan.org). I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

Bugs may be submitted through [the RT bug tracker](http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Conflicts)
(or [bug-dist-zilla-plugin-conflicts@rt.cpan.org](mailto:bug-dist-zilla-plugin-conflicts@rt.cpan.org)).

There is a mailing list available for users of this distribution,
[mailto:http://dzil.org/#mailing-list](mailto:http://dzil.org/#mailing-list).

This distribution also has an IRC channel at
[`#distzilla` on `irc.perl.org`](irc://irc.perl.org/#distzilla).

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

Dave Rolsky <autarch@urth.org>

# CONTRIBUTOR

Karen Etheridge <ether@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
