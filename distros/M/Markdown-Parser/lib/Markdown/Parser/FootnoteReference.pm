## -*- perl -*-
##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/FootnoteReference.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/08/23
## Modified 2021/08/23
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Markdown::Parser::FootnoteReference;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use Nice::Try;
    use Devel::Confess;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{footnote}   = '';
    $self->{id}         = '';
    $self->{sequence}   = '';
    $self->{tag_name}   = 'footnote_ref';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    return( sprintf( '*[%s]: %s', $self->name, $self->value ) );
}

# <li id="fn:1" role="doc-endnote">
#   <p>This is the first footnote.&nbsp;<a href="#fnref:1" class="reversefootnote" role="doc-backlink">↩</a></p>
# </li>
sub as_string
{
    my $self = shift( @_ );
    $self->encode_html( [qw( < > & " ' )], \$val );
    ## e.g. <abbr title="Hyper Text Markup Language">HTML</abbr>
    return( sprintf( '<sup id="fnref:%s"><a href="#fn:%s">%s</a></sup>', $self->id, $self->footnote->id, $self->sequence->scalar ) );
}

## The footnote object
sub footnote { return( shift->_set_get_object( 'footnote', 'Markdown::Parser::Footnote', @_ ) ); }

## The footnote reference own id for backlink, ie link from the footnote back to the point of reference
sub id { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub sequence { return( shift->_set_get_scalar_as_object( 'sequence', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Footnote - Markdown Footnote Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Footnote->new;
    # or
    $doc->add_element( $o->create_footnote( @_ ) );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a footnote. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

This is an extension of the L<original Markdown|https://daringfireball.net/projects/markdown/syntax>.

To quote from L<Markdown Guide|https://www.markdownguide.org/extended-syntax#footnotes>:

Footnotes allow you to add notes and references without cluttering the body of the document. When you create a footnote, a superscript number with a link appears where you added the footnote reference. Readers can click the link to jump to the content of the footnote at the bottom of the page.

To create a footnote reference, add a caret and an identifier inside brackets ([^1]). Identifiers can be numbers or words, but they can’t contain spaces or tabs. Identifiers only correlate the footnote reference with the footnote itself — in the output, footnotes are numbered sequentially.

Add the footnote using another caret and number inside brackets with a colon and text ([^1]: My footnote.). You don’t have to put footnotes at the end of the document. You can put them anywhere except inside other elements like lists, block quotes, and tables.

    Here's a simple footnote,[^1] and here's a longer one.[^bignote]

    [^1]: This is the first footnote.

    [^bignote]: Here's one with multiple paragraphs and code.

        Indent paragraphs to include them in the footnote.

        `{ my code }`

        Add as many paragraphs as you like.

The rendered output looks like this:

    Here’s a simple footnote,1 and here’s a longer one.2

        1. This is the first footnote. ↩

        2. Here’s one with multiple paragraphs and code.

           Indent paragraphs to include them in the footnote.

           { my code }

           Add as many paragraphs as you like. ↩

Inline Footnotes

For consistency with links, footnotes can be added inline, like this:

    I met Jack [^jack](Co-founder of Angels, Inc) at the meet-up.

Inline notes will work even without the identifier. For example:

    I met Jack [^](Co-founder of Angels, Inc) at the meet-up.

However, in compliance with pandoc footnotes style, inline footnotes can also be added like this:

    Here is an inline note.^[Inlines notes are easier to write, since
    you don't have to pick an identifier and move down to type the
    note.]

The footnote id of inline notes will be auto-generated

Footnotes will appear at the end of the document in their order of appearance.

=head1 METHODS

=head2 as_markdown

Returns a string representation of the footnote formatted in markdown.

It returns a plain string.

=head2 as_string

Returns an html representation of the footnote.

It returns a plain string.

=head2 footnote

Set or gets the L<Markdown::Parser::Footnote> object, i.e. the footnote that is reference by this object.

=head2 id

Sets or gets the id of the backlink, i.e. the link reference back to the location that reference this footnote.

This is used to create a link back to the original footnote reference.

Sets or gets the id of the footnote. The value is stored as an L<Module::Generic::Scalar> object.

    Here's a simple footnote,[^1] and here's a longer one.[^bignote]

This will produce:

    Here's a simple footnote,1 and here's a longer one.2

C<1> and C<2> will be displayed in superscript.

L<Markdown::Parser/footnote_ref_sequence> keeps track of the sequence and allocates it to each new footnote reference found.

=head2 sequence

This incremental number set for each occurence of a footnote reference. For example:

=head1 SEE ALSO

L<https://www.markdownguide.org/extended-syntax#footnotes>, L<https://pandoc.org/MANUAL.html#footnotes>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
