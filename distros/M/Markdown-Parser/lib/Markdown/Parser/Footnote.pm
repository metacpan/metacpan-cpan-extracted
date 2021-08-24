## -*- perl -*-
##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Footnote.pm
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
package Markdown::Parser::Footnote;
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
    $self->{id}             = '';
    $self->{reference}      = [];
    $self->{tag_name}       = 'footnote';
    ## Used to contain the unparsed footnote text
    ## Footnotes are parsed once all footnotes are registered.
    ## This is done at the beginning of the Markdown::Parser::parse method
    $self->{unparsed}       = '';
    return( $self->SUPER::init( @_ ) );
}

## Add an Markdown::Parser::FootnoteReference object to our stack of footnote references and set its id for backlinks if necessary
sub add_reference
{
    my $self = shift( @_ );
    my $obj  = shift( @_ ) || return;
    return( $self->error( "Object '$obj' provided is not a 'Markdown::Parser::FootnoteReference' object." ) ) if( !$self->_is_a( $obj, 'Markdown::Parser::FootnoteReference' ) );
    ## Set the id unless it is already provided.
    ## Typically the order of entry of this reference followed by our own id
    ## This makes it visually easy to identify, debug and track when hovering the links generated
    if( !$obj->id->length )
    {
        $obj->id( sprintf( '%d:%s', $self->references->length + 1, $self->id ) );
    }
    $self->references->push( $obj );
    return( $self );
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
    my $arr = $self->new_array;
    my $id  = $self->id;
    use utf8;
    $self->message( 3, "Returning footnote for id '$id'." );
    $arr->push( sprintf( '<li id="fn:%s" role="doc-endnote">', $id ) );
    $arr->push( $self->children->map(sub{ $_->as_string })->join( '' )->scalar );
    ## There could be multiple backlinks for one footnote, given it is possible that there are multiple reference to one footnote.
    ## The id of the reference is set at creation, and in the add_reference method
    my $backref = $self->references->map(sub
    {
        sprintf( '&nbsp:<a href="#fnref:%s" class="reversefootnote" title="Jump back to footnote %s in the text" role="doc-backlink">↩</a>', $_->id, $_->id );
    })->join( ' ' )->scalar;
    $arr->push( '</li>' );
    my $str = $arr->join( '' )->scalar;
    $str =~ s/\s\!{2}FN\!{2}/ $backref/;
    $self->message( 3, "Returning foonote string: '$str'." );
    return( $str );
}

sub id { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub parse
{
    my $self = shift( @_ );
    my $parser = shift( @_ );
    return unless( $self->unparsed->length > 0 );
    my $data = $self->unparsed->scalar;
    $data =~ s/^(?:\s{4}|\t)//gm;
    $parser->parse( $data, { element => $self });
    $self->unparsed->undef;
    return( $self );
}

sub references { return( shift->_set_get_object_array_object( 'reference', 'Markdown::Parser::FootnoteReference', @_ ) ); }

sub text
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $text = shift( @_ );
        return( $self->add_element( $self->create_text({ text => $text }) ) );
    }
    else
    {
        return( $self->children->map(sub{ $_->as_string })->join( '' ) );
    }
}

sub unparsed { return( shift->_set_get_scalar_as_object( 'unparsed', @_ ) ); }

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

=head3 Inline Footnotes

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

=head2 add_reference

Provided with an L<Mardown::Parser::FootnoteReference> object and this will add the object to the array of footnote reference objects.

See L</references>

=head2 as_markdown

Returns a string representation of the footnote formatted in markdown.

It returns a plain string.

=head2 as_string

Returns an html representation of the footnote.

It returns a plain string.

=head2 references

Access the array object of L<Markdown::Parser::FootnoteReference> objects used for backlinks, i.e. the origin for this footnote.
It is used to create a link reference back to the location that reference this footnote, by using the object id.

This is used to create a link back to the original footnote reference.

Note that there may be multiple footnote reference for one footnote.

=head2 id

Sets or gets the id of the footnote. The value is stored as an L<Module::Generic::Scalar> object.

This id is set arbitrarily by the user and must be unique and is used to form a link reference to this footnote.

=head2 parse

Parse the footnote data and returns the current object.

=head2 text

Sets or gets the content of this footnote.

If a text value is provided, it will be stored as a child element of the footnote as a L<Markdown::Parser::Text> object.

You can also add directly element like this:

    $footnote->add_element( $top->create_paragraph )

=head2 unparsed

Sets or gets the unparsed version of the footnotes.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

=head1 SEE ALSO

L<https://www.markdownguide.org/extended-syntax#footnotes>, L<https://pandoc.org/MANUAL.html#footnotes>, L<https://stackoverflow.com/questions/15110479/markdown-and-footnotes-most-natural-format-missing>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
