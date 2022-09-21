##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/DocumentFragment.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/20
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::DocumentFragment;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Node );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub append { return( shift->_element_method( 'append', @_ ) ); }

sub as_string
{
    my $self = shift( @_ );
    my $a = $self->new_array;
    # We get the string version of all of our children, except ourself, since a
    # document fragment is transparent; has no impact on the dom tree.
    $self->children->foreach(sub
    {
        $a->push( $_->as_string );
    });
    return( $a->join( '' )->scalar );
}

# Note: Property
sub childElementCount { return( shift->_elements->length ); }

# Note: Property
sub firstElementChild { return( shift->_elements->first ); }

sub getElementById { return( shift->_element_method( 'getElementById', @_ ) ); }

# Note: Property
sub lastElementChild { return( shift->_elements->last ); }

sub parent { return; }

sub parentNode { return; }

sub parentElement { return; }

sub prepend { return( shift->_element_method( 'prepend', @_ ) ); }

sub querySelector { return( shift->_element_method( 'querySelector', @_ ) ); }

sub querySelectorAll { return( shift->_element_method( 'querySelectorAll', @_ ) ); }

sub replaceChildren { return( shift->_element_method( 'replaceChildren', @_ ) ); }

sub _elements { return( shift->children->filter(sub{ $_->isElementNode }) ); }

sub _element_method
{
    my $self = shift( @_ );
    my $meth = shift( @_ );
    require HTML::Object::DOM::Element;
    my $code = HTML::Object::DOM::Element->can( $meth );
    return( $self->error( "Unknown method \"$meth\" in HTML::Object::DOM::Element" ) ) if( !$code );
    return( $self->$code( @_ ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::DocumentFragment - HTML Object DOM Document Fragment Class

=head1 SYNOPSIS

    use HTML::Object::DOM::DocumentFragment;
    my $frag = HTML::Object::DOM::DocumentFragment->new || 
        die( HTML::Object::DOM::DocumentFragment->error, "\n" );

    <ul id="list"></ul>

    use Module::Generic::Array;
    my $list = $doc->querySelector('#list')
    my $fruits = Module::Generic::Array->new( [qw( Apple Orange Banana Melon )] );

    my $fragment = HTML::Object::DOM::DocumentFragment->new;
    # or
    my $fragment = $doc->createDocumentFragment();

    $fruits->foreach(sub
    {
        my $fruit = shift( @_ );
        my $li = $doc->createElement('li');
        $li->innerHTML = $fruit;
        $fragment->appendChild( $li );
    })

    $list->appendChild( $fragment );

would yield:

=over 4

=item * Apple

=item * Orange

=item * Banana

=item * Melon

=back

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This implements the interface for document fragments, which is a minimal document object that has no parent.

It is used as a lightweight version of L<Document|HTML::Object::DOM::Document> that stores a segment of a document structure comprised of L<nodes|HTML::Object::DOM::Node> just like a L<standard document|HTML::Object::DOM::Document>. The key difference is due to the fact that the document fragment is not part of the active document tree structure. Changes made to the fragment do not affect the document (even on reflow) or incur any performance impact when changes are made.

It inherits from L<HTML::Object::DOM::Node>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +-------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::DocumentFragment |
    +-----------------------+     +---------------------------+     +-------------------------+     +-------------------------------------+

=head1 PROPERTIES

=head2 childElementCount

Read-only

Returns the amount of child elements the L<DocumentFragment|HTML::Object::DOM::DocumentFragment> has.

=head2 children

Read-only

Returns an L<array object|Module::Generic::Array> containing all objects of type L<Element|HTML::Object::DOM::Element> that are children of the L<DocumentFragment|HTML::Object::DOM::DocumentFragment> object.

=head2 firstElementChild

Read-only

Returns the L<Element|HTML::Object::DOM::Element> that is the first child of the L<DocumentFragment|HTML::Object::DOM::DocumentFragment> object, or C<undef> if there is none.

=head2 lastElementChild

Read-only

Returns the L<Element|HTML::Object::DOM::Element> that is the last child of the L<DocumentFragment|HTML::Object::DOM::DocumentFragment> object, or C<undef> if there is 

=head1 CONSTRUCTOR

=head2 new

Instantiates returns a new L<DocumentFragment|HTML::Object::DOM::DocumentFragment> object.

=head1 METHODS

This interface inherits the methods of its parent L<Node|HTML::Object::DOM::Node> and implements the following ones:

=head2 append

Inserts a set of Node objects or HTML string after the last child of the L<document fragment|HTML::Object::DOM::DocumentFragment>.

=head2 as_string

Returns a string representation of all the children contained.

=head2 getElementById

Returns the first L<Element node|HTML::Object::DOM::Element> within the L<DocumentFragment|HTML::Object::DOM::DocumentFragment>, in document order, that matches the specified ID. Functionally equivalent to L<getElementById()|HTML::Object::DOM::Element/getElementById>.

=head2 parent

Returns always C<undef>

=head2 parentElement

Returns always C<undef>

=head2 parentNode

Returns always C<undef>

=head2 prepend

Inserts a set of L<Node objects|HTML::Object::DOM::Node> or HTML string before the first child of the L<document fragment|HTML::Object::DOM::DocumentFragment>.

=head2 querySelector

Returns the first L<Element node|HTML::Object::DOM::Element> within the L<DocumentFragment|HTML::Object::DOM::DocumentFragment>, in document order, that matches the specified selectors.

=head2 querySelectorAll

Returns a L<array object|Module::Generic::Array> of all the L<Element|HTML::Object::DOM::Element> nodes within the L<DocumentFragment|HTML::Object::DOM::DocumentFragment> that match the specified selectors.

=head2 replaceChildren

Replaces the existing children of a L<DocumentFragment|HTML::Object::DOM::DocumentFragment> with a specified new set of children.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Node>

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
