##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Node.pm
## Version v0.2.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/13
## Modified 2022/09/20
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Node;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::EventTarget );
    use vars qw( @EXPORT $XP $VERSION );
    use Nice::Try;
    use Want;
    use constant {
        DOCUMENT_POSITION_IDENTICAL     => 0,
        DOCUMENT_POSITION_DISCONNECTED  => 1,
        DOCUMENT_POSITION_PRECEDING     => 2,
        DOCUMENT_POSITION_FOLLOWING     => 4,
        DOCUMENT_POSITION_CONTAINS      => 8,
        DOCUMENT_POSITION_CONTAINED_BY  => 16,
        DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC => 32,
        XML_DEFAULT_NAMESPACE           => 'http://www.w3.org/XML/1998/namespace',
        ELEMENT_NODE                    => 1,
        ATTRIBUTE_NODE                  => 2,
        TEXT_NODE                       => 3,
        CDATA_SECTION_NODE              => 4,
        # Deprecated
        ENTITY_REFERENCE_NODE           => 5,
        # Deprecated
        ENTITY_NODE                     => 6,
        PROCESSING_INSTRUCTION_NODE     => 7,
        COMMENT_NODE                    => 8,
        DOCUMENT_NODE                   => 9,
        DOCUMENT_TYPE_NODE              => 10,
        DOCUMENT_FRAGMENT_NODE          => 11,
        NOTATION_NODE                   => 12,
        SPACE_NODE                      => 13,
    };
    our @EXPORT = qw( 
        DOCUMENT_POSITION_IDENTICAL
        DOCUMENT_POSITION_DISCONNECTED
        DOCUMENT_POSITION_PRECEDING
        DOCUMENT_POSITION_FOLLOWING
        DOCUMENT_POSITION_CONTAINS
        DOCUMENT_POSITION_CONTAINED_BY
        DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC
        
        ELEMENT_NODE
        ATTRIBUTE_NODE
        TEXT_NODE
        CDATA_SECTION_NODE
        ENTITY_REFERENCE_NODE
        ENTITY_NODE
        PROCESSING_INSTRUCTION_NODE
        COMMENT_NODE
        DOCUMENT_NODE
        DOCUMENT_TYPE_NODE
        DOCUMENT_FRAGMENT_NODE
        NOTATION_NODE
        SPACE_NODE
    );
    use overload (
        '=='    => \&isSameNode,
        'eq'    => \&isSameNode,
    );
    our $XP;
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->HTML::Object::Element::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub appendChild
{
    my $self = shift( @_ );
    return( $self->error({
        message => sprintf( "At least 1 arguments is required, but only %d provided.", scalar( @_ ) ),
        class => 'HTML::Object::TypeError',
    }) ) if( scalar( @_ ) < 1 );
    my $new = shift( @_ );
    my $new_parent = $new->parent;
    my $parent = $self->parent;
    # We use 'nodes' rather than 'children' so this works well with HTML::Object::DOM::Document
    my $nodes = $self->nodes;
    if( $new_parent && 
        !$self->_is_a( $new_parent => 'HTML::Object::DOM::Document' ) && 
        !$self->_is_a( $new_parent => 'HTML::Object::DOM::DocumentFragment' ) &&
        !$self->_is_a( $new_parent => 'HTML::Object::DOM::Element' ) )
    {
        return( $self->error({
            message => "Node's parent is not an HTML::Object::DOM::Document, HTML::Object::DOM::DocumentFragment or HTML::Object::DOM::Element object.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    # All other conditions below are strictly similar to replaceChild()
    elsif( !$self->_is_a( $new => 'HTML::Object::DOM::DocumentFragment' ) &&
           !$self->_is_a( $new => 'HTML::Object::DOM::Declaration' ) &&
           !$self->_is_a( $new => 'HTML::Object::DOM::Element' ) &&
           !$self->_is_a( $new => 'HTML::Object::DOM::CharacterData' ) )
    {
        return( $self->error({
            message => "New node is not an HTML::Object::DOM::DocumentFragment, HTML::Object::DOM::Declaration, HTML::Object::DOM::Element or HTML::Object::DOM::CharacterData object.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( $self->lineage->has( $new ) )
    {
        return( $self->error({
            message => "New node provided is an ancestor of the current node.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( ( $self->_is_a( $new => 'HTML::Object::DOM::Text' ) || $self->_is_a( $new => 'HTML::Object::DOM::Space' ) ) &&
           $self->_is_a( $new_parent => 'HTML::Object::DOM::Document' ) )
    {
        return( $self->error({
            message => "New node is a HTML::Object::DOM::Text or HTML::Object::DOM::Space node and its parent is a HTML::Object::DOM::Document node.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( $self->isa( 'HTML::Object::DOM::Declaration' ) && !$self->_is_a( $parent => 'HTML::Object::DOM::Document' ) )
    {
        return( $self->error({
            message => "Current node is a DocumentType, but its parent is not an HTML::Object::DOM::Document object.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( $self->_is_a( $parent => 'HTML::Object::DOM::Document' ) && 
           $self->_is_a( $new => 'HTML::Object::DOM::DocumentFragment' ) &&
           ( $new->childElementCount > 1 || $new->children->grep(sub{ $self->_is_a( $_ => 'HTML::Object::DOM::Text' ) })->length ) )
    {
        return( $self->error({
            message => "Current node parent is a HTML::Object::DOM::Document object and new node is a HTML::Object::DOM::DocumentFragment object that has either more than 1 element or has a HTML::Object::DOM::Text node.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    # This is different from replaceChild()
    elsif( $self->_is_a( $parent => 'HTML::Object::DOM::Document' ) &&
           $parent->childElementCount > 0 &&
           $self->_is_a( $new => 'HTML::Object::DOM::Element' ) )
    {
        return( $self->error({
            message => "Attempting to replace a child element in a Document with another non HTML-tag element. Document can have only one Element: the HTML-tag element.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    # If the node to append is a doctype and the curent last node is an element, this would put a doctype after an element, which is forbidden
    elsif( $self->_is_a( $new => 'HTML::Object::DOM::Declaration' ) && 
           $self->_is_a( $nodes->last, 'HTML::Object::DOM::Element' ) )
    {
        return( $self->error({
            message => "The last node is an element. Appending the DocumentType would place it after.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }

    $new->detach;
    my $new_array = $self->new_array( $self->_is_a( $new => 'HTML::Object::DOM::DocumentFragment' ) ? $new->children : $new );
    $new_array->foreach(sub
    {
        next if( !$self->_is_a( $_ => 'HTML::Object::DOM::Node' ) );
        $_->parent( $self );
    });
    $nodes->push( $new_array->list );
    $self->reset(1);
    if( $self->_is_a( $new => 'HTML::Object::DOM::DocumentFragment' ) )
    {
        $new->children->reset;
    }
    return( $new );
}

sub appendNodes
{
    my $self = shift( @_ );
    my $children = $self->children;
    foreach my $this ( @_ )
    {
        if( $self->_is_a( $this => 'HTML::Object::DOM::Node' ) )
        {
            $this->parent( $self );
            $children->push( $this );
        }
    }
    return( $self );
}

# Note: Property
# Example: <base href="https://www.example.com/">
sub baseURI : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        my $root = $self->root;
        return( $self->new_null ) if( !$root );
        return( $self->new_null ) if( !$root->can( 'uri' ) );
        return( $root->uri ) if( $root->uri );
        my $nodes = $self->find( 'base' );
        return( $self->new_null ) if( $nodes->is_empty );
        my $node = $nodes->first;
        return( $self->new_null ) if( !$node );
        return( $self->new_null ) if( !$node->attributes->has( 'href' ) );
        my $uri = $node->attributes->get( 'href' );
        return( $self->new_null ) if( !defined( $uri ) || !CORE::length( "$uri" ) );
        return( $self->_set_get_uri( 'uri', $uri ) );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $uri  = shift( @_ );
        my $root = $self->root;
        return( $self->new_null ) if( !$root );
        my $nodes = $root->find( 'base' );
        my $base;
        if( $nodes->is_empty )
        {
            $base = $root->createElement( 'base' ) || return( $self->error( $root->pass_error ) );
            my $head = $root->find( 'head' )->first ||
                return( $self->error( "No base uri can be set, because there is no head element in this document." ) );
            $head->appendChild( $base );
        }
        else
        {
            $base = $nodes->first;
        }
        $base->href( $uri ) || return( $self->error( $base->pass_error ) );
        return( $uri );
    },
}, @_ ) ); }

sub childNodes { return( shift->children ); }

sub cloneNode
{
    my $self = shift( @_ );
    my $clone = $self->clone;
    $clone->parent( undef );
    return( $clone );
}

sub compareDocumentPosition
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error( "No element was provided to append." ) );
    return( $self->error( "Element provided (", overload::StrVal( $elem ), ") is actually not an HTML element." ) ) if( !$self->_is_a( $elem => 'HTML::Object::Element' ) );
    # 0 - Elements are identical.
    #     -> DOCUMENT_POSITION_IDENTICAL
    # 1 - No relationship, both nodes are in different documents or different trees in the same document.
    #     -> DOCUMENT_POSITION_DISCONNECTED
    # 2 - The specified node precedes the current node.
    #     otherNode precedes the node in either a pre-order depth-first traversal of a tree containing both (e.g., as an ancestor or previous sibling or a descendant of a previous sibling or previous sibling of an ancestor) or (if they are disconnected) in an arbitrary but consistent ordering.
    #     -> DOCUMENT_POSITION_PRECEDING
    # 4 - The specified node follows the current node.
    #     The otherNode follows the node in either a pre-order depth-first traversal of a tree containing both (e.g., as a descendant or following sibling or a descendant of a following sibling or following sibling of an ancestor) or (if they are disconnected) in an arbitrary but consistent ordering.
    #     -> DOCUMENT_POSITION_FOLLOWING
    # 8 - The otherNode is an ancestor of / contains the current node.
    #     -> DOCUMENT_POSITION_CONTAINS
    # 16 - The otherNode is a descendant of / contained by the node.
    #     -> DOCUMENT_POSITION_CONTAINED_BY
    # 32 - The specified node and the current node have no common container node or the two nodes are different attributes of the same node.
    #     -> DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC
    
    # "If the two nodes being compared are the same node, then no flags are set on the return."
    # <https://www.w3.org/TR/DOM-Level-3-Core/core.html#DocumentPosition>
    return(0) if( Scalar::Util::refaddr( $self ) eq Scalar::Util::refaddr( $elem ) );
    # Current object and other element are both attributes of the same element (ownerElement)
    # "If neither of the two determining node is a child node and nodeType is the same for both determining nodes, then an implementation-dependent order between the determining nodes is returned."
    # <https://www.w3.org/TR/DOM-Level-3-Core/core.html#DocumentPosition>
    if( $self->nodeType == ATTRIBUTE_NODE && $elem->nodeType == ATTRIBUTE_NODE )
    {
        # 2 attributes of the same node
        return(32) if( $self->ownerElement && $self->ownerElement eq $elem->ownerElement );
    }
    
    my $parent = $self->parent;
    my $parent2 = $elem->parent;
    # "If neither of the two determining node is a child node and one determining node has a greater value of nodeType than the other, then the corresponding node precedes the other."
    # <https://www.w3.org/TR/DOM-Level-3-Core/core.html#DocumentPosition>
    if( !$parent && !$parent2 )
    {
        return( $self->nodeType < $elem->nodeType ? DOCUMENT_POSITION_FOLLOWING : DOCUMENT_POSITION_PRECEDING );
    }
    
    my $root = $self->root;
    my $root2 = $elem->root;
    # Both elements are in different documents
    if( $root ne $root2 )
    {
        return( DOCUMENT_POSITION_DISCONNECTED );
    }
    
    my $bit = 0;
    my $lineage = $self->lineage;
    my $lineage2 = $elem->lineage;
    my $prev_siblings = $self->left;
    my $next_siblings = $self->right;
    my $seen  = {};
    my $crawl;
    $crawl = sub
    {
        my $kid = shift( @_ );
        my $addr = Scalar::Util::refaddr( $kid );
        return if( ++$seen->{ $addr } > 1 );
        my $children = $kid->children;
        foreach( @$children )
        {
            if( $_->can( 'eid' ) && 
                defined( $_->eid ) && 
                defined( $elem->eid ) &&
                $_->eid eq $elem->eid )
            {
                return( $_ );
            }
            if( my $e = $crawl->( $_ ) )
            {
                return( $e );
            }
        }
        return;
    };
    
    # Check if our parent is among the other element's parents
    my $parent_pos = $lineage2->pos( $parent );
    # Check if the other element's parent is among our parents
    my $parent2_pos = $lineage->pos( $parent2 );
    # Then check their position, if found
    if( defined( $parent_pos ) && defined( $parent2_pos ) )
    {
        if( $parent_pos > $parent2_pos )
        {
            $bit |= DOCUMENT_POSITION_FOLLOWING;
        }
        elsif( $parent2_pos > $parent_pos )
        {
            $bit |= DOCUMENT_POSITION_PRECEDING;
        }
        else
        {
        }
    }
    elsif( defined( $parent_pos ) )
    {
        $bit |= DOCUMENT_POSITION_FOLLOWING;
    }
    elsif( defined( $parent2_pos ) )
    {
        $bit |= DOCUMENT_POSITION_PRECEDING;
    }
    # Otherwise neither our parent or the other's parent is in either lineage
    else
    {
    }
    
    if( $lineage->intersection( $lineage2 )->is_empty &&
        $lineage2->intersection( $lineage )->is_empty )
    {
        $bit |= DOCUMENT_POSITION_DISCONNECTED;
    }
    else
    {
    }
    # Check for the other node in:
    # 1) ancestor
    # 2) previous sibling
    # 3) descendant of previous sibling
    # 4) previous sibling of an ancestor
    
    # "If one of the nodes being compared contains the other node, then the container precedes the contained node, and reversely the contained node follows the container."
    # <https://www.w3.org/TR/DOM-Level-3-Core/core.html#DocumentPosition>
    if( $lineage->has( $elem ) )
    {
        $bit |= DOCUMENT_POSITION_PRECEDING;
        $bit |= DOCUMENT_POSITION_CONTAINS;
    }
    # check previous sibling
    elsif( $prev_siblings->has( $elem ) )
    {
        $bit |= DOCUMENT_POSITION_PRECEDING;
    }
    else
    {
        # check for descendant of previous sibling
        $seen  = {};
        foreach( @$prev_siblings )
        {
            if( my $e = $crawl->( $_ ) )
            {
                $bit |= DOCUMENT_POSITION_PRECEDING;
                last;
            }
        }

        # no luck so far. Checking previous sibling of an ancestor
        if( !( $bit & DOCUMENT_POSITION_PRECEDING ) )
        {
            # Go through each ancestor
            foreach( @$lineage )
            {
                # then get its previous siblings
                my $ancestor_siblings = $_->left;
                # and check if the other element is one of them
                if( $ancestor_siblings && $ancestor_siblings->has( $elem ) )
                {
                    $bit |= DOCUMENT_POSITION_PRECEDING;
                    last;
                }
            }
        }
    }
    
    # still no luck, check
    # 1) descendants
    # 2) following sibling
    # 3) a descendant of a following sibling
    # 4) following sibling of an ancestor
    $seen = {};
    # e.g. a child or an attribute of our element:
    # "when comparing an element against its own attribute or child, the element node precedes its attribute node and its child node, which both follow it."
    # <https://www.w3.org/TR/DOM-Level-3-Core/core.html#DocumentPosition>
    if( $lineage2->has( $self ) )
    {
        $bit |= ( DOCUMENT_POSITION_CONTAINED_BY | DOCUMENT_POSITION_FOLLOWING )
    }
    # Now check for following siblings
    elsif( $next_siblings->has( $elem ) )
    {
        $bit |= DOCUMENT_POSITION_FOLLOWING;
    }
    # "If one of the nodes being compared contains the other node, then the container precedes the contained node, and reversely the contained node follows the container."
    # <https://www.w3.org/TR/DOM-Level-3-Core/core.html#DocumentPosition>
    # We look deeper than our direct child
    elsif( my $e = $crawl->( $self ) )
    {
        $bit |= ( DOCUMENT_POSITION_CONTAINED_BY | DOCUMENT_POSITION_FOLLOWING )
    }
    # check for a descendant of a following sibling
    else
    {
        $seen = {};
        foreach( @$next_siblings )
        {
            if( my $e = $crawl->( $_ ) )
            {
                $bit |= DOCUMENT_POSITION_FOLLOWING;
                last;
            }
        }
        
        # no luck so far. Checking previous sibling of an ancestor
        if( !( $bit & DOCUMENT_POSITION_FOLLOWING ) )
        {
            # Go through each ancestor
            foreach( @$lineage )
            {
                # then get its following siblings
                my $ancestor_siblings = $_->right;
                # and check if the other element is one of them
                if( $ancestor_siblings && $ancestor_siblings->has( $elem ) )
                {
                    $bit |= DOCUMENT_POSITION_PRECEDING;
                    last;
                }
            }
        }
    }
    return( $bit );
}

sub contains
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error( "No element was provided to append." ) );
    return( $self->error( "Element provided (", overload::StrVal( $elem ), ") is actually not an HTML element." ) ) if( !$self->_is_a( $elem => 'HTML::Object::Element' ) );
    # Object and comparison object are the same
    return(1) if( Scalar::Util::refaddr( $self ) eq Scalar::Util::refaddr( $elem ) );
    my $found = 0;
    my $seen = {};
    my $traverse;
    $traverse = sub
    {
        my $e = shift( @_ );
        return if( !defined( $e ) || !CORE::length( $e ) );
        my $addr = Scalar::Util::refaddr( $e );
        return if( CORE::exists( $seen->{ $addr } ) );
        $seen->{ $addr }++;
        $e->children->foreach(sub
        {
            if( $_->eid eq $elem->eid )
            {
                $found++;
                return;
            }
            return( $traverse->( $_ ) );
        });
    };
    $traverse->( $self );
    return( $found );
}

# Takes a selector; or
# Element object
sub find
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $results = $self->new_array;
    
    if( ref( $this ) && $self->_is_object( $this ) && $this->isa( 'HTML::Object::DOM::Element' ) )
    {
        my $a = $self->new_array( [ $this ] );
        my $lookup;
        $lookup = sub
        {
            my $kids = shift( @_ );
            $kids->foreach(sub
            {
                my $child = shift( @_ );
                $a->foreach(sub
                {
                    my $candidate = shift( @_ );
                    if( $child->eid eq $candidate->eid )
                    {
                        $results->push( $child );
                        # We've added this child. Move to next child.
                        return( 1 );
                    }
                });
                if( $child->children->length > 0 )
                {
                    $lookup->( $child->children );
                }
            });
        };
        # Wether this is a collection or just an element object, we check our children
        $lookup->( $self->children );
    }
    # I am expecting an xpath value
    else
    {
        if( ref( $this ) &&
            (
                !overload::Overloaded( $this ) || 
                ( overload::Overloaded( $this ) && !overload::Method( $this, '""' ) )
            ) )
        {
            return( $self->error( "I was expecting an xpath string, but instead I got '$this'." ) );
        }
        my $xpath = $self->_xpath_value( $this, $opts ) || return( $self->pass_error );
#         $self->children->foreach(sub
#         {
#             my $child = shift( @_ );
#             return(1) if( !$child->isElementNode );
#             # Propagate debug value
#             $child->debug( $self->debug );
#             try
#             {
#                 my @nodes = $child->findnodes( $xpath );
#                 # $self->messagef( 4, "%d nodes found under child element '$child' whose tag is '%s' -> '%s'", scalar( @nodes ), $child->tag, join( "', '", map( overload::StrVal( $_ ), @nodes ) ) );
#                 $results->push( @nodes );
#             }
#             catch( $e )
#             {
#                 warn( "Error while calling findnodes on element id \"", $_->id, "\" and tag \"", $_->tag, "\": $e\n" );
#             }
#         });
        try
        {
            my @nodes = $self->findnodes( $xpath );
            $results->push( @nodes );
        }
        catch( $e )
        {
            # warn( "Error while calling findnodes on element id \"", ( $self->id // '' ), "\" and tag \"", ( $self->tag // '' ), "\": $e\n" );
            warn( "Error while calling findnodes on element with tag \"", ( $self->tag // '' ), "\": $e\n" );
        }
    }
    return( $results );
}

sub find_xpath
{
    my( $self, $path ) = @_;
    return( $self->xp->find( $path, $self ) );
}

sub findnodes
{
    my( $self, $path ) = @_;
    return( $self->xp->findnodes( $path, $self ) );
}

sub findnodes_as_string
{
    my( $self, $path ) = @_;
    return( $self->xp->findnodes_as_string( $path, $self ) );
}

sub findnodes_as_strings
{
    my( $self, $path ) = @_;
    return( $self->xp->findnodes_as_strings( $path, $self ) );
}

sub findvalue
{
    my( $self, $path ) = @_;
    return( $self->xp->findvalue( $path, $self ) );
}

sub findvalues
{
    my( $self, $path ) = @_;
    return( $self->xp->findvalues( $path, $self ) );
}

# Note: Property
sub firstChild { return( shift->nodes->first ); }

sub getAttributes
{
    my $self = shift( @_ );
    my $rank = 0;
    my $a = $self->attributes_sequence->map(sub
    {
        return( $self->new_attribute(
            name    => $_,
            element => $self,
            rank    => $rank++,
            value   => $self->attributes->get( $_ ),
        ) );
    });
    return( wantarray() ? $a->list : $a );
}

sub getChildNodes
{
    my $self = shift( @_ );
    my $nodes = $self->nodes;
    return( wantarray() ? $nodes->list : $nodes );
}

sub getElementById { return; }

# sub getFirstChild { return; }
sub getFirstChild { return( shift->nodes->first ); }

# sub getLastChild { return; }
sub getLastChild { return( shift->nodes->last ); }

sub getName { return; }

sub getNextSibling { return( shift->nextSibling ); }

sub getParentNode { return( shift->parent ); }

sub getPreviousSibling { return( shift->previousSibling ); }

sub getRootNode
{
    my $self = shift( @_ );
    # The parent of root is a HTML::Object::Root
    # that helps getting the tree to mimic a DOM tree
    # return( $self->root->getParentNode );
    return( $self->root );
}

sub hasChildNodes { return( !shift->nodes->is_empty ); }

sub insertAfter
{
    my $self = shift( @_ );
    my $e = shift( @_ ) || return( $self->error( "No node was provided to insert." ) );
    return( $self->error({
        message => "Node provided (" . overload::StrVal( $e ) . ") is not an HTML::Object::DOM::Node.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $e => 'HTML::Object::DOM::Node' ) );
    my $refNode = shift( @_ );
    my $nodes = $self->nodes;
    my $pos;
    if( !defined( $refNode ) )
    {
        $pos = $nodes->size;
    }
    else
    {
        return( $self->error({
            message => "Reference node provided (" . overload::StrVal( $refNode ) . ") is not an HTML::Object::DOM::Node.",
            class => 'HTML::Object::TypeError',
        }) ) if( !$self->_is_a( $refNode => 'HTML::Object::DOM::Node' ) );
        $pos = $nodes->pos( $refNode );
        return( $self->error({
            message => "Reference node provided (" . overload::StrVal( $refNode ) . ") is not among the document nodes.",
            class => 'HTML::Object::HierarchyRequestError',
        }) ) if( !defined( $pos ) );
        return( $self->error( "Somehow, position for the reference node returned $pos, but I expected an integer equal or above 0" ) ) if( $pos < 0 );
    }
    my $list = $self->new_array( $self->_is_a( $e => 'HTML::Object::DOM::DocumentFragment' ) ? $e->children : $e );
    $nodes->splice( $pos + 1, 0, $list->list );
    $list->foreach(sub
    {
        $_->detach;
        $_->parent( $self );
    });
    $self->reset(1);
    if( $self->_is_a( $e => 'HTML::Object::DOM::DocumentFragment' ) )
    {
        $e->children->reset;
    }
    return( $e );
}

sub insertBefore
{
    my $self = shift( @_ );
    my $e = shift( @_ ) || return( $self->error( "No node was provided to insert." ) );
    return( $self->error({
        message => "Node provided (" . overload::StrVal( $e ) . ") is not an HTML::Object::DOM::Node.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $e => 'HTML::Object::DOM::Node' ) );
    my $refNode = shift( @_ );
    my $nodes = $self->nodes;
    my $pos;
    if( !defined( $refNode ) )
    {
        $pos = $nodes->length; # set the position to size + 1 to make it equivalent to a push()
    }
    else
    {
        return( $self->error({
            message => "Reference node provided (" . overload::StrVal( $refNode ) . ") is not an HTML::Object::DOM::Node.",
            class => 'HTML::Object::TypeError',
        }) ) if( !$self->_is_a( $refNode => 'HTML::Object::DOM::Node' ) );
        $pos = $nodes->pos( $refNode );
        return( $self->error({
            message => "Reference node provided (" . overload::StrVal( $refNode ) . ") is not among the document nodes.",
            class => 'HTML::Object::HierarchyRequestError',
        }) ) if( !defined( $pos ) );
        return( $self->error( "Somehow, position for the reference node returned $pos, but I expected an integer equal or above 0" ) ) if( $pos < 0 );
    }
    my $list = $self->new_array( $self->_is_a( $e => 'HTML::Object::DOM::DocumentFragment' ) ? $e->children : $e );
    $nodes->splice( $pos, 0, $list->list );
    $list->foreach(sub
    {
        $_->detach;
        $_->parent( $self );
    });
    $self->reset(1);
    if( $self->_is_a( $e => 'HTML::Object::DOM::DocumentFragment' ) )
    {
        $e->children->reset;
    }
    return( $e );
}

sub isAttributeNode { return(0); }

sub isCommentNode   { return(0); }

# Note: Property
sub isConnected
{
    my $self = shift( @_ );
    my $root = $self->root;
    return( $self->false ) if( !$root );
    return( $root->isa( 'HTML::Object::Document' ) ? $self->true : $self->false );
}

sub isDefaultNamespace
{
    my $self = shift( @_ );
    my $uri  = shift( @_ );
    return( $self->error( "No namespace URI was provided to check." ) ) if( !defined( $uri ) );
    if( $self->tag eq 'svg' )
    {
        return( $self->attributes->get( 'xmlns' ) eq $uri );
    }
    else
    {
        return( $uri eq "" );
    }
}

sub isEqualNode
{
    my $self = shift( @_ );
    my $e = shift( @_ ) || return( $self->error( "No html element was provided to check for equality." ) );
    return( $self->error( "Element provided (", overload::StrVal( $e ), ") is not an HTML::Object::Element." ) ) if( !$self->_is_a( $e => 'HTML::Object::Element' ) );
    return(0) if( $self->nodeType != $e->nodeType );
    return(0) if( $self->children->length != $e->children->length );
    return(0) if( $self->attributes_sequence->join( ',' ) ne $e->attributes_sequence->join( ',' ) );
    my $failed = 0;
    $self->attributes_sequence->foreach(sub
    {
        my $v1 = $self->attributes->get( $_ );
        my $v2 = $e->attributes->get( $_ );
        if( $v1 ne $v2 )
        {
            $failed++;
            return;
        }
    });
    return(0) if( $failed );
    return(1);
}

sub isElementNode   { return(0); }

sub isNamespaceNode { return(0); }

sub isPINode        { return(0); }

sub isProcessingInstructionNode { return(0); }

sub isSameNode
{
    return(0) if( !defined( $_[1] ) );
    if( !$_[0]->_is_a( $_[1] => 'HTML::Object::DOM::Node' ) )
    {
        warn( "Value provided ($_[1]) is not a reference.\n" ) if( $_[0]->_warnings_is_enabled );
        return(0);
    }
    return( Scalar::Util::refaddr( $_[0] ) eq Scalar::Util::refaddr( $_[1] ) );
}

sub isTextNode      { return(0); }

# Node: Property
sub lastChild { return( shift->nodes->last ); }

sub lookupNamespaceURI
{
    my $self = shift( @_ );
    my $prefix = shift( @_ ) || return( '' );
    return( XML_DEFAULT_NAMESPACE ) if( lc( $prefix ) eq 'xml' );
    return( '' );
}

sub lookupPrefix { return; }

sub new_closing
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::Closing' ) || return( $self->pass_error );
    my $e = HTML::Object::DOM::Closing->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Closing->error ) );
    return( $e );
}

sub new_comment
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::Comment' ) || return( $self->pass_error );
    my $e = HTML::Object::DOM::Comment->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Comment->error ) );
    return( $e );
}

sub new_element
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::Element' ) || return( $self->pass_error );
    my $e = HTML::Object::DOM::Element->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Element->error ) );
    return( $e );
}

sub new_parser
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM' ) || return( $self->pass_error );
    my $p = HTML::Object::DOM->new( debug => $self->debug ) ||
        return( $self->pass_error( HTML::Object::DOM->error ) );
    return( $p );
}

sub new_text
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::Text' ) || return( $self->pass_error );
    my $e = HTML::Object::DOM::Text->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Text->error ) );
    return( $e );
}

# Note: Property
sub nextSibling { return( shift->right->first ); }

# Note: Property
sub nodeName
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $map =
    {
    Comment     => '#comment',
    Document    => '#document',
    DocumentFragment => '#documentFragment',
    Space       => '#space',
    Text        => '#text',
    };
    my $type = [split( /::/, $class )]->[-1];
    return( CORE::exists( $map->{ $type } ) ? $map->{ $type } : $self->tag );
}

# For any nodes except for Document, nodes are the same as children
sub nodes { return( shift->children( @_ ) ); }

# ELEMENT_NODE 	            1
# ATTRIBUTE_NODE 	        2
# TEXT_NODE 	            3
# CDATA_SECTION_NODE 	    4
# PROCESSING_INSTRUCTION_NODE 	7
# COMMENT_NODE 	            8
# DOCUMENT_NODE 	        9
# DOCUMENT_TYPE_NODE 	    10
# DOCUMENT_FRAGMENT_NODE 	11
# <https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType>
# Note: Property
sub nodeType
{
    my $self = shift( @_ );
    my $map =
    [
    # Document also inherits from Element, so we test it first
    'HTML::Object::DOM::Document'    => DOCUMENT_NODE,
    'HTML::Object::DOM::Element'     => ELEMENT_NODE,
    'HTML::Object::DOM::Attribute'   => ATTRIBUTE_NODE,
    'HTML::Object::DOM::Text'        => TEXT_NODE,
    # Nothing for CData (4) or Processing Instruction (7)
    'HTML::Object::DOM::Comment'     => COMMENT_NODE,
    'HTML::Object::DOM::Declaration' => DOCUMENT_TYPE_NODE,
    'HTML::Object::DOM::DocumentFragment' => DOCUMENT_FRAGMENT_NODE,
    # We treat space separately, but the DOM normally treats it as text
    'HTML::Object::DOM::Space'       => SPACE_NODE,
    ];
    
    # return( $map->{ [split( /::/, ( ref( $self ) || $self ) )]->[-1] } );
    for( my $i = 0; $i < scalar( @$map ); $i += 2 )
    {
        my $class = $map->[$i];
        my $const = $map->[$i + 1];
        if( $self->isa( $class ) )
        {
            return( $const );
        }
    }
    return;
}

# Note: Property
sub nodeValue { return; }

sub normalize
{
    my $self = shift( @_ );
    my $process;
    $process = sub
    {
        my $e = shift( @_ );
        my $new = $self->new_array;
        my $found = '';
        $e->children->foreach(sub
        {
            my $kid = shift( @_ );
            # text
            if( $kid->nodeType == 3 )
            {
                if( $found )
                {
                    # merge it with previous text element and skip it
                    $found->value->append( $kid->value->scalar );
                    # next
                    return(1);
                }
                # We found a text element. Save it and merge it with siblings, if any
                else
                {
                    $found = $kid;
                }
            }
            else
            {
                $found = '';
            }
            $new->push( $kid );
        });
        # Set the new children elements array object
        $e->children( $new );
    };
    $process->( $self );
    return( $self );
}

# Note: Property
sub ownerDocument
{
    my $self = shift( @_ );
    my $root = $self->root;
    return( $root );
}

sub parent { return( shift->_set_get_object_without_init( 'parent', 'HTML::Object::DOM::Node', @_ ) ); }

# Note: Property
sub parentNode { return( shift->parent ); }

# Note: Property
# "Returns an Element that is the parent of this node. If the node has no parent, or if that parent is not an Element, this property returns null."
sub parentElement
{
    my $self = shift( @_ );
    my $parent = $self->parent;
    return( $parent ) if( defined( $parent ) && $self->_is_a( $parent => 'HTML::Object::DOM::Element' ) );
    return;
}

# Note: Property
# The last element of our siblings, is our first element on our left
sub previousSibling { return( shift->left->last ); }

sub removeChild
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error({
        message => "No element was provided to remove.",
        class => 'HTML::Object::TypeError'
    }) );
    return( $self->error({
        message => "Element provided (" . overload::StrVal( $elem ) . ") is actually not an HTML element.",
        class => 'HTML::Object::TypeError'
    }) ) if( !$self->_is_a( $elem => 'HTML::Object::Element' ) );
    my $nodes = $self->nodes;
    my $pos = $nodes->pos( $elem );
    return( $self->error({
        message => "Node to remove was not found among the current object's children.",
        class => 'HTML::Object::NotFoundError',
    }) ) if( !defined( $pos ) );
    $nodes->splice( $pos, 1 );
    $elem->parent( undef );
    # Remove the closing tag also, if there are any.
    if( my $close = $elem->close_tag )
    {
        if( defined( $pos = $nodes->pos( $close ) ) )
        {
            $nodes->splice( $pos, 1 );
        }
    }
    $self->reset(1);
    return( $elem );
}

sub replaceChild
{
    my $self = shift( @_ );
    return( $self->error({
        message => sprintf( "At least 2 arguments are required, but only %d provided.", scalar( @_ ) ),
        class => 'HTML::Object::TypeError',
    }) ) if( scalar( @_ ) < 2 );
    my( $new, $old ) = @_;
    my $new_parent = $new->parent;
    my $old_parent = $old->parent;
    my $parent = $self->parent;
    if( !$parent )
    {
        return( $self->error({
            message => "Current node does not have any parent.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( !$old_parent )
    {
        return( $self->error({
            message => "Old node provided does not have any parent",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( $old_parent ne $self )
    {
        return( $self->error({
            message => "Old node parent is not the current node.",
            class => 'HTML::Object::NotFoundError',
        }) );
    }
    elsif( !$self->_is_a( $old_parent => 'HTML::Object::DOM::Document' ) && 
           !$self->_is_a( $old_parent => 'HTML::Object::DOM::DocumentFragment' ) &&
           !$self->_is_a( $old_parent => 'HTML::Object::DOM::Element' ) )
    {
        return( $self->error({
            message => "Old node's parent is not an HTML::Object::DOM::Document, HTML::Object::DOM::DocumentFragment or HTML::Object::DOM::Element object.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( !$self->_is_a( $new => 'HTML::Object::DOM::DocumentFragment' ) &&
           !$self->_is_a( $new => 'HTML::Object::DOM::Declaration' ) &&
           !$self->_is_a( $new => 'HTML::Object::DOM::Element' ) &&
           !$self->_is_a( $new => 'HTML::Object::DOM::CharacterData' ) )
    {
        return( $self->error({
            message => "New node is not an HTML::Object::DOM::DocumentFragment, HTML::Object::DOM::Declaration, HTML::Object::DOM::Element or HTML::Object::DOM::CharacterData object.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( $self->lineage->has( $new ) )
    {
        return( $self->error({
            message => "New node provided is an ancestor of the current node.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( ( $self->_is_a( $new => 'HTML::Object::DOM::Text' ) || $self->_is_a( $new => 'HTML::Object::DOM::Space' ) ) &&
           $self->_is_a( $new_parent => 'HTML::Object::DOM::Document' ) )
    {
        return( $self->error({
            message => "New node is a HTML::Object::DOM::Text or HTML::Object::DOM::Space node and its parent is a HTML::Object::DOM::Document node.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( $self->isa( 'HTML::Object::DOM::Declaration' ) && !$self->_is_a( $parent => 'HTML::Object::DOM::Document' ) )
    {
        return( $self->error({
            message => "Current node is a DocumentType, but its parent is not an HTML::Object::DOM::Document object.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( $self->_is_a( $parent => 'HTML::Object::DOM::Document' ) && 
           $self->_is_a( $new => 'HTML::Object::DOM::DocumentFragment' ) &&
           ( $new->childElementCount > 1 || $new->children->grep(sub{ $self->_is_a( $_ => 'HTML::Object::DOM::Text' ) })->length ) )
    {
        return( $self->error({
            message => "Current node parent is a HTML::Object::DOM::Document object and new node is a HTML::Object::DOM::DocumentFragment object that has either more than 1 element or has a HTML::Object::DOM::Text node.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( $self->_is_a( $parent => 'HTML::Object::DOM::Document' ) &&
           $parent->childElementCount > 0 &&
           $self->_is_a( $new => 'HTML::Object::DOM::Element' ) && 
           # Non-standard addition:
           # replacement is not forbidden if the user replace an element that is not an HTML element by an HTML element and there is no HTML element yet or
           # the user replace an HTML element by another HTML element
           !(
               ( $self->_is_a( $old => 'HTML::Object::DOM::Element' ) && 
                 !$self->_is_a( $old => 'HTML::Object::DOM::Element::HTML' ) && 
                 $parent->children->grep(sub{ $self->_is_a( $_ => 'HTML::Object::DOM::Element::HTML' ) })->is_empty &&
                 $self->_is_a( $new => 'HTML::Object::DOM::Element::HTML' ) ) ||
               ( $self->_is_a( $old => 'HTML::Object::DOM::Element::HTML' ) && 
                 $self->_is_a( $new => 'HTML::Object::DOM::Element::HTML' ) )
           ) )
    {
        return( $self->error({
            message => "Attempting to replace a child element in a Document with another non HTML-tag element. Document can have only one Element: the HTML-tag element.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    elsif( $self->_is_a( $new => 'HTML::Object::DOM::Element' ) && 
           $self->_is_a( $old->previousSibling => 'HTML::Object::DOM::Declaration' ) )
    {
        return( $self->error({
            message => "Attempting to add an Element object before a DocumentType object",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    # We use 'nodes' rather than 'children' so this works well with HTML::Object::DOM::Document
    my $nodes = $self->nodes;
    my $newPos = $nodes->pos( $new );
    my $oldPos = $nodes->pos( $old );
    if( defined( $newPos ) && !defined( $oldPos ) )
    {
        return( $self->error({
            message => "New child already has this parent and old child does not. Please check the order of replaceChild's arguments.",
            class => 'HTML::Object::NotFoundError',
        }) );
    }
    elsif( !defined( $oldPos ) )
    {
        return( $self->error({
            message => "Child to be replaced is not a child of this node",
            class => 'HTML::Object::NotFoundError',
        }) );
    }
    $new->detach;
    my $new_array = $self->new_array( $self->_is_a( $new => 'HTML::Object::DOM::DocumentFragment' ) ? $new->children : $new );
    $new_array->foreach(sub
    {
        next if( !$self->_is_a( $_ => 'HTML::Object::DOM::Node' ) );
        $_->parent( $self );
    });
    $nodes->splice( $oldPos, 1, $new_array->list );
    $old->parent( undef );
    $self->reset(1);
    return( $old );
}

sub textContent : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        return if( $self->isa( 'HTML::Object::DOM::Document' ) );
        unless( $self->isa( 'HTML::Object::DOM::Comment' ) ||
                $self->isa( 'HTML::Object::DOM::Text' ) ||
                $self->isa( 'HTML::Object::DOM::Element' ) )
        {
            return;
        }
        my $str = $self->as_text;
        return( $str );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $ctx = $_;
        my $arg = shift( @_ );
        return if( $self->isa( 'HTML::Object::DOM::Document' ) );
        my $dummy;
        if( $self->isa( 'HTML::Object::DOM::Comment' ) ||
            $self->isa( 'HTML::Object::DOM::Text' ) ||
            $self->isa( 'HTML::Object::DOM::Element' ) )
        {
            if( $self->isa( 'HTML::Object::DOM::Comment' ) ||
                $self->isa( 'HTML::Object::DOM::Text' ) )
            {
                $self->value( $arg );
            }
            else
            {
                my $e = $self->new_text( value => $arg, parent => $self );
                $self->children->set( $e );
            }
            $self->reset(1);
            $dummy = 1;
            return( $dummy );
        }
        return( $dummy );
    },
}, @_ ) ); }

sub trigger
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    return( $self->error({
        message => "No event type was provided to trigger.",
        class => 'HTML::Object::SyntaxError',
    }) ) if( !defined( $type ) || !CORE::length( "$type" ) );
    return( $self->error({
        message => "Event type provided \"$type\" contains illegal characters. Only alphanuneric, underscore (\"_\") and dash (\"-\") are allowed",
        class => 'HTML::Object::TypeError',
    }) ) if( $type !~ /^\w[\w\-]*$/ );
    require HTML::Object::Event;
    my $evt = HTML::Object::Event->new( $type, @_ ) || 
        return( $self->pass_error( HTML::Object::Event->error ) );
    return( $self->dispatchEvent( $evt ) );
}

sub xp
{
    my $self = shift( @_ );
    unless( $XP )
    {
        $self->_load_class( 'HTML::Object::XPath' ) || return( $self->pass_error );
        $XP = HTML::Object::XPath->new;
    }
    # $XP->debug( $self->debug );
    return( $XP );
}

sub _list_to_nodes
{
    my $self = shift( @_ );
    my $list = $self->new_array;
    my $p = $self->new_parser;
    my $prev;
    foreach( @_ )
    {
        if( $self->_is_a( $_ => 'HTML::Object::DOM::Node' ) )
        {
            if( $self->_is_a( $_ => 'HTML::Object::DOM::DocumentFragment' ) )
            {
                my $kids = $_->children->clone;
                $_->children->reset;
                foreach my $kid ( @$kids )
                {
                    $kid->detach;
                }
                $list->push( $kids->list );
            }
            else
            {
                $list->push( $_ );
                $_->detach;
            }
            undef( $prev );
        }
        # HTML string
        elsif( !ref( $_ ) || ( ref( $_ ) && overload::Method( $_, '""' ) ) )
        {
            if( $self->looks_like_html( $_ ) )
            {
                my $doc = $p->parse_data( $_ ) || 
                    return( $self->pass_error({ class => 'HTML::Object::TypeError' }) );
                $list->push( $doc->children->list ) if( !$doc->children->is_empty );
                undef( $prev );
            }
            else
            {
                if( defined( $prev ) && $self->_is_a( $prev => 'HTML::Object::DOM::Text' ) )
                {
                    $prev->value->append( $_ );
                }
                else
                {
                    my $e = $self->new_text( value => $_ );
                    $list->push( $e );
                    $prev = $e;
                }
            }
        }
        else
        {
            return( $self->error({
                message => "Unsupported data provided (" . overload::StrVal( $_ ) . ").",
                class => 'HTML::Object::TypeError',
            }) );
        }
    }
    return( $list );
}

sub _xpath_value
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( ref( $this ) )
    {
        return( $$this );
    }
    else
    {
        $self->_load_class( 'HTML::Selector::XPath' ) ||
            return( $self->pass_error );
        try
        {
            return( HTML::Selector::XPath::selector_to_xpath( $this, %$opts ) );
        }
        catch( $e )
        {
            return( $self->error( "Bad selector \"$this\": $e" ) );
        }
    }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Node - HTML Object DOM Node Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Node;
    my $node = HTML::Object::DOM::Node->new || 
        die( HTML::Object::DOM::Node->error, "\n" );

=head1 VERSION

    v0.2.1

=head1 DESCRIPTION

This module implement the properties and methods for HTML DOM nodes. It inherits from L<HTML::Object::EventTarget> and is used by L<HTML::Object::DOM::Element>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node |
    +-----------------------+     +---------------------------+     +-------------------------+

=head1 PROPERTIES

All the following properties can be used as lvalue method as well as regular method. For example with L</baseURI>

    # Get the base uri, if any
    my $uri = $e->baseURI;
    $e->baseURI = 'https://example.org/some/where';
    # or
    $e->baseURI( 'https://example.org/some/where' );

=head2 baseURI

Normally this is read-only, but in this api, you can set an URI.

This returns an L<URI> object representing the base URL of the document containing the Node, if any.

The base URL is determined as follows:

=over 4

=item 1. By default, the base URL is the location of the document (as set by L<HTML::Object/parse_url>).

=item 2. If it is an L<HTML Document|HTML::Object::DOM::Document> and there is a L<<base>|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base> element in the L<document|HTML::Object::DOM::Document>, the hrefvalue of the first Base element with such an attribute is used instead.

=item 3. By specifying an uri with L<HTML::Object::DOM::Document/documentURI> or L<HTML::Object::DOM::Document/URL>

=back

=head2 childNodes

Read-only

This returns an L<array object|Module::Generic::Array> containing all the children of this node (including elements, text and comments). This list being live means that if the children of the Node change, the L<list object|Module::Generic::Array> is automatically updated.

=head2 firstChild

Read-only

This returns an element representing the first direct child element of the element, or C<undef> if the element has no child.

=head2 isConnected

Returns a boolean indicating whether or not the element is connected (directly or indirectly) to the context object, i.e. the L<Document object|HTML::Object::Document> in the case of the normal DOM.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isConnected>

=head2 lastChild

Read-only

This returns an element representing the last direct child element of the element, or C<undef> if the element has no child.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/lastChild>

=head2 nextSibling

Read-only

This returns an element representing the next element in the tree, or C<undef> if there is not such element.

The next node could also be a L<whitespace|HTML::Object::DOM::Space> or a L<text|HTML::Object::DOM::Text>. If you want to get the next element and not just any node, use L<nextElementSibling|HTML::Object::DOM/nextElementSibling> instead.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nextSibling>

=head2 nodeName

Read-only

This returns a string containing the name of the element. The structure of the name will differ with the element type. E.g. An L<HTML Element|HTML::Object::Element> will contain the name of the corresponding tag, like 'audio' for an HTML audio element, a L<Text|HTML::Object::Text> element will have the '#text' string, or a L<Document|HTML::Object::Document> element will have the '#document' string.

For L<HTML element|HTML::Object::DOM::Element>, contrary to the standard specifications, is not the uppercase value of the tag name, but the lowercase value. However, if you really wanted the uppercase value, you could get it quite easily like so:

    $e->nodeName->uc;

This is because L<HTML::Object::Element/tag> returns a L<scalar object|Module::Generic::Scalar>

Example:

    This is some html:
    <div id="d1">Hello world</div>
    <!-- Example of comment -->
    Text <span>Text</span>
    Text<br/>
    <svg height="20" width="20">
      <circle cx="10" cy="10" r="5" stroke="black" stroke-width="1" fill="red" />
    <hr>
    <output id="result">Not calculated yet.</output>

then, with the script:

    let node = document.getElementsByTagName("body")[0].firstChild;
    let result = "Node names are:<br/>";
    while (node) {
      result += node.nodeName + "<br/>";
      node = node.nextSibling
    }

    const output = document.getElementById("result");
    output.innerHTML = result;

would produce:

    Node names are:
    #text
    div
    #text
    #comment
    #text
    span
    #text
    br
    #text
    svg
    hr
    #text
    output
    #text
    script

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeName>

=head2 nodeType

Read-only

This returns an integer representing the type of the element. Possible values are:

=over 4

=item 1. element node

=item 2. attribute node

=item 3. text node

=item 4. CDATA section node

=item 5. unused (formerly entity reference node)

=item 6. unused (formerly entity node)

=item 7. processing instruction node

=item 8. comment node

=item 9. document node

=item 10. document type node

=item 11. document fragment node

=item 12. notation node

=item 13. space node

=back

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType>

=head2 nodeValue

This returns or sets the value of the current node.

For document, element or collection, this returns C<undef> and for attribute, text or comment, this sets or returns the objct value.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head2 ownerDocument

Read-only

This returns the L<Document|HTML::Object::Document> that this element belongs to. If the element is itself a document, returns C<undef>.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/ownerDocument>

=head2 parentNode

Read-only

This returns an element that is the parent of this element. If there is no such element, like if this element is the top of the tree or if does not participate in a tree, this property returns C<undef>.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/parentNode>

=head2 parentElement

Read-only

This returns an element that is the parent of this element. If the element has no parent, or if that parent is not an Element, this property returns C<undef>.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/parentElement>

=head2 previousSibling

Read-only

This returns a element representing the previous element in the tree, or C<undef> if there is not such element.

The previous node could also be a L<whitespace|HTML::Object::DOM::Space> or a L<text|HTML::Object::DOM::Text>. If you want to get the previous element and not just any node, use L<previousElementSibling|HTML::Object::DOM/previousElementSibling> instead.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/previousSibling>

=head2 textContent

Returns / Sets the textual content of an element and all its descendants.

If this is called on a L<text node|HTML::Object::DOM::Text> or a L<comment node|HTML::Object::DOM::Comment>, it will, instead, set the object value to the textual content provided.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/textContent>

=head1 METHODS

=head2 addEventListener

Registers an event handler to a specific event type on the node. This is inherited from L<HTML::Object::EventTarget>

See L<HTML::Object::EventTarget/addEventListener> for more information.

=head2 appendChild

Adds the specified C<child> L<element|HTML::Object::Element> argument as the last child to the current L<element|HTML::Object::Element>. If the argument referenced an existing L<element|HTML::Object::Element> on the DOM tree, the element will be detached from its current position and attached at the new position.

If the given C<child> is a L<DocumentFragment|HTML::Object::DOM::DocumentFragment>, the entire contents of the L<DocumentFragment|HTML::Object::DOM::DocumentFragment> are moved into the child list of the specified parent node. 

It returns the element added, except when the C<child> is a L<DocumentFragment|HTML::Object::DOM::DocumentFragment>, in which case the empty L<DocumentFragment|HTML::Object::DOM::DocumentFragment> is returned. 

It returns C<undef> and sets an C<HTML::Object::HierarchyRequestError> error

=over 4

=item * the parent of C<child> is not a L<Document|HTML::Object::DOM::Document>, L<DocumentFragment|HTML::Object::DOM::DocumentFragment>, or an L<Element|HTML::Object::DOM::Element>.

=item * the insertion of C<child> would lead to a cycle, that is If C<child> is an ancestor of the node.

=item * C<child> is not a L<DocumentFragment|HTML::Object::DOM::DocumentFragment>, a L<DocumentType|HTML::Object::DOM::Declaration>, an L<Element|HTML::Object::DOM::Element>, or a L<CharacterData|HTML::Object::DOM::CharacterData>.

=item * the current node is a L<Text|HTML::Object::DOM::Text>, and its parent is a L<Document|HTML::Object::DOM::Document>.

=item * the current node is a L<DocumentType|HTML::Object::DOM::Declaration> and its parent is not a L<Document|HTML::Object::DOM::Document>, as a doctype should always be a direct descendant of a document.

=item * the parent of the node is a L<Document|HTML::Object::DOM::Document> and C<child> is a L<DocumentFragment|HTML::Object::DOM::DocumentFragment> with more than one L<Element|HTML::Object::DOM::Element> child, or that has a L<Text|HTML::Object::DOM::Text> child.

=item * the insertion of C<child> would lead to L<Document|HTML::Object::DOM::Document> with more than one L<Element|HTML::Object::DOM::Element> as child.

=item * the insertion of C<child> would lead to the presence of an L<Element|HTML::Object::DOM::Element> node before a L<DocumentType|HTML::Object::DOM::Declaration> node.

=back

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/appendChild>

=head2 appendNodes

Provided with some nodes, and this will add them to the list of nodes for the current node.

Returns the current node object.

=head2 cloneNode

Clone an element, and optionally, all of its contents. By default, it clones the content of the element.

To clone a node to insert into a different document, use L<HTML::Object::DOM::Document/importNode> instead.

Returns the element cloned. The cloned node has no parent and is not part of the document, until it is added to another node that is part of the document, using L</appendChild> or a similar method.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/cloneNode>

=head2 compareDocumentPosition

Compares the position of the current element against another element in any other document and returns a bitwise value comprised of one or more of the following constants (that are automatically exported):

=over 4

=item * DOCUMENT_POSITION_IDENTICAL (0 or in bits: 000000)

Elements are identical.

=item * DOCUMENT_POSITION_DISCONNECTED (1 or in bits: 000001)

No relationship, both nodes are in different documents or different trees in the same document.

=item * DOCUMENT_POSITION_PRECEDING (2 or in bits: 000010)

The specified node precedes the current node.

=item * DOCUMENT_POSITION_FOLLOWING (4 or in bits: 000100)

The specified node follows the current node.

=item * DOCUMENT_POSITION_CONTAINS (8 or in bits: 001000)

The otherNode is an ancestor of / contains the current node.

=item * DOCUMENT_POSITION_CONTAINED_BY (16 or in bits: 010000)

The otherNode is a descendant of / contained by the node.

=item * DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC (32 or in bits: 100000)

The specified node and the current node have no common container node or the two nodes are different attributes of the same node.

=back

    use HTML::Object::DOM::Node;
    my $head = $doc->head;
    my $body = $doc->body;

    if( $head->compareDocumentPosition( $body ) & DOCUMENT_POSITION_FOLLOWING )
    {
        say( 'Well-formed document' );
    } 
    else
    {
        say( '<head> is not before <body>' );
    }

For example:

    <div id="writeroot">
        <form>
            <input id="test" />
        </form>
    </div>

    my $x = $doc->getElementById('writeroot');
    my $y = $doc->getElementById('test');
    say( $x->compareDocumentPosition( $y ) ); # 20, i.e. 16 | 4
    say( $y->compareDocumentPosition( $x ) ); # 10, i.e. 8 | 2

Be careful that, since this method does quite a bit of searching among various hierarchies, this method is a bit expensive, especially on large documents.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/compareDocumentPosition> and also this L<blog post from John Resig|https://johnresig.com/blog/comparing-document-position/> or L<this one from Peter-Paul Koch|https://www.quirksmode.org/blog/archives/2006/01/contains_for_mo.html>

Also the L<W3C specifications|http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#Node3-compareDocumentPosition> and L<here|http://www.w3.org/TR/DOM-Level-3-Core/core.html#DocumentPosition>

=head2 contains

Returns true or false value indicating whether or not an element is a descendant of the calling element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/contains>

=head2 dispatchEvent

Dispatches an event to this node in the DOM and returns a boolean value that indicates whether no handler canceled the event. This is inherited from L<HTML::Object::EventTarget>
 
See L<HTML::Object::EventTarget/dispatchEvent> for more information.

=head2 find

Provided with an node object or a selector and this will search throughout the current node hierarchy using the XPath expression provided.

It returns an L<array object|Module::Generic::Array> of the nodes found.

=head2 find_xpath

Provided with an XPath expression and this will perform a search using the current node as the context.

=head2 findnodes

Provided with an XPath expression and this will perform a search using the current node as the context.

=head2 findnodes_as_string

Provided with an XPath expression and this will perform a search using the current node as the context and return the result as string.

=head2 findnodes_as_strings

Provided with an XPath expression and this will perform a search using the current node as the context and return the result as a list of strings.

=head2 findvalue

Provided with an XPath expression and this will perform a search using the current node as the context and return the result as the node value.

=head2 findvalues

Provided with an XPath expression and this will perform a search using the current node as the context and return the result as a list of node values.

=head2 getAttributes

Returns a list of attribute objects for this node in list context or an L<array object|Module::Generic::Array> in scalar context.

=head2 getChildNodes

Returns a list of the current child nodes in list context or an L<array object|Module::Generic::Array> in scalar context.

=head2 getElementById

Returns an empty list in list context and an empty array reference in scalar context.

=head2 getFirstChild

Returns the first child node of this node, if any, or C<undef> if there are none.

=head2 getLastChild

Returns the last child node of this node, if any, or C<undef> if there are none.

=head2 getName

Returns an C<undef> and this method is superseded in L<HTML::Object::DOM::Element>

=head2 getNextSibling

This non-standard method is an alias for the property L</nextSibling>

=head2 getParentNode

Returns the current node's parent node, if any.

=head2 getPreviousSibling

This non-standard method is an alias for the property L</previousSibling>

=head2 getRootNode

Returns the context object's root.

Under JavaScript, this optionally includes the shadow root if it is available. However a shadow root has no meaning under this perl interface.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/getRootNode>

=head2 hasChildNodes

Returns a boolean value indicating whether or not the element has any child elements.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/hasChildNodes>

=head2 insertAfter

This is a non-standard method since it does not exist in the web API, surprisingly enough.

This is exactly the same as L</insertBefore> below except it inserts the C<node> after.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/insertAfter>

=head2 insertBefore

Provided with a C<new> node and an optional C<reference> node and this inserts an element before the reference element as a child of a specified parent element. If the C<reference> node is C<undef>, then C<new> node is inserted at the end of current node's child nodes. 

If the given node already exists in the document, C<insertBefore> moves it from its current position to the new position. This means it will automatically be removed from its existing parent before appending it to the specified new parent.

This means that a node cannot be in two locations of the document simultaneously.

If the given child is a L<DocumentFragment|HTML::Object::DOM::DocumentFragment>, the entire contents of the L<DocumentFragment|HTML::Object::DOM::DocumentFragment> are moved into the child list of the specified parent node.

Returns the added child (unless C<new> is a L<DocumentFragment|HTML::Object::DOM::DocumentFragment>, in which case the empty L<DocumentFragment|HTML::Object::DOM::DocumentFragment> is returned). 

Example:

    <div id="parentElement">
        <span id="childElement">foo bar</span>
    </div>

    # Create a new, plain <span> element
    my $sp1 = $doc->createElement( 'span' );

    # Get the reference element
    my $sp2 = $doc->getElementById( 'childElement' );
    # Get the parent element
    my $parentDiv = $sp2->parentNode

    # Insert the new element into before sp2
    $parentDiv->insertBefore( $sp1, $sp2 );

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/insertBefore>

=head2 isAttributeNode

Returns false by default.

=head2 isCommentNode

Returns false by default.

=head2 isDefaultNamespace

Accepts a namespace URI as an argument and returns a boolean value with a value of true if the namespace is the default namespace on the given element or false if not.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isDefaultNamespace>

=head2 isElementNode

Returns false by default.

=head2 isEqualNode

Returns a boolean value which indicates whether or not two elements are of the same type and all their defining data points match.

Two elements are equal when they have the same type, defining characteristics (this would be their ID, number of children, and so forth), its attributes match, and so on. The specific set of data points that must match varies depending on the types of the elements. 

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isEqualNode>

=head2 isNamespaceNode

Returns false by default.

=head2 isPINode

Returns false by default.

=head2 isProcessingInstructionNode

Returns false by default.

=head2 isSameNode

Returns a boolean value indicating whether or not the two elements are the same (that is, they reference the same object).

Example:

    my $div1 = $doc->createElement('div');
    $div1->appendChild( $doc->createTextNode('This is an element.') );
    my $div2 = $div1->cloneNode;
    say $div1->isSameNode( $div2 ); # false
    say $div1->isSameNode( $div1 ); # true

We can also use with the equality operator:

    say $div1 == $div2; # false
    say $div1 eq $div2; # same; false
    say $div1 == $div1; # true

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isSameNode>

=head2 isTextNode

Returns false by default.

=head2 lookupNamespaceURI

Accepts a prefix and returns the namespace URI associated with it on the given element if found (and C<undef> if not). Supplying C<undef> for the prefix will return the default namespace.

This always return an empty string and C<http://www.w3.org/XML/1998/namespace> if the prefix is C<xml>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/lookupNamespaceURI>

=head2 lookupPrefix

This always returns C<undef>, because this is for XML, which is not supported.

Returns a string containing the prefix for a given namespace URI, if present, and C<undef> if not.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/lookupPrefix>

=head2 new_closing

Returns a new L<HTML::Object::DOM::Closing> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_comment

Returns a new L<HTML::Object::DOM::Comment> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_element

Returns a new L<HTML::Object::DOM::Element> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_parser

Returns a new L<HTML::Object::DOM> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_text

Returns a new L<HTML::Object::DOM::Text> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 nodes

Returns the L<array object|Module::Generic::Array> containing the current node's sub nodes.

=head2 normalize

Clean up all the text elements under this element (merge adjacent, remove empty).

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/normalize>

=head2 removeChild

Provided with a child node and this removes the child node from the current element, which must be a child of the current element and returns the removed node.

A C<HTML::Object::NotFoundError> error is returned if the child is not a child of the node.

Example:

    <div id="top">
        <div id="nested"></div>
    </div>

To remove a specified element when knowing its parent node:

    my $d = $doc->getElementById('top');
    my $d_nested = $doc->getElementById('nested');
    my $throwawayNode = $d->removeChild( $d_nested );

To remove a specified element without having to specify its parent node:

    my $node = $doc->getElementById('nested');
    if( $node->parentNode )
    {
        $node->parentNode->removeChild( $node );
    }

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/removeChild>

=head2 removeEventListener

Removes an event listener from the node. This is inherited from L<HTML::Object::EventTarget>
 
See L<HTML::Object::EventTarget/removeEventListener> for more information.

=head2 replaceChild

Provided with a C<new> node and and an C<old> node and this will replace the C<old> one by the C<new> one. Note that if the C<new> node is already present somewhere else in the C<DOM>, it is first removed from that position.

This returns the C<old> node removed.

For L<nodes|HTML::Object::DOM::Node> that are L<elements|HTML::Object::DOM::Element>, it might be easier to read and use L<HTML::Object::DOM::Element/replaceWith>

It returns C<undef> and sets an L<HTML::Object::HierarchyRequestError|Module::Generic/error> if:

=over 4

=item * the parent of C<old> node is not a L<Document|HTML::Object::DOM::Document>, L<DocumentFragment|HTML::Object::DOM::DocumentFragment>, or an L<Element|HTML::Object::DOM::Element>.

=item * the replacement of C<old> node by C<new> node would lead to a cycle, that is if C<new> node is an ancestor of the node.

=item * C<new> is not a L<DocumentFragment|HTML::Object::DOM::DocumentFragment>, a L<DocumentType|HTML::Object::DOM::Declaration>, an L<Element|HTML::Object::DOM::Element>, or a L<CharacterData|HTML::Object::DOM::CharacterData>.

=item * the current node is a L<Text|HTML::Object::DOM::Text>, and its parent is a L<Document|HTML::Object::DOM::Document>.

=item * the current node is a L<DocumentType|HTML::Object::DOM::Declaration> and its parent is not a L<Document|HTML::Object::DOM::Document>, as a doctype should always be a direct descendant of a document.

=item * the parent of the node is a L<Document|HTML::Object::DOM::Document> and C<new> node is a L<DocumentFragment|HTML::Object::DOM::DocumentFragment> with more than one L<Element|HTML::Object::DOM::Element> child, or that has a L<Text|HTML::Object::DOM::Text> child.

=item * the replacement of C<old> node by C<new> node would lead to L<Document|HTML::Object::DOM::Document> with more than one L<Element|HTML::Object::DOM::Element> as child.

=item * the replacement of C<old> node by C<new> node would lead to the presence of an L<Element|HTML::Object::DOM::Element> node before a L<DocumentType|HTML::Object::DOM::Declaration> node.

=back

It returns an L<HTML::Object::NotFoundError|Module::Generic/error> if the parent of C<old> is not the current node.

Example:

    <div>
        <span id="childSpan">foo bar</span>
    </div>

    // Build a reference to the existing node to be replaced
    let sp1 = document.getElementById('childSpan');
    let parentDiv = sp2.parentNode;
    // Create an empty element node without an ID, any attributes, or any content
    let sp2 = document.createElement('span');
    // Give it an id attribute called 'newSpan'
    sp2.id = "newSpan";
    // Create some content for the new element.
    sp2.appendChild( document.createTextNode('new replacement span element.') );
    // Replace existing node sp1 with the new span element sp2
    parentDiv.replaceChild(sp2, sp1);

Result:

    <div>
       <span id="newSpan">new replacement span element.</span>
    </div>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/replaceChild>

=head2 trigger

Provided with an even C<type> and this will instantiate a new L<HTML::Object::Event> object, passing it the C<type> argument, and any other arguments provided. it returns the value returned by L<HTML::Object::EventTarget/dispatchEvent>

If no event type is provided, it returns a C<HTML::Object::SyntaxError> error.

If the event type contains illegal characters, it returns a C<HTML::Object::TypeError> error. Accepted characters are alpha-numeric, underscore, and dash ("-").

=head2 xp

Returns a L<HTML::Object::XPath> object.

=head1 CONSTANTS

=over 4

=item * DOCUMENT_POSITION_IDENTICAL (0 or in bits: 000000)

Elements are identical.

=item * DOCUMENT_POSITION_DISCONNECTED (1 or in bits: 000001)

No relationship, both nodes are in different documents or different trees in the same document.

=item * DOCUMENT_POSITION_PRECEDING (2 or in bits: 000010)

The specified node precedes the current node.

=item * DOCUMENT_POSITION_FOLLOWING (4 or in bits: 000100)

The specified node follows the current node.

=item * DOCUMENT_POSITION_CONTAINS (8 or in bits: 001000)

The otherNode is an ancestor of / contains the current node.

=item * DOCUMENT_POSITION_CONTAINED_BY (16 or in bits: 010000)

The otherNode is a descendant of / contained by the node.

=item * DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC (32 or in bits: 100000)

The specified node and the current node have no common container node or the two nodes are different attributes of the same node.

=back

And also the following constants:

=over 4

=item * ELEMENT_NODE (1)

=item * ATTRIBUTE_NODE (2)

=item * TEXT_NODE (3)

=item * CDATA_SECTION_NODE (4)

=item * ENTITY_REFERENCE_NODE (5)

=item * ENTITY_NODE (6)

=item * PROCESSING_INSTRUCTION_NODE (7)

=item * COMMENT_NODE (8)

=item * DOCUMENT_NODE (9)

=item * DOCUMENT_TYPE_NODE (10)

=item * DOCUMENT_FRAGMENT_NODE (11)

=item * NOTATION_NODE (12)

=item * SPACE_NODE (13)

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
