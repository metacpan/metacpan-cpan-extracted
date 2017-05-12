package HTML::AsText::Fix;
# ABSTRACT: extends HTML::Element::as_text() to render text properly

use strict;
use warnings;

use HTML::Tree;
use Monkey::Patch qw(:all);

our $VERSION = '0.003'; # VERSION


my $block_tags = {
    map { $_ => 1 } qw(
        p
        h1 h2 h3 h4 h5 h6
        dl dt dd
        ol ul li
        dir
        address
        blockquote
        center
        del
        div
        hr
        ins
        noscript script
        pre
    )
};

my $nillio = [];


sub as_text {

    # Yet another iteratively implemented traverser
    my ( $this, %options ) = @_;
    my $skip_dels = $options{'skip_dels'} || 0;
    my $lf = defined( $options{'lf_char'} )
        ? $options{'lf_char'}
        : $/;
    my $zwsp = defined( $options{'zwsp_char'} )
        ? $options{'zwsp_char'}
        : "\x{200b}";                    # zero-width space (ZWSP)

    my (@pile) = ($this);
    my $tag;
    my $text = '';
    while (@pile) {
        if ( !defined( $pile[0] ) ) {    # undef!
                                         # no-op
        }
        elsif ( !ref( $pile[0] ) ) {     # text bit!  save it!
            $text .= shift @pile;
        }
        else {                           # it's a ref -- traverse under it
            $this = shift @pile;
            $tag = $this->{'_tag'};
            my @rest = @{ $this->{'_content'} || $nillio };

            if ( exists $block_tags->{$tag} ) {
                push @rest, $lf;
            }
            elsif ( $tag eq 'br' ) {
                push @rest, $lf;
            }
            else {
                push @rest, $zwsp;
            }

            unshift @pile, @rest
                unless $tag eq 'style'
                    or $tag eq 'script'
                    or ( $skip_dels and $tag eq 'del' );
        }
    }

    if ( $options{'trim'} ) {
        my $extra_chars = $options{'extra_chars'} || '';
        $text =~ s/[\n\r\f\t\x{a0}${extra_chars}\x{20}]+$//sx;
        $text =~ s/^[\n\r\f\t\x{a0}${extra_chars}\x{20}]+//sx;
        $text =~ s/[\x{a0}${extra_chars}\x{20}]/ /gx;
    }

    return $text;
}


sub global {
    my ( %options ) = @_;
    return patch_package 'HTML::Element', as_text => sub {
        shift; # $original
        as_text( @_, %options );
    };
}


sub object {
    my ( $obj, %options ) = @_;
    return patch_object $obj, as_text => sub {
        shift; # $original
        my $self = shift;
        as_text( $self, @_, %options );
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::AsText::Fix - extends HTML::Element::as_text() to render text properly

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    # fix individual objects
    my $tree = HTML::TreeBuilder::XPath->new_from_content($html);
    my $guard = HTML::AsText::Fix::object($tree);

    # fix deeply nested objects
    use URI;
    use Web::Scraper;

    # First, create your scraper block
    my $tweets = scraper {
        process "li.status", "tweets[]" => scraper {
            process ".entry-content", body => 'TEXT';
            process ".entry-date", when => 'TEXT';
            process 'a[rel="bookmark"]', link => '@href';
        };
    };

    my $res;
    {
        my $guard = HTML::AsText::Fix::global();
        $res = $tweets->scrape( URI->new("http://twitter.com/creaktive") );
    }

=head1 DESCRIPTION

Consider the following HTML sample:

    <p>
        <span>AAA</span>
        BBB
    </p>
    <h2>CCC</h2>
    DDD
    <br>
    EEE

C<HTML::Element::as_text()> method stringifies it as I<AAABBBCCCDDDEEE>.
Despite being correct, this is far from the actual renderization within a "real" browser.
L<links(1)>, L<lynx(1)> & L<w3m(1)> break lines this way:

    AAABBB
    CCC
    DDD
    EEE

This module tries to implement the same behavior in the method L<HTML::Element/as_text>.
By default, C<$/> value is inserted in place of line breaks, and C<"\x{200b}"> (Unicode zero-width space) separates text from adjacent inline elements.

=head2 Distinction between block/inline nodes

"span", for instance, is an inline node:

    <p><span>A</span>pple</p>

In that case, there really shouldn't be a space between "A" and "pple".
To handle inline nodes properly, only block nodes are separated by line break.
Following nodes are currently assumed being blocks:

=over 4

=item *

p

=item *

h1 h2 h3 h4 h5 h6

=item *

dl dt dd

=item *

ol ul li

=item *

dir

=item *

address

=item *

blockquote

=item *

center

=item *

del

=item *

div

=item *

hr

=item *

ins

=item *

noscript script

=item *

pre

=item *

br (just to make sense)

=back

(source: L<http://en.wikipedia.org/wiki/HTML_element#Block_elements>)

=head1 FUNCTIONS

=head2 as_text

The replacement function.
Not to be used separately.
It is injected inside L<HTML::Element>.

=head2 global

Hook into every L<HTML::Element> within the lexical scope.
Returns the guard object, destroying it will unhook safely.

Accepts following options:

=over 4

=item *

B<lf_char>: character inserted between block nodes (by default, C<$/>);

=item *

B<zwsp_char>: character inserted between inline nodes (by default, C<"\x{200b}">, Unicode zero-width space);

=item *

B<trim>: trim heading/trailing spaces (considers C<"\x{A0}"> as space!);

=item *

B<extra_chars>: extra characters to trim;

=item *

B<skip_dels>: if true, then text content under "del" nodes is not included in what's returned.

=back

For example, to completely get rid of separation between inline nodes:

    my $guard = HTML::AsText::Fix::global(zwsp_char => '');

=head2 object

Hook object instance.
Accepts the same options as L</global>:

    my $guard = HTML::AsText::Fix::object($tree, zwsp_char => '');

=for test_synopsis my ($html);

=head1 SEE ALSO

=over 4

=item *

L<HTML::Element>

=item *

L<HTML::Tree>

=item *

L<HTML::FormatText>

=item *

L<Monkey::Patch>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

L<Αριστοτέλης Παγκαλτζής|https://metacpan.org/author/ARISTOTLE>

=item *

L<Toby Inkster|https://metacpan.org/author/TOBYINK>

=back

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
