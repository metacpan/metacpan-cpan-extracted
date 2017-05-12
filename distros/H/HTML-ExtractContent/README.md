[![Build Status](https://travis-ci.org/tarao/perl5-HTML-ExtractContent.svg?branch=master)](https://travis-ci.org/tarao/perl5-HTML-ExtractContent)
# NAME

HTML::ExtractContent - An HTML content extractor with scoring heuristics

# SYNOPSIS

    use HTML::ExtractContent;
    use LWP::UserAgent;

    my $agent = LWP::UserAgent->new;
    my $res = $agent->get('http://www.example.com/');

    my $extractor = HTML::ExtractContent->new;
    $extractor->extract($res->decoded_content);
    print $extractor->as_text;

# DESCRIPTION

HTML::ExtractContent is a module for extracting content from HTML with scoring
heuristics. It guesses which block of HTML looks like content according to
scores depending on the amount of punctuation marks and the lengths of non-tag
texts. It also guesses whether content end in the block or continue to the
next block.

# METHODS

- new

        $extractor = HTML::ExtractContent->new;

    Creates a new HTML::ExtractContent instance.

- extract

        $extractor->extract($html);

    Extracts content from `$html`.
    `$html` must have its UTF-8 flag on.

- as\_text

        $extractor->extract($html)->as_text;

    Returns extracted content as a plain text. All tags are eliminated.

- as\_html

        $extractor->extract($html)->as_html;

    Returns extracted content as an HTML text.
    Note that the returned text is neither fully tagged nor valid HTML.
    It doesn't contain tags such as <html> and it may have block tags that are
    not closed, or closed but not opened.
    This method is intended for the case that you need to analyse link tags in
    the text for example.

# ACKNOWLEDGMENT

Hiromichi Kishi contributed towards development of this module
as a partner of pair programming.

Implementation of this module is based on the Ruby module ExtractContent by
Nakatani Shuyo.

# AUTHOR

INA Lintaro <tarao at cpan.org>

# COPYRIGHT

Copyright (C) 2008 INA Lintaro / Hatena. All rights reserved.

## Copyright of the original implementation

Copyright (c) 2007/2008 Nakatani Shuyo / Cybozu Labs Inc. All rights reserved.

# LICENCE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

[http://rubyforge.org/projects/extractcontent/](http://rubyforge.org/projects/extractcontent/)
