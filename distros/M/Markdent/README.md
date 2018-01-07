# NAME

Markdent - An event-based Markdown parser toolkit

# VERSION

version 0.29

# SYNOPSIS

    use Markdent::Simple::Document;

    my $parser = Markdent::Simple::Document->new();
    my $html   = $parser->markdown_to_html(
        title    => 'My Document',
        markdown => $markdown,
    );

# DESCRIPTION

This distribution provides a toolkit for parsing Markdown (and Markdown
variants, aka dialects). Unlike the other Markdown Perl tools, this module can
be used for more than just generating HTML. The core parser generates events
(like XML's SAX), making it easy to analyze a Markdown document in any number
of ways.

If you're only interested in converting Markdown to HTML, you can use the
[Markdent::Simple::Document](https://metacpan.org/pod/Markdent::Simple::Document) class to do this, although you can just as well
use better battle-tested tools like [Text::Markdown](https://metacpan.org/pod/Text::Markdown).

See [Markdent::Manual](https://metacpan.org/pod/Markdent::Manual) for more details on how Markdent works and how you can
use it.

# ALPHA WARNING

This code is still quite new. While the Markdown to HTML conversion seems to
work fine, the internals are subject to change.

# DONATIONS

If you'd like to thank me for the work I've done on this module,
please consider making a "donation" to me via PayPal. I spend a lot of
free time creating free software, and would appreciate any support
you'd care to offer.

Please note that **I am not suggesting that you must do this** in order
for me to continue working on this particular software. I will
continue to do so, inasmuch as I have in the past, for as long as it
interests me.

Similarly, a donation made in this way will probably not make me work
on this software much more, unless I get so many donations that I can
consider working on free software full time, which seems unlikely at
best.

To donate, log into PayPal and send money to autarch@urth.org or use
the button on this page:
[http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html)

# BUGS

Please report any bugs or feature requests to `bug-markdent@rt.cpan.org`,
or through the web interface at [http://rt.cpan.org](http://rt.cpan.org).  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Bugs may be submitted at [http://rt.cpan.org/Public/Dist/Display.html?Name=Markdent](http://rt.cpan.org/Public/Dist/Display.html?Name=Markdent) or via email to [bug-markdent@rt.cpan.org](mailto:bug-markdent@rt.cpan.org).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Markdent can be found at [https://github.com/houseabsolute/Markdent](https://github.com/houseabsolute/Markdent).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Andrew Speer <andrew.speer@isolutions.com.au>
- Jason McIntosh <jmac@appleseed-sc.com>
- Polina Shubina <925043@mai.com>
- Tom Hukins <tom@eborcom.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
`LICENSE` file included with this distribution.
