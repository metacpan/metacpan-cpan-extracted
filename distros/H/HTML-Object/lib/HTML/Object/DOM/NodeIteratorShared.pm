##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/NodeIteratorShared.pm
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
package HTML::Object::DOM::NodeIteratorShared;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    # To import its constants
    use HTML::Object::DOM::Node;
    use HTML::Object::DOM::NodeFilter qw( :all );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    return( $self->error({
        message => sprintf( "Expected at least 1 arguments, but only got %d.", scalar( @_ ) ),
        class => 'HTML::Object::SyntaxError',
    }) ) if( scalar( @_ ) < 1 );
    my $root = shift( @_ );
    my $what = shift( @_ );
    my( $filterDef, $filter );
    $filterDef = shift( @_ ) if( ref( $_[0] ) eq 'CODE' );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error({
        message => "Root node provided is not a HTML::Object::DOM::Node object.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $root => 'HTML::Object::DOM::Node' ) );
    $what = HTML::Object::DOM::NodeFilter::SHOW_ALL if( !defined( $what ) );
    # Default value
    if( !defined( $filterDef ) )
    {
        $filterDef = HTML::Object::DOM::NodeFilter->new;
    }
    
    return( $self->error({
        message => "Value provided for what to show is not an integer.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_integer( $what ) );
    if( scalar( keys( %$opts ) ) )
    {
        return( $self->error({
            message => "Filter parameter provided is an hash reference, but it does not have a \"acceptNode\" property or that property is not a code reference.",
            class => 'HTML::Object::TypeError',
        }) ) if( !defined( $filterDef ) && ( !exists( $opts->{acceptNode} ) || ref( $opts->{acceptNode} ) ne 'CODE' ) );
        $filterDef = CORE::delete( $opts->{acceptNode} ) if( CORE::exists( $opts->{acceptNode} ) && ref( $opts->{acceptNode} ) eq 'CODE' );
    }
    
    if( $self->_is_object( $filterDef ) )
    {
        return( $self->error({
            message => "Object provided does not implement the \"acceptNode\" method.",
            class => 'HTML::Object::TypeError',
        }) ) if( !$filterDef->can( 'acceptNode' ) );
        $filter = sub{ return( $filterDef->acceptNode( @_ ) ); };
    }
    else
    {
        return( $self->error({
            message => "Filter parameter provided is not a code reference.",
            class => 'HTML::Object::TypeError',
        }) ) if( ref( $filterDef ) ne 'CODE' );
        $filter = $filterDef;
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{children} = [];
    $self->{pointerbeforereferencenode} = 1;
    $self->root( $root );
    $self->whatToShow( $what );
    $self->filter( $filter );
    $self->{_parent} = $root;
    # This is the position of our cursor in the flatten tree represented by an array of all elements
    $self->{_pos} = 0;
    my $elems = $self->_flatten;
    $self->_elements( $elems );
    return( $self );
}

# Note: property expandEntityReferences read-only
sub expandEntityReferences : lvalue { return( shift->_set_get_boolean( 'expandentityreferences', @_ ) ); }

# Note: property filter read-only
sub filter : lvalue { return( shift->_set_get_code( 'filter', @_ ) ); }

sub nextNode
{
    my $self = shift( @_ );
    my $elems = $self->_elements;
    # Would be -1 if empty
    my $size = $elems->size;
    # We reached the end of this array
    return if( $self->{_pos} >= $size );
    my $whattoshow = $self->whatToShow;
    return( $self->error( "Somehow the bitwise value of what to show is not an integer!" ) ) if( !$self->_is_integer( $whattoshow ) );
    my $filter = $self->filter;
    my $class = ref( $self );
    # Somehow it has been changed maybe? End our iteration
    if( ref( $filter ) ne 'CODE' )
    {
        $self->{_pos} = $size;
        return( $self->error({
            message => "Filter is not a code reference!",
            class => 'HTML::Object::TypeError',
        }) );
    }
    my $node;
    my $tmpPos = $self->{_pos} + 1;
    while(1)
    {
        # We reached the end of the array
        last if( $tmpPos > $size );
        my $tmpNode = $elems->index( $tmpPos );
        my $type = $tmpNode->nodeType;
        $tmpPos++, next if( !$self->_check_element( $tmpNode ) );
        # This is for the pos() method
        $self->{_relative_pos} = $tmpNode->parent->children->pos( $tmpNode );
        local $_ = $tmpNode;
        my $rv = $filter->( $tmpNode );
        # Filter should return FILTER_ACCEPT or FILTER_REJECT or FILTER_SKIP
        $tmpPos++, next if( !defined( $rv ) || $rv == FILTER_REJECT || $rv == FILTER_SKIP );
        $node = $tmpNode;
        $self->{_pos} = $tmpPos;
        last;
    }
    # Return the node to our caller
    return( $node );
}

sub pos { return( shift->{_relative_pos} ); }

sub previousNode
{
    my $self = shift( @_ );
    my $elems = $self->_elements;
    # Would be -1 if empty
    my $size = $elems->size;
    # Already at the beginning
    return if( $self->{_pos} <= 0 );
    my $whattoshow = $self->whatToShow;
    return( $self->error( "Somehow the bitwise value of what to show is not an integer!" ) ) if( !$self->_is_integer( $whattoshow ) );
    my $filter = $self->filter;
    my $class = ref( $self );
    # Somehow it has been changed maybe? End our iteration
    if( ref( $filter ) ne 'CODE' )
    {
        $self->{_pos} = $size;
        return( $self->error({
            message => "Filter is not a code reference!",
            class => 'HTML::Object::TypeError',
        }) );
    }
    my $node;
    my $tmpPos = $self->{_pos} - 1;
    while(1)
    {
        # We reached the start of the array
        last if( $tmpPos < 0 );
        my $tmpNode = $elems->index( $tmpPos );
        my $type = $tmpNode->nodeType;
        $tmpPos--, next if( !$self->_check_element( $tmpNode ) );
        # This is for the pos() method
        $self->{_relative_pos} = $tmpNode->parent->children->pos( $tmpNode );
        local $_ = $tmpNode;
        my $rv = $filter->( $tmpNode );
        # Filter should return FILTER_ACCEPT or FILTER_REJECT or FILTER_SKIP
        $tmpPos--, next if( !defined( $rv ) || $rv == FILTER_REJECT || $rv == FILTER_SKIP );
        $node = $tmpNode;
        # Decrement the position for the next turn
        $self->{_pos} = $tmpPos;
        last;
    }
    # Return the node to our caller
    return( $node );
}

# Note: property root read-only
sub root : lvalue { return( shift->_set_get_object_lvalue( 'root', 'HTML::Object::DOM::Node', @_ ) ); }

# Note: property whatToShow read-only
sub whatToShow : lvalue { return( shift->_set_get_number( 'whattoshow', @_ ) ); }

sub _check_element
{
    my $self = shift( @_ );
    my $node = shift( @_ ) || return;
    my $type = $node->nodeType;
    my $whattoshow = $self->whatToShow;
    unless( $whattoshow == SHOW_ALL )
    {
        if( ( $type == ELEMENT_NODE && !( $whattoshow & SHOW_ELEMENT ) ) ||
            ( $type == ATTRIBUTE_NODE && !( $whattoshow & SHOW_ATTRIBUTE ) ) ||
            ( $type == TEXT_NODE && !( $whattoshow & SHOW_TEXT ) ) ||
            ( $type == CDATA_SECTION_NODE && !( $whattoshow & SHOW_CDATA_SECTION ) ) ||
            ( $type == PROCESSING_INSTRUCTION_NODE && !( $whattoshow & SHOW_PROCESSING_INSTRUCTION ) ) ||
            ( $type == COMMENT_NODE && !( $whattoshow & SHOW_COMMENT ) ) ||
            ( $type == DOCUMENT_NODE && !( $whattoshow & SHOW_DOCUMENT ) ) ||
            ( $type == DOCUMENT_TYPE_NODE && !( $whattoshow & SHOW_DOCUMENT_TYPE ) ) ||
            ( $type == DOCUMENT_FRAGMENT_NODE && !( $whattoshow & SHOW_DOCUMENT_FRAGMENT ) ) ||
            # Notation nodes are deprecated, but we list them here anyway
            ( $type == NOTATION_NODE && !( $whattoshow & SHOW_NOTATION ) ) ||
            # This is a non-standard addition to provide more granularity
            ( $type == SPACE_NODE && !( $whattoshow & SHOW_SPACE ) ) )
        {
            return(0);
        }
    }
    return(1);
}

sub _elements { return( shift->_set_get_array_as_object( '_elements', @_ ) ); }

sub _flatten
{
    my $self = shift( @_ );
    my $root = $self->root;
    # Should not happen
    return( $self->error( "root element is gone!" ) ) if( !defined( $root ) );
    my $elems = $self->new_array;
    my $seen = {};
    my $crawl;
    $crawl = sub
    {
        my $e = shift( @_ );
        my $addr = $self->_refaddr( $e );
        return if( ++$seen->{ $addr } > 1 );
        my $kids = $e->children;
        foreach my $kid ( @$kids )
        {
            # Junk somehow although it should not happen
            next if( !$self->_is_a( $kid => 'HTML::Object::DOM::Node' ) );
            $elems->push( $kid );
            # Drill down...
            $crawl->( $kid );
        }
    };
    $elems->push( $root );
    $crawl->( $root );
    return( $elems );
}

sub _parent { return( shift->_set_get_object_without_init( '_parent', 'HTML::Object::DOM::Node', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::NodeIterator - HTML Object DOM Node Iterator Shared Class

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

Choose C<NodeIterator> when you only need a simple iterator to filter and browse the selected nodes, and choose L<HTML::Object::DOM::TreeWalker> when you need to access to the node and its siblings.

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class is to be inherited by either L<HTML::Object::DOM::NodeIterator> or L<HTML::Object::DOM::TreeWalker> and implements basic tree crawling mechanism.

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

Shows attribute L<Attribute nodes|HTML::Object::DOM::Attribute>. This is meaningful only when creating a NodeIterator with an L<Attribute node|HTML::Object::DOM::Attribute> as its root; in this case, it means that the L<attribute node|HTML::Object::DOM::Attribute> will appear in the first position of the iteration or traversal. Since attributes are never children of other L<nodes|HTML::Object::DOM::Node>, they do not appear when traversing over the document tree.

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

Provided with a L<root node|HTML::Object::DOM::Node>, an optional bitwise value representing what to show and an optional filter callback and this will return a new node iterator or tree walker depending on the class used.

=head1 METHODS

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

L<HTML::Object::DOM::NodeIterator>, L<HTML::Object::DOM::TreeWalker>

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator>, L<StackOverflow topic on NodeIterator|https://stackoverflow.com/questions/7941288/when-to-use-nodeiterator>, L<W3C specifications|https://dom.spec.whatwg.org/#interface-nodeiterator>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
