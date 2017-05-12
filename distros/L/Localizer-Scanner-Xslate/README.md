# NAME

Localizer::Scanner::Xslate - Scanner for [Text::Xslate](https://metacpan.org/pod/Text::Xslate) style file

# SYNOPSIS

    use Localizer::Dictionary;
    use Localizer::Scanner::Xslate;

    my $result  = Localizer::Dictionary->new();
    my $scanner = Localizer::Scanner::Xslate->new(
        syntax => 'TTerse',
    );
    $scanner->scan_file($result, 'path/to/xslate.html');

# DESCRIPTION

Localizer::Scanner::Xslate is localization tag scanner for Xslate templates.

This module finds `[% l("foo") %]` style tags from xslate template files.

# METHODS

- Localizer::Scanner::Xslate(%args | \\%args)

    Constructor. It makes scanner instance.

    e.g.

        my $ext = Localizer::Scanner::Xslate->new(
            syntax => 'Kolon', # => will use Text::Xslate::Syntax::Kolon
        );

    - syntax: String

        Specify syntax of [Text::Xslate](https://metacpan.org/pod/Text::Xslate). Default, this module uses [Text::Xslate::Syntax::TTerse](https://metacpan.org/pod/Text::Xslate::Syntax::TTerse).

- $scanner->scan\_file($result, $filename)

    Scan file which is written by xslate.
    `$result` is the instance of [Localizer::Dictionary](https://metacpan.org/pod/Localizer::Dictionary) to store results.
    `$filename` is file name of the target to scan.

    For example, if target file is follows;

        [% IF xxx == l('term') %]
        [% END %]

        [% l('hello') %]

    Scanner uses `l('foobar')` as `msgid` (in this case, 'foobar' will be `msgid`).

    `$result` will be like a following;

        {
            'term' => {
                'position' => [ [ 'path/to/xslate.html', 1 ] ]
            },
            'hello' => {
                'position' => [ [ 'path/to/xslate.html', 4 ] ]
            }
        }

- $scanner->scan($result, $filename, $data)

    This method is almost the same as `scan_file()`.
    This method does not load file contents, it uses `$data` as file contents instead.

# SEE ALSO

This module is based on [Locale::Maketext::Extract::Plugin::Xslate](https://metacpan.org/pod/Locale::Maketext::Extract::Plugin::Xslate).

# LICENSE

Copyright (C) Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazuhiro Osawa, Tokuhiro Matsuno <tokuhirom@gmail.com>
