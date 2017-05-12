# NAME

Dist::Zilla::Plugin::Test::Pod::Coverage::Configurable - dzil pod coverage tests with configurable parameters

# VERSION

version 0.06

# SYNOPSIS

    [Test::Pod::Coverage::Configurable]
    class = Pod::Coverage::Moose
    trustme = Dist::Some::Module => qr/^(?:foo|bar)$/
    trustme = Dist::Some::Module => qr/^foo_/
    trustme = Dist::This::Module => qr/^bar_/
    skip = Dist::Other::Module
    skip = Dist::YA::Module
    skip = qr/^Dist::Foo/
    also_private = BUILDARGS
    also_private = qr/^ERR_/

# DESCRIPTION

This is a [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugin that creates a POD coverage test for your
distro. Unlike the plugin that ships with dzil in core, this one is quite
configurable. The coverage test is generated as `xt/release/pod-coverage.t`.

[Test::Pod::Coverage](https://metacpan.org/pod/Test::Pod::Coverage) `1.08`, [Test::More](https://metacpan.org/pod/Test::More) `0.88`, and
[Pod::Coverage::TrustPod](https://metacpan.org/pod/Pod::Coverage::TrustPod) will be added as `develop requires` dependencies.

# NAME

Dist::Zilla::Plugin::Test::Pod::Coverage::Configurable - a configurable release test for Pod coverage

# CONFIGURATION

This plugin accepts the following configuration options

## class

By default, this plugin uses [Pod::Coverage::TrustPod](https://metacpan.org/pod/Pod::Coverage::TrustPod) to run its tests. You
can provide an alternate class, such as [Pod::Coverage::Moose](https://metacpan.org/pod/Pod::Coverage::Moose). If you
provide a class then the generate test file will create a subclass of the
class you provide and [Pod::Coverage::TrustPod](https://metacpan.org/pod/Pod::Coverage::TrustPod).

This test can be configured by providing `trustme`, `skip`, and `class`
parameters in your `dist.ini` file.

Since this test always uses [Pod::Coverage::TrustPod](https://metacpan.org/pod/Pod::Coverage::TrustPod), you can use that to
indicate that some subs should be treated as covered, even if no documentation
can be found, you can add:

    =for Pod::Coverage sub_name other_sub this_one_too

## skip

This can either be a plain module name or a regex of the form `qr/.../`. Any
modules defined here will be skipped entirely when testing POD coverage.

## trustme

This parameter allows you to specify regexes for methods that should be
considered coverage on a per-module basis. The parameter is provided in the
form `Module::Name => qr/^regex/`. You can include the same module name
multiple times.

## also\_private

This parameter allows you to specify regexes for methods that should be
considered private. You can provide it as a plain method name string or as a
regular expression of the form `qr/^regex/`. You can specify this parameter
multiple times.

# SUPPORT

Bugs may be submitted through [the RT bug tracker](http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-Pod-Coverage-Configurable)
(or [bug-dist-zilla-plugin-test-pod-coverage-configurable@rt.cpan.org](mailto:bug-dist-zilla-plugin-test-pod-coverage-configurable@rt.cpan.org)).

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

# CONTRIBUTOR

David Golden &lt;dagolden@cpan.org>

# COPYRIGHT AND LICENCE

This software is Copyright (c) 2014 - 2016 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
