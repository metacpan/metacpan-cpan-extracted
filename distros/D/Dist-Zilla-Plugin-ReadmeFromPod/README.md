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

# DESCRIPTION

This plugin generates the `README` from `main_module` (or specified)
by [Pod::Readme](https://metacpan.org/pod/Pod::Readme).

## Options

The following options are supported:

### `filename`

The name of the file to extract the `README` from. This defaults to
the main module of the distribution.

### `type`

The type of `README` you want to generate. This defaults to "text".

Other options are "html", "pod", "markdown" and "rtf".

### `pod_class`

This is the [Pod::Simple](https://metacpan.org/pod/Pod::Simple) class used to translate a file to the
format you want. The default is based on the ["type"](#type) setting, but if
you want to generate an alternative type, you can set this option
instead.

### `readme`

The name of the file, which defaults to one based on the ["type"](#type).

## Conflicts with Other Plugins

We will remove the README created by [Dist::Zilla::Plugin::Readme](https://metacpan.org/pod/Dist::Zilla::Plugin::Readme) automatically.

# AUTHORS

Fayland Lam <fayland@gmail.com> and
Ævar Arnfjörð Bjarmason <avar@cpan.org>

Robert Rothenberg <rrwo@cpan.org> modified this plugin to use
[Pod::Readme](https://metacpan.org/pod/Pod::Readme).

# LICENSE AND COPYRIGHT

Copyright 2010-2014 Fayland Lam <fayland@gmail.com> and Ævar
Arnfjörð Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.
