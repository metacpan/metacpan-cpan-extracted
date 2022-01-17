##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/TreeWalker.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/02
## Modified 2022/01/02
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::TreeWalker;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::NodeIteratorShared );
    # To import its constants
    use HTML::Object::DOM::Node;
    use HTML::Object::DOM::NodeFilter qw( :all );
    our $VERSION = 'v0.1.0';
};

# Note: method init is inherited

# Note: property currentNode
sub currentNode
{
    my $self = shift( @_ );
    my $elems = $self->_elements;
    return( $elems->index( $self->{_pos} ) );
}

# Note: property expandEntityReferences read-only is inherited

# Note: property filter read-only is inherited

sub firstChild
{
    my $self = shift( @_ );
    my $elems = $self->_elements;
    my $this = $elems->index( $self->{_pos} );
    return( $self->error( "Unable to find the current node at position '$self->{_pos}' in our tree array!" ) ) if( !defined( $this ) );
    # Only elements can have children
    return if( $this->nodeType != ELEMENT_NODE );
    my $node;
    my $tmpPos = 0;
    my $children = $this->children;
    my $size = $children->size;
    # We seek the first appropriate first child depending on the value of $whatToShow
    while(1)
    {
        last if( $tmpPos > $size );
        my $tmpNode = $children->index( $tmpPos );
        my $rv = $self->_check_element( $tmpNode );
        last if( !defined( $rv ) );
        $tmpPos++, next if( !$rv );
        $node = $tmpNode;
        last;
    }
    return if( !defined( $node ) );
    my $pos = $elems->pos( $node );
    # Amazingly enough, the first child of this node cannot be found among the list of all nodes in this tree!
    return if( !defined( $pos ) );
    $self->{_pos} = $pos;
    return( $node );
}

sub lastChild
{
    my $self = shift( @_ );
    my $elems = $self->_elements;
    my $this = $elems->index( $self->{_pos} );
    return( $self->error( "Unable to find the current node at position '$self->{_pos}' in our tree array!" ) ) if( !defined( $this ) );
    # Only elements can have children
    return if( $this->nodeType != ELEMENT_NODE );
    my $node;
    my $children = $this->children;
    my $tmpPos = $children->size;
    # We seek the first appropriate first child depending on the value of $whatToShow
    while(1)
    {
        last if( $tmpPos < 0 );
        my $tmpNode = $children->index( $tmpPos );
        my $rv = $self->_check_element( $tmpNode );
        last if( !defined( $rv ) );
        $tmpPos--, next if( !$rv );
        $node = $tmpNode;
        last;
    }
    return if( !defined( $node ) );
    my $pos = $elems->pos( $node );
    # Amazingly enough, the last child of this node cannot be found among the list of all nodes in this tree!
    return if( !defined( $pos ) );
    $self->{_pos} = $pos;
    return( $node );
}

# Note: method nextNode is inherited

sub nextSibling
{
    my $self = shift( @_ );
    my $elems = $self->_elements;
    my $this = $elems->index( $self->{_pos} );
    return( $self->error( "Unable to find the current node at position '$self->{_pos}' in our tree array!" ) ) if( !defined( $this ) );
    # No need to bother if our current node is the root node. Its siblings are not part of the tree
    return if( $this eq $self->root );
    # Get all next siblings
    my $node;
    my $siblings = $this->right;
    my $size = $siblings->size;
    my $tmpPos = 0;
    # We seek the first appropriate sibling depending on the value of $whatToShow
    while(1)
    {
        last if( $tmpPos > $size );
        my $tmpNode = $siblings->index( $tmpPos );
        my $rv = $self->_check_element( $tmpNode );
        last if( !defined( $rv ) );
        $tmpPos++, next if( !$rv );
        $node = $tmpNode;
        last;
    }
    return if( !defined( $node ) );
    my $pos = $elems->pos( $node );
    # Amazingly enough, the next sibling of this node cannot be found among the list of all nodes in this tree!
    return if( !defined( $pos ) );
    $self->{_pos} = $pos;
    return( $node );
}

sub parentNode
{
    my $self = shift( @_ );
    my $elems = $self->_elements;
    my $this = $elems->index( $self->{_pos} );
    return( $self->error( "Unable to find the current node at position '$self->{_pos}' in our tree array!" ) ) if( !defined( $this ) );
    my $root = $self->root;
    # We should not be here in the first place.
    return if( $this eq $root );
    my $node = $this->parent;
    return if( !defined( $node ) );
    # We cannot go up to the root, but only within the root itself.
    # return if( $node eq $root );
    my $pos = $elems->pos( $node );
    # Amazingly enough, the last child of this node cannot be found among the list of all nodes in this tree!
    return if( !defined( $pos ) );
    $self->{_pos} = $pos;
    return( $node );
}

# Note: method previousNode is inherited

sub previousSibling
{
    my $self = shift( @_ );
    my $elems = $self->_elements;
    my $this = $elems->index( $self->{_pos} );
    return( $self->error( "Unable to find the current node at position '$self->{_pos}' in our tree array!" ) ) if( !defined( $this ) );
    # No need to bother if our current node is the root node. Its siblings are not part of the tree
    return if( $this eq $self->root );
    # Get all previous siblings
    my $node;
    my $siblings = $this->left;
    my $tmpPos = $siblings->size;
    # We seek the first appropriate sibling depending on the value of $whatToShow
    while(1)
    {
        last if( $tmpPos < 0 );
        my $tmpNode = $siblings->index( $tmpPos );
        my $rv = $self->_check_element( $tmpNode );
        last if( !defined( $rv ) );
        $tmpPos--, next if( !$rv );
        $node = $tmpNode;
        last;
    }
    return if( !defined( $node ) );
    my $pos = $elems->pos( $node );
    # Amazingly enough, the previous sibling of this node cannot be found among the list of all nodes in this tree!
    return if( !defined( $pos ) );
    $self->{_pos} = $pos;
    return( $node );
}

# Note: property root read-only is inherited

# Note: property whatToShow read-only is inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::TreeWalker - HTML Object DOM Tree Walker Class

=head1 SYNOPSIS

With just one argument, this default to search for everything (C<SHOW_ALL>) and to use the default filter, which always returns C<FILTER_ACCEPT>

    use HTML::Object::DOM::TreeWalker;
    my $walker = HTML::Object::DOM::TreeWalker->new( $doc->body ) || 
        die( HTML::Object::DOM::TreeWalker->error, "\n" );

Or, passing an anonymous subroutine as the filter

    my $nodes = HTML::Object::DOM::TreeWalker->new(
        $root_node,
        $what_to_show_bit,
        sub{ return( FILTER_ACCEPT ); }
    ) || die( HTML::Object::DOM::TreeWalker->error, "\n" );

Or, passing an hash reference with a property 'acceptNode' whose value is an anonymous subroutine, as the filter

    my $nodes = HTML::Object::DOM::TreeWalker->new(
        $root_node,
        $what_to_show_bit,
        {
            acceptNode => sub{ return( FILTER_ACCEPT ); }
        }
    ) || die( HTML::Object::DOM::TreeWalker->error, "\n" );

Or, passing an object that implements the method "acceptNode"

    my $nodes = HTML::Object::DOM::TreeWalker->new(
        $root_node,
        $what_to_show_bit,
        # This object must implement the acceptNode method
        My::Customer::NodeFilter->new
    ) || die( HTML::Object::DOM::TreeWalker->error, "\n" );

There is also L<HTML::Object::DOM::TreeWalker>, which performs a somewhat similar function.

Choose L<HTML::Object::DOM::NodeIterator> when you only need a simple iterator to filter and browse the selected nodes, and choose L<HTML::Object::DOM::TreeWalker> when you need to access to the node and its siblings.

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<TreeWalker> object represents the nodes of a document subtree and a position within them.

=head1 PROPERTIES

=head2 currentNode

Is the L<Node|HTML::Object::DOM::Node> on which the C<TreeWalker> is currently pointing at.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); }
    );
    my $root = $treeWalker->currentNode; # the root element as it is the first element!

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/currentNode>

=head2 expandEntityReferences

Normally this is read-only, but under perl you can set whatever boolean value you want.

Under JavaScript, this is a boolean value indicating if, when discarding an C<EntityReference> its whole sub-tree must be discarded at the same time.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
    );
    my $expand = $treeWalker->expandEntityReferences;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/expandEntityReferences>

=head2 filter

Normally this is read-only, but under perl you can set it to a new L<HTML::Object::DOM::NodeFilter> object you want, even after object instantiation.

Returns a L<HTML::Object::DOM::NodeFilter> used to select the relevant nodes.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
    );
    my $nodeFilter = $treeWalker->filter;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/filter>

=head2 root

Normally this is read-only, but under perl you can set whatever L<node value|HTML::Object::DOM::Node> you want.

Returns a L<Node|HTML::Object::DOM::Node> representing the root node as specified when the C<TreeWalker> was created. 

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
    );
    my $root = $treeWalker->root; # $doc->body in this case

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/root>

=head2 whatToShow

Normally this is read-only, but under perl you can set whatever number value you want.

Returns an unsigned long being a bitmask made of L<constants|/CONSTANTS> describing the types of L<Node|HTML::Object::DOM::Node> that must to be presented. Non-matching nodes are skipped, but their children may be included, if relevant.

Possible constant values (exported by L<HTML::Object::DOM::NodeFilter>) are:

=over 4

=item SHOW_ALL (4294967295)

Shows all nodes.

=item SHOW_ELEMENT (1)

Shows Element nodes.

=item SHOW_ATTRIBUTE (2)

Shows attribute L<Attribute nodes|HTML::Object::DOM::Attribute>. This is meaningful only when creating a C<TreeWalker> with an L<Attribute node|HTML::Object::DOM::Attribute> as its root; in this case, it means that the L<attribute node|HTML::Object::DOM::Attribute> will appear in the first position of the iteration or traversal. Since attributes are never children of other L<nodes|HTML::Object::DOM::Node>, they do not appear when traversing over the document tree.

=item SHOW_TEXT (4)

Shows Text nodes.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        ( SHOW_ELEMENT | SHOW_COMMENT | SHOW_TEXT ),
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
    );
    if( ( $treeWalker->whatToShow & SHOW_ALL ) ||
        ( $treeWalker->whatToShow & SHOW_COMMENT ) )
    {
        # $treeWalker will show comments
    }

=item SHOW_CDATA_SECTION (8)

Will always returns nothing, because there is no support for xml documents.

=item SHOW_ENTITY_REFERENCE (16)

Legacy, no more used.

=item SHOW_ENTITY (32)

Legacy, no more used.

=item SHOW_PROCESSING_INSTRUCTION (64)

Shows ProcessingInstruction nodes.

=item SHOW_COMMENT (128)

Shows Comment nodes.

=item SHOW_DOCUMENT (256)

Shows Document nodes

=item SHOW_DOCUMENT_TYPE (512)

Shows C<DocumentType> nodes

=item SHOW_DOCUMENT_FRAGMENT (1024)

Shows L<HTML::Object::DOM::DocumentFragment> nodes.

=item SHOW_NOTATION (2048)

Legacy, no more used.

=item SHOW_SPACE (4096)

Show Space nodes. This is a non-standard extension under this perl framework.

=back

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/whatToShow>

=head1 METHODS

=head2 firstChild

Moves the current L<Node|HTML::Object::DOM::Node> to the first visible child of the current node, and returns the found child. It also moves the current node to this child. If no such child exists, returns C<undef> and the current node is not changed.

Example:

    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
    );
    my $node = $treeWalker->firstChild(); # returns the first child of the root element, or null if none

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/firstChild>

=head2 lastChild

Moves the current L<Node|HTML::Object::DOM::Node> to the last visible child of the current node, and returns the found child. It also moves the current node to this child. If no such child exists, C<undef> is returned and the current node is not changed.

Example:

    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
    );
    my $node = $treeWalker->lastChild(); # returns the last visible child of the root element

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/lastChild>

=head2 nextNode

Moves the current L<Node|HTML::Object::DOM::Node> to the next visible node in the document order, and returns the found node. It also moves the current node to this one. If no such node exists, returns C<undef> and the current node is not changed.

Example:

    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
    );
    my $node = $treeWalker->nextNode(); # returns the first child of root, as it is the next $node in document order

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/nextNode>

=head2 nextSibling

Moves the current L<Node|HTML::Object::DOM::Node> to its next sibling, if any, and returns the found sibling. If there is no such node, C<undef> is returned and the current node is not changed.

Example:

    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
    );
    $treeWalker->firstChild();
    my $node = $treeWalker->nextSibling(); # returns null if the first child of the root element has no sibling

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/nextSibling>

=head2 parentNode

Moves the current L<Node|HTML::Object::DOM::Node> to the first visible ancestor node in the document order, and returns the found node. It also moves the current node to this one. If no such node exists, or if it is before that the root node defined at the object construction, returns C<undef> and the current node is not changed.

Example:

    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
    );
    my $node = $treeWalker->parentNode(); # returns null as there is no parent

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/parentNode>

=head2 previousNode

Moves the current L<Node|HTML::Object::DOM::Node> to the previous visible node in the document order, and returns the found node. It also moves the current node to this one. If no such node exists, or if it is before that the root node defined at the object construction, returns C<undef> and the current node is not changed.

Example:

    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
    );
    my $node = $treeWalker->previousNode(); # returns null as there is no parent

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/previousNode>

=head2 previousSibling

Moves the current L<Node|HTML::Object::DOM::Node> to its previous sibling, if any, and returns the found sibling. If there is no such node, return C<undef> and the current node is not changed.

Example:

    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
    );
    my $node = $treeWalker->previousSibling(); # returns null as there is no previous sibiling

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/previousSibling>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
