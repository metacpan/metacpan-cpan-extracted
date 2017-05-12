# NAME

HTML::TreeBuilder::LibXML - HTML::TreeBuilder and XPath compatible interface with libxml

# SYNOPSIS

    use HTML::TreeBuilder::LibXML;

    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($html);
    $tree->eof;

    # $tree and $node compatible to HTML::Element
    my @nodes = $tree->findvalue($xpath);
    for my $node (@nodes) {
        print $node->tag;
        my %attr = $node->all_external_attr;
    }

    HTML::TreeBuilder::LibXML->replace_original(); # replace HTML::TreeBuilder::XPath->new

# DESCRIPTION

HTML::TreeBuilder::XPath is libxml based compatible interface to
HTML::TreeBuilder, which could be slow for a large document.

HTML::TreeBuilder::LibXML is drop-in-replacement for HTML::TreeBuilder::XPath.

This module doesn't implement all of HTML::TreeBuilder and
HTML::Element APIs, but enough methods are defined so modules like
Web::Scraper work.

# BENCHMARK

This is a benchmark result by tools/benchmark.pl

        Web::Scraper: 0.26
        HTML::TreeBuilder::XPath: 0.09
        HTML::TreeBuilder::LibXML: 0.01_01

                     Rate  no_libxml use_libxml
        no_libxml  5.45/s         --       -94%
        use_libxml 94.3/s      1632%         --

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

Tatsuhiko Miyagawa <miyagawa@cpan.org>

Masahiro Chiba

# THANKS TO

woremacx++
http://d.hatena.ne.jp/woremacx/20080202/1201927162

id:dailyflower

# SEE ALSO

[HTML::TreeBuilder](https://metacpan.org/pod/HTML::TreeBuilder), [HTML::TreeBuilder::XPath](https://metacpan.org/pod/HTML::TreeBuilder::XPath)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
