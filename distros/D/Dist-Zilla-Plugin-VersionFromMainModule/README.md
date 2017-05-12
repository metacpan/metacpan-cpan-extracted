# NAME

Dist::Zilla::Plugin::VersionFromMainModule - Set the distribution version from your main module's $VERSION

# VERSION

version 0.02

# SYNOPSIS

    [VersionFromMainModule]

# DESCRIPTION

This plugin sets the distribution version from the `$VERSION` found in the
distribution's main module, as defined by [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla).

This plugin is useful if you want to set the `$VERSION` in your module(s)
manually or with some sort of post-release "increment the `$VERSION`" plugin,
rather than letting dzil add the `$VERSION` based on a setting in the
`dist.ini`.

# CREDITS

This code is mostly the same as what Christopher J. Madsen's
[Dist::Zilla::Plugin::VersionFromModule](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromModule) module does. Unfortunately, that
module is only shipped as part of a larger distribution, and that distribution
has not been updated despite the fact that it is failing tests with newer
versions of dzil.

# SUPPORT

Bugs may be submitted at [http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-VersionFromMainModule](http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-VersionFromMainModule) or via email to [bug-dist-zilla-plugin-versionfrommainmodule@rt.cpan.org](mailto:bug-dist-zilla-plugin-versionfrommainmodule@rt.cpan.org).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Dist-Zilla-Plugin-VersionFromMainModule can be found at [https://github.com/houseabsolute/Dist-Zilla-Plugin-VersionFromMainModule](https://github.com/houseabsolute/Dist-Zilla-Plugin-VersionFromMainModule).

# AUTHORS

- Christopher J. Madsen <perl@cjmweb.net>
- Dave Rolsky <autarch@urth.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2009 - 2017 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
`LICENSE` file included with this distribution.
