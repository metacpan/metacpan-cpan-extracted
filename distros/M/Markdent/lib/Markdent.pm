## no critic (Moose::RequireMakeImmutable)
package Markdent;

use 5.010;
use strict;
use warnings;

# The first version that completely worked with newer versions of Specio.
use Moose 2.1802 ();

our $VERSION = '0.37';

1;

# ABSTRACT: An event-based Markdown parser toolkit

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent - An event-based Markdown parser toolkit

=head1 VERSION

version 0.37

=head1 SYNOPSIS

    use Markdent::Simple::Document;

    my $parser = Markdent::Simple::Document->new();
    my $html   = $parser->markdown_to_html(
        title    => 'My Document',
        markdown => $markdown,
    );

=head1 DESCRIPTION

This distribution provides a toolkit for parsing Markdown (and Markdown
variants, aka dialects). Unlike the other Markdown Perl tools, this module can
be used for more than just generating HTML. The core parser generates events
(like XML's SAX), making it easy to analyze a Markdown document in any number
of ways.

If you're only interested in converting Markdown to HTML, you can use the
L<Markdent::Simple::Document> class to do this, although you can just as well
use better battle-tested tools like L<Text::Markdown>.

See L<Markdent::Manual> for more details on how Markdent works and how you can
use it.

=head1 QUICK MARKDOWN TO HTML CONVERSION

If you just want to do some quick Markdown to HTML conversion use either the
L<Markdent::Simple::Document> or L<Markdent::Simple::Fragment> class.

This distribution also ships with a command line tool called
L<markdent-html>. See that tool's documentation for details on how to use it.

=head1 PROCESSING PIPELINES

If you want to create a Markdown processing pipeline, start by looking at the
various handler classes:

=over 4

=item * L<Markdent::Handler::HTMLStream::Document>

=item * L<Markdent::Handler::HTMLStream::Fragment>

=item * L<Markdent::Handler::HTMLStream::Multiplexer>

=item * L<Markdent::Handler::HTMLStream::HTMLFilter>

=item * L<Markdent::Handler::HTMLStream::CaptureEvents>

=back

You will probably also want to write your own handler class as part of the
pipeline. This will need to implement the L<Markdent::Role::Handler> role.

To do that you'll need to review the many C<Markdent::Event::*> classes. Each
event represents something seen by the parse, such as a piece of the start or
end of a piece of block (paragraph, header) or span markup (strong, link) or
some text.

The start of a pipeline will generally be either the L<Markdent::Parser> or
L<Markdent::CapturedEvents> class.

=head1 CUSTOM DIALECTS

You may also want to implement a custom dialect to add some additional
features to the parser. Your parser classes will need to consume either the
L<Markdent::Role::Dialect::BlockParser> or the
L<Markdent::Role::Dialect::SpanParser> role. The best way to understand how a
dialect is implemented is to look at one of the existing dialect classes:

=over 4

=item * L<Markdent::Dialect::GitHub::BlockParser>

=item * L<Markdent::Dialect::GitHub::SpanParser>

=item * L<Markdent::Dialect::Theory::BlockParser>

=item * L<Markdent::Dialect::Theory::SpanParser>

=back

You'll also need to dig into the core L<Markdent::Parser::BlockParser> and
L<Markdent::Parser::SpanParser> classes in order to see how these dialects
interact with the core parser.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module,
please consider making a "donation" to me via PayPal. I spend a lot of
free time creating free software, and would appreciate any support
you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order
for me to continue working on this particular software. I will
continue to do so, inasmuch as I have in the past, for as long as it
interests me.

Similarly, a donation made in this way will probably not make me work
on this software much more, unless I get so many donations that I can
consider working on free software full time, which seems unlikely at
best.

To donate, log into PayPal and send money to autarch@urth.org or use
the button on this page:
L<http://www.urth.org/~autarch/fs-donation.html>

=head1 BUGS

Please report any bugs or feature requests to C<bug-markdent@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Bugs may be submitted at L<https://github.com/houseabsolute/Markdent/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Markdent can be found at L<https://github.com/houseabsolute/Markdent>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<https://www.urth.org/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Andrew Speer Denis Ibaev Jason McIntosh Jonas Smedegaard Polina Shubina Shlomi Fish Stefan Hornburg (Racke) Tom Hukins

=over 4

=item *

Andrew Speer <andrew.speer@isolutions.com.au>

=item *

Denis Ibaev <dionys@gmail.com>

=item *

Jason McIntosh <jmac@appleseed-sc.com>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Polina Shubina <925043@mai.com>

=item *

Shlomi Fish <shlomif@shlomifish.org>

=item *

Stefan Hornburg (Racke) <racke@linuxia.de>

=item *

Tom Hukins <tom@eborcom.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
