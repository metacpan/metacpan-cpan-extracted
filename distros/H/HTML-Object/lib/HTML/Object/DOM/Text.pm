##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Text.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/13
## Modified 2021/12/13
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Text;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Text HTML::Object::DOM::CharacterData );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->HTML::Object::Text::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub assignedSlot { return( shift->_set_get_object_without_init( 'assignedslot', 'HTML::Object::DOM::Element::Slot', @_ ) ); }

sub getAttributes { return( wantarray() ? () : [] ); }

sub getChildNodes { return( wantarray() ? () : [] ); }

sub getElementById { return; }

sub getFirstChild { return; }

sub getLastChild { return; }

sub getParentNode { return( shift->parent ); }

# Inherited
# sub getNextSibling;

# Inherited
# sub getPreviousSibling;

sub getRootNode { return( shift->parent->getRootNode ); }

sub getValue { return( shift->value ); }

sub is_inside
{
    my( $text, $node ) = @_;
    return( $text->parent->is_inside( $node ) );
}

sub isEqualNode
{
    my $self = shift( @_ );
    my $e = shift( @_ ) || return( $self->error( "No html element was provided to insert." ) );
    return( $self->error( "Element provided (", overload::StrVal( $e ), ") is not an HTML::Object::Element." ) ) if( !$self->_is_a( $e => 'HTML::Object::Element' ) );
    return(0) if( !$self->_is_a( $e => 'HTML::Object::Text' ) );
    return( $self->value eq $e->value );
}

sub isAttributeNode { return(0); }

sub isCommentNode   { return(0); }

sub isElementNode   { return(0); }

sub isNamespaceNode { return(0); }

sub isPINode        { return(0); }

sub isProcessingInstructionNode { return(0); }

sub isTextNode { return(1); }

# Note: Property
sub nodeValue : lvalue { return( shift->_set_get_lvalue( 'value', @_ ) ); }

sub parent { return( shift->_set_get_object_without_init( 'parent', 'HTML::Object::DOM::Node', @_ ) ); }

sub replaceWholeText
{
    my $self = shift( @_ );
    my $content = shift( @_ );
    return( $self->error({
        message => "Content provided is a reference that cannot be stringified.",
        class => 'HTML::Object::TypeError',
    }) ) if( ref( $content ) && !overload::Method( $content, '""' ) );
    my $prev = $self->left;
    my $next = $self->right;
    my $parent = $self->parent;
    if( !$parent )
    {
        $self->value( "$content" );
        return( $self );
    }
    my $siblings = $parent->children;
    $self->message( 4, "Parent has the following children: '", $siblings->join( "', '" ), "'" );
    my $pos = $siblings->pos( $self );
    return( $self->error({
        message => "I could not find this text node among its parent's children.",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $pos ) );
    my $start = $pos;
    $prev->reverse->foreach(sub
    {
        if( !$self->_is_a( $_ => 'HTML::Object::DOM::Text' ) &&
            !$self->_is_a( $_ => 'HTML::Object::DOM::Space' ) )
        {
            return;
        }
        $start--;
    });
    my $last = $pos;
    $next->foreach(sub
    {
        if( !$self->_is_a( $_ => 'HTML::Object::DOM::Text' ) &&
            !$self->_is_a( $_ => 'HTML::Object::DOM::Space' ) )
        {
            return;
        }
        $last++;
    });
    $self->message( 4, "Our position is '$pos', start is '$start' and last is '$last'" );
    $self->message( 4, "Removing previous siblings from $start to $last for ", ( ( $last - $start ) + 1 ), " elements." );
    my $removed = $siblings->splice( $start, ( ( $last - $start ) + 1 ), $self );
    $_->parent( undef ) for( @$removed );
    $self->parent( $parent );
    $self->message( 4, "Setting content to '$content' for text element $self" );
    $self->value( "$content" );
    $self->reset(1);
    $self->message( 4, "Parent '$parent' with tag '", $parent->tag, "' has now ", $parent->children->length, " children: '", $siblings->join( "', '" ), "' -> '", $parent->as_string, "' and our text element has value '", $self->value, "'" );
    return( $self );
}

sub splitText
{
    my $self = shift( @_ );
    my $offset = shift( @_ );
    return( $self->error({
        message => "Offset value provided ($offset) is not an integer.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_integer( $offset ) );
    my $value = $self->value;
    my $size = $value->length;
    # $self->message( 4, "Offset is '$offset', text value is '$value' and size is '$size'" );
    return( $self->error({
        message => "Offset value provided ($offset) is higher than the size of the string (" . $value->length . ")",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $offset > $size );
    if( $offset < 0 )
    {
        $offset = ( $offset + $size );
        # For example, in the unlikely scenario where the negative offset is nth time the size of the text
        while( $offset < 0 && abs( $offset ) > $size )
        {
            $offset = ( $offset + $size );
        }
    }
    my $part1 = $value->substr( 0, $offset );
    my $part2 = $value->substr( $offset );
    my $new = $self->new( value => $part2 );
    # $self->message( 4, "Part 1 is '$part1' and part 2 is '$part2' and new is '$new'" );
    my $parent = $self->parent;
    # $self->message( 4, "Parent is '$parent' with tag '", $parent->tag, "'" );
    if( $parent )
    {
        $new->parent( $parent );
        my $siblings = $parent->children;
        my $pos = $siblings->pos( $self );
        # $self->message( 4, "Found our text element at position '$pos' among our parent's children (", $siblings->length, ")." );
        return( $self->error({
            message => "Unable to find our text element among our parent's children.",
            class => 'HTML::Object::HierarchyRequestError',
        }) ) if( !defined( $pos ) );
        $siblings->splice( $pos + 1, 0, $new );
        $self->reset(1);
        # $self->message( 4, "Parent now is: '", $self->as_string, "' with ", $siblings->length, " elements: '", $siblings->join( "', '" ), "'" );
        # $self->message( 4, "New text object is '$new' -> '", $new->value, "'" );
    }
    $self->value( $part1 );
    return( $new );
}

sub string_value { return( shift->value ); }

sub toString { return( shift->value ); }

sub wholeText { return( shift->_get_adjacent_nodes->map(sub{ $_->value })->join( '' )->scalar ); }

sub _get_adjacent_nodes
{
    my $self = shift( @_ );
    my $prev = $self->left;
    my $next = $self->right;
    $self->messagef( 4, "%d previous siblings and %d next siblings.", $prev->length, $next->length );
    my $res = $self->new_array( $self );
    $prev->reverse->foreach(sub
    {
        if( !$self->_is_a( $_ => 'HTML::Object::DOM::Text' ) &&
            !$self->_is_a( $_ => 'HTML::Object::DOM::Space' ) )
        {
            return;
        }
        $res->unshift( $_ );
    });
    $next->foreach(sub
    {
        if( !$self->_is_a( $_ => 'HTML::Object::DOM::Text' ) &&
            !$self->_is_a( $_ => 'HTML::Object::DOM::Space' ) )
        {
            return;
        }
        $res->push( $_ );
    });
    return( $res );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Text - HTML Object DOM Text Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Text;
    my $text = HTML::Object::DOM::Text->new( value => $some_text ) || 
        die( HTML::Object::DOM::Text->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

It inherits from L<HTML::Object::Text> and L<HTML::Object::DOM::CharacterData>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------------+     +-------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::CharacterData | --> | HTML::Object::DOM::Text |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------------+     +-------------------------+
      |                                                                                                                                        ^
      |                                                                                                                                        |
      v                                                                                                                                        |
    +-----------------------+                                                                                                                  |
    |  HTML::Object::Text   | -----------------------------------------------------------------------------------------------------------------+
    +-----------------------+

=head1 PROPERTIES

=head2 assignedSlot

Normally this is a read-only property, but under perl, you can set or get a L<HTML::Object::DOM::Element::Slot> object associated with the element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Text/assignedSlot>

=head2 nodeValue

Sets or gets the text value for this element.

=head2 wholeText

The read-only C<wholeText> property of the L<HTML::Object::DOM::Text> interface returns the full text of all L<Text|HTML::Object::DOM::Text> nodes logically adjacent to the node. The text is concatenated in document order. This allows specifying any text node and obtaining all adjacent text as a single string.

It returns a string with the concanated text.

Example:

    <p id="favy">I like <span class="maybe-not">Shochu</span>, Dorayaki and Natto-gohan.</p>

    $doc->getElementsByTagName('span')->[0]->remove;
    # Now paragraph contains 2 text nodes:
    # 'I like '
    # ', Dorayaki and Natto-gohan.'
    say $doc->getElementById('favy')->getFirstChild->wholeText;
    # I like , Dorayaki and Natto-gohan.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Text/wholeText>

=head1 METHODS

=head2 getAttributes

Returns an empty list in list context, or an empty array reference in scalar context.

=head2 getChildNodes

Returns an empty list in list context, or an empty array reference in scalar context.

=head2 getElementById

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getFirstChild

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getLastChild

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getParentNode

Returns the parent node, if any.

=head2 getRootNode

Returns the L<root node|HTML::Object::DOM::Document>

=head2 getValue

Returns the text value of this comment, i.e. the text between C<<!--> and C<-->>

=head2 is_inside

Provided with a node, this will return true if it is inside this text's parent or false otherwise.

=head2 isAttributeNode

Returns false.

=head2 isCommentNode

Returns true.

=head2 isElementNode

Returns false.

=head2 isEqualNode

Provided with another element object, and this returns true if both text element are the same, or false otherwise.

=head2 isNamespaceNode

Returns false.

=head2 isPINode

Returns false.

=head2 isProcessingInstructionNode

Returns false.

=head2 isTextNode

Returns false.

=head2 parent

Set or get this text's parent L<node|HTML::Object::DOM::Node>

=head2 replaceWholeText

This method of the L<Text|HTML::Object::DOM::Text> interface replaces the text of the node and all of its logically adjacent text nodes with the specified C<text>. The replaced nodes are removed, except the current node.

It returns the current node with the newly C<text> set.

Example:

    <p id="favy">I like apple,<span class="and"> and</span> orange,<span class="and"> and</span> kaki</p>
    $doc->getElementsByTagName('span')->foreach(sub
    {
        $_->remove;
    });
    # Now text is: I like apple, orange, kaki
    # which are 3 text nodes
    # Take the 2nd one (for example) and set a new text for it and its adjacent siblings
    $doc->getElementById('favy')->getChildNodes->[1]->replaceWholeText( 'I like fruits' );
    # Now the whole chunk has become:
    # <p id="favy">I like fruits</p>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Text/replaceWholeText>

=head2 splitText

Provided with an C<offset> position and this method breaks the L<Text|HTML::Object::DOM::Text> node into two nodes at the specified C<offset>, keeping both nodes in the tree as siblings.

After the split, the current node contains all the content up to the specified offset point, and a newly created node of the same type contains the remaining text. The newly created node is returned to the caller. If the original node had a parent, the new node is inserted as the next sibling of the original node. If the offset is equal to the length of the original node, the newly created node has no data. 

It returns the newly created L<Text|HTML::Object::DOM::Text> node that contains the text after the specified offset point.

It returns an C<HTML::Object::IndexSizeError> if the specified C<offset> is greater than the size of the node's text.

Example:

    <p>foobar</p>

    my $p = $doc->getElementsByTagName('p')->first;
    # Get contents of <p> as a text node
    my $foobar = $p->firstChild;

    # Split 'foobar' into two text nodes, 'foo' and 'bar',
    # and save 'bar' as a const
    my $bar = $foobar->splitText(3);

    # Create a <u> element containing ' new content '
    my $u = $doc->createElement('u');
    $u->appendChild( $doc->createTextNode( ' new content ' ) );
    # Add <u> before 'bar'
    $p->insertBefore( $u, $bar );
    # The result is: <p>foo<u> new content </u>bar</p>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Text/splitText>

=head2 string_value

Returns the content of the comment as a string.

=head2 toString

Returns the content of the comment as a string.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Text>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
