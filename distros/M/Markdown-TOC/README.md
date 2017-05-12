[![Build Status](https://travis-ci.org/imago-storm/Markdown-TOC.svg?branch=master)](https://travis-ci.org/imago-storm/Markdown-TOC)
# NAME

Markdown::TOC - Create a table of contents from markdown

# SYNOPSIS

    use Markdown::TOC;

    my $toc = Markdown::TOC->new(handler => sub {
        my %params = @_;

        return '+' x $params{level} . ' ' . $params{text};
    });

    my $md = q{
    # header1 

    some text

    ## header 2

    some another text
    
    };

    my $toc_html = $toc->process;

# DESCRIPTION

Markdown::TOC is a simple module for building table of contents of markdown files.
The module itself produces a very simple and rather ugly table of contents, it is
supposed to be used with handlers to provide a nice custom-formatted toc.

# METHODS

## new

    my $toc = Markdown::Toc->new(
        handler => sub { ... },
        order_handler => sub { ... },
        anchor_handler => sub { ... },

        delimeter => "\n"
    )

Creates a new TOC processor.

    delimeter - is used for final strings concatenations, an empty string by default.

All handlers are described below.

## process 

Produces formatted TOC from the provided markdown content.

    $toc->process($md);

# HANDLERS

When a header is discovered, an event is fired. So several handlers could be defined to take care
of actual formatting.

## raw\_handler

Takes half-raw data and takes care of all formatting. Accepts `$text` - text content of a header
and `$level` - header level

    my $toc = Markdown::TOC->new(raw_handler => sub {
        my ($text, $level) = @_;
        # Do something about that
    });

## handler

Takes processed data, like text, level, determined order and an anchor for a header.

    my $toc = Markdown::TOC->new(handler => sub{
        my (%param) = @_;

        my $text = $param{text};
        my $anchor = $param{anchor};
        my $order_formatted = $param{order_formatted};
        my $order = $param{order}; # an array like [1, 2, 1], where the first element contains first level number and so on
    
        # format text and give it away
    });

## anchor\_handler

Takes `$text` and `$level` and returns an anchor for a header link
(If we want the link in toc to point on the header. Or somewhere else)

    my $toc = Markdown::TOC->new(anchor_handler => sub {
        my ($text, $level) = @_;
        my $anchor = $text;
        # getting rid of all spaces..
        $anchor =~ s/\s+/_/g;
        return $anchor;
    });

## order\_handler 

Takes `$text` and `$level` and returns a formatted order mark for our future table of contents.

    my $toc = Markdown::TOC->new(sub {
        my ($text, $level) = @_;
        return 42;
    });

If this handler and `handler` were specified, the result from the callback is passed as order\_formatted
parameter.

## listener 

Like raw\_handler, but returns nothing.

    my $table = [];
    my $toc = Markdown::TOC->new(listener => sub {
        my ($text, $level) = @_;
        push @$table, {text => $text, level => $level};
    });

# LICENSE

Copyright (C) Polina Shubina.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Polina Shubina <925043@gmail.com>
