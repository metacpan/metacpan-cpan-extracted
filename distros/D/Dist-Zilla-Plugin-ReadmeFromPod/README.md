# NAME

Dist::Zilla::Plugin::ReadmeFromPod - dzil plugin to generate README from POD

# SYNOPSIS

    # dist.ini
    [ReadmeFromPod]

    # or
    [ReadmeFromPod]
    filename = lib/XXX.pod
    type = markdown
    readme = READTHIS.md
    phase = build

# DESCRIPTION

This plugin generates the `README` from `main_module` (or specified)
by [Pod::Readme](https://metacpan.org/pod/Pod%3A%3AReadme).

# ATTRIBUTES

The following options are supported:

## filename

The name of the file to extract the `README` from. This defaults to
the main module of the distribution.

## type

The type of `README` you want to generate. This defaults to "text".

Other options are "html", "pod", "markdown" and "rtf".

## pod\_class

This is the [Pod::Simple](https://metacpan.org/pod/Pod%3A%3ASimple) class used to translate a file to the
format you want. The default is based on the ["type"](#type) setting, but if
you want to generate an alternative type, you can set this option
instead.

## readme

The name of the file, which defaults to one based on the ["type"](#type).

## phase

This indicates what phase to build the README file from. It is either `build` (the default) or `release`.

# AUTHORS

Fayland Lam <fayland@gmail.com> and
Ævar Arnfjörð Bjarmason <avar@cpan.org>

Robert Rothenberg <rrwo@cpan.org> modified this plugin to use
[Pod::Readme](https://metacpan.org/pod/Pod%3A%3AReadme).

Some parts of the code were borrowed from [Dist::Zilla::Plugin::ReadmeAnyFromPod](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AReadmeAnyFromPod).

# LICENSE AND COPYRIGHT

Copyright 2010-2025 Fayland Lam <fayland@gmail.com> and Ævar
Arnfjörð Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.
