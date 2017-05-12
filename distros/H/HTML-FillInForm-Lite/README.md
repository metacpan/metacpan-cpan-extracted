# NAME

HTML::FillInForm::Lite - Lightweight FillInForm module in Pure Perl

# VERSION

The document describes HTML::FillInForm::Lite version 1.15

# SYNOPSIS

    use HTML::FillInForm::Lite;
    use CGI;

    my $q = CGI->new();
    my $h = HTML::FillInForm::Lite->new();

    $output = $h->fill(\$html,    $q);
    $output = $h->fill(\@html,    \%data);
    $output = $h->fill(\*HTML,    \&my_param);
    $output = $h->fill('t.html', [$q, \%default]);

    # or as a class method with options
    $output = HTML::FillInForm::Lite->fill(\$html, $q,
        fill_password => 0, # it is default
        ignore_fields => ['foo', 'bar'],
        target        => $form_id,
    );

    # Moreover, it accepts any object as form data
    # (these classes come form Class::DBI's SYNOPSIS)

    my $artist = Music::Artist->insert({ id => 1, name => 'U2' });
    $output = $h->fill(\$html, $artist);

    my $cd = Music::CD->retrieve(1);
    $output = $h->fill(\$html, $cd);

    # simple function interface
    use HTML::FillInForm::Lite qw(fillinform);

    # the same as HTML::FillInForm::Lite->fill(...)
    $output = fillinform(\$html, $q);

# DESCRIPTION

This module fills in HTML forms with Perl data,
which re-implements `HTML::FillInForm` using regexp-based parser,
not using `HTML::Parser`.

The difference in the parsers makes `HTML::FillInForm::Lite` about 2
times faster than `HTML::FillInForm`.

# FUNCTIONS

## fillinform(source, form\_data)

Simple interface to the `fill()` method, accepting only a string.
If you pass a single argument to this function, it is interpreted as
_form\_data_, and returns a function that accepts _source_.

    my $fillinform = fillinform($query);
    $fillinform->($html); # the same as fillinform($html, $query)

This function is exportable.

# METHODS

## new(options...)

Creates `HTML::FillInForm::Lite` processor with _options_.

There are several options. All the options are disabled when `undef` is
supplied.

Acceptable options are as follows:

- fill\_password => _bool_

    To enable passwords to be filled in, set the option true.

    Note that the effect of the option is the same as that of `HTML::FillInForm`,
    but by default `HTML::FillInForm::Lite` ignores password fields.

- ignore\_fields => _array\_ref\_of\_fields_

    To ignore some fields from filling.

- target => _form\_id_

    To fill in just the form identified by _form\_id_.

- escape => _bool_ | _ref_

    If true is provided (or by default), values filled in text fields will be
    HTML-escaped, e.g. `<tag>` to be `&lt;tag&gt;`.

    If the values are already HTML-escaped, set the option false.

    You can supply a subroutine reference to escape the values.

    Note that it is not implemented in `HTML::FillInForm`.

- decode\_entity => _bool_ | _ref_

    If true is provided , HTML entities in state fields
    (namely, `radio`, `checkbox` and `select`) will be decoded,
    but normally it is not needed.

    You can also supply a subroutine reference to decode HTML entities.

    Note that `HTML::FillInForm` always decodes HTML entities in state fields,
    but not supports this option.

- layer => _:iolayer_

    To read a file with _:iolayer_. It is used when a file name is supplied as
    _source_.

    For example:

        # To read a file encoded in UTF-8
        $fif = HTML::FillInForm::Lite->new(layer => ':utf8');
        $output = $fif->fill($utf8_file, $fdat);

        # To read a file encoded in EUC-JP
        $fif = HTML::FillInForm::Lite->new(layer => ':encoding(euc-jp)');
        $output = $fif->fill($eucjp_file, $fdat);

    Note that it is not implemented in `HTML::FillInForm`.

## fill(source, form\_data \[, options...\])

Fills in _source_ with _form\_data_. If _source_ or _form\_data_ is not
supplied, it will cause `die`.

_options_ are the same as `new()`'s.

You can use this method as a both class or instance method,
but you make multiple calls to `fill()` with the **same**
options, it is a little faster to call `new()` and store the instance.

_source_ may be a scalar reference, an array reference of strings, or
a file name.

_form\_data_ may be a hash reference, an object with `param()` method,
an object with accessors, a code reference, or an array reference of
those above mentioned.

If _form\_data_ is based on procedures (i.e. not a hash reference),
the procedures will be called in the list context.
Therefore, to leave some fields untouched, it must return a null list `()`,
not `undef`.

# DEPENDENCIES

Perl 5.8.1 or later.

# NOTES

## Compatibility with `HTML::FillInForm`

This module implements only the new syntax of `HTML::FillInForm`
version 2. However, `HTML::FillInForm::Lite::Compat` provides
an interface compatible with `HTML::FillInForm`.

## Compatibility with legacy HTML

This module is designed to process XHTML 1.x.

And it also supporting a good part of HTML 4.x , but there are some
limitations. First, it doesn't understand HTML-attributes that the name is
omitted.

For example:

    <INPUT TYPE=checkbox NAME=foo CHECKED> -- NG.
    <INPUT TYPE=checkbox NAME=foo CHECKED=checked> - OK, but obsolete.
    <input type="checkbox" name="foo" checked="checked" /> - OK, valid XHTML

Then, it always treats the values of attributes case-sensitively.
In the example above, the value of `type` must be lower-case.

Moreover, it doesn't recognize omitted closing tags, like:

    <select name="foo">
        <option>bar
        <option>baz
    </select>

When you can't get what you want, try to give your source to a HTML lint.

## Comment handling

This module processes all the processable, not knowing comments
nor something that shouldn't be processed.

It may cause problems. Suppose there is a code like:

    <script> document.write("<input name='foo' />") </script>

`HTML::FillInForm::Lite` will break the code:

    <script> document.write("<input name='foo' value="bar" />") </script>

To avoid such problems, you can use the `ignore_fields` option.

# BUGS

No bugs have been reported.

Please report any bug or feature request to &lt;gfuji(at)cpan.org>,
or through the RT [http://rt.cpan.org/](http://rt.cpan.org/).

# SEE ALSO

[HTML::FillInForm](https://metacpan.org/pod/HTML::FillInForm).

[HTML::FillInForm::Lite::JA](https://metacpan.org/pod/HTML::FillInForm::Lite::JA) - the document in Japanese.

[HTML::FillInForm::Lite::Compat](https://metacpan.org/pod/HTML::FillInForm::Lite::Compat) - HTML::FillInForm compatibility layer

# AUTHOR

Goro Fuji (藤 吾郎) &lt;gfuji(at)cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2008-2010 Goro Fuji, Some rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
