## no critic (Moose::RequireMakeImmutable)
package Markdent;

use strict;
use warnings;

# The first version that completely worked with newer versions of Specio.
use Moose 2.1802 ();

our $VERSION = '0.29';

1;

# ABSTRACT: An event-based Markdown parser toolkit

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent - An event-based Markdown parser toolkit

=head1 VERSION

version 0.29

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

=head1 ALPHA WARNING

This code is still quite new. While the Markdown to HTML conversion seems to
work fine, the internals are subject to change.

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

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Markdent> or via email to L<bug-markdent@rt.cpan.org|mailto:bug-markdent@rt.cpan.org>.

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
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Andrew Speer Jason McIntosh Polina Shubina Tom Hukins

=over 4

=item *

Andrew Speer <andrew.speer@isolutions.com.au>

=item *

Jason McIntosh <jmac@appleseed-sc.com>

=item *

Polina Shubina <925043@mai.com>

=item *

Tom Hukins <tom@eborcom.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
