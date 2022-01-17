##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Title.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/09
## Modified 2022/01/09
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Title;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use Want;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'title' if( !CORE::length( "$self->{tag}" ) );
    # We set this boolean to true to indicate we have not yet looked into the text inside the <title></title>
    $self->{_initial_text} = 1;
    return( $self );
}

# Note: property text
sub text : lvalue
{
    my $self = shift( @_ );
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    if( $has_arg )
    {
        my $nodes = $self->_get_from_list_of_elements_or_html( $arg );
#         $self->messagef( 4, "'$arg' translated into %d elements.", $nodes->length );
#         for( my $i = 0; $i < scalar( @$nodes ); $i++ )
#         {
#             $self->message( 4, "$i: ", ref( $nodes->[$i] ), " -> '", $nodes->[$i]->as_string, "'" );
#         }
        
        if( !defined( $nodes ) )
        {
            if( $has_arg eq 'assign' )
            {
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->pass_error ) if( want( 'LVALUE' ) );
            rreturn( $self->pass_error );
        }
        my $ok = 1;
        for( @$nodes )
        {
            if( !$self->_is_a( $_ => 'HTML::Object::DOM::Text' ) &&
                !$self->_is_a( $_ => 'HTML::Object::DOM::Space' ) )
            {
                $ok = 0, last;
            }
        }
        if( !$ok )
        {
            my $error = 'Values provided for title text contains data other tan text or space. You can provide text, space including HTML::Object::DOM::Text and HTML::Object::DOM::Space objects';
            $self->message( 4, "Error: $error" );
            $self->message( 4, "Called in ASSIGN context." ) if( want( 'ASSIGN' ) );
            $self->message( 4, "Called in LVALUE context." ) if( want( 'LVALUE' ) );
            if( $has_arg eq 'assign' )
            {
                $self->message( 4, "Called in assign context." );
                my $dummy = '';
                $self->error( $error );
                return( $dummy );
            }
            return( $self->error( $error ) ) if( want( 'LVALUE' ) );
            rreturn( $self->error( $error ) );
        }
        $_->parent( $self ) for( @$nodes );
        my $children = $self->children;
        $children->set( $nodes );
        $self->reset(1);
        my $dummy = 'dummy';
        return( $dummy ) if( $has_arg eq 'assign' );
    }
    if( !$self->{_title_text} || $self->_is_reset )
    {
        # We set this boolean to true to indicate we have not yet looked into the text inside the <title></title>
        # The HTML::Parser sets the title value to anything within <title></title> no matter if there are any tag embedded, so we need to parse it further, but only once, hence this boolean value
        if( $self->{_initial_text} )
        {
            my $children = $self->children;
            my $val;
            $val = $self->as_text;
            $self->message( 4, "Checking initial title text for HTML tags -> $val" );
            if( $self->looks_like_it_has_html( "$val" ) )
            {
                $self->message( 4, "Title looks like it contains HTML, parsing it." );
                my $p = $self->new_parser;
                my $doc = $p->parse_data( $val );
                my $kids = $doc->children;
                $self->messagef( 4, "%d children found from '$val'.", $kids->length );
                $_->parent( $self ) for( @$kids );
                $children->set( $kids );
            }
            else
            {
                $self->message( 4, "Title text does not look like it contains HTML." );
            }
            CORE::delete( $self->{_initial_text} );
        }
    
        my $result = $self->new_array;
        # We purposively skip anything that is neither a space nor a text.
        # This is what web browser do, notwithstanding any tag that may exist in the <title> tag
        $self->children->foreach(sub
        {
            if( $self->_is_a( $_ => 'HTML::Object::DOM::Text' ) ||
                $self->_is_a( $_ => 'HTML::Object::DOM::Space' ) )
            {
                my $v = $_->value;
                $result->push( "$v" );
            }
        });
        $self->{_title_text} = $result->join( '' )->scalar;
        $self->_remove_reset;
    }
    my $text = $self->{_title_text};
    return( $text ) if( want( 'LVALUE' ) );
    rreturn( $text );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Title - HTML Object DOM Title Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Title;
    my $title = HTML::Object::DOM::Element::Title->new || 
        die( HTML::Object::DOM::Element::Title->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface contains the title for a document. This element inherits all of the properties and methods of the L<HTML::Object::DOM::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Title |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 text

Is a string representing the text of the document's title, and only the text part. For example, consider this:

    <!doctype html>
    <html>
        <head>
            <title>Hello world! <span class="highlight">Isn't this wonderful</span> really?</title>
        </head>
        <body></body>
    </html>

    my $title = $doc->getElementsByTagName( 'title' )->[0];
    say $title->text;
    # Hello world!  really?

As you can see, the tag C<span> and its content was skipped.

Also, do not confuse:

    $doc->title;

with:

    $doc->getElementsByTagName( 'title' )->[0];

The former is just a setter/getter method to set or get the inner text value of the document title, while the latter is the L<HTML::Object::DOM::Element::Title> object. So you cannot write:

    $doc->title->text = "Hello world!";

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTitleElement/text>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTitleElement>, L<Mozilla documentation on title element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/title>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

