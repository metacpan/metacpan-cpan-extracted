##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/NodeIterator.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/20
## Modified 2021/12/20
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::NodeIterator;
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

sub detach { return; }

# Note: property expandEntityReferences read-only is inherited

# Note: property filter read-only inherited

# Note: method nextNode is inherited

# Note: property pointerBeforeReferenceNode read-only
sub pointerBeforeReferenceNode : lvalue { return( shift->_set_get_boolean( 'pointerbeforereferencenode', @_ ) ); }

sub pos { return( shift->{_relative_pos} ); }

# Note: method previousNode is inherited

# Note: property referenceNode read-only
sub referenceNode
{
    my $self = shift( @_ );
    my $elems = $self->_elements;
    return( $elems->index( $self->{_pos} ) );
}

# Note: property root read-only is inherited

# Note: property whatToShow read-only is inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::NodeIterator - HTML Object DOM Node Iterator Class

=head1 SYNOPSIS

With just one argument, this default to search for everything (C<SHOW_ALL>) and to use the default filter, which always returns C<FILTER_ACCEPT>

    use HTML::Object::DOM::NodeIterator;
    my $nodes = HTML::Object::DOM::NodeIterator->new( $root_node ) || 
        die( HTML::Object::DOM::NodeIterator->error, "\n" );

Or, passing an anonymous subroutine as the filter

    my $nodes = HTML::Object::DOM::NodeIterator->new(
        $root_node,
        $what_to_show_bit,
        sub{ return( FILTER_ACCEPT ); }
    ) || die( HTML::Object::DOM::NodeIterator->error, "\n" );

Or, passing an hash reference with a property 'acceptNode' whose value is an anonymous subroutine, as the filter

    my $nodes = HTML::Object::DOM::NodeIterator->new(
        $root_node,
        $what_to_show_bit,
        {
            acceptNode => sub{ return( FILTER_ACCEPT ); }
        }
    ) || die( HTML::Object::DOM::NodeIterator->error, "\n" );

Or, passing an object that implements the method "acceptNode"

    my $nodes = HTML::Object::DOM::NodeIterator->new(
        $root_node,
        $what_to_show_bit,
        # This object must implement the acceptNode method
        My::Customer::NodeFilter->new
    ) || die( HTML::Object::DOM::NodeIterator->error, "\n" );

There is also L<HTML::Object::DOM::TreeWalker>, which performs a somewhat similar function.

Choose L<HTML::Object::DOM::NodeIterator> when you only need a simple iterator to filter and browse the selected nodes, and choose L<HTML::Object::DOM::TreeWalker> when you need to access to the node and its siblings.

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<NodeIterator> interface represents an iterator over the members of a list of the L<nodes|HTML::Object::DOM::Node> in a subtree of the L<DOM|HTML::Object::DOM>. The nodes will be returned in document order.

A C<NodeIterator> can be created using the L<HTML::Object::DOM::Document/createNodeIterator> method, as follows: 

    use HTML::Object::DOM;
    my $parser = HTML::Object::DOM->new;
    my $doc = $parser->parse_data( $some_html_data ) || die( $parser->error );
    my $nodeIterator = $doc->createNodeIterator( $root, $whatToShow, $filter ) ||
        die( $doc->error );

=head1 PROPERTIES

=head2 expandEntityReferences

Normally this is read-only, but under perl you can set whatever boolean value you want.

Under JavaScript, this is a boolean value indicating if, when discarding an C<EntityReference> its whole sub-tree must be discarded at the same time.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
    );
    my $expand = $nodeIterator->expandEntityReferences;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/expandEntityReferences>

=head2 filter

Normally this is read-only, but under perl you can set it to a new L<HTML::Object::DOM::NodeFilter> object you want, even after object instantiation.

Returns a L<HTML::Object::DOM::NodeFilter> used to select the relevant nodes.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
    );
    my $nodeFilter = $nodeIterator->filter;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/filter>

=head2 pointerBeforeReferenceNode

Normally this is read-only, but under perl you can set whatever boolean value you want. Defaults to true.

Returns a boolean flag that indicates whether the C<NodeIterator> is anchored before, the flag being true, or after, the flag being false, the anchor node.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
    );
    my $flag = $nodeIterator->pointerBeforeReferenceNode;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/pointerBeforeReferenceNode>

=head2 pos

Read-only.

This is a non-standard property, which returns the 0-based position in the array of the anchor element's children.

You can poll this to know where the iterator is at.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    # You need to first declare $nodeIterator to be able to use it in the callback
    my $nodeIterator;
    $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        SHOW_ELEMENT,
        sub
        {
            say "Current position is: ", $nodeIterator->pos );
            return( $_->getName eq 'div' ? FILTER_ACCEPT : FILTER_SKIP );
        },
    );

=head2 referenceNode

Read-only.

Returns the L<Node|HTML::Object::DOM::Node> to which the iterator is anchored.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
    );
    my $node = $nodeIterator->referenceNode;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/referenceNode>

=head2 root

Normally this is read-only, but under perl you can set whatever L<node value|HTML::Object::DOM::Node> you want.

Returns a L<Node|HTML::Object::DOM::Node> representing the root node as specified when the C<NodeIterator> was created. 

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
    );
    my $root = $nodeIterator->root; # $doc->body in this case

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/root>

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

Shows attribute L<Attribute nodes|HTML::Object::DOM::Attribute>. This is meaningful only when creating a C<NodeIterator> with an L<Attribute node|HTML::Object::DOM::Attribute> as its root; in this case, it means that the L<attribute node|HTML::Object::DOM::Attribute> will appear in the first position of the iteration or traversal. Since attributes are never children of other L<nodes|HTML::Object::DOM::Node>, they do not appear when traversing over the document tree.

=item SHOW_TEXT (4)

Shows Text nodes.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        ( SHOW_ELEMENT | SHOW_COMMENT | SHOW_TEXT ),
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
    );
    if( ( $nodeIterator->whatToShow & SHOW_ALL ) ||
        ( $nodeIterator->whatToShow & SHOW_COMMENT ) )
    {
        # $nodeIterator will show comments
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

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/whatToShow>

=head1 CONSTRUCTOR

=head2 new

Provided with a L<root node|HTML::Object::DOM::Node>, an optional bitwise value representing what to show and an optional filter callback and this will return a new node iterator.

=head1 METHODS

=head2 detach

This operation is a no-op. It does not do anything. Previously it was telling the web browser engine that the C<NodeIterator> was no more used, but this is now useless.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/detach>

=head2 nextNode

Returns the next L<Node|HTML::Object::DOM::Node> in the document, or C<undef> if there are none.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
        0 # false; this optional argument is not used any more
    );
    my $currentNode = $nodeIterator->nextNode(); # returns the next node

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/nextNode>

=head2 previousNode

Returns the previous L<Node|HTML::Object::DOM::Node> in the document, or C<undef> if there are none.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
        # or
        # { acceptNode => sub{ return( FILTER_ACCEPT ); } },
        0 # false; this optional argument is not used any more
    );
    my $currentNode = $nodeIterator->nextNode(); # returns the next node
    my $previousNode = $nodeIterator->previousNode(); # same result, since we backtracked to the previous node

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/previousNode>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator>, L<StackOverflow topic on NodeIterator|https://stackoverflow.com/questions/7941288/when-to-use-nodeiterator>, L<W3C specifications|https://dom.spec.whatwg.org/#interface-nodeiterator>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
