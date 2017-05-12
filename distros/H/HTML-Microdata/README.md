# NAME

HTML::Microdata - Extractor of microdata from HTML.

# SYNOPSIS

    use HTML::Microdata;

    my $microdata = HTML::Microdata->extract(<<EOF, base => 'http://example.com/');
    ...
    EOF
    my $json = $microdata->as_json;

    use Data::Dumper;
    warn Dumper $microdata->items; # returns top level items

# DESCRIPTION

HTML::Microdata is extractor of microdata from HTML to JSON etc.

Implementation of http://www.whatwg.org/specs/web-apps/current-work/multipage/microdata.html#microdata .

# TODO

itemref implementation has not been completed.

# WHY

There already is HTML::HTML5::Microdata::Parser in CPAN. But it has very heavy dependency and I can't install it. And more, package name should not include "HTML5" because HTML5 is just HTML now.

# AUTHOR

cho45 <cho45@lowreal.net>

# SEE ALSO

[HTML::HTML5::Microdata::Parser](https://metacpan.org/pod/HTML::HTML5::Microdata::Parser)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
