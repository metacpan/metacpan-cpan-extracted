# NAME

Dist::Zilla::PluginBundle::Author::IOANR - Build dists the way IOANR likes

# VERSION

version 1.201592

# OPTIONS

## `fake_release`

Doesn't commit or release anything

```
fake_release = 1
```

## `disable`

Specify plugins to disable. Can be specified multiple times.

```
disable = Some::Plugin
disable = Another::Plugin
```

## `assert_os`

Use [Devel::AssertOS](https://metacpan.org/pod/Devel%3A%3AAssertOS) to control which platforms this dist will build on.
Can be specified multiple times.

```
assert_os = Linux
```

## `custom_builder`

If `custom_builder` is set, [Module::Build](https://metacpan.org/pod/Module%3A%3ABuild) will be used instead of
[Module::Build::Tiny](https://metacpan.org/pod/Module%3A%3ABuild%3A%3ATiny) with a custom build class set to `My::Builder`

## `semantic_version`

If `semantic_version` is true (the default), git tags will be in the form
`^v(\d+\.\d+\.\d+)$`. Otherwise they will be `^v(\d+\.\d+)$`.

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

```
perldoc Dist::Zilla::PluginBundle::Author::IOANR
```

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [https://metacpan.org/release/Dist-Zilla-PluginBundle-Author-IOANR](https://metacpan.org/release/Dist-Zilla-PluginBundle-Author-IOANR)

## Bugs / Feature Requests

Please report any bugs or feature requests through the web interface at [https://gitlab.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR/issues](https://gitlab.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR/issues).
You will be automatically notified of any progress on the request by the system.

## Source Code

The source code is available for from the following locations:

[https://gitlab.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR](https://gitlab.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR)

```
git clone https://gitlab.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR.git
```

# AUTHOR

Ioan Rogers <ioanr@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ioan Rogers.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
