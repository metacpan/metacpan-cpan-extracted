##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Document.pm
## Version v0.2.2
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
package HTML::Object::DOM::Document;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Document HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::ErrorEvent;
    use Scalar::Util ();
    use Want;
    our $VERSION = 'v0.2.2';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->HTML::Object::Document::init( @_ ) || return( $self->pass_error );
    $self->{onload} = undef;
    $self->{onreadystatechange} = undef;
    $self->{visibilitystate} = 'visible';
    $self->{_xpath_eval} = undef;
    # Nodes are special in the document. In other elements, nodes are the same as children
    # But here no. There can be only 1 element: html, but one can add a doctype or comments
    # comments added will be part of the children, but not the doctype. So
    # $doc->children is always equal to 1, but
    # $doc->childNodes->length would be equal to 2 (including the doctype)
    # So our real array is nodes, i.e. what would otherwise be children for other elements
    # $self->{nodes} is automatically created by the read-only method 'nodes'
    # State of the document for document->open(), document->close()
    $self->{_closed} = 1;
    return( $self );
}

sub activeElement : lvalue { return( shift->_set_get_object_lvalue( 'activeelement', 'HTML::Object::DOM::Element', @_ ) ); }

sub adoptNode
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error( "No element object was provided to adopt into our document." ) );
    return( $self->error( "Element provided ($elem) is not a HTML::Object::Element object." ) ) if( !$self->_is_a( $elem, 'HTML::Object::Element' ) || $self->_is_a( $elem, 'HTML::Object::Collection' ) );
    if( $elem->parent )
    {
        $elem->detach;
    }
    return( $elem );
}

# Note: method append is different from HTML::Object::DOM::Element because we need to check what goes in
sub append
{
    my $self = shift( @_ );
    return( $self ) if( !scalar( @_ ) );
    # If a HTML::Object::DOM::DocumentFragment object is provided, its children are 
    # copied to the list and its own children array is emptied.
    my $list = $self->_check_list_of_nodes_or_text( @_ ) || return( $self->pass_error );
    my $nodes = $self->nodes;
    $self->reset(1) if( !$list->is_empty );
    $list->foreach(sub
    {
        $_->parent( $self );
    });
    $nodes->push( $list->list );
    return( $self );
}

# Node: method appendChild is inherited

sub as_string
{
    my $self = shift( @_ );
    my $a = $self->new_array;
    $self->nodes->foreach(sub
    {
        my $e = shift( @_ );
        my $v = $e->as_string;
        $a->push( defined( $v ) ? $v->scalar : $v );
    });
    return( $a->join( '' ) );
}

sub body : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        my $html = $self->documentElement ||
            die( "Unable to find a top HTML tag" );
        my $children = $html->children;
        my $body;
        foreach( @$children )
        {
            if( $_->tag eq 'body' )
            {
                $body = $_;
                # End loop
                last;
            }
        }
        # $body may be undef, and that's ok. A Module::Generic::Null object will be returned instead
        return( $body );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $e = shift( @_ );
        my $html = $self->documentElement ||
            die( "Unable to find a top HTML tag" );
        my $children = $html->children;
        if( !$self->_is_a( $e, 'HTML::Object::Element' ) )
        {
            die( "Element provided to set as new body element is not a HTML::Object::Element object." );
        }
    
        my $body;
        for( my $pos = 0; $pos < scalar( @$children ); $pos++ )
        {
            my $child = $children->[$pos];
            if( $child->tag eq 'body' )
            {
                $body = $child;
                $children->offset( $pos, 1, $e );
                # End loop
                last;
            }
        }
    
        # No body was found, amazingly enough; add it now
        if( !defined( $body ) )
        {
            $children->push( $e );
        }
        return( $e );
    }
}, @_ ) ); }

sub captureEvents { return( shift->defaultView->captureEvents( @_ ) ); }

sub caretPositionFromPoint { return; }

sub caretRangeFromPoint { return; }

# read-only
# e.g.:
# <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
# <meta charset="utf-8" />
sub characterSet : lvalue
{
    my $self = shift( @_ );
    # Get an Module::Generic::Array object
    my $results = $self->find( 'meta' ) || return( $self->pass_error );
    require Module::Generic::HeaderValue;
    foreach my $e ( $results->list )
    {
        if( $e->attributes->has( 'http-equiv' ) &&
            $e->attributes->get( 'http-equiv' ) eq 'Content-Type' &&
            $e->attributes->has( 'content' ) )
        {
            my $type = $e->attributes->get( 'content' );
            next if( !defined( $type ) || !CORE::length( $type ) );
            my $hv = Module::Generic::HeaderValue->new_from_header( $type );
            my $charset = $hv->param( 'charset' );
            return( $charset // '' );
        }
        elsif( $e->attributes->has( 'charset' ) )
        {
            return( $e->attributes->get( 'charset' ) // '' );
        }
    }
    return( '' );
}

# Note: property childElementCount read-only inherited from HTML::Object::DOM::Element

# Note: property children read-only
sub children
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->_set_get_object_array_object( 'children', 'HTML::Object::Element', @_ ) );
    }
    $self->_init_nodes;
    return( $self->_set_get_object_array_object( 'children', 'HTML::Object::Element' ) );
}

sub childNodes : lvalue { return( shift->_set_get_array_as_object( 'nodes', @_ ) ); }

# Note: property children read-only inherited

# method cloneNode is inherited from HTML::Object::DOM::Node

sub close { return( shift->{_closed} = 1 ); }

sub compatMode : lvalue { return; }

# read-only
# e.g.:
# <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
sub contentType
{
    my $self = shift( @_ );
    my $results = $self->find( 'meta' ) || return( $self->pass_error );
    require Module::Generic::HeaderValue;
    my $default = 'text/html';
    foreach my $e ( $results->list )
    {
        if( $e->attributes->has( 'http-equiv' ) &&
            $e->attributes->get( 'http-equiv' ) eq 'Content-Type' &&
            $e->attributes->has( 'content' ) )
        {
            my $type = $e->attributes->get( 'content' );
            next if( !defined( $type ) || !CORE::length( $type ) );
            my $hv = Module::Generic::HeaderValue->new_from_header( $type );
            return( $hv->value->first // $default );
        }
    }
    return( $default );
}

sub cookie : lvalue { return( shift->_set_get_lvalue( '_cookie', @_ ) ); }

sub createAttribute
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    $name = lc( $name ) if( defined( $name ) );
    return( $self->error({
        message => "The attribute provided \"$name\" contains illegal characters.",
        class => 'HTML::Object::SyntaxError',
    }) ) if( !$self->is_valid_attribute( $name ) );
    require HTML::Object::DOM::Attribute;
    my $att = HTML::Object::DOM::Attribute->new( $name, @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Attribute->error ) );
    return( $att );
}

sub createAttributeNS { return; }

sub createCDATASection { return; }

# TODO Create pod: https://developer.mozilla.org/en-US/docs/Web/API/Document/createComment
sub createComment
{
    my $self = shift( @_ );
    my $data;
    $data = join( '', @_ ) if( @_ );
    return( $self->new_comment( value => $data ) );
}

sub createDocumentFragment
{
    my $self = shift( @_ );
    require HTML::Object::DOM::DocumentFragment;
    my $frag = HTML::Object::DOM::DocumentFragment->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::DocumentFragment->error ) );
    return( $frag );
}

sub createElement
{
    my $self = shift( @_ );
    my $tag  = shift( @_ ) || return( $self->error( "No tag was provided to create an element." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my $p = HTML::Object::DOM->new;
    my $def = $p->get_definition( $tag );
    # Even if the tag does not exist, the default behaviour is to accept whatever was 
    # provided and assume it is a non-empty tag
    if( !defined( $def ) )
    {
        $def = 
        {
        is_empty    => 0,
        is_inline   => 0,
        };
    }
    
    $opts->{debug} = $self->debug;
    @$opts{qw( is_empty is_inline )} = @$def{qw( is_empty is_inline )};
    $opts->{tag} = $tag;
    
    my $e;
    $def->{class} //= '';
    if( $def->{class} )
    {
        $e = $p->new_special( $def->{class} => $opts );
    }
    else
    {
        $e = $p->new_element( $opts );
    }
    $e->close;
    return( $e );
}

sub createElementNS { return; }

# TODO: createEntityReference
sub createEntityReference { return; }

# TODO createEvent https://developer.mozilla.org/en-US/docs/Web/API/Document/createEvent
sub createEvent
{
    my $self = shift( @_ );
    my $type = shift( @_ ) || return( $self->error({
        message => 'No event type was provided',
        class => 'HTML::Objct::SyntaxError',
    }) );
    $self->_load_class( 'HTML::Object::Event' ) || return( $self->pass_error );
    my $evt = HTML::Object::Event->new( $type, @_ ) ||
        return( $self->pass_error( HTML::Object::Event->error ) );
    return( $evt );
}

# TODO: createExpression
sub createExpression
{
    my $self = shift( @_ );
    my $eval;
    unless( $eval = $self->{_xpath_eval} )
    {
        $self->_load_class( 'HTML::Object::DOM::XPathEvaluator' ) || return( $self->pass_error );
        $self->{_xpath_eval} = $eval = HTML::Object::DOM::XPathEvaluator->new ||
            return( $self->pass_error( HTML::Object::DOM::XPathEvaluator->error ) );
    }
    my $expr = $eval->createExpression( @_ );
    return( $self->pass_error( $eval->error ) ) if( !defined( $expr ) );
    return( $expr );
}

# TODO: createNSResolver
sub createNSResolver { return; }

# TODO: createNodeIterator
sub createNodeIterator
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::NodeIterator' ) || return( $self->pass_error );
    my $iterator = HTML::Object::DOM::NodeIterator->new( @_ );
    return( $self->pass_error( HTML::Object::DOM::NodeIterator->error ) ) if( !defined( $iterator ) );
    return( $iterator );
}

sub createProcessingInstruction { return; }

# TODO: createRange
sub createRange { return; }

sub createTextNode
{
    my $self = shift( @_ );
    my $txt = @_ == 1 ? shift( @_ ) : join( '', @_ );
    $self->_load_class( 'HTML::Object::DOM::Text' ) || return( $self->pass_error );
    my $node = HTML::Object::DOM::Text->new( value => $txt ) ||
        return( $self->pass_error( HTML::Object::DOM::Text->error ) );
    return( $node );
}

sub createTouch { return; }

sub createTouchList { return; }

sub createTreeWalker
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::TreeWalker' ) || return( $self->pass_error );
    my $crawler = HTML::Object::DOM::TreeWalker->new( @_ );
    return( $self->pass_error( HTML::Object::DOM::TreeWalker->error ) ) if( !defined( $crawler ) );
    return( $crawler );
}

sub currentScript { return( shift->_set_get_object_lvalue( 'currentscript', 'HTML::Object::DOM::Element', @_ ) ); }

sub defaultView : lvalue { return( shift->_set_get_object_lvalue( 'defaultview', 'HTML::Object::DOM::Window', @_ ) ); }

sub designMode : lvalue { return; }

sub dir : lvalue { return( shift->_set_get_lvalue( '_dir' ) ); }

# Note: property doctype read-only
sub doctype : lvalue
{
    my $self = shift( @_ );
    return( $self->declaration );
}

# Note: property documentElement read-only
sub documentElement : lvalue
{
    my $self = shift( @_ );
    if( @_ )
    {
        warnings::warn( "This property \"documentElement\" is read-only.\n" ) if( warnings::enabled( 'HTML::Object' ) );
    }
    my $html;
    # It should be the first one, but let's not assume anything
    my $children = $self->children;
    foreach( @$children )
    {
        if( $_->tag eq 'html' )
        {
            $html = $_;
            last;
        }
    }
    if( !$html && Want::want( 'OBJECT' ) )
    {
        require Module::Generic::Null;
        return( Module::Generic::Null->new( wants => 'OBJECT' ) );
    }
    return( $html );
}

# Note: property documentURI read-only
sub documentURI : lvalue { return( shift->_set_get_uri( 'uri', @_ ) ); }

sub elementFromPoint { return; }

sub elementsFromPoint { return; }

# Note: property read-only embeds
sub embeds
{
    my $self = shift( @_ );
    my $results = $self->find( 'embed' ) || return( $self->pass_error );
    return( $self->new_collection( $results ) );
}

sub enableStyleSheetsForSet { return; }

sub evaluate
{
    my $self = shift( @_ );
    my $eval;
    unless( $eval = $self->{_xpath_eval} )
    {
        $self->_load_class( 'HTML::Object::DOM::XPathEvaluator' ) || return( $self->pass_error );
        $self->{_xpath_eval} = $eval = HTML::Object::DOM::XPathEvaluator->new ||
            return( $self->pass_error( HTML::Object::DOM::XPathEvaluator->error ) );
    }
    return( $eval->evaluate( @_ ) );
}

sub execCommand { return; }

sub exitPictureInPicture { return; }

sub exitPointerLock { return; }

sub featurePolicy : lvalue { return; }

# Note: firstChild returns its values from the nodes array, not the children one; is inherited

# Note: method firstElementChild is inherited from HTML::Object::DOM::Element

# Note: property read-only fonts
sub fonts { return; }

# Note: property read-only forms
sub forms
{
    my $self = shift( @_ );
    my $results = $self->find( 'form' ) || return( $self->pass_error );
    return( $self->new_collection( $results ) );
}

sub fullscreenElement : lvalue { return; }

sub getAnimations { return; }

sub getBoxQuads { return; }

sub getElementById
{
    my $self = shift( @_ );
    my $id   = shift( @_ );
    return if( !defined( $id ) || !CORE::length( $id ) );
    my $seen = {};
    my $crawl;
    $crawl = sub
    {
        my $elem = shift( @_ );
        my $addr = Scalar::Util::refaddr( $elem );
        return if( CORE::exists( $seen->{ $addr } ) );
        # Not a true element, such as text, comment
        return if( $elem->tag->substr( 0, 1 ) eq '_' && !$self->_is_a( $elem => 'HTML::Object::Document' ) );
        $seen->{ $addr }++;
        if( $elem->attributes->has( 'id' ) && 
            $elem->attributes->get( 'id' ) eq $id )
        {
            return( $elem );
        }
        my $e;
        $elem->children->foreach(sub
        {
            my $this = shift( @_ );
            if( my $found = $crawl->( $this ) )
            {
                $e = $found;
                return;
            }
            return(1);
        });
        return( $e );
    };
    return( $crawl->( $self ) );
}

# Note: method getElementsByClassName is inherited from HTML::Object::DOM::Element

sub getElementsByName
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    return( $self->error( "No value was provided for getElementsByName()" ) ) if( !defined( $name ) || !CORE::length( "$name" ) );
    my $results = $self->look_down( name => $name ) || return( $self->pass_error );
    my $list = $self->new_nodelist( $results ) || return( $self->pass_error );
    return( $list ); 
}

# Note: method getElementsByTagName is inherited from HTML::Object::DOM::Element

sub getElementsByTagNameNS { return; }

sub getRootNode { return( shift->root ); }

sub getSelection { return; }

# Note: method hasChildNodes is inherited

sub hasFocus { return(1); }

sub hasStorageAccess { return; }

# Note: property head read-only
sub head : lvalue
{
    my $self = shift( @_ );
    my $results = $self->find( 'head' ) || return( $self->pass_error );
    my $head = $results->first;
    if( !$head && want( 'OBJECT' ) )
    {
        require Module::Generic::Null;
        rreturn( Module::Generic::Null->new( wants => 'OBJECT' ) );
    }
    return( $head );
}

# Note: property hidden read-only
sub hidden : lvalue { return; }

# Note: property images read-only
sub images : lvalue
{
    my $self = shift( @_ );
    my $results = $self->find( 'img' ) || return( $self->pass_error );
    return( $self->new_collection( $results ) );
}

# Note: property implementation read-only
sub implementation
{
    my $self = shift( @_ );
    unless( $self->{_implementation} )
    {
        $self->_load_class( 'HTML::Object::DOM::Implementation' ) || return( $self->pass_error );
        $self->{_implementation} = HTML::Object::DOM::Implementation->new( debug => $self->debug ) ||
            return( $self->pass_error( HTML::Object::DOM::Implementation->error ) );
    }
    return( $self->{_implementation} );
}

sub importNode { return( shift->adoptNode( @_ ) ); }

# Note: method insertAfter is inherited

# Note: method insertBefore is inherited

# Note: property lastChild is inherited

# Note: method lastElementChild is inherited from HTML::Object::DOM::Element

sub lastModified : lvalue { return( shift->_set_get_datetime( '_last_modified' ) ); }

# Note: property links read-only
sub links : lvalue
{
    my $self = shift( @_ );
    my $results = $self->find( 'a' ) || return( $self->pass_error );
    return( $results );
}

sub location : lvalue { return( shift->_set_get_uri( 'uri', @_ ) ); }

sub mozSetImageElement { return; }

# Note: property mozSyntheticDocument
sub mozSyntheticDocument : lvalue { return( shift->_set_get_boolean( 'mozsyntheticdocument', @_ ) ); }

sub nextSibling { return( shift->new_null ); }

# See also children for its alter ego
sub nodes { return( shift->_init_nodes ); }

# Note: Property
# Should be undef for document
# <https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>
sub nodeValue { return; }

# Note: this is merely an alias to HTML::Object::DOM::Node->normalize
sub normalizeDocument { return( shift->normalize( @_ ) ); }

# Note: Property
sub onabort : lvalue { return( shift->_set_get_on_signal( [qw( ABRT TERM INT )], @_ ) ); }

sub onafterscriptexecute : lvalue { return( shift->on( 'afterscriptexecute', @_ ) ); }

sub onbeforescriptexecute : lvalue { return( shift->on( 'beforescriptexecute', @_ ) ); }

sub oncopy : lvalue { return( shift->on( 'copy', @_ ) ); }

sub oncut : lvalue { return( shift->on( 'cut', @_ ) ); }

sub onerror : lvalue { return( shift->_set_get_on_signal( [qw( __WARN__ )], @_ ) ); }

sub onfullscreenchange : lvalue { return( shift->on( 'fullscreenchange', @_ ) ); }

sub onfullscreenerror : lvalue { return( shift->on( 'fullscreenerror', @_ ) ); }

sub onload : lvalue { return( shift->_set_get_code( 'onload', @_ ) ); }

sub onpaste : lvalue { return( shift->on( 'paste', @_ ) ); }

# sub onreadystatechange : lvalue { return( shift->_set_get_code( 'onreadystatechange', @_ ) ); }
sub onreadystatechange : lvalue { return( shift->on( 'readystatechange', @_ ) ); }

sub onscroll : lvalue { return( shift->on( 'scroll', @_ ) ); }

sub onselectionchange : lvalue { return( shift->on( 'selectionchange', @_ ) ); }

sub onvisibilitychange : lvalue { return( shift->on( 'visibilitychange', @_ ) ); }

sub onwheel : lvalue { return( shift->on( 'wheel', @_ ) ); }

sub open
{
    my $self = shift( @_ );
    # Already opened
    return( $self ) if( !$self->{_closed} );
    my $doc = $self->_list_to_nodes( q{<html><head><title></title></head><body></body></html>} ) ||
        return( $self->pass_error );
    # Remove the DTD
    $self->declaration( undef );
    my $html = $doc->children->first;
    return( $self->error( "Cannot find the top <html> element in our own standard document for document->open!" ) ) if( !$html );
    return( $self->error( "HTML top element found is not a <html> element" ) ) if( $html->tag ne 'html' );
    $html->parent( $self );
    $self->children->reset;
    $self->children->push( $html );
    $self->reset(1);
    return( $self );
}

# Note: property ownerDocument inherited from HTML::Object::DOM::Node

sub parentElement { return( shift->new_null ); }

sub parentNode { return( shift->new_null ); }

sub pictureInPictureElement : lvalue { return( shift->_set_get_object_lvalue( 'pictureinpictureelement', 'HTML::Object::DOM::Element', @_ ) ); }

sub pictureInPictureEnabled : lvalue { return( shift->_set_get_boolean( 'pictureinpictureenabled', @_ ) ); }

# Note: property read-only plugins
sub plugins { return( shift->new_collection ); }

sub pointerLockElement : lvalue { return( shift->_set_get_object_lvalue( 'pointerlockelement', 'HTML::Object::DOM::Element', @_ ) ); }

sub prepend
{
    my $self = shift( @_ );
    return( $self ) if( !scalar( @_ ) );
    # If a HTML::Object::DOM::DocumentFragment object is provided, its children are 
    # copied to the list and its own children array is emptied.
    my $list = $self->_check_list_of_nodes_or_text( @_ ) || return( $self->pass_error );
    my $nodes = $self->nodes;
    $self->reset(1) if( !$list->is_empty );
    $list->foreach(sub
    {
        $_->parent( $self );
    });
    $nodes->unshift( $list->list );
    return( $self );
}

sub previousSibling { return( shift->new_null ); }

sub queryCommandEnabled { return(0); }

sub queryCommandIndeterm { return(1); }

sub queryCommandState { return(0); }

sub queryCommandSupported { return(0); }

sub queryCommandValue { return; }

# Note: method querySelector is inherited from HTML::Object::DOM::Element

# Note: method querySelectorAll is inherited from HTML::Object::DOM::Element

sub readyState : lvalue { return( shift->_set_get_lvalue( 'readyState', @_ ) ); }

sub referrer : lvalue { return( shift->_set_get_uri( 'referrer', @_ ) ); }

sub releaseCapture { return( shift->defaultView->releaseCapture( @_ ) ); }

sub releaseEvents { return( shift->defaultView->releaseEvents( @_ ) ); }

# Note: method removeChild is inherited

# Note: replaceChild is inherited

# Note: the Document replaceChildren() method is different from the HTML::Object::DOM::Element replaceChildren()
sub replaceChildren
{
    my $self = shift( @_ );
    if( !scalar( @_ ) )
    {
        $self->nodes->reset;
        return( $self );
    }
    my $list = $self->_get_from_list_of_elements_or_html( @_ );
    return( $list ) if( $list->is_empty );
    my $html;
    foreach my $e ( @$list )
    {
        if( $self->_is_a( $e => 'HTML::Object::DOM::Element' ) )
        {
            if( $e->tag eq 'html' )
            {
                if( defined( $html ) )
                {
                    return( $self->error({
                        message => "You have already provided an <html> element. You can only provide one.",
                        class => 'HTML::Object::HierarchyRequestError',
                    }) );
                }
                else
                {
                    $html = $e;
                }
            }
            else
            {
                return( $self->error({
                    message => "Only the <html> element is allowed inside the Document.",
                    class => 'HTML::Object::HierarchyRequestError',
                }) );
            }
        }
    }
    return( $self->error({
        message => "You have not provided any <html> element. A document must have at least one <html> element.",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $html ) );
    return( $self ) if( $list->is_empty );
    my $nodes = $self->nodes;
    $nodes->reset;
    $list->foreach(sub
    {
        $_->detach;
        $_->parent( $self );
    });
    $nodes->push( $list->list );
    $self->children->reset;
    $self->children->push( $html );
    return( $self );
}

sub requestStorageAccess { return; }

# Note: property scripts read-only
sub scripts : lvalue
{
    my $self = shift( @_ );
    my $results = $self->find( 'script' ) || return( $self->pass_error );
    return( $results );
}

# Note: property scrollingElement read-only
sub scrollingElement : lvalue { return( shift->_set_get_object_lvalue( 'scrollingelement', 'HTML::Object::DOM::Element', @_ ) ); }

sub string_value { return; }

# Note: property styleSheets read-only
sub styleSheets : lvalue
{
    my $self = shift( @_ );
    my $list = $self->find( 'link[rel="stylesheet"]' ) || return( $self->pass_error );
    my $results2 = $self->find( 'stylesheet' ) || return( $self->pass_error );
    $list->merge( $results2 );
    return( $list );
}

# Note: property timeline read-only
sub timeline : lvalue { return; }

sub title : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        my $results = $self->find( 'title' ) || die( $self->error );
        return if( $results->is_empty );
        return( $results->first->text );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $arg  = shift( @_ );
        my $results = $self->find( 'title' ) || die( $self->error );
        my $e;
        if( $results->is_empty )
        {
            my $head_results = $self->find( 'head' ) || die( $self->error );
            if( $head_results->is_empty )
            {
                die( "Could not find the <head> tag to set as parent of the missing <title>. Something is seriously wrong." );
            }
            my $head = $head_results->first;
            $e = $self->createElement( 'title' );
            $e->close;
            $head->push( $e );
            $e->parent( $head );
        }
        else
        {
            $e = $results->first;
        }
        
        return( $e->text( $arg ) );
    },
}, @_ ) ); }

sub URL : lvalue { return( shift->_set_get_uri( 'uri', @_ ) ); }

# Note: property visibilityState read-only
sub visibilityState : lvalue { return( shift->_set_get_scalar_as_object( 'visibilitystate', @_ ) ); }

sub write
{
    my $self = shift( @_ );
    if( $self->{_closed} )
    {
        $self->open() || return( $self->pass_error );
    }
    my $body = $self->body || return( $self->pass_error );
    # Using _list_to_nodes from HTML::Object::DOM::Node
    my $list = $self->_list_to_nodes( @_ );
    $list->foreach(sub
    {
        $_->parent( $body );
    });
    $body->children->push( $list->list );
    return( $list );
}

sub writeln
{
    my $self = shift( @_ );
    my @args = @_;
    for( @args )
    {
        next if( ref( $_ ) && !overload::Method( $_, '""' ) );
        $_ .= "\n" unless( /\n$/ );
    }
    return( $self->write( @args ) );
}

sub _check_list_of_nodes_or_text
{
    my $self = shift( @_ );
    # If a HTML::Object::DOM::DocumentFragment object is provided, its children are 
    # copied to the list and its own children array is emptied.
    my $list = $self->_get_from_list_of_elements_or_html( @_ );
    return( $list ) if( $list->is_empty );
    my $html = $self->documentElement;
    foreach my $e ( @$list )
    {
        if( $self->_is_a( $e => 'HTML::Object::DOM::Element' ) )
        {
            # There can be only one element in the document: the <html> element.
            if( ref( $html ) )
            {
                return( $self->error({
                    message => "Cannot have more than one Element child of a Document and it must be an <html> element.",
                    class => 'HTML::Object::HierarchyRequestError',
                }) );
            }
            elsif( $e->tag ne 'html' )
            {
                return( $self->error({
                    message => "Only the <html> element is allowed inside the Document.",
                    class => 'HTML::Object::HierarchyRequestError',
                }) );
            }
        }
    }
    return( $list );
}

sub _init_nodes
{
    my $self = shift( @_ );
    unless( CORE::exists( $self->{nodes} ) )
    {
        my $children = $self->_set_get_object_array_object( 'children', 'HTML::Object::Element' );
        $self->{nodes} = $children;
        my $html = $children->grep(sub{ $self->_is_a( $_ => 'HTML::Object::DOM::Node' ) && $_->tag eq 'html' })->first;
        # We have a document with an <html> tag, we change the children to be an array with just the <html> element
        # and we set nodes to be the array containing all top nodes.
        # Maybe, we should change that structural design in the future to make it better
        if( $html )
        {
            my $new_children = $self->new_array( $html );
            $self->_set_get_object_array_object( 'children', 'HTML::Object::Element', $new_children );
        }
    }
    return( $self->{nodes} );
}

sub _set_get_on_signal : lvalue
{
    my $self = shift( @_ );
    my $sigs = shift( @_ ) || return;
    return if( ref( $sigs ) ne 'ARRAY' );
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    # To empty it, it must be set to an empty string
    if( $has_arg && defined( $arg ) )
    {
        my $code = $arg;
        if( ref( $code ) ne 'CODE' )
        {
            my $error = "Value provided is not a code reference (reference to a subroutine or anonymous subroutine).";
            if( $has_arg eq 'assign' )
            {
                $self->error({ message => $error, class => 'HTML::Object::TypeError' });
                return( $self->{__lvalue_error} = undef );
            }
            return( $self->error({ message => $error, class => 'HTML::Object::TypeError' }) ) if( want( 'LVALUE' ) );
            Want::rreturn( $self->error({ message => $error, class => 'HTML::Object::TypeError' }) );
        }
        foreach my $sig ( @$sigs )
        {
            $SIG{ $sig } = sub
            {
                my $type;
                if( $sig eq '__WARN__' || $sig eq '__DIE__' )
                {
                    ( $type = $sig ) =~ s/^__([A-Z]+)__$/$1/;
                }
                else
                {
                    $type = shift( @_ );
                }
                my $event = HTML::Object::ErrorEvent->new( $type, @_ );
                $code->( $event );
            };
        }
    }
    my $dummy = 1;
    return( $dummy ) if( want( 'LVALUE' ) );
    Want::rreturn( $dummy );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Document - HTML Object DOM Document Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Document;
    my $doc = HTML::Object::DOM::Document->new || 
        die( HTML::Object::DOM::Document->error, "\n" );

=head1 VERSION

    v0.2.2

=head1 DESCRIPTION

This module represents an HTML document. It inherits from L<HTML::Object::Document> and L<HTML::Object::DOM::Element>

It is the top object in the hierarchy and thus has no parent. It should contain only one child, the C<html> element, and has one associated L<element|HTML::Object::DOM::Element>, the L<doctype|/doctype>, which can also be accessed with L</declaration>

=head1 INHERITANCE

    +------------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------+
    | HTML::Object::Element  | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Document |
    +------------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------+
      |                                                                                                                                   ^
      |                                                                                                                                   |
      v                                                                                                                                   |
    +------------------------+                                                                                                            |
    | HTML::Object::Document | -----------------------------------------------------------------------------------------------------------+
    +------------------------+

=head1 PROPERTIES

=head2 activeElement

Normally this returns C<undef> under perl, but you can set it to whatever L<element object|HTML::Object::DOM::Element> you want.

Under JavaScript, this returns the L<element|HTML::Object::DOM::Element> that currently has focus.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/activeElement>

=head2 body

Returns the C<body> L<node object|HTML::Object::Element> of the current document.

Example:

    # Given this HTML: <body id="oldBodyElement"></body>
    say($doc->body->id); # "oldBodyElement"

    my $aNewBodyElement = $doc->createElement("body");

    $aNewBodyElement->id = "newBodyElement";
    $doc->body = $aNewBodyElement;
    say($doc->body->id); # "newBodyElement"

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/body>

=head2 characterSet

This is read-only.

Returns the character set being used by the document. This is always C<utf-8>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/characterSet>

=head2 childElementCount

This is read-only.

Returns the number of child elements of the current document. This being the top document, it typically contains only 1 element, the C<<html>> tag.

The total number of children is not the same as the number of child nodes.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/childElementCount>

=head2 children

This is read-only.

Returns the child elements of the current document, as an L<array object|Module::Generic::Array>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/children>

=head2 compatMode

Returns C<undef> since this is not relevant under perl.

Normally, it would indicate whether the document is rendered in quirks or strict mode.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/compatMode>

=head2 contentType

This is read-only.

Returns the Content-Type from the MIME Header of the current document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/contentType>

=head2 cookie

Set or get a semicolon-separated list of the cookies for that document or sets a single cookie.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/cookie>

=head2 currentScript

Under perl, this does not nor return do anything special, but you can set yourself an L<HTML::Object::DOM::Element>.

Normally, under JavaScript, this returns the C<currentScript> property returns the <script> element whose script is currently being processed and is not a JavaScript module.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/currentScript>

=head2 defaultView

This returns a reference to the L<window object|HTML::Object::DOM::Window>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/defaultView>

=head2 designMode

This always returns true under perl.

Under the web, with JavaScript, this would get/set the ability to edit the whole document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/designMode>

=head2 dir

Get or set directionality (rtl/ltr) of the document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/dir>

=head2 doctype

This is read-only.

Returns the Document Type Definition (DTD) L<object|HTML::Object::Element> of the current document.

Example:

    my $doctypeObj = $doc->doctype;

    say(
        "doctype->name: " . $doctypeObj->name . "\n" +
        "doctype->internalSubset: " . $doctypeObj->internalSubset . "\n" +
        "doctype->publicId: " . $doctypeObj->publicId . "\n" +
        "doctype->systemId: " . $doctypeObj->systemId
    );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/doctype>

=head2 documentElement

This is read-only.

Returns the L<element|HTML::Object::DOM::Element> that is a direct child of the document. For HTML documents, this is normally the L<HTML Element|HTML::Object::Element> object representing the document's C<<html>> element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/documentElement>

=head2 documentURI

Set or get the document location as a string, if any.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/documentURI>

=head2 embeds

This is read-only.

Returns a list, as an L<html collection object|HTML::Object::DOM::Collection>, of the embedded <embed> elements within the current document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/embeds>

=head2 featurePolicy

Returns C<undef> since this is not relevant under perl.

Normally, under JavaScript, this would return the FeaturePolicy interface which provides a simple API for introspecting the feature policies applied to a specific document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/featurePolicy>

=head2 firstElementChild

This is read-only.

Returns the first child L<element|HTML::Object::DOM::Element> of the current document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/firstElementChild>

=head2 fonts

Returns C<undef> since this is not relevant under perl.

Normally, it would return the C<FontFaceSet> interface of the current document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/fonts>

=head2 forms

This is read-only.

Returns a list, as an L<html collection object|HTML::Object::DOM::Collection>, of the <form> elements within the current document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/forms>

=head2 fullscreenElement

Returns C<undef> since this is not relevant under perl.

Normally, it would return the element that is currently in full screen mode for this document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/fullscreenElement>

=head2 head

This is read-only.

Returns the L<<head> element|HTML::Object::DOM::Head> of the current document, or C<undef> if there is none.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/head>

=head2 hidden

Returns C<undef> since this is not relevant under perl.

Normally, it would return a boolean value indicating if the page is considered hidden or not.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/hidden>

=head2 images

This is read-only.

Returns a list, as an L<html collection object|HTML::Object::DOM::Collection>, of the images in the current document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/images>

=head2 implementation

This returns the L<DOM implementation object|HTML::Object::DOM::Implementation> associated with the current document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/implementation>

=head2 lastElementChild

This is read-only.

Returns the last child L<element|HTML::Object::DOM::Element> of the current document, which is the root <html> element, the only child of the document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/lastElementChild>

=head2 lastModified

This is read-only.

Returns the date on which the document was last modified, if any, as a L<DateTime> object.

This value exists if the document was read from a file, and it would contain the file last modification time.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/lastModified>

=head2 links

This is read-only.

Returns a list, as an L<html collection object|HTML::Object::DOM::Collection>, of all the hyperlinks in the document.

Example:

    my $links = $doc->$links;
    for( my $i = 0; $i < $links->length; $i++ )
    {
        my $linkHref = $doc->createTextNode( $links->[$i]->href );
        my $lineBreak = $doc->createElement("br");
        $doc->body->appendChild( $linkHref );
        $doc->body->appendChild( $lineBreak );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/links>

=head2 location

Set or get the URI of the current document. This is the same as L</documentURI>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/location>

=head2 mozSyntheticDocument

Normally this is returns C<undef> under perl, byt you can set whatever boolean value you want.

Under JavaScript, this returns a boolean that is true only if this document is synthetic, such as a standalone image, video, audio file, or the like.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/mozSyntheticDocument>

=head2 nodeValue

This returns or sets the value of the current node.

For document, element or collection, this returns C<undef> and for attribute, text or comment, this returns the objct value.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head2 ownerDocument

Read-only. This always returns C<undef> since this is the top element. This is inherited from L<HTML::Object::DOM::Node>

=head2 pictureInPictureElement

Normally this returns C<undef> under perl, but you can set whatever L<element|HTML::Object::DOM::Element> object you want.

Under JavaScript, this returns C<undef> since this is not relevant under perl.

Normally, under JavaScript, this would return the Element currently being presented in picture-in-picture mode in this document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/pictureInPictureElement>

=head2 pictureInPictureEnabled

Normally this returns C<undef> under perl, but you can set whatever boolean value you want.

Under JavaScript, this would return true if the picture-in-picture feature is enabled, and false otherwise.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/pictureInPictureEnabled>

=head2 plugins

Returns always an empty L<collection object|HTML::Object::DOM::Collection> since this is not relevant under perl.

Normally, under JavaScript, this would return a list, as a collection, of the available plugins.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/plugins>

=head2 pointerLockElement

Normally this returns C<undef> under perl, but you can set whatever L<element|HTML::Object::DOM::Element> object you want.

Under JavaScript, this would return the element set as the target for mouse events while the pointer is locked. null if lock is pending, pointer is unlocked, or if the target is in another document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/pointerLockElement>

=head2 readyState

This is read-only.

Returns loading status of the document. This always returns a true value.

The readyState of a document can be one of following:

=over 4

=item B<loading>

The document is still loading.

=item B<interactive>

The document has finished loading and the document has been parsed.

There is actually no distinction with the following C<complete> state.

=item B<complete>

The document and all its resources have finished loading. The state indicates that the load event is about to fire.

This is actually the same state as C<interactive>

=back

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/readyState>

=head2 referrer

Set or get the URI of the page that linked to this page.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/referrer>

=head2 scripts

This is read-only.

Returns all the L<<script> elements|HTML::Object::DOM::Element::Script> on the document, as a L<collection object|HTML::Object::DOM::Collection>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/scripts>

=head2 scrollingElement

Although this is meaningless under perl, you can set or get an L<element object|HTML::Object::DOM::Element> that scrolls the document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/scrollingElement>

=head2 styleSheets

This is read-only.

Returns a list, as an L<array object|Module::Generic::Array>, of L<CSS StyleSheet element objects|HTML::Object::Element> for stylesheets explicitly linked into, or embedded in a document.

Contrary to the original JavaScript equivalent, this does not return C<CSSStyleSheet> objects, because it would be potentially heavy to parse each css in C<link> and C<style> tags. You could do this yourself by using L<CSS::Object> and looping through each L<element object|HTML::Object::Element> returned. For example:

    $doc->styleSheets->foreach(sub
    {
        my $e = shift( @_ );
        if( $e->tag eq 'link' )
        {
            my $resp = $ua->get( $e->attr( 'href' ) );
            die( $resp->message ) if( $resp->is_error );
            my $style = $resp->decoded_content;
            my $css = CSS::Object->new;
            $css->read_string( $style );
            $css->rules->foreach(sub
            {
                my $rule = shift( @_ );
                # more processing
            });
        }
        elsif( $e->tag eq 'style' )
        {
            my $css = CSS::Object->new;
            $css->read_string( $e->text );
            $css->rules->foreach(sub
            {
                my $rule = shift( @_ );
                # more processing
            });
        }
    });

or you can use L<HTML::Object::XQuery/find> with a xpath selector, such as:

    use HTML::Object::XQuery; # Load jQuery style query functions
    # $doc is the HTML::Object::Document returned by HTML::Object->parse
    my $collection = $doc->find( 'link[rel="https://example.org/css/main.css"]' ) ||
        die( $doc->error );
    $collection->children->foreach(sub
    {
        # more processing
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/styleSheets>

=head2 timeline

Returns C<undef> since this is not relevant under perl.

Normally, under JavaScript, this would return timeline as a special instance of DocumentTimeline that is automatically created on page load.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/timeline>

=head2 title

Set or get the title of the current document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/title>

=head2 URL

Set or get the document location as a string.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/URL>

=head2 visibilityState

Normally this returns C<undef> under perl, but you can set whatever string value you want. This returns a L<scalar object|Module::Generic::Scalar>

Under JavaScript, this would return a string denoting the visibility state of the document. Possible values are visible, hidden, prerender, and unloaded.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilityState>

=head1 METHODS

=head2 adoptNode

L</adoptNode> transfers a L<node|HTML::Object::Element> from another document into the method's L<document|HTML::Object::Document>. The adopted L<node|HTML::Object::Element> and its subtree is removed from its original document (if any), and its ownerDocument is changed to the current document. The L<node|HTML::Object::Element> can then be inserted into the current L<document|HTML::Object::Document>.

Before they can be inserted into the current document, nodes from external documents should either be: 

=over 4

=item * cloned using L</importNode>; or

=item * adopted using L</adoptNode>.

=back

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/adoptNode>

=head2 append

Inserts a set of Node objects or string objects after the last child of the document.

This is inherited from L<HTML::Object::DOM::Element>

Example:

    my $html = $doc->createElement( 'html' );
    $doc->append( $html );
    # HierarchyRequestError: The operation would yield an incorrect node tree.

# Also

    my $doc = HTML::Object::DOM::Document->new;
    my $html = $doc->createElement( 'html');
    $doc->append( $html );

    $doc->children; # HTMLCollection [<html>]

=head2 appendChild

Provided with one or more nodes and this will add them to the list of this document's children.

=head2 as_string

Returns a string representation of this document and all its hierarchy.

=head2 captureEvents

See L<HTML::Object::DOM::Window/captureEvents>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/captureEvents>

=head2 caretRangeFromPoint

Always returns C<undef> under perl.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/caretRangeFromPoint>

=head2 caretPositionFromPoint

Returns C<undef> since this is not relevant under perl.

Normally, under JavaScript, this would return a CaretPosition object containing the DOM node containing the caret, and caret's character offset within that node.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/caretPositionFromPoint>

=head2 childNodes

Returns an L<array object|Module::Generic::Array> of the document child nodes.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/childNodes>

=head2 close

The C<close()> method finishes writing to a document, opened with L</open>.

Example:

    # Open a document to write to it
    $doc->open();

    # Write the content of the document
    $doc->write("<p>The one and only content.</p>");

    # Close the document
    $doc->close();

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/close>

=head2 contentType

=head2 createAttribute

Provided with an argument and this creates a new L<attribute object|HTML::Object::Attribute> and returns it.

The attribute name is converted to lowercase.

Example:

    my $node = $doc->getElementById( 'div1' );
    my $a = $doc->createAttribute( 'my_attrib' );
    $a->value = 'newVal';
    $node->setAttributeNode( $a );
    say( $node->getAttribute( 'my_attrib' ) ); # "newVal"

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createAttribute>

=head2 createAttributeNS

Returns C<undef> since this is not relevant under perl.

Normally, under JavaScript, this would create a new attribute node in a given namespace and returns it.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createAttributeNS>

=head2 createCDATASection

Returns C<undef> since this is not relevant under perl.

Normally, under JavaScript, this would create a new CDATA node and returns it.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createCDATASection>

=head2 createComment

Creates a new comment node and returns it.

Example:

    my $comment = $doc->createComment( 'This is a not-so-secret comment in your document' );
    $doc->getElementsByTagName( 'div' )->[0]->appendChild( $comment );
    say( $doc->as_string );
    # <div><!--This is a not-so-secret $comment in your document--></div>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createComment>

=head2 createDocumentFragment

This create a new L<HTML::Object::DOM::DocumentFragment> object, passing its C<new()> constructor whatever argument was provided.

It returns the newly instantiated object.

L<Document fragments|HTML::Object::DOM::DocumentFragment> are L<DOM Node|HTML::Object::DOM::Node> objects which are never part of the main L<DOM tree|HTML::Object::DOM::Document>. The usual use case is to create the document fragment, append elements to the document fragment and then append the document fragment to the L<DOM tree|HTML::Object::DOM::Document>. In the L<DOM tree|HTML::Object::DOM::Document>, the document fragment is replaced by all its children.

Since the L<document fragment|HTML::Object::DOM::DocumentFragment> is not part of the main L<DOM tree|HTML::Object::DOM::Document>, appending children to it does not affect the main tree.

Example:

    <ul id="ul"></ul>

    use Module::Generic::Array;
    my $element  = $doc->getElementById('ul'); # assuming ul exists
    my $fragment = $doc->createDocumentFragment();
    my $browsers = Module::Generic::Array->new( ['Firefox', 'Chrome', 'Opera',
        'Safari', 'Internet Explorer'] );

    $browsers->foreach(sub
    {
        my $browser = shift( @_ );
        my $li = $doc->createElement('li');
        $li->textContent = $browser;
        $fragment->appendChild( $li );
    });

    $element->appendChild( $fragment );

would yield:

=over 4

=item * Firefox

=item * Chrome

=item * Opera

=item * Safari

=item * Internet Explorer

=back

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createDocumentFragment>

=head2 createElement

Provided with a tag name and this creates a new L<HTML::Object::Element> object that is returned.

This methods sets an L<error|Module::Generic/error> and returns C<undef> upon error.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createElement>

=head2 createElementNS

Returns C<undef> since this is not relevant under perl.

Normally, under JavaScript, this would create a new element with the given tag name and namespace URI.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createElementNS>

=head2 createEntityReference

Returns C<undef> since this is not relevant for HTML document. This is used for XML.

This was used to create a new entity reference object and returns it.

Example:

    $doc->createEntityReference( '&amp' ); # &

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createEntityReference>

=head2 createEvent

Creates an event object, passing it whatever arguments were provided, and returns it.

Example:

    my $event = $doc->createEvent( $type );

    # Create the $event.
    my $event = $doc->createEvent( 'click' );

    # Define that the event name is 'build'.
    $event->initEvent( build => { bubbles => 1 });

    # Listen for the $event.
    $elem->addEventListener( build => sub
    {
        # e->target matches elem
    }, { capture => 0 });

    # Target can be any Element or other EventTarget.
    $elem->dispatchEvent( $event );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createEvent>

=head2 createExpression

Compiles an L<HTML::Object::XPath::Expr> which can then be used for (repeated) evaluations. It returns a L<HTML::Object::DOM::XPathResult> object.

Example:

    my $xpathExpr = $doc->createExpression( $xpathText );
    my $result = $xpathExpr->evaluate( $contextNode );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createExpression>

=head2 createNSResolver

This always returns C<undef> as XML is not used in L<HTML::Object>

Normally, under JavaScript, this creates an C<XPathNSResolver> object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createNSResolver>

=head2 createNodeIterator

Creates a L<HTML::Object::DOM::NodeIterator> object.

Example:

    use Module::Generic::Array;
    my $nodeIterator = $doc->createNodeIterator(
        $doc->body,
        NodeFilter->SHOW_ELEMENT,
        {
            sub acceptNode
            {
                my $node = shift( @_ );
                return( $node->nodeName->toLowerCase() == 'p' ? NodeFilter->FILTER_ACCEPT : NodeFilter->FILTER_REJECT;
            }
        }
    );
    my $pars = Module::Generic::Array->new;
    my $currentNode;

    while( $currentNode = $nodeIterator->nextNode() )
    {
        $pars->push( $currentNode );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createNodeIterator>

=head2 createProcessingInstruction

Creates a new C<ProcessingInstruction> object.

Example:

    my $doc = HTML::Object::DOM->new->parseFromString('<foo />', 'application/xml');
    my $pi = $doc->createProcessingInstruction('xml-stylesheet', 'href="mycss->css" type="text/css"');

    $doc->insertBefore($pi, $doc->firstChild);

    say( $doc->as_string );
    # Displays: <?xml-stylesheet href="mycss->css" type="text/css"?><foo/>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createProcessingInstruction>

=head2 createRange

This always returns C<undef> under perl.

Normally, under JavaScript, this creates a C<Range> object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createRange>

=head2 createTextNode

Provided with a text, either as a string, or as a list of strings, and this creates a text node.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createTextNode>

=head2 createTouch

This always returns C<undef> under perl.

Normally, under JavaScript, this creates a Touch object.

Also, this feature is deprecated.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createTouch>

=head2 createTouchList

This always returns C<undef> under perl.

Normally, under JavaScript, this creates a C<TouchList> object.

Also, this feature is deprecated.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createTouchList>

=head2 createTreeWalker

Creates a C<TreeWalker> object.

Example:

    use HTML::Object::DOM::NodeFilter qw( :all );
    my $treeWalker = $doc->createTreeWalker(
        $doc->body,
        SHOW_ELEMENT,
        sub{ return( FILTER_ACCEPT ); },
    );

    my $nodeList = Module::Generic::Array->new;
    my $currentNode = $treeWalker->currentNode;

    while( $currentNode )
    {
        $nodeList->push( $currentNode );
        $currentNode = $treeWalker->nextNode();
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/createTreeWalker>

=head2 elementFromPoint

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the topmost element at the specified coordinates.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/elementFromPoint>

=head2 elementsFromPoint

This always returns C<undef> under perl.

Normally, under JavaScript, this returns an array of all elements at the specified coordinates.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/elementsFromPoint>

=head2 enableStyleSheetsForSet

This always returns C<undef> under perl.

Normally, under JavaScript, this enables the style sheets for the specified style sheet set.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/enableStyleSheetsForSet>

=head2 evaluate

Evaluates an L<XPath|HTML::Object::XPath> expression.

Example:

    my $xpathResult = $doc->evaluate(
        $xpathExpression,
        $contextNode
    );

    my $headings = $doc->evaluate( "/html/body//h2", $document );
    # Search the document for all h2 elements.
    # The result will likely be an unordered node iterator.
    my $thisHeading = $headings->iterateNext();
    my $alertText = "Level 2 $headings in this document are:\n";
    while( $thisHeading )
    {
        $alertText .= $thisHeading->textContent . "\n";
        $thisHeading = $headings->iterateNext();
    }
    say( $alertText ); # print the text of all h2 elements

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/evaluate>

=head2 execCommand

This does absolutely nothing and always returns C<undef>.

This is actually a deprecated feature of the web API.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand>

=head2 exitPictureInPicture

This always returns C<undef> under perl.

Normally, under JavaScript, this removes the video from the floating picture-in-picture window back to its original container.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/exitPictureInPicture>

=head2 exitPointerLock

This always returns C<undef> under perl.

Normally, under JavaScript, this releases the pointer lock.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/exitPointerLock>

=head2 firstChild

Returns the first child from the document list of nodes.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/firstChild>

=head2 firstElementChild

=head2 getElementById

Provided with an element C<id>, and this method returns the corresponding L<element object|HTML::Object::Element>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementById>

=head2 getAnimations

This always returns C<undef> under perl.

Normally, under JavaScript, this returns an array of all Animation objects currently in effect, whose target elements are descendants of the document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/getAnimations>

=head2 getBoxQuads

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a list of C<DOMQuad> objects representing the CSS fragments of the node.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/getBoxQuads>

=head2 getElementById

Provided with a string and this returns an element object whose C<id> attribute matches the string specified.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementById>

=head2 getElementsByClassName

Returns a list of elements with the given class name.

Example:

    <span class="orange fruit">Orange Fruit</span>
    <span class="orange juice">Orange Juice</span>
    <span class="apple juice">Apple Juice</span>
    <span class="foo bar">Something Random</span>
    <textarea id="resultArea" style="width:98%;height:7em"></textarea>

Another example:

    # getElementsByClassName only selects elements that have both given classes
    my $allOrangeJuiceByClass = $doc->getElementsByClassName('orange juice');
    my $result = "$doc->getElementsByClassName('orange juice')";
    for( my $i=0; $i < $allOrangeJuiceByClass->length; $i++ )
    {
        $result .= "\n    " . $allOrangeJuiceByClass->[$i]->textContent;
    }

    # querySelector only selects full complete matches
    my $allOrangeJuiceQuery = $doc->querySelectorAll('.orange->juice');
    $result += "\n\ndocument->querySelectorAll('.orange->juice')";
    for( my $i=0; $i < $allOrangeJuiceQuery->length; $i++ )
    {
        $result .= "\n    " . $allOrangeJuiceQuery->[$i]->textContent;
    }

    $doc->getElementById( 'resultArea' )->value = $result;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByClassName>

=head2 getElementsByName

Returns a L<NodeList|HTML::Object::DOM::NodeList> Collection of elements with a given name attribute in the L<document|HTML::Object::DOM::Element>.

Example:

    <!DOCTYPE html>
    <html lang="en">
        <head>
            <title>Example: using getElementsByName</title>
        </head>
        <body>
            <input type="hidden" name="up" />
            <input type="hidden" name="down" />
        </body>
    </html>

    my $up_names = $doc->getElementsByName( 'up' );
    say( $up_names->[0]->tagName ); # displays "input"

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByName>

=head2 getElementsByTagName

Returns a L<list|HTML::Object::DOM::Collection> of elements with the given tag name.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByTagName>

=head2 getElementsByTagNameNS

This is merely an alias to L</getElementsByTagName> since there is no support for namespace.

Normally, under JavaScript, this returns a list of elements with the given tag name and namespace.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByTagNameNS>

=head2 getRootNode

Returns the current object.

=head2 getSelection

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a C<Selection> object representing the range of text selected by the user, or the current position of the caret.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/getSelection>

=head2 hasChildNodes

Returns true if the document list of nodes is not empty, false otherwise.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/hasChildNodes>

=head2 hasFocus

Under perl, this always returns true.

Normally, under JavaScript, this returns a boolean value indicating whether the document or any element inside the document has focus. This method can be used to determine whether the active element in a document has focus. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/hasFocus>

=head2 hasStorageAccess

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a C<Promise> that resolves with a boolean value indicating whether the document has access to its first-party storage.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/hasStorageAccess>

=head2 importNode

Returns a clone of a node from an external document.

Example:

    my $iframe  = $doc->querySelector( 'iframe' );
    my $oldNode = $iframe->contentWindow->document->getElementById( 'myNode' );
    my $newNode = $doc->importNode( $oldNode, $true );
    $doc->getElementById( 'container' )->appendChild( $newNode );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/importNode>

=head2 insertAfter

Provided with a node and a reference node and this will insert the node after the reference node.

It returns the current object upon success, or C<undef> upon L<error|Module::Generic/error>

Surprisingly enough there is no C<insertAfter> method in the web API, only L</insertBefore>

=head2 insertBefore

Provided with a node and a reference node and this will insert the node before the reference node.

It returns the current object upon success, or C<undef> upon L<error|Module::Generic/error>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/insertBefore>

=head2 lastChild

Returns the last child node from the document list of nodes.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/lastChild>

=head2 mozSetImageElement

This always returns C<undef> under perl.

Normally, under JavaScript, this allows you to change the element being used as the background image for a specified element ID.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/mozSetImageElement>

=head2 nextSibling

Returns a L<smart undef|Module::Generic/new_null>. This means the return value will depend on what the caller expects. In scalar context it will return C<undef> and an empty list in list context, but if this method is chained, it will return a dummy object to avoid the perl error "method called on an undefined value"

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/nextSibling>

=head2 normalizeDocument

Replaces entities, normalizes text nodes, etc.

This is actually an alias to L<HTML::Object::DOM::Node/normalize>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/normalizeDocument>

=head2 open

The C<open()> method opens a document for writing and returns the current L<document|HTML::Object::DOM::Document> object.

This does come with some side effects. For example:

=over 4

=item * All event listeners currently registered on the L<document|HTML::Object::DOM::Document>, L<nodes|HTML::Object::DOM::Node> inside the L<document|HTML::Object::DOM::Document>, or the document's L<window|HTML::Object::DOM::Window> are removed.

=item * All existing L<nodes|HTML::Object::DOM::Node> are removed from the L<document|HTML::Object::DOM::Document>.

=back

Example:

The following simple code opens the document and replaces its content with a number of different HTML fragments, before closing it again.

    my $doc = $parser->parse_data( $html );
    $doc->open();
    $doc->write("<p>Hello world!</p>");
    $doc->write("<p>I am a fish</p>");
    $doc->write("<p>The number is 42</p>");
    $doc->close();

An automatic L</open> call happens when L</write> is called after the document has loaded.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/open>

=head2 parentElement

This interface returns the DOM node's parent Element, or C<undef> if the node either has no parent, or its parent isn't a DOM Element. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/parentElement>

=head2 parentNode

This returns the parent of the specified node in the DOM tree.

Document and L<DocumentFragment|HTML::Object::DOM::DocumentFragment> nodes can never have a parent, so C<parentNode> will always return C<undef>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/parentNode>

=head2 prepend

Inserts a set of L<Node|HTML::Object::DOM::Node> objects or string objects before the first child of the document.

Example:

    my $html = $doc->createElement( 'html' );
    $doc->prepend( $html );
    # HierarchyRequestError: The operation would yield an incorrect node tree.

Another example:

    my $doc = HTML::Object::DOM::Document->new;
    my $html = $doc->createElement( 'html' );
    $doc->prepend( $html );

    $doc->children; # HTMLCollection [<$html>]

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/prepend>

=head2 previousSibling

This returns the node immediately preceding the specified one in its parent's childNodes list, or C<undef> if the specified node is the first in that list.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/previousSibling>

=head2 queryCommandEnabled

This always returns false under perl.

Normally, under JavaScript, this reports whether or not the specified editor command is enabled by the browser.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/queryCommandEnabled>

=head2 queryCommandIndeterm

This always returns true under perl.

Normally, under JavaScript, this returns true if the formatting command is in an indeterminate state on the current range.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/queryCommandIndeterm>

=head2 queryCommandState

This always returns false under perl.

Normally, under JavaScript, this returns true if the formatting command has been executed on the current range.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/queryCommandState>

=head2 queryCommandSupported

This always returns false under perl.

Normally, under JavaScript, this returns true if the formatting command is supported on the current range.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/queryCommandSupported>

=head2 queryCommandValue

This always returns C<undef> under perl.

Normally, under JavaScript, this returns the current value of the current range for a formatting command.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/queryCommandValue>

=head2 querySelector

Returns the first Element node within the document, in document order, that matches the specified selectors.

Example:

    <div id="foo\bar"></div>
    <div id="foo:bar"></div>

    $doc->querySelector( '#foo\\bar' ); # Match the first div
    $doc->querySelector( '#foo\:bar' ); # Match the second div

    my $el = $doc->querySelector(".myclass");

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector>

=head2 querySelectorAll

Returns a list of all the Element nodes within the document that match the specified selectors.

Example:

    <div class="outer">
        <div class="select">
            <div class="inner">
            </div>
        </div>
    </div>

    my $inner = $select->querySelectorAll( '.outer .inner' );
    $inner->length; # 1, not 0

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelectorAll>

=head2 releaseCapture

Releases the current mouse capture if it's on an element in this document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/releaseCapture>

=head2 releaseEvents

See L<HTML::Object::DOM::Window/releaseEvents>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/releaseEvents>

=head2 removeChild

Provided with a node and this removes a child node from the DOM and returns the removed node. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/removeChild>

=head2 replaceChild

Provided with a C<new> node and and an C<old> node and this will replace the C<old> one by the C<new> one. Note that if the C<new> node is already present somewhere else in the C<DOM>, it is first removed from that position.

This returns the C<old> node removed.

See the document in L<HTML::Object::DOM::Node/replaceChild> for more details.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Node/replaceChild>

=head2 replaceChildren

Replaces the existing children of a document with a specified new set of children.

Example:

    $doc->replaceChildren();
    $doc->children; # HTMLCollection []

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/replaceChildren>

=head2 requestStorageAccess

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a C<Promise> that resolves if the access to first-party storage was granted, and rejects if access was denied.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/requestStorageAccess>

=head2 string_value

This always return C<undef>.

=head2 write

Provided with a list of nodes and this will write them to the body of this document. If the document is already closed, such as when it has already loaded, this will call L</open>, which will cause to empty the document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/write>

=head2 writeln

Same as with L</write>, except this will add a new line.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/writeln>

=head1 EVENTS

There is only limited support for events under perl, but you can trigger yourself any event.

Event listeners for those events can also be found by prepending C<on> before the event type:

C<click> event listeners can be set also with C<onclick> method:

    $e->onclick(sub{ # do something });
    # or as an lvalue method
    $e->onclick = sub{ # do something };

Below are some key ones, but you can see the full lists on the L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document#events>

=head2 DOMContentLoaded

Fired when the document has been completely loaded and parsed, without waiting for stylesheets, images, and subframes to finish loading.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/DOMContentLoaded_event>

=head2 readystatechange

Fired when the readyState attribute of a document has changed.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/readystatechange_event>

=head2 visibilitychange

Fired when the content of a tab has become visible or has been hidden. Also available via the onvisibilitychange property.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilitychange_event>

=head1 EVENT HANDLERS

Listen to these events using L<HTML::Object::EventTarget/addEventListener> or by assigning an event listener to the C<oneventname> property of this interface.

Under perl, few events are actually "fired" by L<HTML::Object::DOM::Document> and L<for the others|https://developer.mozilla.org/en-US/docs/Web/API/Element#events>, nothing prevents you from L<triggering|HTML::Object::EventTarget/dispatchEvent> whatever events you want on any L<element|HTML::Object::DOM::Element>, even private non-standard ones, and set up listeners for them.

Below are the ones actually "fired" by L<HTML::Object>.

=head2 onabort

This takes a code reference (a reference to a subroutine or an anonymous subroutine) as its unique argument.

The C<onabort> property is the L<event|HTML::Object::Event> handler for processing C<abort> events sent to the perl script.

It returns C<undef> and sets an C<HTML::Object::TypeError> error if the value provided is not a code reference, i.e. a reference to an existing subroutine or an anonymous subroutine.

It returns true upon success.

Upon an abort signal (C<ABRT>, C<INT> or C<TERM>), this will execute the code reference, passing it an L<error event object|HTML::Object::ErrorEvent>

Example:

    use HTML::Object::DOM;
    my $p = HTML::Object::DOM->new;
    $doc = $p->parse_data( $some_html_string );
    $doc->onabort = sub
    {
        my $event = shift( @_ );
        print( "Oh no: ", $event->trace, "\n" );
    };
    # or
    $doc->onabort = \&exception_handler;

=head2 onafterscriptexecute

Under perl, no such event is fired, but you can trigger one yourself.

This property references a function that fires when a static <script> element finishes executing its script. It does not fire if the element is added dynamically, such as with appendChild().

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/onafterscriptexecute>

=head2 onbeforescriptexecute

Under perl, no such event is fired, but you can trigger one yourself.

This is fired when the code in a <script> element declared in an HTML document is about to start executing. Does not fire if the element is added dynamically, eg with appendChild().

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/onbeforescriptexecute>

=head2 oncopy

Under perl, no such event is fired, but you can trigger one yourself.

This represents the event handling code for the copy event.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/oncopy>

=head2 oncut

Under perl, no such event is fired, but you can trigger one yourself.

This represents the event handling code for the cut event.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/oncut>

=head2 onerror

The C<onerror> property is an L<event|HTML::Object::Event> handler that processes error events triggered by a L<perlfunc/warn> or L<perlfunc/die>

Upon an error signal (C<__WARN__>, or C<__DIE__>), this will execute the code reference, passing it an L<error event object|HTML::Object::ErrorEvent>

Example:

    use HTML::Object::DOM;
    my $p = HTML::Object::DOM->new;
    $doc = $p->parse_data( $some_html_string );
    $doc->onerror = sub
    {
        my $event = shift( @_ );
        print( "Oh no: ", $event->trace, "\n" );
    };
    # or
    $doc->onerror = \&exception_handler;

=head2 onfullscreenchange

Under perl, no such event is fired, but you can trigger one yourself.

This property is an event handler for the fullscreenchange event that is fired immediately before a document transitions into or out of full-screen mode.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/onfullscreenchange>

=head2 onfullscreenerror

Under perl, no such event is fired, but you can trigger one yourself.

This property is an event handler for the fullscreenerror event that is sent to the  document when it fails to transition into full-screen mode after a prior call to Element.requestFullscreen().

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/onfullscreenerror>

=head2 onload

The C<onload> property is an event handler for the C<load> event that fires when the initial HTML L<document|HTML::Object::DOM::Document> has been completely loaded and parsed. It is fired after the L</readyState> has changed to C<complete>

Contrary to the JavaScript environment, under perl, there is obviously no window and thus no difference between the JavaScript L<window load|https://developer.mozilla.org/en-US/docs/Web/API/Window/load_event> event and the L<DOMContentLoaded|https://developer.mozilla.org/en-US/docs/Web/API/Document/DOMContentLoaded_event> event

For example:

    $doc->addEventListener( load => sub
    {
        say( 'Document fully loaded and parsed' );
    });

    sub doSomething
    {
        say( 'Document loaded' );
    }

    # Loading has not finished yet
    if( $doc->readyState eq 'loading' )
    {
        $doc->addEventListener( load => \&doSomething );
    }
    # 'load' has already fired
    else
    {
        doSomething();
    }

Upon execution, a new L<event|HTML::Object::Event> is passed of type C<readstate> and with the C<detail> property having the following data available:

=over 4

=item document

The L<document object|HTML::Object::DOM::Document>

=item state

The state of the document parsing.

=back

The event C<target> property is also set to the L<document object|HTML::Object::DOM::Document>.

=head2 onpaste

Under perl, no such event is fired, but you can trigger one yourself.

This property interface is an event handler that processes paste events.

The paste event fires when the user attempts to paste text.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/onpaste>

=head2 onreadystatechange

The C<onreadystatechange> property is an event handler for the C<readystatechange> event that is fired when the L</readyState> attribute of a L<document|HTML::Object::DOM::Document> has changed.

There are 3 state: C<loading>, C<interactive> and C<complete> (which is the same, under perl, as C<loading>)

This event does not bubble and is not cancelable

Upon execution, a new L<event|HTML::Object::Event> is passed of type C<readstate> and with the C<detail> property having the following data available:

=over 4

=item document

The L<document object|HTML::Object::DOM::Document>

=item state

The state of the document parsing.

=back

The event C<target> property is also set to the L<document object|HTML::Object::DOM::Document>.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Document/readystatechange_event>

=head2 onscroll

Under perl, no such event is fired, but you can trigger one yourself.

This property interface is an event handler that processes events when the document view or an element has been scrolled, whether by the user, a Web API, or the user agent. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers/onscroll>

=head2 onselectionchange

Under perl, no such event is fired, but you can trigger one yourself.

This is fired when the Selection of a Document is changed. The Selection consists of a starting position and (optionally) a range of HTML nodes from that position. Clicking or starting a selection outside of a text field will generally fire this event.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers/onselectionchange>

=head2 onvisibilitychange

Is an event handler representing the code to be called when the visibilitychange event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/onvisibilitychange>

=head2 onwheel

Under perl, no such event is fired, but you can trigger one yourself.

This event is fired when the user rotates the mouse (or other pointing device) wheel. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers/onwheel>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::Document>, L<HTML::Object::DOM::Element>

L<Mozilla documentation on DOM|https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model>, L<Mozilla documentation on Document object|https://developer.mozilla.org/en-US/docs/Web/API/Document>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
