##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Title.pm
## Version v0.2.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/09
## Modified 2022/09/20
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
    use vars qw( $VERSION );
    use Want;
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

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
sub text : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        if( !$self->{_title_text} || $self->_is_reset )
        {
            # We set this boolean to true to indicate we have not yet looked into the text inside the <title></title>
            # The HTML::Parser sets the title value to anything within <title></title> no matter if there are any tag embedded, so we need to parse it further, but only once, hence this boolean value
            if( $self->{_initial_text} )
            {
                my $children = $self->children;
                my $val;
                $val = $self->as_text;
                if( $self->looks_like_it_has_html( "$val" ) )
                {
                    my $p = $self->new_parser;
                    my $doc = $p->parse_data( $val );
                    my $kids = $doc->children;
                    $_->parent( $self ) for( @$kids );
                    $children->set( $kids );
                }
                else
                {
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
        return( $text );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $arg = shift( @_ );
        my $nodes = $self->_get_from_list_of_elements_or_html( $arg );
#         for( my $i = 0; $i < scalar( @$nodes ); $i++ )
#         {
#         }
        
        if( !defined( $nodes ) )
        {
            return( $self->pass_error );
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
            return( $self->error( 'Values provided for title text contains data other tan text or space. You can provide text, space including HTML::Object::DOM::Text and HTML::Object::DOM::Space objects' ) );
        }
        $_->parent( $self ) for( @$nodes );
        my $children = $self->children;
        $children->set( $nodes );
        $self->reset(1);
        return(1);
    }
}, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Title - HTML Object DOM Title Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Title;
    my $title = HTML::Object::DOM::Element::Title->new || 
        die( HTML::Object::DOM::Element::Title->error, "\n" );

=head1 VERSION

    v0.2.1

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
