[![Build Status](https://travis-ci.org/ywatase/p5-HTML-WikiConverter-FreeStyleWiki.svg?branch=master)](https://travis-ci.org/ywatase/p5-HTML-WikiConverter-FreeStyleWiki)
# NAME

HTML::WikiConverter::FreeStyleWiki - Convert HTML to FreeStyleWiki markup

# SYNOPSIS

    use HTML::WikiConverter;
    my $wc = new HTML::WikiConverter( dialect => 'FreeStyleWiki' );
    print $wc->html2wiki( $html );

# DESCRIPTION

This module contains rules for converting HTML into FreeStyleWiki
markup. See [HTML::WikiConverter](https://metacpan.org/pod/HTML::WikiConverter) for additional usage details.

# ATTRIBUTES

In addition to the regular set of attributes recognized by the
[HTML::WikiConverter](https://metacpan.org/pod/HTML::WikiConverter) constructor, this dialect also accepts the
following attributes that can be passed into the `new()`
constructor. See ["ATTRIBUTES" in HTML::WikiConverter](https://metacpan.org/pod/HTML::WikiConverter#ATTRIBUTES) for usage details.

## preserve\_tags

Possible values: `0`, `1`. Default is `0`.
Preserve tags: `'big', 'small', 'tt', 'abbr', 'acronym', 'cite', 'code', 'dfn', 'kbd', 'samp', 'var', 'sup', 'sub`

# LICENSE

Copyright (C) Yusuke Watase.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yusuke Watase <ywatase@gmail.com>
