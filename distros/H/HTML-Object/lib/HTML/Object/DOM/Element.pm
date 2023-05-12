##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element.pm
## Version v0.3.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/13
## Modified 2023/05/07
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element;
BEGIN
{
    use strict;
    use warnings;
    use HTML::Object::DOM::Node qw( TEXT_NODE COMMENT_NODE );
    use parent qw( HTML::Object::DOM::Node );
    use vars qw( @EXPORT_OK $VERSION );
    use HTML::Object::Exception;
    use Nice::Try;
    use Scalar::Util ();
    use URI;
    use Want;
    our @EXPORT_OK = qw(
        DOCUMENT_POSITION_IDENTICAL DOCUMENT_POSITION_DISCONNECTED 
        DOCUMENT_POSITION_PRECEDING DOCUMENT_POSITION_FOLLOWING DOCUMENT_POSITION_CONTAINS 
        DOCUMENT_POSITION_CONTAINED_BY DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC
    );
    our $VERSION = 'v0.3.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{contentEditable} = 1;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    # internal trigger, essentially to be triggered when an attribute is being updated
    # so the TokenList object can be updated
    $self->{_internal_attribute_callbacks} = {} if( !exists( $self->{_internal_attribute_callbacks} ) || ref( $self->{_internal_attribute_callbacks} ) ne 'HASH' );
    $self->{_internal_attribute_callbacks}->{class} = sub
    {
        my( $this, $val ) = @_;
        my $list;
        return if( !( $list = $this->{_class_list} ) );
        $list->update( $val );
    };
    return( $self );
}

# Note: accessKey -> property
sub accessKey : lvalue { return( shift->_set_get_property( 'accesskey', @_ ) ); }

# Note: accessKeyLabel -> property
sub accessKeyLabel : lvalue { return( shift->_set_get_property( 'accessKeyLabel', @_ ) ); }

sub after
{
    my $self = shift( @_ );
    return( $self ) if( !scalar( @_ ) );
    my $parent = $self->parent;
    return( $self->error( "No parent set for this element, so you cannot set this \"after\" method." ) ) if( !$parent );
    my $pos = $parent->children->pos( $self );
    # If a HTML::Object::DOM::DocumentFragment object is provided, its children are 
    # copied to the list and its own children array is emptied.
    my $list = $self->_get_from_list_of_elements_or_html( @_ );
    $list->foreach(sub
    {
        $_->parent( $parent );
        $parent->children->splice( $pos + 1, 0, $_ );
        $pos++;
        # Required, because $pos++ as the last execution in this anon sub somehow returns defined and false
        return(1);
    });
    $parent->reset(1);
    return( $self );
}

sub append
{
    my $self = shift( @_ );
    return( $self ) if( !scalar( @_ ) );
    # If a HTML::Object::DOM::DocumentFragment object is provided, its children are 
    # copied to the list and its own children array is emptied.
    my $list = $self->_get_from_list_of_elements_or_html( @_ );
    my $children = $self->children;
    $list->foreach(sub
    {
        $_->parent( $self );
        $children->push( $_ );
    });
    $self->reset(1);
    return( $list );
}

sub assignedSlot { return; }

sub attachInternals { return; }

# Note: attributeStyleMap -> property
sub attributeStyleMap : lvalue { return( shift->_set_get_property( 'style', @_ ) ); }

sub before
{
    my $self = shift( @_ );
    return( $self ) if( !scalar( @_ ) );
    my $parent = $self->parent;
    return( $self->error( "No parent set for this element, so you cannot set this \"before\" method." ) ) if( !$parent );
    my $pos = $parent->children->pos( $self );
    $pos--;
    # If a HTML::Object::DOM::DocumentFragment object is provided, its children are 
    # copied to the list and its own children array is emptied.
    my $list = $self->_get_from_list_of_elements_or_html( @_ );
    $list->foreach(sub
    {
        $_->parent( $parent );
        $parent->children->splice( $pos + 1, 0, $_ );
        $pos++;
    });
    $parent->reset(1);
    return( $self );
}

sub blur { return; }

# NOTE: HTML element property read-pnly
sub childElementCount { return( $_[0]->children->grep(sub{ $_[0]->_isa( $_ => 'HTML::Object::DOM::Element' ) })->length ); }

# NOTE: HTML element property
# <https://developer.mozilla.org/en-US/docs/Web/API/Element/classList>
sub classList
{
    my $self = shift( @_ );
    unless( $self->{_class_list} )
    {
        my $classes = $self->attr( 'class' );
        require HTML::Object::TokenList;
        $self->{_class_list} = HTML::Object::TokenList->new( $classes, element => $self, attribute => 'class' ) ||
            return( $self->pass_error( HTML::Object::TokenList->error ) );
    }
    return( $self->{_class_list} );
}

# NOTE: Property
sub className : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        return( $self->new_scalar( $self->attr( 'class' ) ) );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $arg  = shift( @_ );
        $self->attr( class => $arg );
        $self->reset(1);
        return( $self->new_scalar( $arg ) );
    }
}, @_ ) ); }

sub clientHeight { return; }

sub clientLeft { return; }

sub clientTop { return; }

sub clientWidth { return; }

sub click { return( shift->trigger( 'click' ) ); }

# TODO: closest: expand the support for xpath
sub closest
{
    my $self = shift( @_ );
    # Right now, only support a tag name.
    my $what = shift( @_ ) || return( $self->error( "No value provided to find ancestor." ) );
    $what = lc( $what );
    my $lineage = $self->lineage;
    my $result = $lineage->grep(sub{ $_->tag eq $what });
    return( $result->first );
}

# Taken from HTML::TreeBuilder::XPpath
sub cmp
{
    my( $a, $b ) = @_;
    # comparison with the root (in $b, or processed in HTML::Object::Root)
    return( -1 ) if( $b->isa( 'HTML::Object::Root' ) );

    return(0) if( $a->eid eq $b->eid );
    # easy cases
    return(  0 ) if( $a == $b );
    # a starts after b 
    return(  1 ) if( $a->is_inside( $b ) );
    # a starts before b
    return( -1 ) if( $b->is_inside( $a ) );

    # lineage does not include the element itself
    my $a_pile = $a->lineage->unshift( $a );
    my $b_pile = $b->lineage->unshift( $b );
    # $a->debug(4);
    
    # the 2 elements are not in the same twig
    unless( $a_pile->last == $b_pile->last ) 
    {
        warnings::warn( "2 nodes not in the same pile: " . ref( $a ) . " - " . ref( $b ) . "\n" ) if( warnings::enabled( 'HTML::Object' ) );
        # print "a: ", $a->string_value, "\nb: ", $b->string_value, "\n";
        return;
    }

    # find the first non common ancestors (they are siblings)
    my $a_anc = $a_pile->pop;
    my $b_anc = $b_pile->pop;

    while( $a_anc == $b_anc )
    {
        $a_anc = $a_pile->pop;
        $b_anc = $b_pile->pop;
    }

    if( defined( $a_anc->rank ) && defined( $b_anc->rank ) )
    {
        return( $a_anc->rank <=> $b_anc->rank );
    }
    else
    {
        # from there move left and right and figure out the order
        my( $a_prev, $a_next, $b_prev, $b_next ) = ( $a_anc, $a_anc, $b_anc, $b_anc );
        while()
        {
            $a_prev = $a_prev->getPreviousSibling || return( -1 );
            return( 1 ) if( $a_prev == $b_anc );
            $a_next = $a_next->getNextSibling     || return( 1 );
            return( -1 ) if( $a_next == $b_anc );
            $b_prev = $b_prev->getPreviousSibling || return( 1 );
            return( -1 ) if( $b_prev == $a_next );
            $b_next = $b_next->getNextSibling     || return( -1 );
            return( 1 ) if( $b_next == $a_prev );
        }
    }
}

# Note: contentEditable -> property
sub contentEditable : lvalue { return( shift->_set_get_property( 'contentEditable', @_ ) ); }

# NOTE: dataset -> property
sub dataset
{
    my $self = shift( @_ );
    return( $self->{_data_map} ) if( $self->{_data_map} );
    $self->_load_class( 'HTML::Object::ElementDataMap' ) ||
        return( $self->pass_error );
    my $map = HTML::Object::ElementDataMap->new( $self ) ||
        return( $self->pass_error( HTML::Object::ElementDataMap->error ) );
    return( $self->{_data_map} = $map );
}

# Note: dir -> property
sub dir : lvalue { return( shift->_set_get_property( 'dir', @_ ) ); }

# Note: draggable -> property
sub draggable : lvalue { return( shift->_set_get_property( { attribute => 'draggable', is_boolean => 1 }, @_ ) ); }

# Note: enterKeyHint -> property
sub enterKeyHint : lvalue { return( shift->_set_get_property( 'enterKeyHint', @_ ) ); }

sub firstElementChild
{
    my $self = shift( @_ );
    my $children = $self->children;
    my $elem;
    $children->foreach(sub
    {
        if( $_->isa( 'HTML::Object::DOM::Element' ) )
        {
            $elem = $_;
            return;
        }
        return(1);
    });
    return( $self->new_null ) if( !defined( $elem ) );
    return( $elem );
}

sub focus { return; }

sub getAttribute { return( shift->attributes->get( shift( @_ ) ) ); }

# We return a clone version to be safe, since we rely on this, so if this get messed up
# things will go awry
sub getAttributeNames { return( shift->attributes_sequence->clone ); }

sub getAttributeNode
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return;
    # new_null is a nifty method inherited from Module::Generic
    # It returns the right value based on the caller's expectation
    return( $self->new_null ) if( !$self->attributes->exists( $name ) );
    my $val = $self->attributes->get( $name );
    my $att = $self->new_attribute( name => $name, value => $val, element => $self );
    return( $att );
}

sub getAttributeNodeNS { return; }

sub getAttributeNS { return; }

# Note: method getAttributes is inherited

# Note: method getChildNodes is inherited

sub getElementById
{
    my( $self, $id ) = @_;
    return( $self->error( "No id was provided to get its corresponding element." ) ) if( !defined( $id ) || !CORE::length( $id ) );
    return( $self->look_down( id => $id )->first );
}

sub getElementsByClassName
{
    my $self = shift( @_ );
    my @args = ();
    if( scalar( @_ ) == 1 )
    {
        @args = split( /[[:blank:]\h]+/, $_[0] );
    }
    else
    {
        @args = @_;
    }
    my $results = $self->new_array;
    my $test = $self->new_array( \@args )->unique(1);
    my $totalClassRequired = $test->length->scalar;
    # Nothing to do somehow
    return( $results ) if( !$totalClassRequired );
    
    my $seen = {};
    my $crawl;
    $crawl = sub
    {
        my $kid = shift( @_ );
        $kid->children->foreach(sub
        {
            my $e = shift( @_ );
            # Avoid looping
            my $addr = Scalar::Util::refaddr( $e );
            return(1) if( CORE::exists( $seen->{ $addr } ) );
            $seen->{ $addr }++;
            if( $e->attributes->exists( 'class' ) )
            {
                my $val = $self->new_scalar( $e->attributes->get( 'class' ) );
                $val->trim( qr/[[:blank:]\h]+/ );
                if( !$val->is_empty )
                {
                    my $classes = $val->split( qr/[[:blank:]\h]+/ );
                    my $found = 0;
                    $test->foreach(sub
                    {
                        $found++ if( $classes->has( $_ ) );
                    });
                    $results->push( $e ) if( $found == $totalClassRequired );
                }
            }
            $crawl->( $e );
            # Always return true
            return(1);
        });
    };
    $crawl->( $self );
    return( $results );
}

sub getElementsByTagName
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    my $results = $self->new_array;
    # Nothing to do somehow
    return( $self->error( "No name was provided for getElementsByTagName()" ) ) if( !defined( $name ) || !CORE::length( "$name" ) );
    
    my $seen = {};
    my $crawl;
    $crawl = sub
    {
        my $kid = shift( @_ );
        $kid->children->foreach(sub
        {
            my $e = shift( @_ );
            # Avoid looping
            my $addr = Scalar::Util::refaddr( $e );
            return(1) if( CORE::exists( $seen->{ $addr } ) );
            $seen->{ $addr }++;
            if( $e->tag eq $name )
            {
                $results->push( $e );
            }
            $crawl->( $e );
            # Always return true
            return(1);
        });
    };
    $crawl->( $self );
    return( $results );
}

# Credits John Resig
# <https://johnresig.com/blog/comparing-document-position/>
# Original by PPK quirksmode.org
sub getElementsByTagNames
{
    my $self = shift( @_ );
    my $this;
    my $results = $self->new_array;
    if( scalar( @_ ) == 1 && !ref( $_[0] ) )
    {
        $this = [split( /[[:blank:]\h]+/, $this )];
    }
    elsif( scalar( @_ ) == 1 && $self->_is_array( $this ) )
    {
        # Good as-is
    }
    # list of elements
    elsif( scalar( @_ ) > 1 )
    {
        $this = [@_];
    }
    else
    {
        return( $results );
    }
    
    my $tags = $self->new_array( $this );
    $tags->foreach(sub
    {
        my $elems = $self->getElementsByTagName( $_ );
        $results->push( $elems->list ) if( !$elems->is_empty );
    });
    $results->unique(1);
    return( $results );
}

# sub getFirstChild { return( shift->children->first ); }
# Note: method getFirstChild is inherited

# Note: method getLastChild is inherited

sub getLocalName
{
    my $self = shift( @_ );
    ( my $name = $self->tag ) =~ s{^.*:}{};
    return( $name );
}

sub getName { return( shift->tag ); }

# sub getNextSibling { return( shift->right->first ); }
# Note: method getNextSibling is inherited

sub getNodePath
{
    my $self = shift( @_ );
    my $a;
    my $init;
    if( @_ )
    {
        $a = shift( @_ );
    }
    else
    {
        $a = $self->new_array;
        $init = 1;
    }
    return if( $self->isa( 'HTML::Object::Text' ) || $self->isa( 'HTML::Object::Comment' ) || $self->isa( 'HTML::Object::Declaration' ) );
    my $tag = $self->tag;
    my $parent = $self->parent;
    if( !defined( $parent ) )
    {
        return( $a ) if( !defined( $tag ) || $tag CORE::eq '_document' );
        $a->unshift( $tag );
        return( $a );
    }
    my $nth = 0;
    my $pos = 0;
    $parent->children->foreach(sub
    {
        if( $_->tag CORE::eq $self->tag )
        {
            $nth++;
            if( $_->eid CORE::eq $self->eid )
            {
                $pos = $nth;
            }
        }
        # Continue to the next one
        return( 1 );
    });
    $a->unshift( $nth > 1 ? "${tag}\[${pos}\]" : $tag );
    return( $parent->getNodePath( $a ) ) unless( $init );
    my $xpath = '/' . $a->join( '/' );
    return( $xpath );
}

sub getParentNode
{
    my $self = shift( @_ );
    return( $self->parent || $self->new_root( root => $self ) );
}

# Note: getPreviousSibling is inherited

sub getValue 
{
    my $self = shift( @_ );
    # return( $self->text ) if( $self->isCommentNode );
    return( $self->value ) if( $self->isCommentNode );
    return( $self->as_text );
}

sub hasAttribute { return( shift->attributes->has( shift( @_ ) ) ); }

sub hasAttributes { return( !shift->attributes->is_empty ); }

# Note: hidden -> property
sub hidden : lvalue { return( shift->_set_get_property( { attribute => 'hidden', is_boolean => 1 }, @_ ) ); }

sub hidePopover { return; }

# Note: inert -> property
sub inert : lvalue { return( shift->_set_get_property( { attribute => 'inert', is_boolean => 1 }, @_ ) ); }

sub innerHTML : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        # Create a new document, because we want to use the document object as_string function which produce a string of its children, and no need to reproduce it here
        my $doc = $self->new_document;
        $doc->children( $self->children );
        return( $doc->as_string );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $this = shift( @_ );
        my $children;
        if( !ref( $this ) ||
            ( ref( $this ) && overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) )
        {
            my $p = $self->new_parser;
            my $res = $p->parse_data( "$this" ) ||
                die( "Error while parsing html data provided: " . $p->error );
            $children = $res->children;
        }
        # We are provided with an element, so we set it as our inner html
        elsif( $self->_is_a( $this => 'HTML::Object::Element' ) )
        {
            # If a HTML::Object::DOM::DocumentFragment object is provided, its children are 
            # copied to the list and its own children array is emptied.
            if( $self->_is_a( $this => 'HTML::Object::DOM::DocumentFragment' ) )
            {
                $children = $this->children->clone;
                $this->children->reset;
            }
            else
            {
                my $child = $this->clone;
                $children = $self->new_array( $child );
            }
        }
        else
        {
            die( "I was expecting some html data in replacement of html for this element \"" . $self->tag . "\", but instead got '" . ( CORE::length( $this ) > 1024 ? ( CORE::substr( $this, 0, 1024 ) . '...' ) : $this ) . "'." );
        }
        
        $children->foreach(sub
        {
            $_->parent( $self );
        });
        $self->children( $children );
        $self->reset(1);
        return(1);
    }
}, @_ ) ); }

# Note: innerText -> property
sub innerText : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        # Create a new document, because we want to use the document object as_string function which produce a string of its children, and no need to reproduce it here
        my $txt = $self->as_trimmed_text;
        my $obj = $self->new_scalar( \$txt );
        return( $obj );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $this = shift( @_ );
        my $children;
        # We are provided with an element, so we set it as our inner html
        if( $self->_is_a( $this => 'HTML::Object::DOM::Text' ) )
        {
            $children = $self->new_array( $this );
        }
        elsif( !ref( $this ) ||
               ( ref( $this ) && overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) )
        {
            $this =~ s,\n,<br />\n,gs;
            my $txt = $self->new_text( value => $this ) || die( $self->error );
            $children = $self->new_array( $txt );
        }
        else
        {
            die( "I was expecting some text data in replacement of html for this element \"" . $self->tag . "\", but instead got '" . ( CORE::length( $this ) > 1024 ? ( CORE::substr( $this, 0, 1024 ) . '...' ) : $this ) . "'." );
        }
        
        $children->foreach(sub
        {
            $_->parent( $self );
        });
        $self->children( $children );
        $self->reset(1);
        return(1);
    }
}, @_ ) ); }

# Note: inputMode -> property
sub inputMode : lvalue { return( shift->_set_get_property( 'inputMode', @_ ) ); }

sub insertAdjacentElement
{
    my $self = shift( @_ );
    my( $pos, $elem ) = @_;
    return( $self->error({
        message => 'No position was provided',
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !defined( $pos ) || !CORE::length( "$pos" ) );
    # Return error if the element provided is either undefined , or an empty string
    return( $self->error({
        message => "No element was provided.",
        code => 500,
        class => 'HTML::Object::TypeError',
    }) ) if( !defined( $elem ) || ( !ref( $elem ) && !CORE::length( $elem ) ) );
    $pos = lc( "$pos" );
    # Error if the position string provided is of an unknown value.
    return( $self->error({
        message => "Position provided \"$pos\" is not a recognised value. Use beforebegin, afterbegin, beforeend or afterend",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( $pos !~ /^(?:beforebegin|afterbegin|beforeend|afterend)$/ );
    # Error if the element value provided is not an element object.
    return( $self->error({
        message => "Element provided (" . overload::StrVal( $elem ) . ") is not an HTML::Object::DOM::Element object.",
        code => 500,
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $elem => 'HTML::Object::DOM::Element' ) );
    my $parent = $self->parent;
    return( $self->error({
        message => "Current object has no parent, so the provided element cannot be inserted before or after it.",
        code => 500,
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !$parent && ( $pos eq 'beforebegin' || $pos eq 'afterend' ) );
    if( $pos eq 'beforebegin' )
    {
        my $offset = $parent->children->pos( $self );
        if( !defined( $offset ) )
        {
            return( $self->error({
                message => "The current element (" . overload::StrVal( $self ) . ") could not be found in its parent element (" . overload::StrVal( $parent ) . ") whose tag is \"" . $parent->tag . "\".",
                code => 500,
                class => 'HTML::Object::HierarchyRequestError',
            }) );
        }
        else
        {
            $parent->splice( $offset, 0, $elem );
        }
    }
    elsif( $pos eq 'beforeend' )
    {
        $self->children->push( $elem );
    }
    elsif( $pos eq 'afterbegin' )
    {
        $self->children->unshift( $elem );
    }
    elsif( $pos eq 'afterend' )
    {
        my $offset = $parent->children->pos( $self );
        if( !defined( $offset ) )
        {
            return( $self->error({
                message => "The current element (" . overload::StrVal( $self ) . ") could not be found in its parent element (" . overload::StrVal( $parent ) . ") whose tag is \"" . $parent->tag . "\".",
                code => 500,
                class => 'HTML::Object::HierarchyRequestError',
            }) );
        }
        $parent->splice( ++$offset, 0, $elem );
    }
    return( $elem );
}

sub insertAdjacentHTML
{
    my $self = shift( @_ );
    my( $pos, $html ) = @_;
    return( $self->error({
        message => 'No position was provided',
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !defined( $pos ) || !CORE::length( "$pos" ) );
    # Return error if the element provided is either undefined , or an empty string
    return( $self->error({
        message => "No html string was provided to insert.",
        code => 500,
        class => 'HTML::Object::TypeError',
    }) ) if( !defined( $html ) || !CORE::length( "$html" ) );
    return( $self->error({
        message => "A reference (" . ref( $html ) . ") was provided instead of an HTML string.",
        code => 500,
        class => 'HTML::Object::TypeError',
    }) ) if( ref( $html ) && !overload::Method( $html, '""' ) );
    $html = "$html";
    my $p = $self->new_parser || return( $self->pass_error );
    my $doc = $p->parse_data( $html ) || return( $self->pass_error( $p->error ) );
    my $parent = $self->parent;
    return( $self->error({
        message => "Current object has no parent, so the provided html nodes cannot be inserted before or after it.",
        code => 500,
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !$parent && ( $pos eq 'beforebegin' || $pos eq 'afterend' ) );
    if( $pos eq 'beforebegin' )
    {
        my $offset = $parent->children->pos( $self );
        if( !defined( $offset ) )
        {
            return( $self->error({
                message => "The current element (" . overload::StrVal( $self ) . ") could not be found in its parent element (" . overload::StrVal( $parent ) . ") whose tag is \"" . $parent->tag . "\".",
                code => 500,
                class => 'HTML::Object::HierarchyRequestError',
            }) );
        }
        $doc->children->foreach(sub
        {
            my $elem = shift( @_ );
            $elem->parent( $parent );
            $parent->children->splice( $offset, 0, $elem );
            $offset++;
        });
    }
    elsif( $pos eq 'beforeend' )
    {
        $doc->children->foreach(sub
        {
            my $elem = shift( @_ );
            $elem->parent( $self );
            $self->children->push( $elem );
        });
    }
    elsif( $pos eq 'afterbegin' )
    {
        my $offset = -1;
        $doc->children->foreach(sub
        {
            my $elem = shift( @_ );
            $elem->parent( $self );
            $self->children->splice( ++$offset, 0, $elem );
        });
        # $self->children->unshift( $elem );
    }
    elsif( $pos eq 'afterend' )
    {
        my $offset = $parent->children->pos( $self );
        if( !defined( $offset ) )
        {
            return( $self->error({
                message => "The current element (" . overload::StrVal( $self ) . ") could not be found in its parent element (" . overload::StrVal( $parent ) . ") whose tag is \"" . $parent->tag . "\".",
                code => 500,
                class => 'HTML::Object::HierarchyRequestError',
            }) );
        }
        $doc->children->foreach(sub
        {
            my $elem = shift( @_ );
            $elem->parent( $parent );
            $parent->children->splice( ++$offset, 0, $elem );
        });
    }
    return( $doc->children );
}

sub insertAdjacentText
{
    my $self = shift( @_ );
    my $pos  = shift( @_ );
    return( $self->error({
        message => 'No position was provided',
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !defined( $pos ) || !CORE::length( "$pos" ) );
    my $text;
    if( !scalar( @_ ) || 
        ( scalar( @_ ) == 1 && !defined( $_[0] ) ) ||
        ( scalar( @_ ) > 1 && !CORE::length( $text = join( '', @_ ) ) ) )
    {
        return( $self->error({
            message => "No text was provided.",
            code => 500,
            class => 'HTML::Object::TypeError',
        }) );
    }
    return( $self->error({
        message => "A reference (" . ref( $text ) . ") was provided instead of an text string.",
        code => 500,
        class => 'HTML::Object::TypeError',
    }) ) if( ref( $text ) && !overload::Method( $text, '""' ) );
    my $node = $self->new_text( value => "$text" );
    my $parent = $self->parent;
    return( $self->error({
        message => "Current object has no parent, so the provided text cannot be inserted before or after it.",
        code => 500,
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !$parent && ( $pos eq 'beforebegin' || $pos eq 'afterend' ) );
    if( $pos eq 'beforebegin' )
    {
        my $offset = $parent->children->pos( $self );
        if( !defined( $offset ) )
        {
            return( $self->error({
                message => "The current element (" . overload::StrVal( $self ) . ") could not be found in its parent element (" . overload::StrVal( $parent ) . ") whose tag is \"" . $parent->tag . "\".",
                code => 500,
                class => 'HTML::Object::HierarchyRequestError',
            }) );
        }
        else
        {
            $parent->splice( $offset, 0, $node );
        }
    }
    elsif( $pos eq 'beforeend' )
    {
        $self->children->push( $node );
    }
    elsif( $pos eq 'afterbegin' )
    {
        $self->children->unshift( $node );
    }
    elsif( $pos eq 'afterend' )
    {
        my $offset = $parent->children->pos( $self );
        if( !defined( $offset ) )
        {
            return( $self->error({
                message => "The current element (" . overload::StrVal( $self ) . ") could not be found in its parent element (" . overload::StrVal( $parent ) . ") whose tag is \"" . $parent->tag . "\".",
                code => 500,
                class => 'HTML::Object::HierarchyRequestError',
            }) );
        }
        $parent->splice( ++$offset, 0, $node );
    }
    return( $node );
}

sub is_inside
{
    my $self = shift( @_ );
    return( 0 ) if( !scalar( @_ ) );
    my @elems = @_;
    my @literals = ();
    for( my $i = 0; $i < scalar( @elems ); $i++ )
    {
        return( $self->error( "The element provided (", overload::StrVal( $elems[$i] ), ") is not an HTML::Object::Element object." ) ) if( ref( $elems[$i] ) && ( !$self->_is_object( $elems[$i] ) || !$elems[$i]->isa( 'HTML::Object::Element' ) ) );
        push( @literals, splice( @elems, $i, 1 ) ) if( !ref( $elems[$i] ) );
    }
    # We need to ensure the literals provided, if any, are in lowercase
    # @$lit{ @literals } = (1) x scalar( @literals );
    my $lit = +{ map( lc( $_ ), @literals ) };
    my $obj = +{ map{ $_->eid => 1 } @elems };
    my $parent = $self;
    # Check if ourself for any of our parent are a match of any of the element given
    while( $parent )
    {
        return( 1 ) if( exists( $obj->{ $parent->eid } ) || exists( $lit->{ $parent->tag } ) );
        $parent = $parent->parent;
    }
    return( 0 );
}

sub isAttributeNode { return(0); }

sub isCommentNode { return( shift->tag CORE::eq '_comment' ? 1 : 0 ); }

sub isContentEditable
{
    my $self = shift( @_ );
    return( $self->contentEditable ? $self->true : $self->false );
}

sub isElementNode { return( shift->tag->substr( 0, 1 ) CORE::eq '_' ? 0 : 1 ); }

sub isNamespaceNode { return(0); }

sub isPINode        { return(0); }

sub isProcessingInstructionNode { return( shift->tag CORE::eq '_pi' ? 1 : 0 ); }

sub isTextNode { return( shift->tag CORE::eq '_text' ? 1 : 0 ); }

# Note: lang  -> property
sub lang : lvalue { return( shift->_set_get_property( 'lang', @_ ) ); }

sub lastElementChild
{
    my $self = shift( @_ );
    my $children = $self->children;
    my $elem;
    $children->reverse->foreach(sub
    {
        if( $_->isa( 'HTML::Object::DOM::Element' ) )
        {
            $elem = $_;
            return;
        }
        return(1);
    });
    return( $self->new_null ) if( !defined( $elem ) );
    return( $elem );
}

sub localName { return( shift->getName ); }

sub matches
{
    my $self = shift( @_ );
    my $selector = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $params = {};
    # The only supported parameter by HTML::Selector::XPath
    $params->{root} = CORE::delete( $opts->{root} ) if( CORE::exists( $opts->{root} ) );
    if( !$self->{_xp} )
    {
        $self->_load_class( 'HTML::Object::XPath' ) ||
            return( $self->pass_error );
        my $xp = HTML::Object::XPath->new;
        $self->{_xp} = $xp;
    }
    $self->_load_class( 'HTML::Selector::XPath', { version => '0.20' } ) ||
        return( $self->pass_error );
    my $xpath;
    try
    {
        my $sel = HTML::Selector::XPath->new( $selector, %$params );
        $xpath = $sel->to_xpath( %$params );
    }
    catch( $e )
    {
        return( $self->error( "Error trying to get the xpath value for selector \"$selector\": $e" ) );
    }
    my $xp = $self->{_xp};
    $self->message( 4, "Calling xp->matches for xpath '$xpath' with context '", $self->as_string, "'" ); 
    return( $xp->matches( $self, $xpath, $self ) );
}

sub namespaceURI { return; }

sub new_attribute
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::Attribute' ) || return( $self->pass_error );
    my $att = HTML::Object::DOM::Attribute->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Attribute->error ) );
    return( $att );
}

sub new_closing
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::Closing' ) || return( $self->pass_error );
    my $e = HTML::Object::DOM::Closing->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Closing->error ) );
    return( $e );
}

sub new_collection
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::Collection' ) || return( $self->pass_error );
    my $e = HTML::Object::DOM::Collection->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Collection->error ) );
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

sub new_document
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::Document' ) || return( $self->pass_error );
    my $e = HTML::Object::DOM::Document->new( debug => $self->debug ) ||
        return( $self->pass_error( HTML::Object::DOM::Document->error ) );
    return( $e );
}

sub new_element
{
    my $self = shift( @_ );
    my $tag  = shift( @_ ) || return( $self->error( "No tag was provided to create an element." ) );
    my $dict = HTML::Object->get_definition( $tag ) || return( $self->pass_error( HTML::Object->error ) );
    my $e = HTML::Object::DOM::Element->new({
        is_empty    => $dict->{is_empty},
        tag         => $dict->{tag},
        debug       => $self->debug,
    }) || return( $self->pass_error( HTML::Object::DOM::Element->error ) );
    return( $e );
}

sub new_nodelist
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::NodeList' ) || return( $self->pass_error );
    my $list = HTML::Object::DOM::NodeList->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::NodeList->error ) );
    return( $list );
}

sub new_parser
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM' ) || return( $self->pass_error );
    my $p = HTML::Object::DOM->new( debug => $self->debug ) ||
        return( $self->pass_error( HTML::Object::DOM->error ) );
    return( $p );
}

sub new_space
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::Space' ) || return( $self->pass_error );
    my $e = HTML::Object::DOM::Space->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Space->error ) );
    return( $e );
}

sub new_text
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::Text' ) || return( $self->pass_error );
    my $e = HTML::Object::DOM::Text->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Text->error ) );
    return( $e );
}

sub nextElementSibling
{
    my $self = shift( @_ );
    my $all = $self->right;
    for( my $i = 0; $i < scalar( @$all ); $i++ )
    {
        return( $all->[$i] ) if( $self->_is_a( $all->[$i] => 'HTML::Object::DOM::Element' ) );
    }
    return( $self->new_null );
}

# Note: noModule -> property
sub noModule : lvalue { return( shift->_set_get_property( { attribute => 'noModule', is_boolean => 1 }, @_ ) ); }

# Note: nonce -> property
sub nonce : lvalue { return( shift->_set_get_property( 'nonce', @_ ) ); }

# Note: offsetHeight -> property
sub offsetHeight : lvalue { return( shift->_set_get_property( 'offsetheight', @_ ) ); }

# Note: offsetLeft -> property
sub offsetLeft : lvalue { return( shift->_set_get_property( 'offsetleft', @_ ) ); }

# Note: offsetParent -> property
sub offsetParent { return( shift->parent( @_ ) ); }

# Note: offsetTop -> property
sub offsetTop : lvalue { return( shift->_set_get_property( 'offsettop', @_ ) ); }

# Note: offsetWidth -> property
sub offsetWidth : lvalue { return( shift->_set_get_property( 'offsetwidth', @_ ) ); }

sub onerror : lvalue { return( shift->_set_get_code( '_error_handler', @_ ) ); }

# Note: Property
sub outerHTML : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        return( $self->as_string );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $this = shift( @_ );
        my $children;
        my $pos;
        my $parent = $self->parent;
        $pos = $parent->children->pos( $self ) if( $parent );
        my $dummy;
        if( !ref( $this ) ||
            ( ref( $this ) && overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) )
        {
            # User provided an empty string, so we just remove the element
            if( !CORE::length( $this ) )
            {
                if( defined( $pos ) )
                {
                    $parent->children->splice( $pos, 0 );
                    # If this element has a closing tag in the dom, we remove it too
                    if( my $close = $self->close_tag )
                    {
                        $parent->children->remove( $close );
                        $close->parent( undef );
                    }
                    $self->parent( undef );
                    $self->parent->reset(1);
                    $dummy = 1;
                }
                # Fallback
                else
                {
                    $dummy = 0;
                }
                return( $dummy );
            }
            else
            {
                my $p = $self->new_parser;
                my $res = $p->parse_data( "$this" ) ||
                return( $self->error( "Error while parsing html data provided: ", $p->error ) );
                $children = $res->children;
                if( !$children->is_empty && defined( $pos ) )
                {
                    $children->foreach(sub
                    {
                        $_->parent( $parent );
                    });
                    $parent->children->splice( $pos, 1, $children->list );
                    # If this element has a closing tag in the dom, we remove it too
                    if( my $close = $self->close_tag )
                    {
                        $parent->children->remove( $close );
                        $close->parent( undef );
                    }
                    $parent->reset(1);
                    $dummy = 1;
                }
                else
                {
                    $dummy = 0;
                }
                return( $dummy );
            }
        }
        # We are provided with an element, so we set it as our inner html
        elsif( $self->_is_a( $this => 'HTML::Object::Element' ) )
        {
            # If a HTML::Object::DOM::DocumentFragment object is provided, its children are 
            # copied to the list and its own children array is emptied.
            if( $self->_is_a( $this => 'HTML::Object::DOM::DocumentFragment' ) )
            {
                my $copy = $this->children->clone;
                $this->children->reset;
                if( defined( $pos ) )
                {
                    $parent->children->splice( $pos, 1, $copy->list );
                    $copy->children->foreach(sub
                    {
                        $_->parent( $parent );
                    });
                    # The element itself is being replace, so we remove out own parent
                    $self->parent->reset(1);
                    $self->parent( undef );
                    # If this element has a closing tag in the dom, we remove it too
                    if( my $close = $self->close_tag )
                    {
                        $parent->children->remove( $close );
                        $close->parent( undef );
                    }
                    $dummy = 1;
                }
                else
                {
                    $dummy = 0;
                }
            }
            else
            {
                my $child = $this->clone;
                if( defined( $pos ) )
                {
                    $parent->children->splice( $pos, 1, $child );
                    # Add the closing tag if any
                    if( my $close = $child->close_tag )
                    {
                        $parent->children->splice( $pos + 1, 0, $close );
                        # $parent->children->splice( 2, 0, $close );
                    }
                    $child->parent( $parent );
                    # The element itself is being replace, so we remove out own parent
                    $self->parent->reset(1);
                    $self->parent( undef );
                    # If this element has a closing tag in the dom, we remove it too
                    if( my $close = $self->close_tag )
                    {
                        $parent->children->remove( $close );
                        $close->parent( undef );
                    }
                    $dummy = 1;
                }
                else
                {
                    $dummy = 0;
                }
            }
            return( $dummy );
        }
        else
        {
            die( "I was expecting some html data in replacement of html for this element \"" . $self->tag . "\", but instead got '" . ( CORE::length( $this ) > 1024 ? ( CORE::substr( $this, 0, 1024 ) . '...' ) : $this ) . "'." );
        }
    }
}, @_ ) ); }

# Note: outerText -> property
sub outerText : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        # Create a new document, because we want to use the document object as_string function which produce a string of its children, and no need to reproduce it here
        my $txt = $self->as_trimmed_text;
        my $obj = $self->new_scalar( \$txt );
        return( $obj );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $this = shift( @_ );
        my $element;
        # We are provided with an element, so we set it as our inner html
        if( $self->_is_a( $this => 'HTML::Object::DOM::Text' ) )
        {
            $element = $this->clone;
        }
        elsif( !ref( $this ) ||
               ( ref( $this ) && overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) )
        {
            $this =~ s,\n,<br />\n,gs;
            $element = $self->new_text( value => $this ) || die( $self->error );
        }
        else
        {
            die( "I was expecting some text data in replacement of html for this element \"" . $self->tag . "\", but instead got '" . ( CORE::length( $this ) > 1024 ? ( CORE::substr( $this, 0, 1024 ) . '...' ) : $this ) . "'." );
        }
        
        my $parent = $self->parent;
        my $pos = $parent->children->pos( $self );
        if( !defined( $pos ) )
        {
            die( "Unable to find the current element among its parent's children." );
        }
        
        $element->parent( $parent );
        $parent->splice( $pos, 1, $element );
        $self->parent( undef() );
        $parent->reset(1);
        my $dummy = 'dummy';
        return( $dummy );
    }
}, @_ ) ); }

# Note: popover  -> property
sub popover : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        my $val = $self->_set_get_property( 'popover' );
        return( $val ) if( defined( $val ) );
        return( $self->root->_set_get_property( 'popover' ) );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $arg = shift( @_ );
        $self->_set_get_property( 'popover', $arg );
        return( $arg );
    }
}, @_ ) ); }

sub prefix { return; }

sub prepend
{
    my $self = shift( @_ );
    return( $self->error({
        message => "No data to prepend was provided.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !scalar( @_ ) );
    # If a HTML::Object::DOM::DocumentFragment object is provided, its children are 
    # copied to the list and its own children array is emptied.
    my $list = $self->_get_from_list_of_elements_or_html( @_ );
    my $children = $self->children;
    my $pos = -1;
    $list->foreach(sub
    {
        $_->parent( $self );
        $children->splice( ++$pos, 0, $_ );
    });
    $self->reset(1);
    return( $list );
}

sub previousElementSibling
{
    my $self = shift( @_ );
    my $all = $self->left->reverse;
    for( my $i = 0; $i < scalar( @$all ); $i++ )
    {
        return( $all->[$i] ) if( $self->_is_a( $all->[$i] => 'HTML::Object::DOM::Element' ) );
    }
    return( $self->new_null );
}

# Note: properties -> property experimental
sub properties { return( shift->new_array ); }

sub querySelector
{
    my $self = shift( @_ );
    my @sels = @_;
    return( $self->error({
        message => "No CSS selector was provided to query.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !scalar( @sels ) );
    
    foreach my $sel ( @sels )
    {
        my $results = $self->find( $sel, { root => '.' } ) || 
            return( $self->pass_error({ class => 'HTML::Object::SyntaxError' }) );
        return( $results->first ) if( !$results->is_empty );
    }
    return( $self->new_null );
}

sub querySelectorAll
{
    my $self = shift( @_ );
    my @sels = @_;
    return( $self->error({
        message => "No CSS selector was provided to query.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !scalar( @sels ) );
    
    my $results = $self->new_array;
    foreach my $sel ( @sels )
    {
        my $elems = $self->find( $sel, { root => './' } ) ||
            return( $self->pass_error({ class => 'HTML::Object::SyntaxError' }) );
        $results->push( $elems->list ) if( !$elems->is_empty );
    }
    $results->unique(1);
    return( $results );
}

sub remove
{
    my $self = shift( @_ );
    my $parent = $self->parent;
    return( $self->error({
        message => "This element has no parent, and thus cannot be removed.",
        code => 500,
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !$parent );
    my $pos = $parent->children->pos( $self );
    return( $self->error({
        message => "This element could not be found among its parent's children.",
        code => 500,
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $pos ) );
    $parent->children->splice( $pos, 1 );
    $parent->reset(1);
    return( $self->true );
}

sub removeAttribute
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    return( $self->error({
        message => "No attribute name was provided.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !defined( $name ) || !CORE::length( $name ) );
    if( $self->attributes->has( $name ) )
    {
        $self->attributes->remove( $name );
        $self->attributes_sequence->remove( $name );
        return( $self );
    }
    return;
}

sub removeAttributeNode
{
    my $self = shift( @_ );
    my $node = shift( @_ ) || return( $self->error({
        message => "No attribute node was provided to remove.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) );
    return( $self->error({
        message => "Object provided is not an attribute node.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !$self->_is_a( $node => 'HTML::Object::DOM::Attribute' ) );
    my $name = $node->name;
    return( $self->error({
        message => "Attribute node provided has no name value.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( $name->is_empty );
    return( $self->removeAttribute( $name ) );
}

sub removeAttributeNS { return; }

sub replaceChildren
{
    my $self = shift( @_ );
    my $results = $self->new_array;
    my $children = $self->children;
    if( !scalar( @_ ) )
    {
        $results->push( $children->list );
        $children->reset;
        $results->foreach(sub
        {
            $_->parent( undef );
        });
        return( $results );
    }
    my $new = $self->_list_to_nodes( @_ ) || return( $self->pass_error({ class => 'HTML::Object::SyntaxError' }) );
    
    # We take some care to keep the same original array, so that if it is used or 
    # referenced elsewhere it continues to be valid, as a 'live' array of (new) elements
    $children->foreach(sub
    {
        $_->parent( undef() );
    });
    $results->push( $children->list );
    # We empty it, and pu the new content inside
    $children->reset;  
    
    $new->foreach(sub
    {
        $_->parent( $self );
        $children->push( $_ );
    });
    # Return the old set
    return( $results );
}

sub replaceWith
{
    my $self = shift( @_ );
    return( $self->error({
        message => "No data was provided to replace this element.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !scalar( @_ ) );
    my $parent = $self->parent;
    return( $self->error({
        message => "Current object does not have a parent",
        code => 500,
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !$parent );
    my $new = $self->_list_to_nodes( @_ ) || return( $self->pass_error({ class => 'HTML::Object::SyntaxError' }) );
    my $pos = $parent->children->pos( $self );
    $parent->children->splice( $pos, 1, $new->list );
    $new->foreach(sub
    {
        $_->parent( $parent );
    });
    return( $new );
}

sub scrollHeight { return; }

sub scrollLeft { return; }

sub scrollTop { return; }

sub scrollWidth { return; }

sub setAttribute
{
    my $self = shift( @_ );
    my( $name, $value ) = @_;
    return( $self->error({
        message => "No attribute name was provided.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !defined( $name ) || !CORE::length( $name ) );
    
    # Inherited from HTML::Object::Element
    if( !$self->is_valid_attribute( $name ) )
    {
        return( $self->error({
            message => "Attribute name provided \"$name\" contains illegal characters.",
            code => 500,
            class => 'HTML::Object::InvalidCharacterError',
        }) );
    }
    $name = lc( $name );
    
    if( !defined( $value ) )
    {
        return( $self->removeAttribute( $name ) );
    }
    $self->attributes->set( $name => $value );
    $self->attributes_sequence->push( $name ) if( !$self->attributes_sequence->has( $name ) );
    return( $self );
}

sub setAttributeNode
{
    my $self = shift( @_ );
    my $att  = shift( @_ );
    return( $self->error({
        message => "No attribute name was provided.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !defined( $att ) );
    return( $self->error({
        message => "Attribute node provided (", overload::StrVal( $att ), ") is not actually an HTML::Object::DOM::Attribute object.",
        code => 500,
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $att => 'HTML::Object::DOM::Attribute' ) );
    return( $self->error({
        message => "Attribute node object provided has no attribute name set.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !$att->name->defined || $att->name->is_empty );
    my $old = $self->getAttributeNode( $att->name );
    $self->setAttribute( $att->name, $att->value ) || return( $self->pass_error );
    return( $old );
}

# setHTML is a mutator only
sub setHTML : lvalue { return( shift->_set_get_callback({
    set => sub
    {
        my $self = shift( @_ );
        my $this = shift( @_ );
        if( !defined( $this ) || !CORE::length( $this ) )
        {
            die( "No html provided." );
        }
        
        my $children;
        if( $self->_is_a( $this => 'HTML::Object::Element' ) )
        {
            if( $self->_is_a( $this => 'HTML::Object::DOM::DocumentFragment' ) )
            {
                $children = $this->children->clone;
                $this->children->reset;
                # DocumentFragment children are not cloned, but moved as per the specification
                $children->foreach(sub
                {
                    $_->detach;
                });
            }
            else
            {
                my $clone = $this->clone;
                $children = $self->new_array( $clone );
                $children->push( $clone->close_tag ) if( $clone->close_tag );
            }
        }
        else
        {
            if( ref( $this ) && ( !$self->_is_object( $this ) || ( $self->_is_object( $this ) && !overload::Method( $this, '""' ) ) ) )
            {
                die( "I was expecting some HTML data, but got '" . overload::StrVal( $this ) . "'" );
            }
            my $p = $self->new_parser;
            my $res = $p->parse_data( "$this" ) ||
                die( "Error while parsing html data provided: " . $p->error );
            $children = $res->children;
        }
        $children->foreach(sub
        {
            $_->parent( $self );
        });
        $self->children( $children );
        return( $self );
    }
}, @_ ) ); }

sub shadowRoot { return; }

sub showPopover { return; }

# Note: spellcheck -> property
sub spellcheck : lvalue { return( shift->_set_get_property( { attribute => 'spellcheck', is_boolean => 1 }, @_ ) ); }

sub string_value
{
    my $self = shift( @_ );
    my $type = $self->nodeType;
    if( $type == TEXT_NODE || $type == COMMENT_NODE )
    {
        return( $self->value );
    }
    else
    {
        return( $self->as_text );
    }
}

# Note: style -> property
sub style { return( shift->new_hash ); }

# Note: property
sub tabIndex : lvalue { return( shift->_set_get_property( 'tabindex', @_ ) ); }

sub tagName { return( shift->getName ); }

# Note: title -> property
sub title : lvalue { return( shift->_set_get_property( 'title', @_ ) ); }

sub to_number
{
    my $self = shift( @_ );
    return( $self->new_number( $self->as_text ) );
}

# Based on the polyfill provided by Mozilla at:
# <https://developer.mozilla.org/en-US/docs/Web/API/Element/toggleAttribute>
# because, otherwise, as of 2021-12-15, the description of the use of 'force' is cryptic
sub toggleAttribute
{
    my $self = shift( @_ );
    my( $name, $force ) = @_;
    return( $self->error({
        message => "No attribute name was provided.",
        code => 500,
        class => 'HTML::Object::SyntaxError',
    }) ) if( !defined( $name ) || !CORE::length( $name ) );
    
    # Inherited from HTML::Object::Element
    if( !$self->is_valid_attribute( $name ) )
    {
        return( $self->error({
            message => "Attribute name provided \"$name\" contains illegal characters.",
            code => 500,
            class => 'HTML::Object::InvalidCharacterError',
        }) );
    }
    $name = lc( $name );
    if( $self->attribute->has( $name ) )
    {
        return( $self->true ) if( defined( $force ) && $force );
        $self->removeAttribute( $name );
        return( $self->false );
    }
    return( $self->false ) if( defined( $force ) && !$force );
    $self->setAttribute( $name => '' );
    return( $self->true );
}

sub togglePopover { return; }

sub toString { return( shift->as_string ); }

# Note: translate -> property
sub translate : lvalue { return( shift->_set_get_property( { attribute => 'translate', is_boolean => 1 }, @_ ) ); }

# Used by HTML::Object::DOM::Element::*
sub _get_parent_form { return( shift->closest( 'form' ) ); }

# Note: moved _list_to_nodes to HTML::Object::DOM::Node to make it also available to HTML::Object::DOM::Declaration

# Used by HTML::Object::DOM::Element::Anchor and HTML::Object::DOM::Element::Area
sub _set_get_anchor_uri
{
    my $self = shift( @_ );
    my $link = $self->href;
    # We constantly get a new URI object, because the value of the href attribute may have been altered by other means
    try
    {
        return( $link ) if( $self->_is_a( $link => 'URI' ) );
        return( ( defined( $link ) && CORE::length( "$link" ) ) ? URI->new( $link ) : URI->new );
    }
    catch( $e )
    {
        return( $self->error( "Unable to create a URI object from \"$link\" (", overload::StrVal( $link ), "): $e" ) );
    }
}

sub _set_get_form_attribute : lvalue
{
    my $self = shift( @_ );
    my $attr = shift( @_ );

    return( $self->_set_get_callback({
        get => sub
        {
            my $form = $self->_get_parent_form;
            if( !defined( $form ) )
            {
                return;
            }
            my $code = $form->can( $attr );
            if( !defined( $code ) )
            {
                die( "Form object has no method \"$attr\"." );
            }
            
            my $rv = $code->( $form );
            return( $rv );
        },
        set => sub
        {
            my $arg = shift( @_ );
            my $ctx = $_;
            my $form = $self->_get_parent_form;
            if( !defined( $form ) )
            {
                return;
            }
            my $code = $form->can( $attr );
            if( !defined( $code ) )
            {
                die( "Form object has no method \"$attr\"." );
            }
            
            $code->( $form, $arg );
            return( $arg ) if( $ctx->{assign} );
            return( $self );
        },
    }, @_ ) );
}

# _set_get_property has been moved up in HTML::Object::Element
# Note: private method to set or get attribute as an lvalue method for DOM properties in HTML::Object::DOM::Element::* and also for some DOM List abstract class like HTML::Object::DOM::List
sub _set_get_property : lvalue
{
    my $self = shift( @_ );
    my $attr = shift( @_ );
    
    my $def = {};
    # If the $attr parameter is an hash reference, it is used to provide more information
    # such as whether this property is a boolean
    if( ref( $attr ) eq 'HASH' )
    {
        $def = $attr;
        $attr = $def->{attribute};
    }
    $def->{is_boolean} //= 0;
    
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            if( $def->{is_datetime} )
            {
                my $val = $self->attr( $attr );
                try
                {
                    my $dt = $self->_parse_timestamp( $val );
                    return( $self->pass_error ) if( !defined( $dt ) );
                    return( $dt );
                }
                catch( $e )
                {
                    return( $self->error( "Unable to parse datetime value \"$val\": $e" ) );
                }
            }
            elsif( $def->{is_number} )
            {
                my $val = $self->attr( $attr );
                return if( !$self->_is_number( $val ) );
                if( $val =~ /^(\d{1,10})(?:\.\d+)?$/ )
                {
                    my $dt = $self->_parse_timestamp( $val );
                    return( $dt ) if( ref( $dt ) );
                }
                return( $self->new_number( $val ) );
            }
            elsif( $def->{is_uri} )
            {
                my $val = $self->attr( $attr );
                # We constantly get a new URI object, because the value of the href attribute may have been altered by other means
                try
                {
                    return( $val ) if( $self->_is_a( $val => 'URI' ) );
                    return if( !defined( $val ) );
                    return( $val ) if( !CORE::length( "$val" ) );
                    return( URI->new( "$val" ) );
                }
                catch( $e )
                {
                    return( $self->error( "Unable to create a URI object from \"$val\" (", overload::StrVal( $val ), "): $e" ) );
                }
            }
            elsif( $def->{callback} && ref( $def->{callback} ) eq 'CODE' )
            {
                return( $def->{callback}->( $self, $attr ) );
            }
            return( $self->attr( $attr ) );
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            if( $def->{is_boolean} )
            {
                # Any true value works, even in the web browser
                if( $arg )
                {
                    # it is ok to set an empty value
                    $self->attr( $attr => '' );
                }
                else
                {
                    # Passing undef implies it will be removed. See HTML::Object::Element
                    $self->attr( $attr => undef );
                }
            }
            elsif( $def->{is_datetime} )
            {
                $self->attr( $attr => "$arg" );
            }
            # form target
            elsif( $def->{is_uri} )
            {
                try
                {
                    my $uri = URI->new( $arg );
                    $self->attr( $attr => $uri );
                }
                catch( $e )
                {
                    die( "Unable to create an URI with \"$arg\": $e" );
                }
            }
            # Used for <option>
            elsif( $def->{callback} && ref( $def->{callback} ) eq 'CODE' )
            {
                $def->{callback}->( $self, $attr => $arg );
            }
            else
            {
                $self->attr( $attr => $arg );
            }
            $self->reset(1);
            return( $arg );
        }
    }, @_ ) );
}

# Used by HTML::Object::DOM::Element::Anchor and HTML::Object::DOM::Element::Area
sub _set_get_uri_property : lvalue
{
    my $self = shift( @_ );
    my $prop = shift( @_ );
    my $uri  = $self->_set_get_anchor_uri;
    my $map = 
    {
    hash        => 'fragment',
    # URI's host_port is tolerant just like DOM's host is. Even if no port is provided, it will not complain
    host        => 'host_port',
    hostname    => 'host',
    pathname    => 'path',
    password    => 'userinfo',
    protocol    => 'scheme',
    search      => 'query',
    username    => 'userinfo',
    };
    
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            # If there is an URI, we use it as a alue storage
            # It is convenient and let the user modify it directly if he wants.
            if( ref( $uri ) )
            {
                try
                {
                    my $meth = exists( $map->{ $prop } ) ? $map->{ $prop } : $prop;
                    my $code = $uri->can( $meth );
                    # User trying to access URI method like host port, etc on a generic URI
                    # which is ok for method like path, query, fragment
                    # So we convert what would otherwise be an error into an undef returned, meaning no value
                    if( !defined( $code ) )
                    {
                        if( $uri->isa( 'URI::_generic' ) )
                        {
                            return( $self->{ $prop } );
                        }
                        else
                        {
                            return( $self->error( "URI object has no method \"$meth\"." ) );
                        }
                    }
                    my $val = $code->( $uri );
                    # We assign the value from the URI method in case, the user would have modified the URI object directly
                    # We need to stay synchronised.
                    if( $prop eq 'username' || $prop eq 'password' )
                    {
                        if( defined( $val ) )
                        {
                            @$self{qw( username password )} = split( /:/, $val, 2 );
                        }
                        else
                        {
                            $self->{username} = undef;
                            $self->{password} = undef;
                        }
                        return( $self->{ $prop } );
                    }
                    # We add back the colon, because URI stores the scheme without it, but our 'protocol' method returns the scheme with it.
                    elsif( $prop eq 'protocol' )
                    {
                        $val .= ':' if( defined( $val ) );
                    }
                    elsif( $prop eq 'hash' )
                    {
                        substr( $val, 0, 0, '#' ) if( defined( $val ) );
                    }
                    elsif( $prop eq 'search' )
                    {
                        substr( $val, 0, 0, '?' ) if( defined( $val ) );
                    }
                    return( $self->{ $prop } = $val );
                }
                catch( $e )
                {
                    die( "Unable to get value for URI method \"${prop}\": $e" );
                }
            }
            return( $self->{ $prop } );
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            $self->{ $prop } = $arg;
            if( ref( $uri ) )
            {
                my $uri_class = ref( $uri ); # URI::https or maybe URI::_generic ?
                try
                {
                    if( $prop eq 'username' || $prop eq 'password' )
                    {
                        no warnings 'uninitialized';
                        $arg = join( ':', @$self{ qw( username password ) } );
                    }
                    elsif( $prop eq 'protocol' )
                    {
                        # Remove the trailing colon, because URI scheme method takes it without it
                        $arg =~ s/\:$//;
                    }
                    elsif( $prop eq 'hash' )
                    {
                        $arg =~ s/^\#//;
                    }
                    elsif( $prop eq 'search' )
                    {
                        $arg =~ s/^\?//;
                    }
                    my $meth = exists( $map->{ $prop } ) ? $map->{ $prop } : $prop;
                    my $code = $uri->can( $meth );
                    # User trying to access URI method like host port, etc on a generic URI
                    # which is ok for method like path, query, fragment
                    # So we convert what would otherwise be an error into an undef returned, meaning no value
                    if( !defined( $code ) )
                    {
                        if( $uri->isa( 'URI::_generic' ) )
                        {
                            return( $self->{ $prop } );
                        }
                        else
                        {
                            return( $self->error( "URI object has no method \"$meth\"." ) );
                        }
                    }
                    $code->( $uri, $arg );
                    # If the URI object was generic and we switched it to a non-generic one by setting the schem
                    # We also set other properties if we have them
                    if( $prop eq 'protocol' && $uri_class eq 'URI::_generic' )
                    {
                        if( $self->{hostname} )
                        {
                            $uri->host_port( $self->{hostname} );
                        }
                        elsif( $self->{host} || $self->{port} )
                        {
                            $uri->host( $self->{host} ) if( $self->{host} );
                            $uri->port( $self->{port} ) if( $self->{port} );
                        }
                        if( $self->{username} || $self->{password} )
                        {
                            $uri->userinfo( join( ':', @$self{qw( username password )} ) );
                        }
                    }
                    $self->attr( href => $uri );
                }
                catch( $e )
                {
                    die( "Unable to set value \"${arg}\" for URI method \"${prop}\": $e" );
                }
            }
            $self->reset(1);
            $self->{ $prop } = $arg;
            $self->attr( href => $uri );
            return( $arg );
        }
    }, @_ ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element - HTML Object

=head1 SYNOPSIS

    use HTML::Object::DOM::Element;
    my $this = HTML::Object::DOM::Element->new || 
        die( HTML::Object::DOM::Element->error, "\n" );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This module represents an HTML element and contains also all the methods for L<DOM nodes|https://developer.mozilla.org/en-US/docs/Web/API/Node>. It is inherited by all other element objects in a L<document|HTML::Object::Document>.

This module inherits from L<HTML::Object::Node> and is extended by L<HTML::Object::XQuery>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+

=head1 PROPERTIES

All the following properties can be used as lvalue method as well as regular method. For example with L</baseURI>

=head2 accessKey

A string representing the access key assigned to the element.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/accessKey> for more information.

=head2 accessKeyLabel

    my $label = $element->accessKeyLabel;

    my $btn = $document->getElementById("btn1");
    my $shortcutLabel = $btn->accessKeyLabel || $btn->accessKey;
    $btn->title .= " [" . uc( $shortcutLabel ) . "]";

Read-only

Returns a string containing the element's assigned access key.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/accessKeyLabel> for more information.

=head2 attributeStyleMap

Sets or gets the C<style> attribute.

Normally, this is read-only, and represents a C<StylePropertyMap> representing the declarations of the element's style attribute.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/attributeStyleMap> for more information.

=head2 baseURI

    # Get the base uri, if any
    my $uri = $e->baseURI;
    $e->baseURI = 'https://example.org/some/where';
    # or
    $e->baseURI( 'https://example.org/some/where' );

Read-only

This returns an L<URI> object representing the base URL of the document containing the Node, if any.

=head2 childElementCount

Read-only

Returns the number of child elements of this element.

=head2 childNodes

Read-only

This returns an L<array object|Module::Generic::Array> containing all the children of this node (including elements, text and comments). This list being live means that if the children of the Node change, the L<list object|Module::Generic::Array> is automatically updated.

=head2 classList

The C<classList> property is a read-only property that returns a live L<HTML::Object::TokenList> collection of the class attributes of the element. This can then be used to manipulate the class list.

Using classList is a convenient alternative to accessing an element's list of classes as a space-delimited string via L</className>

It returns a L<HTML::Object::TokenList> object representing the contents of the element's class attribute. If the class attribute is not set or empty, it returns an empty L<HTML::Object::TokenList>, i.e. a L<HTML::Object::TokenList> with the L<length|HTML::Object::TokenList/length> property equal to 0.

Although the classList property itself is read-only, you can modify its associated L<HTML::Object::TokenList> using the L<add()|HTML::Object::TokenList/add>, L<remove()|HTML::Object::TokenList/add>, L<replace()|HTML::Object::TokenList/add>, and L<toggle()|HTML::Object::TokenList/add> methods.

For example:

    my $div = $doc->createElement('div');
    # use the classList API to remove and add classes
    $div->classList->remove("foo");
    $div->classList->add("anotherclass");
    say $div->outerHTML; # <div class="anotherclass"></div>
    # if visible is set remove it, otherwise add it
    $div->classList->toggle("visible");
    $div->classList->contains("foo");
    # add or remove multiple classes
    $div->classList->add("foo", "bar", "baz");
    $div->classList->remove("foo", "bar", "baz");
    # replace class "foo" with class "bar"
    $div->classList->replace("foo", "bar");

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Element/classList>

=head2 className

Set or get the element class.

Returns a string representing the class of the element.

This method is an lvalue method, so you can assign value like this:

    $e->className = "my-class";

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/className>

=head2 clientHeight

Read-only.

This always return C<undef> since this has no meaning under perl.

Normally, under JavaScript, this would return a number representing the inner height of the element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/clientHeight>

=head2 clientLeft

This always return C<undef> since this has no meaning under perl.

Normally, under JavaScript, this would return a number representing the width of the left border of the element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/clientLeft>

=head2 clientTop

This always return C<undef> since this has no meaning under perl.

Normally, under JavaScript, this would return a number representing the width of the top border of the element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/clientTop>

=head2 clientWidth

This always return C<undef> since this has no meaning under perl.

Normally, under JavaScript, this would return a number representing the inner width of the element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/clientWidth>

=head2 contentEditable

Set or get the boolean value where true means the element is editable and a value of false means it is not. Defautls to true.

    $e->contentEditable = 0; # turn off content editability

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/contentEditable> for more information.

=head2 dataset

    <div id="user" data-id="1234567890" data-user="carinaanand" data-date-of-birth>
      Carina Anand
    </div>

    var $el = $document->getElementById('user');

    # $el->id eq 'user';
    # $el->dataset->id eq '1234567890';
    # $el->dataset->user eq 'carinaanand';
    # $el->dataset->dateOfBirth eq '';

    # set a data attribute
    $el->dataset->dateOfBirth = "1960-10-03";
    # <div id="user" data-id="1234567890" data-user="carinaanand" data-date-of-birth="1960-10-03">Carina Anand</div>

Read-only

Returns an L<HTML::Object::ElementDataMap> object with which script can read and write the element's custom data attributes (data-*).

The attribute name begins with data-. It can contain only letters, numbers, dashes (-), periods (.), colons (:), and underscores (_). Any ASCII capital letters (A to Z) are converted to lowercase.

Name conversion

dash-style to camelCase conversion

A custom data attribute name is transformed to a key for the DOMStringMap entry by the following:

=over 4

=item 1. Lowercase all ASCII capital letters (A to Z);

=item 2. Remove the prefix data- (including the dash);

=item 3. For any dash (U+002D) followed by an ASCII lowercase letter a to z, remove the dash and uppercase the letter;

=item 4. Other characters (including other dashes) are left unchanged.

=back

camelCase to dash-style conversion

The opposite transformation, which maps a key to an attribute name, uses the following:

=over 4

=item 1. Restriction: Before transformation, a dash must not be immediately followed by an ASCII lowercase letter a to z;

=item 2. Add the data- prefix;

=item 3. Add a dash before any ASCII uppercase letter A to Z, then lowercase the letter;

=item 4. Other characters are left unchanged.

=back

For example, a data-abc-def attribute corresponds to C<<$dataset->abcDef>>.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/dataset> for more information.

=head2 dir

    my $parg = $document->getElementById("para1");
    $parg->dir = "rtl";
    # change the text direction on a paragraph identified as "para1"

A string, reflecting the dir global attribute, representing the directionality of the element. Possible values are:

=over 4

=item * C<ltr>

for left-to-right;

=item * C<rtl>

for right-to-left;

=item * C<auto>

for specifying that the direction of the element must be determined based on the contents of the element.

=back

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/dir> for more information.

=head2 draggable

A boolean value indicating if the element can be dragged.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/draggable> for more information.

=head2 enterKeyHint

A string defining what action label (or icon) to present for the enter key on virtual keyboards.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/enterKeyHint> for more information.

=head2 firstChild

Read-only

This returns an element representing the first direct child element of the element, or C<undef> if the element has no child.

=head2 firstElementChild

Read-only.

It returns the first child element of this element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/firstElementChild>

=head2 hidden

A string or boolean value reflecting the value of the element's hidden attribute.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/hidden> for more information.

=head2 id

Set or get an string representing the id of the element.

    # Set it as a regular method
    $e->id( 'hello' );
    # Set it as a lvalue method
    $e->id = 'hello';
    # Retrieve it
    my $id = $e->id;

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/id>

=head2 innerHTML

Set or get the element's content. This returns a string representing the markup of the element's content.

Se L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/innerHTML>

=head2 inert

A boolean value indicating whether the user agent must act as though the given node is absent for the purposes of user interaction events, in-page text searches (C<find in page>), and text selection.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/inert> for more information.

=head2 innerText

Represents the rendered text content of a node and its descendants. As a getter, it approximates the text the user would get if they highlighted the contents of the element with the cursor and then copied it to the clipboard. This returns a L<string object|Module::Generic::Scalar>. As a setter, it replaces the content inside the selected element, with either a L<text object|HTML::Object::DOM::Text> or by a string converting any line breaks into C<<br />> elements.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/innerText> for more information.

=head2 inputMode

A string value reflecting the value of the element's inputmode attribute.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/inputMode> for more information.

=head2 isConnected

Returns a boolean indicating whether or not the element is connected (directly or indirectly) to the context object, i.e. the L<Document object|HTML::Object::Document> in the case of the normal DOM.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isConnected>

=head2 isContentEditable

    <p id="firstParagraph">Uneditable Paragraph</p>
    <p id="secondParagraph" contenteditable="true">Editable Paragraph</p>

    my $firstParagraph = $document->getElementById("firstParagraph");
    my $secondParagraph = $document->getElementById("secondParagraph");

Read-only

Returns a L<boolean value|HTML::Object::Boolean> indicating whether or not the content of the element can be edited. Use L<contentEditable> to change the value.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/isContentEditable> for more information.

=head2 lang

A string representing the language of an element's attributes, text, and element contents.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/lang> for more information.

=head2 lastChild

Read-only

This returns an element representing the last direct child element of the element, or C<undef> if the element has no child.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/lastChild>

=head2 lastElementChild

Read-only

Returns the last child element of this element, if any at all.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/lastElementChild>

=head2 localName

Read-only

A string representing the local part of the qualified name of the element. This is basically the tag name. This has a special meaning only when using xml, which we do not. So this is just an alias to L</getName>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/localName>

=head2 namespaceURI

Read-only

The namespace URI of the element, or C<undef> if it is no namespace.

This always return C<undef>, because as HTML, we do not deal with namespace, which is used primarily under xml.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/namespaceURI>

=head2 nextElementSibling

Read-only

Is an L<Element|HTML::Object::Element>, the element immediately following the given one in the tree, or C<undef> if there's no sibling node.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/nextElementSibling>

=head2 nextSibling

Read-only

This returns an element representing the next element in the tree, or C<undef> if there is not such element.

The next node could also be a whitespace or a text. If you want to get the next element and not just any node, use L<nextElementSibling|HTML::Object::DOM/nextElementSibling> instead.

=head2 nodeName

Read-only

This returns a string containing the name of the element. The structure of the name will differ with the element type. E.g. An L<HTML Element|HTML::Object::Element> will contain the name of the corresponding tag, like 'audio' for an HTML audio element, a L<Text|HTML::Object::Text> element will have the '#text' string, or a L<Document|HTML::Object::Document> element will have the '#document' string.

=head2 nodeType

Read-only

This returns an integer representing the type of the element. Possible values are:

=over 4

=item 1. element node

=item 2. attribute node

=item 3. text node

=item 4. CDATA section node

=item 5. unused

=item 6. unsued

=item 7. processing instruction node

=item 8. comment node

=item 9. document node

=item 10. document type node

=item 11. document fragment node

=back

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType>

=head2 nodeValue

This returns or sets the value of the current node.

For document, element or collection, this returns C<undef> and for attribute, text or comment, this sets or returns the objct value.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head2 noModule

A boolean value indicating whether an import script can be executed in user agents that support module scripts.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/noModule> for more information.

=head2 nonce

This returns nothing.

Normally, under JavaScript, this would return the cryptographic number used once that is used by Content Security Policy to determine whether a given fetch will be allowed to proceed.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/nonce> for more information.

=head2 offsetHeight

Sets or gets the property C<offsetheight>.

Normally, under JavaScript, this would be read-only and return a double containing the height of an element, relative to the layout.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/offsetHeight> for more information.

=head2 offsetLeft

Sets or gets the property C<offsetleft>.

Normally, under JavaScript, this would be read-only and return a double, the distance from this element's left border to its offsetParent's left border.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/offsetLeft> for more information.

=head2 offsetParent

Sets or gets the property C<offsetparent>.

Normally, under JavaScript, this would be read-only and return Element that is the element from which all offset calculations are currently computed.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/offsetParent> for more information.

=head2 offsetTop

Sets or gets the property C<offsettop>.

Normally, under JavaScript, this would be read-only and return a double, the distance from this element's top border to its offsetParent's top border.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/offsetTop> for more information.

=head2 offsetWidth

Sets or gets the property C<offsetwidth>.

Normally, under JavaScript, this would be read-only and return a double containing the width of an element, relative to the layout.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/offsetWidth> for more information.

=head2 outerHTML

Returns a string representing the markup of the element including its content.
When used as a setter, replaces the element with nodes parsed from the given string.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/outerHTML>

=head2 outerText

Represents the rendered text content of a node and its descendants.

As a getter, it is the same as L</innerText> (it represents the rendered text content of an element and its descendants).

As a setter, it replaces the selected node and its contents with the given value, converting any line breaks into C<<br />> elements. 

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/outerText> for more information.

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

=head2 part

This always returns C<undef>, because it has no meaning under perl.

Normally, under JavaScript, this would be a part that represents the part identifier(s) of the element (i.e. set using the part attribute), returned as a DOMTokenList.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/outerHTML>

=head2 popover

Experimental

Gets and sets an element's popover state via JavaScript (C<auto> or C<manual>), and can be used for feature detection. Reflects the value of the popover global HTML attribute.

If no value are set, this will return the one of the HTML attribute.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/popover> for more information.

=head2 prefix

Read-only

This always return C<undef>

Normally, for xml documents, this would be a string representing the namespace prefix of the element, or C<undef> if no prefix is specified.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/prefix>

=head2 previousElementSibling

Read-only

Returns an Element, the element immediately preceding the given one in the tree, or C<undef> if there is no sibling element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/previousElementSibling>

=head2 previousSibling

Read-only

This returns a element representing the previous element in the tree, or C<undef> if there is not such element.

The previous node could also be a whitespace or a text. If you want to get the previous element and not just any node, use L<previousElementSibling|HTML::Object::DOM/previousElementSibling> instead.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/previousSibling>

=head2 properties

This does nothing, but return an empty L<array object|Module::Generic::Array>

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/properties> for more information.

=head2 scrollHeight

Read-only

This always return C<undef> as this is not applicable under perl.

Normally, under JavaScript, this would return a number representing the scroll view height of an element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollHeight>

=head2 scrollLeft

This always return C<undef> as this is not applicable under perl.

Normally, under JavaScript, this would set or return a number representing the left scroll offset of the element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollLeft>

=head2 scrollTop

This always return C<undef> as this is not applicable under perl.

Normally, under JavaScript, this would set or return a number representing number of pixels the top of the document is scrolled vertically.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollTop>

=head2 scrollWidth

Read-only

This always return C<undef> as this is not applicable under perl.

Normally, under JavaScript, this would return a number representing the scroll view width of the element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollWidth>

=head2 setHTML

Parses and sanitizes a string of HTML and inserts into the DOM as a subtree of the element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/setHTML>

=head2 shadowRoot

Read-only

Always returns C<undef>

Normally, under JavaScript, this would return the open shadow root that is hosted by the element, or null if no open shadow root is present.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/shadowRoot>

=head2 spellcheck

A boolean value that controls spell-checking. It is present on all HTML elements, though it doesn't have an effect on all of them.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/spellcheck> for more information.

=head2 style

This does nothing, but return a new empty L<hash object|Module::Generic::Hash>

Normally, this would set or get A C<CSSStyleDeclaration> representing the declarations of the element's style attribute.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/style> for more information.

=head2 tabIndex

The tabIndex property represents the tab order of the current element.

Tab order is as follows:

=over

=item 1. Elements with a positive tabIndex. Elements that have identical tabIndex values should be navigated in the order they appear. Navigation proceeds from the lowest tabIndex to the highest tabIndex.

=item 2. Elements that do not support the tabIndex attribute or support it and assign tabIndex to 0, in the order they appear.

=back

Elements that are disabled do not participate in the tabbing order.

Values do not need to be sequential, nor must they begin with any particular value. They may even be negative, though each browser trims very large values.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/tabIndex>

=head2 tagName

Read-only. This is merely an alias for L</getName>

This returns a string with the name of the tag for the given element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/tagName>

=head2 textContent

This returns or sets the textual content of an element and all its descendants.

Example:

    <div id="divA">This is <span>some</span> text!</div>

    my $text = $doc->getElementById('divA')->textContent;
    # The text variable is now: 'This is some text!'
    
    $doc->getElementById('divA')->textContent = 'This text is different!';
    # The HTML for divA is now:
    # <div id="divA">This text is different!</div>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/textContent>

=head2 title

A string containing the text that appears in a popup box when mouse is over the element.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/title> for more information.

=head2 translate

A boolean value representing the translation.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/translate> for more information.

=head1 METHODS

=head2 addEventListener

Registers an event handler to a specific event type on the element. This is inherited from L<HTML::Object::EventTarget>

See L<HTML::Object::EventTarget/addEventListener> for more information.

=head2 after

Inserts a list of L<element|HTML::Object::Element> or HTML string in the L<children|/children> list of the L<element|HTML::Object::Element>'s parent, just after the L<element|HTML::Object::Element>.

For example:

Inserting an element:

    my $container = $doc->createElement("div");
    my $p = $doc->createElement("p");
    $container->appendChild( $p );
    my $span = $doc->createElement("span");

    $p->after( $span );

    say( $container->outerHTML );
    # "<div><p></p><span></span></div>"

Inserting an element and text

    my $container = $doc->createElement("div");
    my $p = $doc->createElement("p");
    $container->appendChild( $p );
    my $span = $doc->createElement("span");

    $p->after( $span, "Text" );

    say( $container->outerHTML );
    # "<div><p></p><span></span>Text</div>"

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/after>

=head2 append

Inserts a set of L<element|HTML::Object::Element> objects or HTML strings after the last child of the L<element|HTML::Object::Element>.

It returns the objects thus inserted as an L<array object|Module::Generic::Array>.

Differences from L</appendChild>:

=over 4

=item 1. L</append> allows you to also append HTML strings, whereas L</appendChild> only accepts L<element|HTML::Object::Element> objects.

=item 2. L</append> returns the current L<element|HTML::Object::Element> object, whereas L</appendChild> returns the appended L<element|HTML::Object::Element> object.

=item 3. L</append> can append several L<element|HTML::Object::Element> and strings, whereas L</appendChild> can only append one L<element|HTML::Object::Element>.

=back

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/append>

=head2 appendChild

Adds the specified child L<element|HTML::Object::Element> argument as the last child to the current L<element|HTML::Object::Element>. If the argument referenced an existing L<element|HTML::Object::Element> on the DOM tree, the element will be detached from its current position and attached at the new position.

Returns the appended object.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/appendChild>

=for assignedSlot

=head2 attachInternals

This does nothing.

Normally, under JavaScript, this would set or return an C<ElementInternals> object, and enables a custom element to participate in HTML forms.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/attachInternals> for more information.

=head2 before

Inserts a set of L<element|HTML::Object::Element> or HTML strings in the L<children|/children> list of the L<element|HTML::Object::Element>'s parent, just before the L<element|HTML::Object::Element>.

For example:

    my $container = $doc->createElement("div");
    my $p = $doc->createElement("p");
    $container->appendChild( $p );
    my $span = $doc->createElement("span");

    $p->before(span);

    say( $container->outerHTML );
    # "<div><span></span><p></p></div>"

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/before>

=head2 blur

This does nothing.

Normally, under JavaScript, this would remove keyboard focus from the currently focused element.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/blur> for more information.

=head2 click

Sends a mouse click event to the element.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/click> for more information.

=head2 cloneNode

Clone an element, and optionally, all of its contents. By default, it clones the content of the element.

Returns the element cloned.

=head2 closest

Returns the L<element|HTML::Object::Element> which is the closest ancestor of the current L<element|HTML::Object::Element> (or the current L<element|HTML::Object::Element> itself) which matches the selectors given in parameter.

For example:

    <article>
    <div id="div-01">Here is div-01
        <div id="div-02">Here is div-02
        <div id="div-03">Here is div-03</div>
        </div>
    </div>
    </article>

    my $el = $doc->getElementById('div-03');
    my $r1 = $el->closest("#div-02");
    # returns the element with the id C<div-02>

    my $r2 = $el->closest("div div");
    # returns the closest ancestor which is a div in div, here it is the C<div-03> itself

    my $r3 = $el->closest("article > div");
    # returns the closest ancestor which is a div and has a parent article, here it is the C<div-01>

    my $r4 = $el->closest(":not(div)");
    # returns the closest ancestor which is not a div, here it is the outmost article

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/closest>

=for cmp

=head2 compareDocumentPosition

Compares the position of the current element against another element in any other document.

    my $head = $doc->head;
    my $body = $doc->body;

    if( $head->compareDocumentPosition( $body ) & HTML::Object::Element->Node.DOCUMENT_POSITION_FOLLOWING )
    {
        say( 'Well-formed document' );
    } 
    else
    {
        say( '<head> is not before <body>' );
    }

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/compareDocumentPosition>

=head2 contains

Returns true or false value indicating whether or not an element is a descendant of the calling element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/contains>

=for css

=for css_cache_check

=for css_cache_store

=for data

=head2 dispatchEvent

Dispatches an event to this element in the DOM and returns a boolean value that indicates whether no handler canceled the event.

This is inherited from L<HTML::Object::EventTarget>
 
See L<HTML::Object::EventTarget/dispatchEvent> for more information.

=for each

=for empty

=for eq

=for even

=for exists

=head2 focus

This does nothing.

Normally, under JavaScript, this would make the element the current keyboard focus.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/focus> for more information.

=head2 getAttribute

Retrieves the value of the named attribute from the current node and returns it as a string.

Example:

    my $parser = HTML::Object::DOM->new;
    my $doc = $parser->parse_data( q{<div id="div1">Hi Champ!</div>} );

    # in a console
    my $div1 = $doc->getElementById('div1');
    # => <div id="div1">Hi Champ!</div>

    my $exampleAttr = $div1->getAttribute('id');
    # => "div1"

    my $align = $div1->getAttribute('align');
    # => null

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttribute>

=head2 getAttributeNames

Returns an L<array object|Module::Generic::Array> of attribute names from the current element.

Example:

    <div id="hello" class="opened" data-status="ok"></div>

    my $div = $doc->getElementById( 'hello' );
    my $arr = $div->getAttributeNames; # id class data-status
    $arr->foreach(sub
    {
        say $_;
    });
    # would print:
    # id
    # class
    # data-status

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttributeNames>

=head2 getAttributeNode

Retrieves the node representation of the named attribute from the current node and returns it as an Attr.

Example:

    # html: <div id="top" />
    my $t = $doc->getElementById("top");
    my $idAttr = $t->getAttributeNode("id");
    say( $idAttr->value eq "top" ); # 1

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttributeNode>

=head2 getAttributeNodeNS

This always returns C<undef> since there is no support for namespace.

Retrieves the node representation of the attribute with the specified name and namespace, from the current node and returns it as an Attr.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttributeNodeNS>

=head2 getAttributeNS

This always returns C<undef> since there is no support for namespace.

Retrieves the value of the attribute with the specified namespace and name from the current node and returns it as a string.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttributeNS>

=head2 getElementsByClassName

Provided with a space-delimited list of classes, or a list of classes, and this returns an L<array object|Module::Generic::Array> that contains all descendants of the current element that possess the list of classes given in the parameter.

Example:

    my $array = $element->getElementsByClassName('test');

This example finds all elements that have a class of C<test>, which are also a descendant of the element that has the id of C<main>:

    my $array = $doc->getElementById('main')->getElementsByClassName('test');

To find elements whose class lists include both the C<red> and C<test> classes:

    $element->getElementsByClassName('red test');

or, equivalently:

    $element->getElementsByClassName('red', 'test');

Inspecting the results:

    my $matches = $element->getElementsByClassName('colorbox');

    for( my $i=0; $i<$matches->length; $i++ )
    {
        $matches->[$i]->classList->remove('colorbox');
        $matches->get($i)->classList->add('hueframe');
    }

or, somewhat more streamlined:

    $matches->foreach(sub
    {
        $_->classList->remove('colorbox');
        $_->classList->add('hueframe');
    });

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/getElementsByClassName>

=head2 getElementsByTagName

Provided with a tag name, and this returns an L<array object|Module::Generic::Array> containing all descendant elements, of a particular tag name, from the current element.

The special string C<*> represents all elements.

Example:

    # Check the status of each data cell in a table
    my $cells = $doc->getElementById('forecast-table')->getElementsByTagName('td');

    $cells->foreach(sub
    {
        my $cell = shift( @_ ); $_ is available too
        my $status = $cell->getAttribute('data-status');
        if( $status === 'open' )
        {
            # Grab the data
        }
    });

All descendants of the specified element are searched, but not the element itself.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/getElementsByTagName>

=head2 getElementsByTagNameNS

This always returns C<undef> since there is no support for namespace.

Normally, under JavaScript, this would return a live HTMLCollection containing all descendant elements, of a particular tag name and namespace, from the current element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/getElementsByTagNameNS>

=head2 getElementsByTagNames

Provided with a space-separated string of tag names, or an array reference of tag names or a list of tag names, and this will return an L<array object|Module::Generic::Array> of descendant elements matching those tag names.

This is a non-standard method, courtesy of L<John Resig|https://johnresig.com/blog/comparing-document-position/#postcomment>

=for getLocalName

=head2 getNextSibling

This non-standard method is an alias for the property L</nextSibling>

=for getNodePath

=head2 getPreviousSibling

This non-standard method is an alias for the property L</previousSibling>

=head2 getRootNode

Returns the context object's root which optionally includes the shadow root if it is available.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/getRootNode>

=for getValue

=head2 hasAttribute

Provided with an attribute name and this returns a boolean value indicating if the element has the specified attribute or not.

Example:

    my $foo = $doc->getElementById("foo");
    if( $foo->hasAttribute("bar") )
    {
        # do something
    }

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/hasAttribute>

=head2 hasAttributeNS

This always returns C<undef> since there is no support for namespace.

Returns a boolean value indicating if the element has the specified attribute, in the specified namespace, or not.

=head2 hasAttributes

Returns a boolean value indicating if the element has one or more HTML attributes present.

Example:

    my $foo = $doc->getElementById('foo');
    if( $foo->hasAttributes() )
    {
        # Do something with '$foo->attributes'
    }

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/hasAttributes>

=head2 hasChildNodes

Normally, under JavaScript, this would return a boolean value indicating whether or not the element has any child elements.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/hasChildNodes>

=for hasClass

=for hide

=head2 hidePopover

Experimental

This does nothing.

Normally, under JavaScript, this would hide a popover element by removing it from the top layer and styling it with display: none.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/hidePopover> for more information.

=for html

=for index

=head2 insertAdjacentElement

Provided with a C<position> and an L<element|HTML::Object::DOM::Element> and this inserts a given L<element|HTML::Object::DOM::Element> node at a given C<position> relative to the L<element|HTML::Object::DOM::Element> it is invoked upon.

It returns the element that was inserted, or C<undef>, if the insertion failed.

It returns a C<HTML::Object::SyntaxError> error if the C<position> specified is not a recognised value.

It returns a C<HTML::Object::TypeError> error if the C<element> specified is not a valid element.

THe C<position> can be any one of (case insensitive)

=over 4

=item C<beforebegin>

Before the targetElement itself.

=item C<afterbegin>

Just inside the targetElement, before its first child.

=item C<beforeend>

Just inside the targetElement, after its last child.

=item C<afterend>

After the targetElement itself.

=back

    <!-- beforebegin -->
    <p>
        <!-- afterbegin -->
        foo
        <!-- beforeend -->
    </p>
    <!-- afterend -->

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentElement>

=head2 insertAdjacentHTML

Provided with a C<position> and an L<element|HTML::Object::DOM::Element> and this parses the text as HTML and inserts the resulting nodes into the tree in the position given.

This takes the same C<position> parameter as L</insertAdjacentElement>

It returns the newly created objects from parsing the html data and that were inserted, as an L<array object|Module::Generic::Array>, or C<undef>, if the insertion failed.

It returns a C<HTML::Object::SyntaxError> error if the C<position> specified is not a recognised value.

It returns a C<HTML::Object::TypeError> error if the C<element> specified is not a valid element.

Example:

    # <div id="one">one</div>
    my $d1 = $doc->getElementById('one');
    $d1->insertAdjacentHTML('afterend', q{<div id="two">two</div>});

    # At this point, the new structure is:
    # <div id="one">one</div><div id="two">two</div>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentHTML>

=head2 insertAdjacentText

Provided with a C<position> and a C<text> string, or a list of C<text> string that will be concatenated, and this inserts the given C<text> at the given C<position> relative to the element it is invoked upon.

This takes the same C<position> parameter as L</insertAdjacentElement>

It returns the newly created text L<node|HTML::Object::DOM::Node> that was inserted, or C<undef>, if the insertion failed.

It returns a C<HTML::Object::SyntaxError> error if the C<position> specified is not a recognised value.

It returns a C<HTML::Object::TypeError> error if the C<element> specified is not a valid element.

Example:

    $beforeBtn->addEventListener( click => sub
    {
        $para->insertAdjacentText('afterbegin',$textInput->value);
    });

    $afterBtn->addEventListener( click => sub
    {
        $para->insertAdjacentText('beforeend',$textInput->value);
    });

Or

    $para->insertAdjacentText( beforesend => 'Some chunks', 'of', 'text to insert' );

Or, more simply:

    $para->insertAdjacentText( beforesend => qw( Some chunks of text to insert ) );

But, the following would fail since there is no data provided:

    $para->insertAdjacentText( beforesend => '' );
    $para->insertAdjacentText( beforesend => undef );
    $para->insertAdjacentText( beforesend => '', '', '' );

So you have to make sure the data submitted is not zero length.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentText>

=head2 insertBefore

Inserts an element before the reference element as a child of a specified parent element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/insertBefore>

=for isa_collection

=for isa_element

=head2 isDefaultNamespace

Accepts a namespace URI as an argument and returns a boolean value with a value of true if the namespace is the default namespace on the given element or false if not.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isDefaultNamespace>

=head2 isEqualNode

Returns a boolean value which indicates whether or not two elements are of the same type and all their defining data points match.

Two elements are equal when they have the same type, defining characteristics (this would be their ID, number of children, and so forth), its attributes match, and so on. The specific set of data points that must match varies depending on the types of the elements. 

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isEqualNode>

=head2 isSameNode

Returns a boolean value indicating whether or not the two elements are the same (that is, they reference the same object).

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isSameNode>

=for length

=for load

=head2 lookupNamespaceURI

Accepts a prefix and returns the namespace URI associated with it on the given element if found (and C<undef> if not). Supplying C<undef> for the prefix will return the default namespace.

This always return an empty string and C<http://www.w3.org/XML/1998/namespace> if the prefix is C<xml>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/lookupNamespaceURI>

=head2 lookupPrefix

This always returns C<undef>.

Returns a string containing the prefix for a given namespace URI, if present, and C<undef> if not.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/lookupPrefix>

=for map

=head2 matches

Provided with a CSS C<selector> string, and an optional hash or hash reference, and this returns a boolean value indicating whether or not the element would be selected by the specified C<selector> string.

Example:

    <ul id="birds">
        <li>Orange-winged parrot</li>
        <li class="endangered">Philippine eagle</li>
        <li>Great white pelican</li>
    </ul>

    my $birds = $doc->getElementsByTagName('li');

    for( my $i = 0; $i < $birds->length; $i++ )
    {
        if( $birds->[$i]->matches('.endangered') )
        {
            say('The ' + $birds->[i]->textContent + ' is endangered!');
        }
    }
    # The Philippine eagle is endangered!

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/matches>

=for name

=head2 new_attribute

Returns a new L<HTML::Object::DOM::Attribute> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_closing

Returns a new L<HTML::Object::DOM::Closing> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_collection

Returns a new L<HTML::Object::DOM::Collection> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_comment

Returns a new L<HTML::Object::DOM::Comment> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_document

Returns a new L<HTML::Object::DOM::Document> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_element

Returns a new L<HTML::Object::DOM::Element> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_nodelist

Returns a new L<HTML::Object::DOM::NodeList> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_parser

Returns a new L<HTML::Object::DOM> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=for new_root

=head2 new_space

Returns a new L<HTML::Object::DOM::Space> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 new_text

Returns a new L<HTML::Object::DOM::Text> object, passing it whatever arguments were provided and return the newly instantiated object.

If an error occurred, this returns C<undef> and sets an L<error|Module::Generic/error>

=head2 normalize

Clean up all the text elements under this element (merge adjacent, remove empty).

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/normalize>

=for odd

=head2 prepend

Provided with a list of L<node objects|HTML::Object::DOM::Node> (this includes L<element objects|HTML::Object::DOM::Element>) or C<text>, or a mixture of them and this inserts them before the first child of the L<element|HTML::Object::DOM::Element>.

It returns the objects thus inserted as an L<array object|Module::Generic::Array>.

It returns a C<HTML::Object::HierarchyRequestError> error if the objects cannot be inserted at the specified point into the hierarchy.

It returns a C<HTML::Object::TypeError> error if any argument provided is neither a text string nor a L<node object|HTML::Object::DOM::Node>.

It returns a C<HTML::Object::SyntaxError> error if no argument was provided.

Upon success, it returns an L<array objects|Module::Generic::Array> of the nods thus prepended, and upon error, it returns undef and sets one of the errors aforementioned.

Example:

Prepending an element:

    my $div = $doc->createElement("div");
    my $p = $doc->createElement("p");
    my $span = $doc->createElement("span");
    $div->append($p);
    $div->prepend($span);

    # Array object containing <span>, <p>
    my $list = $div->childNodes;

Prepending text

    my $div = $doc->createElement("div");
    $div->append("Some text");
    $div->prepend("Headline: ");

    # "Headline: Some text"
    say( $div->textContent );

Prepending both an element and some text

    my $div = $doc->createElement("div");
    my $p = $doc->createElement("p");
    $div->prepend("Some text", $p);

    # Array object containing "Some text", <p>
    my $list = $div->childNodes;

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/prepend>

=for prependTo

=for promise

=for prop

=head2 querySelector

Provided with a list of CSS C<selector> strings and this returns the first L<element|HTML::Object::DOM::Element> that is a descendant of the L<element|HTML::Object::DOM::Element> on which it is invoked that matches the specified group of selectors.

If returns a L<smart undef|Module::Generic/new_null> if nothing is found (to differentiate from an error and still treated as false), and C<undef> upon error and sets an L<error|Module::Generic/error>.

It returns a C<HTML::Object::SyntaxError> error if any of the selector provided is not a valid selector.

Example:

    <div>
        <h6>Page Title</h6>
        <div id="parent">
            <span>Love is Kind.</span>
            <span>
                <span>Love is Patient.</span>
            </span>
            <span>
                <span>Love is Selfless.</span>
            </span>
        </div>
    </div>

    my $parentElement = $doc->querySelector('#parent');
    # would need to check that $parentElement is not undef here through...
    my $allChildren = $parentElement->querySelectorAll(":scope > span");
    $allChildren->foreach(sub
    {
        my $item = shift( @_ );
        $item->classList->add("red");
    });

    <div>
        <h6>Page Title</h6>
        <div id="parent">
            <span class="red">Love is Kind.</span>
            <span class="red">
                <span>Love is Patient.</span>
            </span>
            <span class="red">
                <span>Love is Selfless.</span>
            </span>
        </div>
    </div>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelector>

=head2 querySelectorAll

Provided with a list of CSS C<selector> strings and this returns an L<array object|Module::Generic::Array> representing a list of L<elements|HTML::Object::DOM::Element> matching the specified group of C<selectors> which are descendants of the L<element|HTML::Object::DOM::Element> on which the method was called. 

It returns a C<HTML::Object::SyntaxError> error if any of the selector provided is not a valid selector.

Example:

    my $matches = $myBox->querySelectorAll("p");
    my $matches = $myBox->querySelectorAll("div.note, div.alert");

Get a list of the document's <p> elements whose immediate parent element is a C<div> with the class C<highlighted> and which are located inside a container whose ID is C<test>.

    my $container = $doc->querySelector("#test");
    my $matches = $container->querySelectorAll("div.highlighted > p");

Here with an attribute C<selector>

    my $container = $doc->querySelector("#userlist");
    my $matches = $container->querySelectorAll("li[data-active='1']");

To access the matched element, see L<Module::Generic::Array/foreach> for example:

    $matches->foreach(sub
    {
        my $elem = shift( @_ ); # $_ is available too
        # Do something with $elem
        
        # To satisfy array object's foreach and avoid ending abruptly the loop
        return(1);
    });

or

    foreach my $elem ( @$matches )
    {
        # Do something with $elem
    }

A word of caution on some edge case. While the JavaScript equivalent of C<querySelectorAll> takes a document global view at the CSS selector provided, here in perl, it only matches descendants.

For example, the following would return 1 in JavaScript while it would return 0 in our implementation.

    <div class="outer">
        <div class="select">
            <div class="inner"></div>
        </div>
    </div>

With JavaScript:

    var select = document.querySelector('.select');
    var inner = select.querySelectorAll('.outer .inner');
    inner.length; // 1, not 0 !

With Perl:

    my $select = $doc->querySelector('.select');
    my $inner = $select->querySelectorAll('.outer .inner');
    $inner->length; // 0, not 1 !!

Why is that? Because, when JavaScript does it search for the element whose class is C<inner> and who is inside another element whose class is C<outer>, it does not bother JavaScript that C<outer> is a parent of the elment on which C<querySelectorAll> is being called, because it retains only the last part of the selector, i.e. C<inner>.

In perl, there is no such elaborate CSS engine that would allow us this level of granularity, and thus it would look for C<.outer .inner> below C<select> and since there are none, it would return C<0>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelectorAll>

=for rank

=head2 remove

Removes the element from the children list of its parent.

It returns true upon success, and upon error, it returns C<undef> and sets an L<error|Module::Generic/error>

It returns an C<HTML::Object::HierarchyRequestError> if the L<element|HTML::Object::DOM::Element> does not have any parent, like so:

    my $div = $doc->createElement( 'div' );
    $div->remove; # Error returned !

Example:

    <div id="div-01">Here is div-01</div>
    <div id="div-02">Here is div-02</div>
    <div id="div-03">Here is div-03</div>

    my $el = $doc->getElementById('div-02');
    $el->remove(); # Removes the div with the 'div-02' id

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/remove>

=for removeAttr

=head2 removeAttribute

Provided with an attribute C<name> and this removes the attribute with the specified C<name> from the L<element|HTML::Object::DOM::Element>.

It returns true upon success or false otherwise.

It returns an C<HTML::Object::SyntaxError> if no attribute name was provided.

Example:

    # Given: <div id="div1" align="left" width="200px">
    $doc->getElementById("div1")->removeAttribute("align");
    # Now: <div id="div1" width="200px">

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttribute>

=head2 removeAttributeNode

Provided with an L<attribute node|HTML::Object::DOM::Attribute> and this removes the node representation of the named attribute from the current node. This is similar to L</removeAttribute>, except that L</removeAttribute> takes a string as attribute name, while L</removeAttributeNode> takes an L<attribute object|HTML::Object::DOM::Attribute>.

Upon error, it returns C<undef> and sets an L<error|Module::Generic/error>.

It returns an C<HTML::Object::SyntaxError> if the value provided is not an L<attribute object|HTML::Object::DOM::Attribute>.

Example:

    # Given: <div id="top" align="center" />
    my $d = $doc->getElementById("top");
    my $d_align = $d->getAttributeNode("align");
    $d->removeAttributeNode( $d_align ); # <-- passing the attribute object
    # align is now removed: <div id="top" />

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttributeNode>

=head2 removeAttributeNS

This always return C<undef> since there is no support for namespace.

Under JavaScript, this would remove the attribute with the specified name and namespace, from the current node.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttributeNS>

=head2 removeChild

Removes a child element from the current element, which must be a child of the current element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/removeChild>

=for removeClass

=head2 removeEventListener

Removes an event listener from the element. This is inherited from L<HTML::Object::EventTarget>
 
See L<HTML::Object::EventTarget/removeEventListener> for more information.

=head2 replaceChild

Replaces one child element of the current one with the second one given in parameter.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/replaceChild>

=head2 replaceChildren

Replaces the existing children of a L<Node|HTML::Object::DOM::Node> with a specified new set of children.
These can be HTML strings or L<node objects|HTML::Object::DOM::Node>.

It returns an L<array object|Module::Generic::Array> of the replaced or removed children. Note that those replaced children will have their parent value set to C<undef>.

You can call it on a node without any argument specified to remove all of its children:

    $myNode->replaceChildren();

This method also enables you to easily transfer nodes between elements since each new nodes provided will be detached from their previous parent and re-attached under the current element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceChildren>

=head2 replaceWith

Replaces the element in the children list of its parent with a set of Node or DOMString objects.

This method replaces the current L<element|HTML::Object::DOM::Element> in the children list of its parent with a set of L<node|HTML::Object::DOM::Node> or strings. Strings that look like HTML are parsed and added as L<HTML::Object::DOM::Element> and other text strings are inserted as equivalent L<Text nodes|HTML::Object::DOM::Text>.

This returns a C<HTML::Object::HierarchyRequestError> when a L<node|HTML::Object::DOM::Node> provided cannot be inserted at the specified point in the hierarchy.

It returns an L<array object|Module::Generic::Array> of the newly inserted nodes.

Example:

    my $div = $doc->createElement("div");
    my $p = $doc->createElement("p");
    $div->appendChild( $p );
    # Now div is: <div><p></p></div>
    my $span = $doc->createElement("span");

    $p->replaceWith( $span );

    say( $div->outerHTML );
    # "<div><span></span></div>"

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceWith>

=for set_namespace

=head2 setAttribute

Provided with a C<name> and a C<value> and this sets the value of an attribute on the specified L<element|HTML::Object::DOM::Element>. If the attribute already exists, the value is updated; otherwise a new attribute is added with the specified name and value.

To get the current value of an attribute, use L</getAttribute>; to remove an attribute, use L</removeAttribute>.

Contrary to the original JavaScript equivalent, providing a C<value> with C<undef> results in removing the attribute altogether.

It returns the current element upon success and upon error, it returns C<undef> and sets an L<error|Module::Generic/error>

It returns an C<HTML::Object::InvalidCharacterError> object when the attribute name provided contains illegal characters.

It returns an C<HTML::Object::SyntaxError> object when no attribute name was provided.

Example:

Set attributes on a button

    <button>Hello World</button>

    my $b = $doc->querySelector("button");

    $b->setAttribute("name", "helloButton");
    $b->setAttribute("disabled", "");
    # <button name="helloButton" disabled="">Hello World</button>

To remove an attribute (same as calling L</removeAttribute>)

    $b->setAttribute("disabled", undef);

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttribute>

=head2 setAttributeNode

Provided with an L<attribute object|HTML::Object::DOM::Attribute> and this sets, or possibly replace, the node representation of the named attribute from the current node.

If a previous L<attribute|HTML::Object::DOM::Attribute> existed, it will be replaced and returned.

Example:

    <div id="one" align="left">one</div>
    <div id="two">two</div>

    my $d1 = $doc->getElementById('one');
    my $d2 = $doc->getElementById('two');
    my $a = $d1->getAttributeNode('align');

    $d2->setAttributeNode( $a.cloneNode($true) );

    # Returns: 'left'
    say( $d2->attributes->get( 'align' )->value );
    # or
    say( $d2->attributes->{align}->value );

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttributeNode>

=head2 setAttributeNodeNS

This always return C<undef> since namespace is not supported.

Under JavaScript, this would set the L<node|HTML::Object::DOM::Attribute> representation of the attribute with the specified C<name> and C<namespace>, from the current node.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttributeNS>

=for show

=head2 showPopover

Experimental

This does nothing.

Normally, under JavaScript, this would show a popover element by adding it to the top layer and removing display: none; from its styles.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/showPopover> for more information.

=for string_value

=for tagname

=head2 toggleAttribute

Provided with an attribute name and an optiona C<force> value, and this toggles a boolean attribute, removing it if it is present and adding it if it is not present, on the specified element.

C<force> is a boolean value to determine whether the attribute should be added or removed, no matter whether the attribute is present or not at the moment.

It returns C<true> if attribute C<name> is eventually present, and C<false> otherwise. 

It returns an C<HTML::Object::InvalidCharacterError> error if the specified attribute C<name> contains one or more characters which are not valid in attribute names.

Example:

To toggle the C<disabled> attribute of an input field

    <input value="text">
    <button>toggleAttribute("disabled")</button>

    my $button = $doc->querySelector("button");
    my $input = $doc->querySelector("input");

    $button->addEventListener( click => sub
    {
        $input->toggleAttribute("disabled");
    });

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Element/toggleAttribute>

=for toggleClass

=head2 togglePopover

Experimental

This does nothing.

Normally, under JavaScript, this would toggle a popover element between the hidden and showing states.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/togglePopover> for more information.

=head2 toString

Returns a string representation for this element.

=head2 to_number

Returns a L<HTML::Object::DOM::Number> object representing the text value of this element.

=for xq

=head1 EVENTS

Listen to these events using L<HTML::Object::EventTarget/addEventListener> or by assigning an event listener to the C<oneventname> property of this interface.

Under perl, few events are actually "fired" by L<HTML::Object> and L<for the others|https://developer.mozilla.org/en-US/docs/Web/API/Element#events> (also L<here|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement#events>), nothing prevents you from L<triggering|HTML::Object::EventTarget/dispatchEvent> whatever events you want, even private non-standard ones, and set up listeners for them.

Below are the ones actually "fired" by L<HTML::Object>.

=head2 change

This event is fired when there has been some change to the underlying element. This is also available via the onchange property.

=head2 error

This event is fired when an error occurs for this element. This is also available via the onerror property.

Example:

    $video->onerror = sub
    {
        say( "Error " . $video->error->code . "; details: " . $video->error->message );
    }

=head1 EXTENDED

Inheriting from L<HTML::Object::EventTarget> and extended with L<HTML::Object::XQuery>

See detailed documentation in L<HTML::Object::XQuery>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::DOM>, L<HTML::Object::DOM::Attribute>, L<HTML::Object::DOM::Boolean>, L<HTML::Object::DOM::Closing>, L<HTML::Object::Collection>, L<HTML::Object::DOM::Comment>, L<HTML::Object::DOM::Declaration>, L<HTML::Object::DOM::Document>, L<HTML::Object::DOM::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::DOM::Number>, L<HTML::Object::DOM::Root>, L<HTML::Object::DOM::Space>, L<HTML::Object::DOM::Text>, L<HTML::Object::XQuery>

L<Mozilla DOM documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement>, L<Mozilla Element documentation|https://developer.mozilla.org/en-US/docs/Web/API/Element>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
