##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XQuery.pm
## Version v0.2.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/05/01
## Modified 2023/05/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::XQuery;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM );
    use vars qw( @EXPORT $DEBUG $VERSION );
    our @EXPORT = qw( xq );
    our $DEBUG = 0;
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

{
    no warnings 'once';
    *xq = \&HTML::Object::DOM::Element::xq;
}

# NOTE: HTML::Object::DOM::Element class
package HTML::Object::DOM::Element;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $XP $LOOK_LIKE_HTML $VERSION );
    use CSS::Object;
    use HTML::Object::Collection;
    use HTML::Object::DOM::Attribute;
    use HTML::Object::DOM::Boolean;
    use HTML::Object::DOM::Document;
    use HTML::Object::DOM::Number;
    use HTML::Object::DOM::Root;
    # use HTML::Object::DOM::Text;
    use HTML::Selector::XPath 0.20 qw( selector_to_xpath );
    use List::Util ();
    use Nice::Try;
    # use Promise::XS ();
    # use Promise::Me;
    use HTML::Object::XPath;
    use overload (
        'eq'    => \&_same_as,
        '=='    => \&_same_as,
        fallback => 1,
    );
    our $XP;
    # As perl jQuery documentation
    our $LOOK_LIKE_HTML = qr/^[[:blank:]\h]*\<\w+.*?\>/;
};

no warnings 'redefine';

# Takes a selector (e.g. '.some-class'); or
# a collection (i.e. one or more elements resulting from a find or equivalent query); or
# "HTML fragment to add to the set of matched elements."; or
# a selector and a context (i.e. an element object); or
# a element object
# $self->add( $selector );
# $self->add( $elements );
# $self->add( $html );
# $self->add( $selector, $context );
sub add
{
    my $self = shift( @_ );
    my( $this, $context ) = @_;
    # Compliant with what jQuery does, i.e. when no argument is provide this just returns a collection of the collecting object
    my $collection = $self->new_collection( end => $self );
    # if( $self->isa_element && !$self->isa_collection )
    if( $self->isa_collection )
    {
        $collection->children( $self->children );
    }
    elsif( $self->isa_element )
    {
        $collection->children->push( $self );
    }
    
    if( !defined( $this ) )
    {
        return( $collection )
    }
    # e.g.: $( "p" ).add( "div" )
    # $( "li" ).add( "<p id='new'>new paragraph</p>" )
    # elsif( !ref( $this ) || ( ref( $this ) && overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) )
    elsif( !ref( $this ) || overload::Method( $this, '""' ) )
    {
        # https://api.jquery.com/Types/#htmlString
        # $( "li" ).add( "<p id='new'>new paragraph</p>" )
        if( "$this" =~ /$LOOK_LIKE_HTML/ )
        {
            my $p = $self->new_parser;
            $this = $p->parse_data( "$this" ) || return( $self->pass_error( $p->error ) );
        }
        # selector
        #　$( "p" ).add( "div" )
        else
        {
            # $self->add( $selector, $context );
            if( defined( $context ) )
            {
                return( $self->error( "A context has been provided, but it is not an HTML::Object::DOM::Element." ) ) if( !$self->_is_object( $context ) || !$context->isa( 'HTML::Object::DOM::Element' ) );
                $this = $context->find( "$this" ) || return( $self->pass_error( $context->error ) );
            }
            # $self->add( $selector );
            elsif( defined( $HTML::Object::DOM::GLOBAL_DOM ) )
            {
                my $selector = "$this";
                $this = $HTML::Object::DOM::GLOBAL_DOM->find( "$selector" ) || return( $self->pass_error( $HTML::Object::DOM::GLOBAL_DOM->error ) );
            }
            else
            {
                return( $self->error( "You need to provide some context to the selector by supplying an HTML::Object::DOM::Element object." ) );
            }
        }
    }
    # Some array or hash ref provided maybe ?
    elsif( !$self->_is_object( $this ) )
    {
        return( $self->error( "I was expecting an HTML::Object::DOM::Element, an HTML::Object::Collection, an html string or a selector., but instead I got '$this'." ) );
    }
    
    # We now have either an element object or a collection of them
    # We return a new collection either way
    if( $self->isa_collection( $this ) )
    {
        $collection->children->merge( $this->children->unique );
    }
    elsif( $this->isa( 'HTML::Object::DOM::Element' ) )
    {
        $collection->children->push( $this );
    }
    else
    {
        return( $self->error( "An object of class \"", ref( $this ), "\" was provided, but I do not know what to do with it. I was expecting an HTML::Object::DOM::Element, or an HTML::Object::Collection." ) );
    }
    return( $collection );
}

## To make it look like really like jQuery
sub addClass
{
    my( $self, $class ) = @_;
    return( $self->error( "I received a reference to add as a class, but was expecting a string or a code reference." ) ) if( ref( $class ) && ref( $class ) ne 'CODE' && !( overload::Overloaded( $class ) && overload::Method( $class, '""' ) ) );
    $class = "${class}" unless( ref( $class ) CORE::eq 'CODE' );
    my $set_attr;
    $set_attr = sub
    {
        my( $i, $e ) = @_;
        my $v = $e->attr( 'class' ) // '';
        local $_ = $e;
        my $classes = ref( $class ) CORE::eq 'CODE'
            ? $class->({ element => $e, pos => $i, value => $v })
            : $class;
        my $cl_ref = $self->new_array(
            $self->_is_array( $classes )
                ? $classes
                : CORE::length( "$classes" )
                    ? [split( /[[:blank:]\h]+/, "${classes}" )]
                    : []
        );
        my $curr;
        if( CORE::length( "${v}" ) )
        {
            $curr = $self->_is_a( $v, 'Module::Generic::Array' ) ? $v : $self->new_array( [split( /[[:blank:]\h]+/, $v )] );
            my $new = $self->new_array;
            $cl_ref->foreach(sub
            {
                # <http://www.w3.org/TR/CSS21/grammar.html#scanner>
                # <https://stackoverflow.com/questions/448981/which-characters-are-valid-in-css-class-names-selectors#449000>
                $new->push( $_ ) if( !$curr->exists( $_ ) );
            });
            $curr->push( $new->list ) if( $new->length );
        }
        else
        {
            $curr = $cl_ref;
        }
        $e->attr( class => $curr->join( ' ' )->scalar );
        $e->reset(1);
    };
    
    if( $self->isa_collection )
    {
        $self->children->for( $set_attr );
    }
    else
    {
        my $v = $self->attr( 'class' ) // '';
        # Here 0 is a dummy number to satisfy the code ref required by for()
        $set_attr->( 0, $self );
    }
}

# <https://api.jquery.com/after/>
sub after { return( shift->_before_after( @_, { action => 'after' } ) ); }

# Takes html string (start with <tag...), text object (HTML::Object::DOM::Text), array or element object
# or alternatively a code reference that returns the above
# <https://api.jquery.com/append/>
sub append { return( shift->_append_prepend( @_, { action => 'append' } ) ); }

sub appendTo { return( shift->_append_prepend_to( @_, { action => 'append' } ) ); }

# $e->attr( attribute );
# $collection->attribute( attribute );
# $e->attr( attribute1 => value1, attribute2 => value2 );
# $collection->attr( attribute1 => value1, attribute2 => value2 );
# $e->attr( attribute1 => $sub_routine1, attribute2 => $string );
# $collection->attr( attribute1 => $sub_routine1, attribute2 => $string );
sub attr
{
    my $self = shift( @_ );
    my @classes = @_;
    return if( !scalar( @classes ) );
    if( scalar( @classes ) > 1 )
    {
        my $ref = {};
        %$ref = @classes;
        my $set_attributes;
        $set_attributes = sub
        {
            my $e = shift( @_ );
            while( my( $a, $v ) = each( %$ref ) )
            {
                local $_ = $e;
                my $val = ref( $v ) CORE::eq 'CODE'
                    ? $v->({ element => $e, attribute => $a, current => $e->attributes->get( $a ) })
                    : $v;
                return( $self->error( "I was expecting a string value for the attribute \"${a}\", but instead got \"", overload::StrVal( $val ), "\"." ) ) if( ref( $val ) && !( overload::Overloaded( $val ) && overload::Method( $val, '""' ) ) );
                if( defined( $val ) )
                {
                    $val = "$val";
                    $val =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
                    $e->attributes->set( $a => $val );
                }
                else
                {
                    $e->attributes->delete( $a );
                }
            }
            return(1);
        };
        
        if( $self->isa_collection )
        {
            $self->children->foreach(sub
            {
                my $e = shift( @_ );
                $e->reset(1);
                # $e->attributes->merge( $ref );
                $set_attributes->( $e ) || return( $self->pass_error );
            });
        }
        else
        {
            $self->reset(1);
            $set_attributes->( $self ) || return( $self->pass_error );
        }
        return( $self );
    }
    # Get mode
    else
    {
        # return( $self->children->map(sub{ $_->attributes->get( $classes[0] ) }) );
        # Get the value of an attribute for the first element in the set of matched elements.
        if( $self->isa_collection )
        {
            return( $self->children->first->attributes->get( $classes[0] ) );
        }
        else
        {
            return( $self->attributes->get( $classes[0] ) );
        }
    }
}

sub before { return( shift->_before_after( @_, { action => 'before' } ) ); }

# Takes a selector; or
# a selector and an HTML::Object::DOM::Element as a context; or
# a HTML::Object::DOM::Element object
# "Given a jQuery object that represents a set of DOM elements, the .closest() method searches through these elements and their ancestors in the DOM tree and constructs a new jQuery object from the matching elements."
sub closest
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    my $context = shift( @_ );
    my $collection = $self->new_collection;
    return $collection if( !defined( $this ) );
    if( defined( $context ) && 
        ( !$self->_is_object( $context ) || 
          ( $self->_is_object( $context ) && 
            !$context->isa( 'HTML::Object::DOM::Element' ) 
          )
        ) )
    {
        return( $self->error( "Context provided (", overload::StrVal( $context ), ") is not an HTML::Object::DOM::Element." ) );
    }
    elsif( ref( $this ) && 
           $self->_is_object( $this ) && 
           ( !$this->isa( 'HTML::Object::DOM::Element' ) || 
             ( overload::Overloaded( $this ) && !overload::Method( $this, '""' ) )
           ) )
    {
        return( $self->error( "I was expecting a selector or an HTML::Object::DOM::Element, but instead received '$this'" ) );
    }
    else
    {
        return( $self->error( "I was expecting a selector or an HTML::Object::DOM::Element, but instead received '$this'" ) );
    }
    
    my $xpath;
    if( !ref( $this ) )
    {
        $xpath = $self->_xpath_value( $this );
    }
    my $process;
    $process = sub
    {
        my $elem = shift( @_ );
        # We reach the limit of our upward search
        return if( defined( $context ) && $elem->eid CORE::eq $context->eid );
        my $parent = $elem->parent;
        if( defined( $xpath ) )
        {
            if( $elem->matches( $xpath ) )
            {
                $collection->push( $elem );
            }
        }
        else
        {
            if( $elem->eid CORE::eq $this->eid )
            {
                $collection->push( $elem );
            }
        }
        return if( !$parent );
        return( $process->( $parent ) );
    };
    $process->( $self );
    return( $collection );
}

# Takes a property name; or
# an array reference of one or more css properties; or
# a property name and a value; or
# a property name and a function; or
# an hash reference of property name-value pairs
# <https://api.jquery.com/css/>
# $e->css( $property_name );
# $e->css( [$property_name1, $property_name2, $property_name3] );
# $e->css( $property_name, $value );
# $e->css( $property_name, $code_reference );
# $e->css({ $property_name1 => $value1, $property_name2 => $value2 });
# <https://api.jquery.com/css/>
sub css
{
    my $self = shift( @_ );
    # "An element should be connected to the DOM when calling .css()"
    return( $self->error( "Method css() must be called on an HTML::Object::DOM::Element." ) ) if( ( !$self->isa_element && !$self->isa_collection ) || $self->tag->substr( 0, 1 ) CORE::eq '_' );
    my( $name, $more ) = @_;
    return( $self->error( "No css property was provided." ) ) if( !defined( $name ) || !CORE::length( $name ) );
    
    my $process;
    $process = sub
    {
        my $elem = shift( @_ );
        my $style = $elem->attributes->get( 'style' );
        # return if( !defined( $style ) );
        my $css = CSS::Object->new( format => 'CSS::Object::Format::Inline', debug => $self->debug );
        my $cached;
        $cached = $elem->css_cache_check( $style ) if( defined( $style ) );
        if( $cached )
        {
            $css = $cached;
        }
        elsif( defined( $style ) )
        {
            # 'inline' here is just a fake selector to serve as a container rule for the inline properties, 
            # because CSS::Object requires properties to be within a rule
            $css->read_string( 'inline {' . $style . ' }' ) ||
            return( $self->error( "Unable to parse existing style for tag name \"", $elem->prop( 'tagName' ), "\":", $css->error ) );
        }
        else
        {
        }
        my $main = $css->rules->first;
        # my $rule = defined( $main ) ? $css->builder->select( $main ) : $css->builder->select( 'inline' );
        my $rule;

        # Get the requested property values
        # $e->css( $property_name );
        # $e->css( [$property_name1, $property_name2, $property_name3] );
        # $e->css({ $property_name1 => $value1, $property_name2 => $value2 });
        if( $self->_is_array( $name ) || 
            $self->_is_hash( $name ) || 
            ( ( !ref( $name ) || overload::Method( $name, '""' ) ) && !defined( $more ) ) )
        {
            # If this is just 1 css property, we encapsulate it into an array to standardise our processing
            # $e->css( $property_name );
            $name = [ "$name" ] if( !defined( $more ) && ( !ref( $name ) || overload::Method( $name, '""' ) ) );
            # $e->css( [$property_name1, $property_name2, $property_name3] );
            # "assing an array of style properties to .css() will result in an object of property-value pairs."
            # <https://api.jquery.com/css/#css-propertyName>
            if( $self->_is_array( $name ) )
            {
                my $res = $self->new_hash;
                $self->new_array( $name )->foreach(sub
                {
                    my $prop = shift( @_ );
                    $prop =~ tr/_/-/;
                    my $obj = $main->get_property_by_name( $prop );
                    # next
                    return( 1 ) if( !defined( $obj ) );
                    $res->{ $prop } = $obj->value->as_string;
                    return( 1 );
                });
                return( $res );
            }
            # $e->css({ $property_name1 => $value1, $property_name2 => $value2 });
            elsif( $self->_is_hash( $name ) )
            {
                $rule = defined( $main ) ? $css->builder->select( $main ) : $css->builder->select( 'inline' );
                $self->new_hash( $name )->each(sub
                {
                    my( $prop, $value ) = @_;
                    my $obj = $main->get_property_by_name( $prop );
                    # if the value is undef, remove the property from the set of css properties
                    # "Setting the value of a style property to an empty string — e.g. $( "#mydiv" ).css( "color", "" ) — removes that property from an element if it has already been directly applied,"
                    # <https://api.jquery.com/css/#css-propertyName-value>
                    if( !defined( $value ) || !CORE::length( $value ) )
                    {
                        $main->element->remove( $obj ) if( $obj );
                    }
                    elsif( defined( $obj ) )
                    {
                        $obj->value( "$value" );
                    }
                    else
                    {
                        $main->$prop( "$value" );
                    }
                });
                if( $rule->elements->length > 0 )
                {
                    my $style = $rule->as_string;
                    $elem->css_cache_store( $style, $css ) || return( $self->pass_error( $elem->error ) );
                    $elem->attributes->set( style => $style );
                }
                else
                {
                }
                return( $self );
            }
            else
            {
                return( $self->error( "I was expecting a css property, or an array reference of css property, but instead I received '$name'." ) );
            }
        }
        else
        {
            # Set css property values
            # $e->css( $property_name, $value );
            # $e->css( $property_name, $code_reference );
            if( defined( $more ) )
            {
                return( $self->error( "More than 2 arguments were provided. I was expecting a property and its value or a function." ) ) if( scalar( @_ ) > 2 );
                $rule = defined( $main ) ? $css->builder->select( $main ) : $css->builder->select( 'inline' );
                # $e->css( $property_name, $code_reference );
                if( ref( $more ) CORE::eq 'CODE' )
                {
                    my $pos = $elem->parent ? $elem->parent->children->pos( $elem ) : 0;
                    $name =~ tr/_/-/;
                    my $obj = $main->get_property_by_name( $name );
                    my $val;
                    if( defined( $obj ) )
                    {
                        $val = $obj->value->as_string;
                    }
                    local $_ = $elem;
                    my $ret = $more->( $pos, $val );
                    # "If nothing is returned in the setter function (ie. function( index, style ){} ), or if undefined is returned, the current value is not changed. This is useful for selectively setting values only when certain criteria are met."
                    # <https://api.jquery.com/css/#css-propertyName-function>
                    return( $elem ) if( !defined( $ret ) || !CORE::length( $ret ) );
                    if( defined( $obj ) )
                    {
                        $obj->value( "$val" );
                    }
                    else
                    {
                        $rule->$name( "$val" );
                    }
                }
                # $e->css( $property_name, $value );
                else
                {
                    return( $self->error( "I was expecting a value as a string, but instead got '$more'." ) ) if( ref( $more ) && !( overload::Overloaded( $more ) && overload::Method( $more, '""' ) ) );
                    $name =~ tr/_/-/;
                    my $obj = $rule->get_property_by_name( $name );
                    if( defined( $obj ) )
                    {
                        $obj->value( "$more" );
                    }
                    else
                    {
                        $rule->$name( "$more" );
                    }
                }
            }
        
            if( defined( $rule ) && $rule->elements->length > 0 )
            {
                my $style = $rule->as_string;
                $elem->css_cache_store( $style, $css ) || return( $self->pass_error( $elem->error ) );
                $elem->attributes->set( style => $style );
            }
            else
            {
            }
            return( $elem );
        }
    };
    
    if( $self->isa_collection )
    {
        $self->children->foreach(sub
        {
            $_->reset(1);
            $process->( $_ );
        });
        return( $self );
    }
    else
    {
        $self->reset(1);
        return( $process->( $self ) );
    }
}

sub css_cache_check
{
    my $self = shift( @_ );
    # my $data = shift( @_ );
    # return if( !defined( $data ) );
    return( $self->error( "css_cache_check() must be called on an HTML element, not a collection." ) ) if( $self->isa_collection );
    my $internal = $self->internal;
    $internal->{css_cache} //= {};
    if( exists( $internal->{css_cache} ) )
    {
        my $css = $internal->{css_cache}->{object} ||
            return( $self->error( "CSS object could not be found in cache!" ) );
        # return( $css->clone );
        # my $clone = $css->clone;
        # return( $clone );
        return( $css );
    }
    return( '' );
}

sub css_cache_store
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    return if( !defined( $data ) );
    return( $self->error( "css_cache_store() must be called on an HTML element, not a collection." ) ) if( $self->isa_collection );
    my $css  = shift( @_ );
    return( $self->error( "No css object provided to store in the element cache." ) ) if( !$self->_is_object( $css ) );
    my $trace = $self->_get_stack_trace;
    my $internal = $self->internal;
    $internal->{css_cache} =
    {
    timestamp => time(),
    # object    => $css->clone,
    object    => $css,
    };
    return( $self );
}

# sub data { return( shift->attr( join( '-', 'data', shift( @_ ) ) => shift( @_ ) ) ) }
# nothing which returns everything as a hash; or
# a key-value pair; or
# a hash reference
sub data
{
    my $self = shift( @_ );
    my( $this, $val ) = @_;
    my $elem;
    if( $self->isa_collection )
    {
        $elem = $self->children->first;
    }
    elsif( $self->tag->substr( 0, 1 ) )
    {
        return( $self->error( "You can only call the data method on html elements." ) );
    }
    else
    {
        $elem = $self;
    }
    
    my $attr = $self->attributes;
    if( $self->_is_hash( $this ) )
    {
        $this = $self->new_hash( $this )->each(sub
        {
            my( $k, $v ) = @_;
            # Remove leading and trailing spaces if this is not a reference
            $v =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g if( !ref( $v ) );
            $attr->set( 'data-' . $k, $v );
        });
        $elem->reset(1);
        return( $elem );
    }
    elsif( defined( $this ) && defined( $val ) )
    {
        return( $self->error( "I was provided data name '$this', but I was expcting a regular string." ) ) if( ref( $this ) && ( !overload::Overloaded( $this ) || ( overload::Overloaded( $this ) && !overload::Method( $this, '""' ) ) ) );
        $attr->set( 'data-' . $this => $val );
        $elem->reset(1);
        return( $elem );
    }
    elsif( defined( $this ) && !defined( $val ) )
    {
        return( $attr->get( $this ) );
    }
    else
    {
        my $ref = {};
        $attr->each(sub
        {
            my( $k, $v ) = @_;
            if( substr( $k, 0, 5 ) CORE::eq 'data-' && CORE::length( $k ) > 5 )
            {
                $ref->{ substr( $k, 5 ) } = $v;
            }
        });
        return( Module::Generic::Dynamic->new( $ref ) );
    }
}

# TODO: Instead of adding this method, maybe we should change the one in HTML::Object::DOM::Element to have it return $self instead of $parent, because otherwise there is no difference
sub detach
{
    my $self = shift( @_ );
    # If this is a collection, walk through its children
    if( $self->isa_collection )
    {
        $self->children->foreach(sub
        {
            my $e = shift( @_ );
            my $parent = $e->parent;
            return( 1 ) if( !$parent );
            my $pos = $parent->children->pos( $e );
            $parent->children->splice( $pos, 1 );
            $e->parent( undef() );
            $parent->reset(1);
        });
    }
    # otherwise, process this one element individually
    else
    {
        my $parent = $self->parent;
        return( $self ) if( !$parent );
        my $pos = $parent->children->pos( $self );
        if( defined( $pos ) )
        {
            $parent->children->splice( $pos, 1 );
            $self->parent( undef() );
            $parent->reset(1);
        }
    }
    return( $self );
}

# Takes a code reference which receives the element position and element object as parameter
# It returns the current object it was called with
sub each
{
    my( $self, $code ) = @_;
    return( $self->error( "I was expecting a code reference to pass it the element position and element object, but instead I got \"", overload::StrVal( $code ), "\"." ) ) if( ref( $code ) ne 'CODE' );
    # Make a copy of the array so that call to code ref that may remove a child element does not alter our looping operation through all the children
    $self->children->clone->for(sub
    {
        my( $i, $e ) = @_;
        $code->( $i, $e );
    });
    return( $self );
}

sub empty
{
    my $self = shift( @_ );
    # Element object of Collection object, it does not matter
    $self->children->reset;
    $self->reset(1);
    return( $self );
}

sub end { return( shift->_set_get_object( 'end', 'HTML::Object::DOM::Element', @_ ) ); }

sub eq { return( shift->children->index( shift( @_ ) ) ); }

# Returns a new collection of elements whose position is an even number
sub even
{
    my $self = shift( @_ );
    return( $self ) unless( $self->isa_collection );
    my $even = $self->children->even;
    my $collection = $self->new_collection;
    $collection->children( $even );
    return( $collection );
}

sub exists
{
    my( $self, $path ) = @_;
    return( $self->xp->exists( $path, $self ) );
}

# Takes a selector; or
# function with arguments are element position (starting from 0) and the element itself, expecting a true value in return; or
# an array of element objects; or
# an element object;
sub filter
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    my $collection = $self->new_collection;
    return( $collection ) if( !defined( $this ) );
    if( !ref( $this ) || 
        ( ref( $this ) && 
          overload::Overloaded( $this ) && 
          overload::Method( $this, '""' )
        ) )
    {
        my $xpath = $self->_xpath_value( "$this" ) || return;
        if( $self->isa_collection )
        {
            $self->children->foreach(sub
            {
                if( $_->matches( $xpath ) )
                {
                    $collection->children->push( $_ );
                }
            });
        }
        elsif( $self->tag->substr( 0, 1 ) ne '_' && $self->matches( $xpath ) )
        {
            $collection->children->push( $self );
        }
    }
    elsif( ref( $this ) eq 'CODE' )
    {
        if( $self->isa_collection )
        {
            $self->for(sub
            {
                my( $i, $e ) = @_;
                local $_ = $e;
                if( $this->( $i, $e ) )
                {
                    $collection->children->push( $e );
                }
            });
        }
        elsif( $self->isa( 'HTML::Object::DOM::Element' ) )
        {
            return( $collection ) if( $self->tag->substr( 0, 1 ) eq '_' );
            local $_ = $self;
            $collection->children->push( $self ) if( $this->( 0, $self ) );
        }
    }
    elsif( $self->_is_array( $this ) || $self->_is_object( $this ) )
    {
        if( $self->_is_object( $this ) && 
            ( !$this->isa( 'HTML::Object::DOM::Element' ) || 
              (
                # Probably need to change this to HTML::Object::DOM::Node
                $this->isa( 'HTML::Object::Element' ) && 
                $this->tag->substr( 0, 1 ) eq '_' && 
                !$this->isa( 'HTML::Object::Collection' )
              ) 
            ) )
        {
            return( $self->error( "Object of class \"", ref( $this ), "\", but you can only provide an HTML::Object::DOM::Element or an HTML::Object::Collection object." ) );
        }
        my $a = $self->new_array( $self->_is_array( $this ) ? $this : [ $this ] );
        $a->foreach(sub
        {
            my $xpath = $_->getNodePath();
            if( $self->isa_collection )
            {
                $self->children->foreach(sub
                {
                    my $e = shift( @_ );
                    if( $e->matches( $xpath ) )
                    {
                        $collection->children->push( $e );
                    }
                });
            }
            elsif( $self->matches( $xpath ) )
            {
                $collection->children->push( $self );
            }
        });
    }
    else
    {
        return( $self->error( "I was expecting a selector, a code reference, an array of elements or an element to use in filter(), but instead I got '$this', and I do not know what to do with it." ) );
    }
    return( $collection );
}

# Takes a selector; or
# Element object
sub find
{
    my( $self, $this ) = @_;
    my $collection = $self->new_collection;
    return( $collection ) if( !defined( $this ) );
    
    if( ref( $this ) && $self->_is_object( $this ) && $this->isa( 'HTML::Object::DOM::Element' ) )
    {
        my $a = $self->new_array( $self->isa_collection( $this ) ? $this->children : [ $this ] );
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
                        $collection->children->push( $child );
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
        my $xpath = $self->_xpath_value( $this ) || return( $self->pass_error );
#         $self->children->foreach(sub
#         {
#             my $child = shift( @_ );
#             # Propagate debug value
#             $child->debug( $self->debug );
#             try
#             {
#                 my @nodes = $child->findnodes( $xpath );
#                 $collection->children->push( @nodes );
#             }
#             catch( $e )
#             {
#                 warn( "Error while calling findnodes on element id \"", $_->id, "\" and tag \"", $_->tag, "\": $e\n" );
#             }
#         });
        try
        {
            my @nodes = $self->findnodes( $xpath );
            $collection->children->push( @nodes );
        }
        catch( $e )
        {
            warn( "Error while calling findnodes on element id \"", $_->id, "\" and tag \"", $_->tag, "\": $e\n" );
        }
    }
    return( $collection );
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

sub first
{
    my $self = shift( @_ );
    my $collection = $self->new_collection;
    if( $self->isa_collection )
    {
        return( $self->children->first );
    }
    else
    {
        return( $self );
    }
}

# Originally, in jQuery, this returns the underlying DOM element, but here, in perl context,
# this does not mean much, and we return our own object.
sub get { return( $_[0] ); }

sub has
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    my $collection = $self->new_collection;
    return( $collection ) if( !defined( $this ) );
    if( ref( $this ) && $self->_is_object( $this ) && $self->isa( 'HTML::Object::DOM::Element' ) )
    {
        my $lookup;
        $lookup = sub
        {
            my $kids = shift( @_ );
            my $found;
            $kids->foreach(sub
            {
                my $child = shift( @_ );
                $this->children->foreach(sub
                {
                    my $candidate = shift( @_ );
                    # Found a match, no need to look down further
                    if( $child->eid eq $candidate->eid )
                    {
                        $found = $child;
                        return( $kids->return( undef() ) );
                    }
                });
                if( $child->children->length )
                {
                    my $rc = $lookup->( $child->children );
                    if( $rc )
                    {
                        $found = $rc;
                        return( $kids->return( undef() ) );
                    }
                }
            });
            return( $found );
        };
        $self->children->foreach(sub
        {
            $collection->children->push( $_ ) if( $lookup->( $_->children ) );
        });
    }
    # An xpath then?
    else
    {
        if( ref( $this ) &&
            (
                !overload::Overloaded( $this ) ||
                ( overload::Overloaded( $this ) && !overload::Method( $this, '""' ) ) 
            ) )
        {
            return( $self->error( "I was expecting an xpath value, but got '$this' instead." ) );
        }
        my $xpath = $self->_xpath_value( "$this" ) || return;
        
        my $lookup;
        $lookup = sub
        {
            my $kids = shift( @_ );
            my $found;
            $kids->foreach(sub
            {
                my $child = shift( @_ );
                if( $child->matches( $xpath ) )
                {
                    $found = $child;
                    # No need to look further, we found a match
                    return;
                }
                if( $child->children->length > 0 )
                {
                    my $rc = $lookup->( $child->children );
                    if( $rc )
                    {
                        $found = $rc;
                        return;
                    }
                }
            });
            return( $found );
        };
        
        $self->children->foreach(sub
        {
            $collection->children->push( $_ ) if( $lookup->( $_->children ) );
        });
    }
    return( $collection );
}

sub hasClass
{
    my $self = shift( @_ );
    my $class = shift( @_ );
    return( 0 ) if( !CORE::length( $class ) );
    my $found = 0;
    if( $self->isa_collection )
    {
        $self->children->foreach(sub
        {
            my $e = shift( @_ );
            my $classes = $e->attributes->get( 'class' );
            # No class attribute, skip to next element
            return( 1 ) if( !defined( $classes ) );
            # Found a match, no need to go further since we only need to return true or false
            $found++, return( undef() ) if( $classes =~ /(?:\A|[[:blank:]\h]+)${class}(?:[[:blank:]\h]+|\Z)/ );
            return( 1 );
        });
    }
    else
    {
        my $classes = $self->attributes->get( 'class' );
        return( 0 ) if( !defined( $classes ) );
        return( 1 ) if( $classes =~ /(?:\A|[[:blank:]\h]+)${class}(?:[[:blank:]\h]+|\Z)/ );
        return( 0 );
    }
}

# Since this is a perl context, this only set the inline css to "display: none" like jQuery actually does
# Any parameter provided will be ignored
# See the show() method for its alter ego
sub hide
{
    my $self = shift( @_ );
    my( $this, $code ) = @_;
    $code = $this if( ref( $this ) eq 'CODE' && !defined( $code ) );
    my $process;
    $process = sub
    {
        my $e = shift( @_ );
        my $internal = $e->internal;
        my $rule = $self->_css_object();
        if( defined( $rule ) )
        {
            my $display = $rule->get_property_by_name( 'display' );
            my $val = $display->value;
            # $val may be undefined if it was not set in the first place, and that's ok
            # when we'll restore it with show(), we'll see the original value was empty and
            # we'll just remove the "display: none"
            # Here we check what the current value is, because, if it is already set to none, we just ignore it
            if( $val ne 'none' )
            {
                $internal->{css_display_value} = $val;
            }
            $display->value( 'none' );
        }
        else
        {
            $rule = $self->_css_builder;
            $rule->display( 'none' );
        }
        if( $rule->elements->length > 0 )
        {
            $e->_css_object( $rule );
        }
    };
    
    if( $self->isa_collection )
    {
        $self->children->foreach(sub
        {
            $process->( $_ );
        });
    }
    elsif( $self->tag->substr( 0, 1 ) eq '_' )
    {
        return( $self->error( "You can only use the hide() or show() method on html object elements. The element you are calling hide() with is an object of class \"", ref( $self ), "\"." ) );
    }
    else
    {
        $process->( $self );
    }
}

# This takes either no arguments and it returns the inner html; or
# it takes an html string to replace its content; or
# it takes a code reference that is called with the index position in the set of element and
# the current html data. It returns the new html data
# See also text() method
sub html
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    if( defined( $this ) )
    {
        if( !ref( $this ) ||
            ( ref( $this ) && overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) )
        {
            my $p = $self->new_parser;
            my $res = $p->parse_data( "$this" ) ||
            return( $self->error( "Error while parsing html data provided: ", $p->error ) );
            $this = $res;
        }
        elsif( ref( $this ) ne 'CODE' )
        {
            return( $self->error( "I was expecting some html data or a code reference in replacement of html for this element \"", $self->tag, "\", but instead got '$this'." ) );
        }
        
        $self->children->for(sub
        {
            my( $i, $e ) = @_;
            if( ref( $this ) eq 'CODE' )
            {
                my $current_html = $e->as_string;
                my $html = $this->( $i, $current_html );
                if( !defined( $html ) || !CORE::length( $html ) )
                {
                    $e->empty();
                    # Next please
                    return(1);
                }
                # We were provided with an HTML::Object::DOM::Element in response, we use its children as the new content
                elsif( ref( $html ) && $self->_is_object( $html ) && $html->isa( 'HTML::Object::DOM::Element' ) )
                {
                    if( $html->tag->substr( 0, 1 ) eq '_' && !$html->isa_collection )
                    {
                        warn( "You cannot use this object of class ", ref( $html ), " to set its children as the new html. You can only use html element objects.\n" );
                        return(1);
                    }
                    $e->children( $html->children );
                    $html->children->foreach(sub
                    {
                        $_->parent( $e );
                    });
                    $self->reset(1);
                    return(1);
                }
                elsif( ref( $html ) &&
                       !( overload::Overloaded( $html ) && overload::Method( $html, '""' ) ) )
                {
                    warn( "I was provided a reference '$html' as a result from calling this code reference to get the replacement html for tag \"", $e->tag, "\", but I do not know what to do with it.\n" );
                    return(1);
                }
                my $p = $self->new_parser;
                my $doc = $p->parse_data( "$html" ) || do
                {
                    warn( "Error while trying to parse html data returned by code reference supplied: ", $p->error, "\n" );
                    # Switch to next element
                    return(1);
                };
                # Replace the children element by the new ones found in parsing.
                $e->children( $doc->children );
                $doc->children->foreach(sub
                {
                    $_->parent( $e );
                });
                $self->reset(1);
            }
            # It's an HTML::Object::DOM::Document object
            else
            {
                my $a = $self->new_array;
                $this->children->foreach(sub
                {
                    $a->push( $_->clone );
                });
                $e->children( $a );
            }
            # Return true at the end to satisfy Module::Generic::Array->for
            return(1);
        });
    }
    else
    {
        # "Get the HTML contents of the first element in the set of matched elements."
        my $elem = $self->isa_collection ? $self->children->first : $self;
        return( '' ) unless( $self );
        # Create a new document, because we want to use the document object as_string function which produce a string of its children, and no need to reproduce it here
        my $doc = $elem->new_document;
        $doc->children( $elem->children );
        return( $doc->as_string );
    }
}

sub id
{
    my $self = shift( @_ );
    if( @_ )
    {
        if( $self->isa_collection )
        {
            return( $self->error( "Cannot set an id on a collection" ) );
        }
        else
        {
            # Method in HTML::Object::DOM::Element
            return( $self->_set_get_id( @_ ) );
        }
    }
    else
    {
        my $e = $self;
        if( $self->isa_collection )
        {
            my $first = $self->children->first;
            return if( !$first || !$self->isa_element( $first ) );
            $e = $first;
        }
        my $id = $e->attributes->get( 'id' );
        return( $e->new_scalar( $id ) );
    }
}

# Takes either nothing; or
# a selector; or
# an element object
sub index
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    if( defined( $this ) )
    {
        if( !ref( $this ) ||
            ( ref( $this ) && overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) )
        {
            my $xpath = $self->_xpath_value( "$this" );
            if( $self->isa_collection() )
            {
                my $found;
                $self->children->for(sub
                {
                    my( $i, $e ) = @_;
                    if( $e->matches( $xpath ) )
                    {
                        $found = $i;
                        # Exit the for loop
                        return;
                    }
                });
                return( $self->new_number(-1) ) if( !defined( $found ) );
                return( $self->new_number( $found ) );
            }
            else
            {
                if( $self->matches( $xpath ) )
                {
                    return( $self->new_number(0) ) if( !$self->parent );
                    my $pos = $self->parent->children->pos( $self );
                    return( $self->new_number( defined( $pos ) ? $pos : -1 ) );
                }
                else
                {
                    return( $self->new_number(-1) );
                }
            }
        }
        elsif( ref( $this ) && $self->_is_object( $this ) && $this->isa( 'HTML::Object::DOM::Element' ) )
        {
            my $elem = $this->isa_collection() ? $this->children->first : $this;
            my $found;
            if( $self->isa_collection() )
            {
                $self->children->for(sub
                {
                    my( $i, $e ) = @_;
                    if( $e->eid eq $elem->eid )
                    {
                        $found = $i;
                        return;
                    }
                });
            }
            else
            {
                return( $self->new_number( $self->eid eq $elem->eid ? 0 : -1 ) );
            }
        }
    }
    # Return the position of the element or if this is a collection, the position of the first element in the collection
    else
    {
        my $elem = ( $self->isa_collection ? $self->children->first : $self );
        return( $self->new_number(-1) ) if( !defined( $elem ) || !CORE::length( $elem ) );
        return( $self->new_number(0) ) if( !$elem->parent );
        my $pos = $elem->parent->children->pos( $elem );
        return( $self->new_number( defined( $pos ) ? $pos : -1 ) );
    }
}

sub insertAfter { return( shift->_insert_before_after( @_, { action => 'after' }) ); }

sub insertBefore { return( shift->_insert_before_after( @_, { action => 'before' }) ); }

# Takes a selector; or
# an element object; or
# a collection object; or
# a code reference and
# return true or false object
# "Check the current matched set of elements against a selector, element, or jQuery object and return true if at least one of these elements matches the given arguments."
# <https://api.jquery.com/is/#is-selector>
sub is
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    my $found = $self->false;
    if( ref( $this ) CORE::eq 'CODE' )
    {
        if( $self->isa_collection() )
        {
            $self->children->for(sub
            {
                my( $i, $e ) = @_;
                local $_ = $e;
                if( $this->( $i, $e ) )
                {
                    $found = $self->true;
                    return;
                }
            });
        }
        else
        {
            my $pos = ( $self->parent ? $self->parent->children->pos( $self ) : 0 );
            if( $this->( $pos, $self ) )
            {
                $found = $self->true;
            }
        }
        return( $found );
    }
    elsif( ref( $this ) && $self->_is_object( $this ) && $this->isa( 'HTML::Object::DOM::Element' ) )
    {
        my $a = $this->isa_collection() ? $this->children() : $self->new_array( [ $this ] );
        if( $self->isa_collection() )
        {
            my $kids = $self->children;
            $kids->foreach(sub
            {
                my $e = shift( @_ );
                $a->foreach(sub
                {
                    my $other = shift( @_ );
                    if( $e->eid CORE::eq $other->eid )
                    {
                        $found = $self->true;
                        # Exit this loop and tell the upper loop to exit as well
                        return( $kids->return( undef() ) );
                    }
                });
            });
        }
        else
        {
            $a->foreach(sub
            {
                if( $_->eid CORE::eq $self->eid )
                {
                    $found = $self->true;
                    return;
                }
            });
        }
        return( $found );
    }
    # Works for xpath, but also need to account for special keywords starting with ':'
    # e.g.:
    # is( ":first-child" )
    # is( ":contains('Peter')" )
    # is( ":checked" )
    elsif( !ref( $this ) ||
           ( ref( $this ) && overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) )
    {
        my $xpath = $self->_xpath_value( $this );
        # false() method is inherited from Module::Generic module.
        if( $self->isa_collection() )
        {
            $self->children->foreach(sub
            {
                if( $_->matches( $xpath ) )
                {
                    $found = $self->true;
                    return;
                }
            });
        }
        else
        {
            $found = $self->true if( $self->matches( $xpath ) );
        }
        return( $found );
    }
    else
    {
        return( $self->error( "I was expecting a selector, an element object, a collection object or a code reference, but got '$this'." ) );
    }
}

sub isa_collection
{
    my $self = shift( @_ );
    if( scalar( @_ ) )
    {
        return( $_[0]->isa( 'HTML::Object::Collection' ) );
    }
    return( $self->isa( 'HTML::Object::Collection' ) );
}

sub isa_element
{
    my $self = shift( @_ );
    my $e = scalar( @_ ) ? shift( @_ ) : $self;
    return( $self->_is_a( $e, 'HTML::Object::DOM::Element' ) );
}

sub length
{
    my $self = shift( @_ );
    if( $self->isa_collection )
    {
        return( $self->children->length );
    }
    else
    {
        return( $self->new_number(1) );
    }
}

# $e->load( 'https://example.org/some/where' );
# $e->load( 'https://example.org/some/where', { param1 => value1, param2 => value2 } );
# $e->load( 'https://example.org/some/where', { param1 => value1, param2 => value2 }, sub
# {
#     my( $responseText, $responseStatus, $responseObject ) = @_;
#     # do something
# });
# <https://api.jquery.com/load/#load-url-data-complete>
# $e->load( 'https://example.org/some/where', sub
# {
#     my( $responseText, $responseStatus, $responseObject ) = @_;
#     # do something
# });
# $e->load({
#     url => 'https://example.org/some/where',
#     data => { param1 => value1, param2 => value2 },
#     callback => sub
#     {
#         my( $responseText, $responseStatus, $responseObject ) = @_;
#         # do something
#     }
# });
# <https://api.jquery.com/load/#load-url-data-complete>
sub load
{
    my $self = shift( @_ );
    my( $url, $data, $complete ) = @_;
    my $opts = {};
    if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
    {
        $opts = shift( @_ );
        ( $url, $data, $complete ) = @$opts{qw( url data callback )};
    }
    # e.g. $e->load( $url, $data, $complete, $options );
    elsif( scalar( @_ ) > 2 && ref( $_[-1] ) eq 'HASH' )
    {
        $opts = pop( @_ );
    }
    
    if( !defined( $complete ) && defined( $data ) && ref( $data ) eq 'CODE' )
    {
        $complete = $data;
        undef( $data );
    }
    if( defined( $data ) && ref( $data ) ne 'HASH' )
    {
        return( $self->error( "Data to be submitted to $url was provided, but I was expecting an hash reference and I got '$data'" ) );
    }
    if( defined( $complete ) && ref( $complete ) ne 'CODE' )
    {
        return( $self->error( "A callback parameter was provided, and I was expecting a code reference, such as an anonymous subroutine, but instead I got '$complete'" ) );
    }
    
    # No need to go further if there is nothing in our collection
    my $children = $self->isa_collection ? $self->children : $self->new_array( $self );
    return( $self ) if( !$children->length );
#     if( !$children->length )
#     {
#         if( defined( $complete ) )
#         {
#             my $resp = HTTP::Response->new( 204, 'No content', [] );
#             $children->foreach(sub
#             {
#                 $complete->( '', 'nocontent', $resp );
#             });
#         }
#         return( $self );
#     }
    
    # Ultimately, if the callback is not set, we set a dummy one instead
    $complete = sub{1} if( !defined( $complete ) );
    
    return( $self->error( "No url was provided to load data" ) ) if( !defined( $url ) || !CORE::length( "$url" ) );
    if( !$self->_load_class( 'LWP::UserAgent', { version => '6.49' } ) )
    {
        return( $self->error( "LWP::UserAgent version 6.49 or higher is required to use load()" ) );
    }
    if( !$self->_load_class( 'URI', { version => '1.74' } ) )
    {
        return( $self->error( "URI version 1.74 or higher is required to use load()" ) );
    }
    $opts->{timeout} //= 10;
    # "If one or more space characters are included in the string, the portion of the string following the first space is assumed to be a jQuery selector that determines the content to be loaded."
    # e.g.: $( "#new-projects" )->load( "/resources/load.html #projects li" );
    # <https://api.jquery.com/load/#load-url-data-complete>
    ( $url, my $target ) = split( /[[:blank:]\h]+/, $url, 2 );
    
    my $uri;
    try
    {
        $uri = URI->new( "$url" );
    }
    catch( $e )
    {
        return( $self->error( "Bad url provided \"$url\": $e" ) );
    }
    
    try
    {
        my $ua = LWP::UserAgent->new(
            agent   => "HTML::Object/$VERSION",
            timeout => $opts->{timeout},
        );
        my $resp;
        # "The POST method is used if data is provided as an object; otherwise, GET is assumed."
        # <https://api.jquery.com/load/#load-url-data-complete>
        if( defined( $data ) )
        {
            $resp = $ua->post( $uri, $data, ( ref( $opts->{headers} ) eq 'HASH' && scalar( keys( %{$opts->{headers}} ) ) ) ? %{$opts->{headers}} : () );
        }
        else
        {
            $resp = $ua->get( $uri, ( ref( $opts->{headers} ) eq 'HASH' && scalar( keys( %{$opts->{headers}} ) ) ) ? %{$opts->{headers}} : () );
        }
        
        if( $resp->header( 'Client-Warning' ) || !$resp->is_success )
        {
            $complete->( $resp->decoded_content, 'error', $resp );
            return( $self->error({
                code => $resp->code,
                message => $resp->message,
            }) );
        }
        my $content = $resp->decoded_content;
        my $parser = $self->new_parser;
        # HTML::Object::DOM::Document
        my $doc = $parser->parse_data( $content );
        my $new = $doc->children;
        # "When this method executes, it retrieves the content of ajax/test.html, but then jQuery parses the returned document to find the element with an ID of container. This element, along with its contents, is inserted into the element with an ID of result, and the rest of the retrieved document is discarded."
        if( defined( $target ) )
        {
            my $elem = $doc->find( $target ) || return( $self->pass_error( $doc->error ) );
            # $new = $self->new_array( $elem );
            $new = $elem->children;
        }
        
        # "If a "complete" callback is provided, it is executed after post-processing and HTML insertion has been performed. The callback is fired once for each element in the collection, and $_ is set to each DOM element in turn."
        $children->foreach(sub
        {
            my $child = shift( @_ );
            # Make a deep copy for each child element and set each child element's children
            my $clone = $new->map(sub{ $_->clone });
            $child->children( $clone );
            $child->reset(1);
            my $status = 'error';
            if( $resp->code >= 200 && $resp->code < 300 )
            {
                $status = 'success';
            }
            elsif( $resp->code == 304 )
            {
                $status = 'notmodified';
            }
            elsif( $resp->is_error )
            {
                $status = 'error';
            }
            $complete->( $content, $status, $resp );
        });
    }
    catch( $e )
    {
        require HTTP::Response;
        my $err = "Error trying to get url \"$url\": $e";
        my $resp2 = HTTP::Response->new( 500, "Unexpected error", [], $err );
        $complete->( $err, 'error', $resp2 );
        return( $self->error({
            code => 500,
            message => $err,
        }) );
    }
    return( $self );
}

sub map
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No code reference was provided." ) );
    return( $self->error( "I was expecting a code reference, but instead I was provided with this: \"", overload::StrVal( $code ), "\"." ) ) if( ref( $code ) ne 'CODE' );
    return( $self->children->for( $code ) );
}

sub matches
{
    my( $self, $path ) = @_;
    return( $self->xp->matches( $self, $path, $self ) );
}

sub name { return( shift->attr( name => shift( @_ ) ) ); }

sub new_attribute
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} = $self->debug unless( exists( $opts->{debug} ) );
    my $e = HTML::Object::DOM::Attribute->new( $opts ) ||
        return( $self->pass_error( HTML::Object::DOM::Attribute->error ) );
    return( $e );
}

sub new_collection
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} = $self->debug unless( exists( $opts->{debug} ) );
    $opts->{end} = $self unless( exists( $opts->{end} ) );
    my $e = HTML::Object::Collection->new( $opts ) ||
        return( $self->pass_error( HTML::Object::Collection->error ) );
    return( $e );
}

sub new_parser { HTML::Object::DOM->new }

sub new_root
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} = $self->debug unless( exists( $opts->{debug} ) );
    my $e = HTML::Object::DOM::Root->new( $opts ) ||
        return( $self->pass_error( HTML::Object::DOM::Root->error ) );
    return( $e );
}

# Takes a selector expression; or
# a element object; or
# a collection of elements; or
# an array of element objects to match against the set.
sub not
{
    my $self = shift( @_ );
    my $this;
    $this = shift( @_ ) if( scalar( @_ ) );
    my $collection = $self->new_collection( end => $self );
    # Process array of elements
    my $process;
    $process = sub
    {
        my( $kids, $to_exclude ) = @_;
        my $exclude = $self->new_array;
        $kids->foreach(sub
        {
            my $elem = shift( @_ );
            my $path = $elem->getNodePath();
            $to_exclude->foreach(sub
            {
                my $e = shift( @_ );
                return( 1 ) if( !$self->_is_object( $e ) || !$e->isa( 'HTML::Object::DOM::Element' ) );
                return( 1 ) if( !$e->isa( 'HTML::Object::DOM::Comment' ) || $e->isa( 'HTML::Object::DOM::Text' ) || $e->isa( 'HTML::Object::DOM::Declaration' ) || $e->isa( 'HTML::Object::DOM::Space' ) );
                # This element matches the xpath of one of the collection element, so we exclude it from the result
                if( $e->matches( $path ) )
                {
                    $exclude->push( $elem );
                    return(1);
                }
            });
        });
        return( $kids->clone->remove( $exclude ) );
    };
    
    # No parameter provided, thus we return an empty collection
    if( !defined( $this ) )
    {
        return( $collection );
    }
    elsif( !ref( $this ) || ( $self->_is_object( $this ) && overload::Overloaded( $this ) && overload::Method( '""' ) ) )
    {
        my $xpath = $self->_xpath_value( "$this" );
        my $doc = $self->filter(sub
        {
            my $elem = shift( @_ );
            try
            {
                return( !$elem->matches( $xpath ) );
            }
            catch( $e )
            {
                return( $self->error( "Caught an exception while calling matches with xpath '$xpath' for element of class ", ref( $elem ), " and tag '", $elem->tag, "': $e" ) );
            }
        });
        $collection->children( $doc->children );
    }
    elsif( $self->_is_array( $this ) )
    {
        $this = $self->new_array( $this );
        #my $new = $self->children->clone->remove( $this );
        #$collection->children( $new );
        $this->unique(1);
        my $new = $process->( $self->children, $this );
        $collection->children( $new );
    }
    elsif( $self->_is_object( $this ) && $self->isa_collection( $this ) )
    {
        my $kids = $this->children;
        my $new = $process->( $self->children, $kids );
        $collection->children( $new );
    }
    elsif( $self->_is_object( $this ) && $this->isa( 'HTML::Object::DOM::Element' ) )
    {
        $this = $self->new_array( [ $this ] );
        my $new = $process->( $self->children, $this );
        $collection->children( $new );
    }
    else
    {
        return( $self->error( "I receive an object \"", ref( $this ), "\", but I do not know what to do with it." ) );
    }
    return( $collection );
}

# Returns a new collection of elements whose position is an even number
sub odd
{
    my $self = shift( @_ );
    return( $self ) unless( $self->isa_collection );
    my $odd = $self->children->odd;
    my $collection = $self->new_collection;
    $collection->children( $odd );
    return( $collection );
}

# Takes html string (start with <tag...), text object (HTML::Object::DOM::Text), array or element object
# or alternatively a code reference that returns the above
sub prepend { return( shift->_append_prepend( @_, { action => 'prepend' } ) ); }

sub prependTo { return( shift->_append_prepend_to( @_, { action => 'prepend' } ) ); }

# TODO: prop(), e.g. $e->prop('outerHTML') or $e->prop('tagName')
sub prop
{
    my $self = shift( @_ );
    # In get mode, this only affects the first element of the set
    # In set mode, this affect all elements of the set
    # <https://api.jquery.com/prop/#prop-propertyName>
    # <https://developer.mozilla.org/en-US/docs/Web/API/Element#properties>
    my $map =
    {
    checked             => sub{ return( shift->attr( 'checked' ) ); },
    # Returns the number of child elements of this element.
    childElementCount   => sub{ return( shift->children->length ); },
    # Returns the child elements of this element.
    children            => sub{ return( shift->children ); },
    # Is a DOMString representing the class of the element.
    className           => sub{ return( shift->attr( 'class' ) ); },
    disabled            => sub{ return( shift->attr( 'disabled' ) ); },
    # Returns the first child element of this element.
    firstElementChild   => sub{ return( shift->children->first ); },
    # Is a DOMString representing the id of the element.
    id                  => sub{ return( shift->attr( 'id' ) ); },
    # Is a DOMString representing the markup of the element's content.
    innerHTML           => sub
    {
        my $e = shift( @_ );
        my $a = $self->new_array;
        $self->children->foreach(sub
        {
            my $e = shift( @_ );
            my $v = $e->as_string;
            $a->push( defined( $v ) ? $v->scalar : $v );
        });
        return( $a->join( '' ) );
    },
    # Returns the last child element of this element.
    lastElementChild    => sub{ return( shift->children->last ); },
    # A DOMString representing the local part of the qualified name of the element.
    localName           => sub{ return( shift->tag ); },
    # Is an Element, the element immediately following the given one in the tree, or null if there's no sibling node.
    nextElementSibling  => sub
    {
        my $e = shift( @_ );
        my $parent = $e->parent || return;
        my $pos = $parent->children->pos( $e );
        return( $parent->children->index( $pos + 1 ) );
    },
    # Is a DOMString representing the markup of the element including its content. When used as a setter, replaces the element with nodes parsed from the given string.
    outerHTML           => sub{ return( shift->as_string ); },
    # Is a Element, the element immediately preceding the given one in the tree, or null if there is no sibling element.
    previousElementSibling => sub
    {
        my $e = shift( @_ );
        my $parent = $e->parent || return;
        my $pos = $parent->children->pos( $e );
        return( $parent->children->index( $pos - 1 ) );
    },
    readonly            => sub{ return( shift->attr( 'readonly' ) ); },
    # Returns a String with the name of the tag for the given element.
    tagName             => sub{ return( shift->tag ); },
    };
    my $ro = $self->new_array( [qw(
        childelementcount children firstelementchild
    )] );
    
    # Get
    if( scalar( @_ ) == 1 )
    {
        my $e = $self->isa_collection ? $self->children->first : $self;
        return if( !$e );
        my $prop = lc( shift( @_ ) );
        return( $self->error( "No such property \"$prop\"." ) ) if( !CORE::exists( $map->{ $prop } ) );
        my $code = $map->{ $prop };
        return( $code->( $e ) );
    }
    # Set
    elsif( scalar( @_ ) > 1 )
    {
        my $all = $self->new_array( $self->isa_collection ? $self->children : [ $self ] );
        my @props = @_;
        while( scalar( @props ) )
        {
            my( $prop, $val ) = CORE::splice( @props, 0, 2 );
            $prop = lc( $prop );
            if( defined( $val ) && CORE::length( $val ) && $ro->exists( $prop ) )
            {
                next;
            }
            
            # process the html
            if( $prop eq 'innerHTML' )
            {
                if( defined( $val ) )
                {
                    my $p = HTML::Object::DOM->new;
                    my $doc = $p->parse_data( $val ) || do
                    {
                        $! = $p->error;
                        return;
                    };
                    $all->foreach(sub
                    {
                        my $e = shift( @_ );
                        $e->children( $doc->children );
                        $e->reset(1);
                    });
                }
                else
                {
                    $all->foreach(sub
                    {
                        my $e = shift( @_ );
                        $e->children->empty;
                        $e->reset(1);
                    });
                }
                next;
            }
            elsif( $prop eq 'outerHTML' )
            {
                if( defined( $val ) )
                {
                    my $p = HTML::Object::DOM->new;
                    my $doc = $p->parse_data( $val ) || do
                    {
                        $! = $p->error;
                        return;
                    };
                    $all->foreach(sub
                    {
                        my $e = shift( @_ );
                        my $parent = $e->parent;
                        return(1) if( !$parent );
                        my $pos = $parent->children->pos( $e );
                        my @new = ();
                        $doc->children->foreach(sub
                        {
                            my $kid = shift( @_ );
                            my $clone = $kid->clone;
                            $clone->parent( $parent );
                            push( @new, $clone );
                        });
                        $parent->children->splice( $pos, 1, @new );
                        $parent->reset(1);
                    });
                }
                else
                {
                    $all->foreach(sub
                    {
                        my $e = shift( @_ );
                        my $parent = $e->parent;
                        return(1) if( !$parent );
                        my $pos = $parent->children->pos( $e );
                        $e->children->splice( $pos, 1 );
                        $e->reset(1);
                    });
                }
                next;
            }
            
            $all->foreach(sub
            {
                my $e = shift( @_ );
                if( $prop eq 'checked' )
                {
                    if( $val )
                    {
                        $e->attr( checked => 'checked' );
                    }
                    else
                    {
                        $e->attributes->delete( $prop );
                    }
                    $e->reset(1);
                }
                elsif( $prop eq 'className' )
                {
                    if( defined( $val ) )
                    {
                        $e->attr( class => $val );
                    }
                    else
                    {
                        $e->attributes->delete( 'class' );
                    }
                    $e->reset(1);
                }
                elsif( $prop eq 'disabled' )
                {
                    if( $val )
                    {
                        $e->attr( disabled => 'disabled' );
                    }
                    else
                    {
                        $e->attributes->delete( $prop );
                    }
                    $e->reset(1);
                }
                elsif( $prop eq 'id' )
                {
                    if( defined( $val ) )
                    {
                        $e->attr( id => $val );
                    }
                    else
                    {
                        $e->attributes->delete( $prop );
                    }
                    $e->reset(1);
                }
                elsif( $prop eq 'readonly' )
                {
                    if( $val )
                    {
                        $e->attr( readonly => 'readonly' );
                    }
                    else
                    {
                        $e->attributes->delete( $prop );
                    }
                    $e->reset(1);
                }
            });
        }
    }
}

sub promise
{
    my $self = shift( @_ );
    return( Promise::Me->new( @_ ) );
    # my $deferred = Promise::XS::deferred();
    # return( $deferred->promise() );
}

sub rank { return( shift->_set_get_number_as_object( 'rank', @_ ) ); }

# <https://api.jquery.com/remove/>
# TODO: Need to check again and do some test to ensure this api is compliant
sub remove
{
    my $self = shift( @_ );
    if( $self->isa_collection )
    {
        my $deleted = $self->children->foreach(sub{ $_->delete });
    }
    # xpath provided
    elsif( @_ )
    {
        my $xpath = $self->_xpath_value( shift( @_ ) ) || return;
        return( $self->find( $xpath )->remove );
    }
    # Equivalent to delete
    else
    {
        return( $self->delete );
    }
}

sub removeAttr
{
    my $self = shift( @_ );
    my $attr = shift( @_ );
    return( $self ) if( !defined( $attr ) );
    if( $self->isa_collection )
    {
        $self->children->foreach(sub
        {
            $_->attributes->delete( $attr );
            $_->reset(1);
        });
    }
    else
    {
        $self->attributes->delete( $attr );
        $self->reset(1);
    }
    return( $self );
}

# class name, array of class name or a code reference
# If parameter is a code reference it must return a class name or an array of class name
# It receives "the index position of the element in the set and the old class value as arguments"
sub removeClass
{
    my $self = shift( @_ );
    my $this;
    $this = shift( @_ ) if( @_ );
    my $a;
    # No class provided, so we will remove all existing class
    if( !defined( $this ) )
    {
        $a = $self->new_array;
    }
    elsif( $self->_is_array( $this ) )
    {
        $a = $self->new_array( $this );
        my $failed = 0;
        $a->foreach(sub
        {
            $failed++, return( $self->error( "Class provided to be removed \"$_\" is not a string nor an overloaded object." ) ) if( ref( $_ ) && !( overload::Overloaded( $_ ) && overload::Method( $_, '""' ) ) );
        });
        return( $self ) if( $failed );
    }
    
    my $process;
    $process = sub
    {
        my $e = shift( @_ );
        return( $e ) unless( $e->attributes->exists( 'class' ) );
        my $c = $self->new_array( [split( /[[:blank:]\h]+/, $e->attributes->get( 'class' ) )] );
        # Loop through the element classes
        $c->for(sub
        {
            my( $i, $v ) = @_;
            if( ref( $this ) CORE::eq 'CODE' )
            {
                local $_ = $self;
                my $res = $this->( $i, $v );
                if( $self->_is_array( $res ) )
                {
                    $a = $self->new_array( $res );
                }
                else
                {
                    $a = $self->new_array( [ $res ] );
                }
            }
            $a->foreach(sub
            {
                my $to_remove = shift( @_ );
                if( $v CORE::eq "$to_remove" )
                {
                    $c->splice( $i, 1 );
                    $c->return( -1 );
                }
                return;
            });
        });
        $e->reset(1);
        return(1);
    };
    if( $self->isa_collection )
    {
        $self->children->foreach( $process );
    }
    else
    {
        $process->( $self );
    }
    return( $self );
}

# Takes html string, array of elements, an element (including a collection object) or a code reference
sub replaceWith
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "Nothing was provided to replace." ) );
    my $a;
    if( !ref( $this ) )
    {
        my $p = $self->new_parser;
        $this = $p->parse_data( $this ) || return( $self->pass_error( $p->error ) );
        $a = $self->new_array( [ $this ] );
    }
    elsif( $self->_is_array( $this ) )
    {
        # Make sure this is a Module::Generic::Array object
        $a = $self->new_array( $this );
    }
    elsif( $self->_is_object( $this ) )
    {
        return( $self->error( "Object provided '$this' (", overload::StrVal( $this ), ") is not an HTML::Object::DOM::Element object." ) ) if( !$this->isa( 'HTML::Object::DOM::Element' ) );
        $a = $self->new_array( [ $this ] );
    }
    elsif( ref( $this ) ne 'CODE' )
    {
        return( $self->error( "I do not know what to do with '$this'. I was expecing an html string, or an HTML::Object::DOM::Element or an array of element objects or a collection object (HTML::Object::Collection) or a code reference." ) );
    }
    
    if( $self->isa_collection )
    {
        my $failed = 0;
        $self->children->foreach(sub
        {
            my $elem = shift( @_ );
            if( ref( $this ) CORE::eq 'CODE' )
            {
                local $_ = $elem;
                my $res = $this->( $elem );
                $failed++, return( $self->error( "An error occurred while executing code reference to replace html element(s). Code reference returned undef." ) ) if( !defined( $res ) );
                if( $self->_is_object( $res ) && $res->isa( 'HTML::Object::DOM::Element' ) )
                {
                    $a = $self->new_array( [ $res ] );
                }
                elsif( overload::Overloaded( $res ) && overload::Method( $res, '""' ) )
                {
                    my $elem = $self->new_parser( "$res" );
                    $failed++, return if( !defined( $elem ) );
                    $a = $self->new_array( [ $elem ] );
                }
                else
                {
                    $failed++, return( $self->error( "Value returned from code reference to be used in replaceWith is neither a string nor a HTML::Object::DOM::Element, so I do not know what to do with it." ) );
                }
            }
            return( $self->error( "Found an element within a collection that has no parent! Element has tag \"", $elem->tag, "\"." ) ) if( !$elem->parent );
            my $pos = $elem->parent->pos( $elem );
            return( $self->error( "This element with tag \"", $self->tag, "\" has a parent and yet I could not find its position." ) ) if( !defined( $pos ) );
            my $new = $self->new_array;
            $a->foreach(sub
            {
                my $e = $_->detach->clone();
                $e->parent( $elem->parent );
                $new->push( $e );
            });
            $elem->parent->children->splice( $pos, 1, $a->list );
            $elem->parent->reset(1);
        });
        # Now that the element have been copied to their replacement location, we remove them
        $a->foreach(sub
        {
            $_->delete;
        });
        return if( $failed );
    }
    else
    {
        if( ref( $this ) CORE::eq 'CODE' )
        {
            local $_ = $self;
            my $res = $this->( $self );
            return( $self->error( "An error occurred while executing code reference to replace html element(s). Code reference returned undef." ) ) if( !defined( $res ) );
            if( $self->_is_object( $res ) && $res->isa( 'HTML::Object::DOM::Element' ) )
            {
                $a = $self->new_array( [ $res ] );
            }
            elsif( overload::Overloaded( $res ) && overload::Method( $res, '""' ) )
            {
                my $elem = $self->new_parser( "$res" );
                return if( !defined( $elem ) );
                $a = $self->new_array( [ $elem ] );
            }
            else
            {
                return( $self->error( "Value returned from code reference to be used in replaceWith is neither a string nor a HTML::Object::DOM::Element, so I do not know what to do with it." ) );
            }
        }
        
        # Object has no parent, so we are essentially replace 1 element for one or more others with no attachment to the dom
        if( !$self->parent )
        {
            # Basically swapping one element for another
            if( $a->length == 1 )
            {
                my $e = $a->first;
                $e->detach;
                return( $e );
            }
            # There are multiple element, create a document element
            else
            {
                my $doc = HTML::Object::DOM::Document->new;
                $doc->children( $a );
                $a->foreach(sub
                {
                    $_->detach;
                    $_->parent( $doc );
                    $_->parent->reset(1);
                });
                return( $doc );
            }
        }
        else
        {
            my $pos = $self->parent->pos( $self );
            return( $self->error( "This element with tag \"", $self->tag, "\" has a parent and yet I could not find its position." ) ) if( !defined( $pos ) );
            $a->foreach(sub
            {
                $_->detach->parent( $self->parent );
            });
            $self->parent->children->splice( $pos, 1, $a->list );
            $self->parent->reset(1);
        }
    }
    return( $self );
}

sub set_namespace
{
    my $self = shift( @_ );
    return( $self->xp->new->set_namespace( @_ ) );
}

# Since this is a perl context, this only set the inline css 1) back to its previous value, 
# if any; or 2) remove the display property if there was no previous value set.
# Any parameter provided will be ignored
# See the hide() method for its alter ego.
sub show
{
    my $self = shift( @_ );
    my( $this, $code ) = @_;
    $code = $this if( ref( $this ) eq 'CODE' && !defined( $code ) );
    my $process;
    $process = sub
    {
        my $e = shift( @_ );
        my $internal = $e->internal;
        my $rule = $self->_css_object();
        if( defined( $rule ) )
        {
            my $display = $rule->get_property_by_name( 'display' );
            my $val = $display->value;
            # if display current value is 'none', we check if there was a previous value we kept
            # and if there is we restore it, otherwise we simply just remove the property
            if( $val eq 'none' )
            {
                my $previous_val = $internal->{css_display_value};
                if( defined( $previous_val ) && CORE::length( $previous_val ) )
                {
                    $display->value( $previous_val );
                }
                else
                {
                    $display->remove_from( $rule );
                }
            }
        }
        # otherwise, there is no rule inline defined, and thus, nothing to do.
        
        # Is there any rule and properties to save back?
        if( defined( $rule ) && $rule->elements->length > 0 )
        {
            $e->_css_object( $rule );
        }
    };
    
    if( $self->isa_collection )
    {
        $self->children->foreach(sub
        {
            $process->( $_ );
            $_->reset(1);
        });
    }
    elsif( $self->tag->substr( 0, 1 ) eq '_' )
    {
        return( $self->error( "You can only use the hide() or show() method on html object elements. The element you are calling hide() with is an object of class \"", ref( $self ), "\"." ) );
    }
    else
    {
        $process->( $self );
        $self->reset(1);
    }
}

sub string_value 
{
    my $self = shift( @_ );
    return( $self->value ) if( $self->isCommentNode );
    return( $self->as_text );
}

# This is normally a HTML::Object::DOM::Element property and it should not be used equally
# by a collection object, because of its nature, so we created it here to catch calls to it
# while still allowing HTML::Object::DOM::Element to use it normally
sub tag
{
    my $self = shift( @_ );
    if( @_ )
    {
        if( $self->isa_collection )
        {
            return( $self->error( "tag is a read-only property" ) );
        }
        else
        {
            return( $self->_set_get_scalar_as_object( 'tag', @_ ) );
        }
    }
    else
    {
        if( $self->isa_collection )
        {
            my $first = $self->children->first;
            return unless( $first && $self->_is_a( $first, 'HTML::Object::DOM::Element' ) );
            return( $first->_set_get_scalar_as_object( 'tag' ) );
        }
        else
        {
            return( $self->_set_get_scalar_as_object( 'tag' ) );
        }
    }
}

sub tagname
{
    my $self = shift( @_ );
    my @args = @_;
    my $map =
    {
    Comment => '#comment',
    Text    => '#text'
    };
    my $a = $self->new_array;
    $self->children->foreach(sub
    {
        my $e = shift( @_ );
        my $type = [split( /::/, ref( $e ) )]->[-1];
        $a->push( exists( $map->{ $type } ) ? $map->{ $type } : $e->tag( @args ) );
    });
    return( $a );
}

# Takes a class name; or
# class name and state (true or false); or
# array of class names; or
# array of class names and a state; or
# a code reference called with the index position of the current class and its name. Returns a space separated list of classes or an array
# <https://api.jquery.com/toggleClass/>
sub toggleClass
{
    my $self = shift( @_ );
    my $this;
    $this = shift( @_ ) if( @_ );
    my $state;
    $state = scalar( @_ ) ? shift( @_ ) : 1;
    my $a = $self->new_array;
    my $has_code = 0;
    if( defined( $this ) )
    {
        if( $self->_is_array( $this ) )
        {
            $a = $self->new_array( $this );
        }
        elsif( ref( $this ) CORE::eq 'CODE' )
        {
            # ok
            $has_code++;
        }
        elsif( ref( $this ) && overload::Overloaded( $this ) && overload::Method( $this, '""' ) )
        {
            $a = $self->new_array( [split( /[[:blank:]\h]+/, "$this" )] );
        }
        else
        {
            return( $self->error( "I was expecting an array reference of classes, or class string or a code reference, but instead I got '$this', and I do not know what to do with it." ) );
        }
        # Make sure the classes we are provided are unique
        $a->unique(1);
    }
    
    my $process;
    $process = sub
    {
        my( $i, $e ) = @_;
        my $ref = $e->internal->{class};
        $ref //= {};
        $ref->{toggle_status} //= 0;
        my $classes;
        if( $e->attributes->exists( 'class' ) )
        {
            $classes = $self->new_array( [split( /[[:blank:]\h]+/, $e->attributes->get( 'class' ) )] );
            $ref->{original_classes} //= $classes;
        }
        # No class on this element yet
        
        if( $has_code )
        {
            local $_ = $e;
            my $res = $this->( $i, $classes, $ref->{toggle_status} );
            if( $self->_is_array( $res ) )
            {
                $a = $self->new_array( $res );
            }
            elsif( !ref( $res ) || ( overload::Overloaded( $res ) && overload::Method( $res, '""' ) ) )
            {
                $a = $self->new_array( [ split( /[[:blank:]\h]+/, "$res" ) ] );
            }
            else
            {
                warn( "Code reference for class of element with tag \"", $e->tag, "\" returned '$this', but I do not know what to do with it.\n" );
                return( 1 );
            }
            $a->unique(1);
        }
        
        # No class set yet on this element
        if( !defined( $classes ) )
        {
            # and we have no class either, so we skip to the next element. Nothing to do here
            if( !$a->length )
            {
                return(1);
            }
            # we activate our classes
            else
            {
                $ref->{toggle_status} = 1;
                $e->attributes->set( class => $a->join( ' ' ) );
                $e->reset(1);
            }
        }
        else
        {
            # we found existing class, and we toggled without specifying any
            # which mean we switch them all on/off
            if( !$a->length )
            {
                $e->attributes->set( class => ( $ref->{toggle_status} ? $ref->{original_classes} : '' ) );
            }
            # Specific were provided. We toggle them on/off
            else
            {
                if( $ref->{toggle_status} )
                {
                    $classes->remove( $a );
                }
                else
                {
                    $classes->push( $a->list )->unique;
                }
                $e->attributes->set( class => $classes->join( ' ' ) );
                $e->reset(1);
                $ref->{toggle_status} = !$ref->{toggle_status};
            }
        }
    };
    
    if( $self->isa_collection )
    {
        $self->children->for( $process );
    }
    else
    {
        $process->( 0, $self );
    }
}

sub to_number { return( HTML::Object::DOM::Number->new( shift->getValue ) ); }

sub toString { return( shift->as_xml( @_ ) ); }

sub xp
{
    my $self = shift( @_ );
    unless( $XP )
    {
        $XP = HTML::Object::XPath->new;
    }
    # $XP->debug( $self->debug );
    return( $XP );
}

# Ref: <https://api.jquery.com/Types/#jQuery>
# xq( '#myId', $document )
# xq( '<div />', { id => 'Pouec', class => 'Hello' } );
# xq( '<html><head><title>Hello world</title></head><body>Hello!</body></html>' );
# xq();
sub xq
{
    my( $this, $more ) = @_;
    # e.g. $('<div />', { id => 'pouec', class => 'hello' });
    if( $this =~ /$LOOK_LIKE_HTML/ )
    {
        print( STDERR __PACKAGE__, "::xq: Argument provided looks like ", CORE::length( $this ), " bytes of HTML, parsing it.\n" ) if( $HTML::Object::XQuery::DEBUG >= 4 );
        my $p = HTML::Object::DOM->new;
        my $doc = $p->parse_data( $this ) || do
        {
            $! = $p->error;
            return;
        };
        # $doc is a HTML::Object::DOM::Document, which is not suitable, so we change it to a
        # collection object
        my $collection = $doc->new_collection;
        print( STDERR __PACKAGE__, "::xq: Pushing ", $doc->children->length, " elements found into our new collection.\n" ) if( $HTML::Object::XQuery::DEBUG >= 4 );
        $collection->children( $doc->children );
        if( $doc->children->length == 1 )
        {
            my $e = $doc->children->first;
            # I do not use Module::Generic::_is_hash on purpose because I do not want to catch objects inadvertently
            # We found attributes, so we set them up now
            if( ref( $more ) CORE::eq 'HASH' )
            {
                my $debug = CORE::delete( $more->{_debug} ) if( CORE::exists( $more->{_debug} ) );
                $e->attributes->merge( $more );
                $e->debug( $debug );
                $collection->debug( $debug );
            }
            # We correct a situation where the user called for example $('<div />', { class => 'hello', id => 'pouec' });
            # And this would lead the parser to flag it to be empty, respecting the user decision,
            # but in this case, this is merely a short-hand notation to create a tag, and is not a
            # reflexion that this tag should indeed be treated as empty when it is not by standard
            # hus, we correct it here.
            if( $e->children->length == 0 && $e->is_empty )
            {
                my $def = $p->get_definition( $e->tag );
                $e->is_empty(0) if( !$def->{is_empty} );
                $e->close;
            }
        }
        return( $collection );
    }
    elsif( !ref( $this ) || ( overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) )
    {
        print( STDERR __PACKAGE__, "::xq: Argument provided '$this' looks like a selector, searching for it.\n" ) if( $HTML::Object::XQuery::DEBUG >= 4 );
        # e.g. $('div')
        if( !defined( $more ) )
        {
            # e.g. $('body')
            if( defined( $HTML::Object::DOM::GLOBAL_DOM ) )
            {
                my $collection = $HTML::Object::DOM::GLOBAL_DOM->find( $this ) || return;
                return( $collection );
            }
            else
            {
                return( HTML::Object::DOM->error( "You need to provide some context to the selector by supplying an HTML::Object::DOM::Element object." ) );
            }
        }
        # e.g., with context: $('div', $element);
        elsif( !ref( $more ) || ( ref( $more ) && !$more->isa( 'HTML::Object::DOM::Element' ) ) )
        {
            return( HTML::Object::DOM->error( "Context provided selector must be an element object. Got '", overload::StrVal( $more ), "'" ) );
        }
        my $collection = $more->find( $this ) || return( HTML::Object::DOM->pass_error( $more->error ) );
        $collection->debug( $more->debug );
        return( $collection );
    }
    else
    {
        return( HTML::Object::DOM->error( "I do not know what to do with '$this'." ) );
    }
}

sub _append_prepend
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "Nothing was provided to append or prepend." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !exists( $opts->{action} ) )
    {
        my @caller_info = caller(1);
        my $caller = [split( /::/, $caller_info[3])]->[-1];
        return( $self->error( "No action argument was provided and I am unable to guess it." ) ) if( $caller !~ /^(append|prepend)$/ );
        $opts->{action} = $caller;
    }
    return( $self->error( "Invalid value for argument \"action\": '$opts->{action}'" ) ) if( $opts->{action} !~ /^(append|prepend)$/ );
    my $a;
    if( !ref( $this ) )
    {
        my $p = $self->new_parser;
        $this = $p->parse_data( $this ) || return( $self->pass_error( $p->error ) );
        $a = $self->new_array( [ $this ] );
    }
    elsif( $self->_is_array( $this ) )
    {
        # Make sure this is a Module::Generic::Array object
        $a = $self->new_array( $this );
    }
    elsif( $self->_is_object( $this ) )
    {
        return( $self->error( "Object provided '$this' (", overload::StrVal( $this ), ") is not an HTML::Object::DOM::Element object." ) ) if( !$this->isa( 'HTML::Object::DOM::Element' ) );
        $a = $self->new_array( [ $this ] );
    }
    elsif( ref( $this ) ne 'CODE' )
    {
        return( $self->error( "I do not know what to do with '$this'. I was expecing an html string, or an HTML::Object::DOM::Element or an array of element objects or a collection object (HTML::Object::Collection) or a code reference." ) );
    }
    
    if( $self->isa_collection )
    {
        my $failed = 0;
        # Going through each object in the collection
        $self->children->for(sub
        {
            my( $i, $e ) = @_;
            $e->reset(1);
            # will silently fail just like jQuery does
            my $parent = $e->parent;
            my $pos = $parent ? $parent->children->pos( $e ) : $i;
            if( ref( $this ) CORE::eq 'CODE' )
            {
                local $_ = $e;
                my $res = $this->( $pos, $e->as_string );
                $failed++, return( $self->error( "An error occurred while executing code reference to $opts->{action} html element(s). Code reference returned undef." ) ) if( !defined( $res ) );
                if( $self->_is_object( $res ) && $res->isa( 'HTML::Object::DOM::Element' ) )
                {
                    $a = $self->new_array( [ $res ] );
                }
                elsif( overload::Overloaded( $res ) && overload::Method( $res, '""' ) )
                {
                    my $elem = $self->new_parser( "$res" );
                    $failed++, return if( !defined( $elem ) );
                    $a = $self->new_array( [ $elem ] );
                }
                else
                {
                    $failed++, return( $self->error( "Value returned from code reference to be used in $opts->{action}\(\) is neither a string nor a HTML::Object::DOM::Element, so I do not know what to do with it." ) );
                }
            }
            $a->foreach(sub
            {
                my $elem = $_->detach->clone;
                $elem->parent( $e );
                if( $opts->{action} CORE::eq 'append' )
                {
                    $e->children->push( $elem );
                }
                elsif( $opts->{action} CORE::eq 'prepend' )
                {
                    $e->children->unshift( $elem );
                }
            });
        });
        return if( $failed );
    }
    else
    {
        $self->reset(1);
        # will silently fail just like jQuery does
        my $parent = $self->parent;
        my $pos = $parent ? $parent->children->pos( $self ) : 0;
        if( ref( $this ) CORE::eq 'CODE' )
        {
            local $_ = $self;
            my $res = $this->( $pos, $self->as_string );
            return( $self->error( "An error occurred while executing code reference to $opts->{action} html element(s). Code reference returned undef." ) ) if( !defined( $res ) );
            if( $self->_is_object( $res ) && $res->isa( 'HTML::Object::DOM::Element' ) )
            {
                $a = $self->new_array( [ $res ] );
            }
            elsif( overload::Overloaded( $res ) && overload::Method( $res, '""' ) )
            {
                my $elem = $self->new_parser( "$res" );
                return if( !defined( $elem ) );
                $a = $self->new_array( [ $elem ] );
            }
            else
            {
                return( $self->error( "Value returned from code reference to be used in $opts->{action}\(\) is neither a string nor a HTML::Object::DOM::Element, so I do not know what to do with it." ) );
            }
        }
        $a->foreach(sub
        {
            $_->detach();
            $_->parent( $self );
            if( $opts->{action} CORE::eq 'append' )
            {
                $self->children->push( $_ );
            }
            elsif( $opts->{action} CORE::eq 'prepend' )
            {
                $self->children->unshift( $_ );
            }
        });
    }
    return( $self );
}

# Takes html string; or
# selector; or
# element object; or
# array of objects; or
# collection
# "If there is more than one target element, however, cloned copies of the inserted element will be created for each target except the last, and that new set (the original element plus clones) is returned."
sub _append_prepend_to
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "No target was provided to insert element." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !exists( $opts->{action} ) )
    {
        my @caller_info = caller(1);
        my $caller = [split( /::/, $caller_info[3])]->[-1];
        return( $self->error( "No action argument was provided and I am unable to guess it." ) ) if( $caller !~ /^(appendTo|prependTo|append_to|prepend_to)$/ );
        $opts->{action} = ( $caller =~ /^(append|prepend)(?:To|_to)$/ )[0];
    }
    return( $self->error( "Invalid value for argument \"action\": '$opts->{action}'" ) ) if( $opts->{action} !~ /^(append|prepend)$/ );
    my $a;
    # A collection to be returned if there is more than 1 target
    my $collection = $self->new_collection;
    if( !ref( $this ) )
    {
        if( $self->_is_html( $this ) )
        {
            my $p = $self->new_parser;
            $this = $p->parse_data( $this ) || return( $self->pass_error( $p->error ) );
            $a = $self->new_array( [ $this ] );
        }
        # otherwise this has to be a selector
        # TODO: Need to correct this and adjust the object used as a base for the find
        # since $self could very well be a dynamically created dom object
        else
        {
            $this = $self->find( $this ) || return;
            $a = $self->new_array( [ $this ] );
        }
    }
    elsif( $self->_is_array( $this ) )
    {
        # Make sure this is a Module::Generic::Array object
        $a = $self->new_array( $this );
    }
    elsif( $self->_is_object( $this ) )
    {
        return( $self->error( "Object provided '$this' (", overload::StrVal( $this ), ") is not an HTML::Object::DOM::Element object." ) ) if( !$this->isa( 'HTML::Object::DOM::Element' ) );
        $a = $self->new_array( [ $this ] );
    }
    else
    {
        return( $self->error( "I do not know what to do with \"$this\". I was expecting a selector, html data, an element object or an array." ) );
    }
    
    # If the content to be inserted is a collection, we loop through it, duplicate each element and insert them
    if( $self->isa_collection )
    {
        $a->foreach(sub
        {
            my $elem = $_;
            my $parent = $elem->parent;
            return( 1 ) if( !$parent );
            my $pos = $parent->children->pos( $elem );
            warn( "Found a parent for tag \"", $elem->tag, "\", but somehow I could not find its position among its children elements.\n" ) if( !defined( $pos ) );
            return( 1 ) if( !defined( $pos ) );
            $self->children->foreach(sub
            {
                my $e = shift( @_ );
                # Making sure the content element is detached from its original parent
                my $clone = $e->detach->clone;
                $clone->parent( $elem );
                $clone->reset(1);
                if( $opts->{action} CORE::eq 'before' )
                {
                    $parent->children->splice( $pos, 0, $clone );
                }
                elsif( $opts->{action} CORE::eq 'after' )
                {
                    $parent->children->splice( $pos + 1, 0, $clone );
                }
                $collection->children->push( $clone );
            });
        });
    }
    else
    {
        # If the target is just one element, we do not duplicate them, but simply move them
        if( $a->length == 1 )
        {
            my $elem = $a->first;
            my $parent = $elem->parent;
            return( 1 ) if( !$parent );
            $elem->reset(1);
            my $pos = $parent->children->pos( $elem );
            return( $self->error( "Found a parent for tag \"", $elem->tag, "\", but somehow I could not find its position among its children elements." ) ) if( !defined( $pos ) );
            $self->detach;
            $self->parent( $elem );
            if( $opts->{action} CORE::eq 'before' )
            {
                $parent->children->splice( $pos, 0, $self );
            }
            elsif( $opts->{action} CORE::eq 'after' )
            {
                $parent->children->splice( $pos + 1, 0, $self );
            }
            $collection->children->push( $self );
        }
        # However, if the target contain multiple element, we clone the content element
        else
        {
            $a->foreach(sub
            {
                my $elem = $_;
                my $parent = $elem->parent;
                return( 1 ) if( !$parent );
                $elem->reset(1);
                my $pos = $parent->children->pos( $elem );
                warn( "Found a parent for tag \"", $elem->tag, "\", but somehow I could not find its position among its children elements.\n" ) if( !defined( $pos ) );
                return( 1 ) if( !defined( $pos ) );
                my $clone = $self->detach->clone;
                $clone->parent( $elem );
                if( $opts->{action} CORE::eq 'before' )
                {
                    $parent->children->splice( $pos, 0, $clone );
                }
                elsif( $opts->{action} CORE::eq 'after' )
                {
                    $parent->children->splice( $pos + 1, 0, $clone );
                }
                $collection->children->push( $clone );
            });
        }
    }
    return( $collection );
}

# Takes html string (start with <tag...), text object (HTML::Object::DOM::Text), array or element object
# or alternatively a code reference that returns the above
sub _before_after
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "Nothing was provided to insert before or after." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !exists( $opts->{action} ) )
    {
        my @caller_info = caller(1);
        my $caller = [split( /::/, $caller_info[3])]->[-1];
        return( $self->error( "No action argument was provided and I am unable to guess it." ) ) if( $caller !~ /^(before|after)$/ );
        $opts->{action} = $caller;
    }
    return( $self->error( "Invalid value for argument \"action\": '$opts->{action}'" ) ) if( $opts->{action} !~ /^(before|after)$/ );
    my $a;
    if( !ref( $this ) )
    {
        my $p = $self->new_parser;
        $this = $p->parse_data( $this ) || return( $self->pass_error( $p->error ) );
        # $a = $self->new_array( [ $this ] );
        # $this is a HTML::Document; we take its children
        $a = $this->children;
    }
    elsif( $self->_is_array( $this ) )
    {
        # Make sure this is a Module::Generic::Array object
        $a = $self->new_array( $this );
    }
    elsif( $self->_is_object( $this ) )
    {
        return( $self->error( "Object provided '$this' (", overload::StrVal( $this ), ") is not an HTML::Object::DOM::Element object." ) ) if( !$this->isa( 'HTML::Object::DOM::Element' ) );
        $a = $self->new_array( [ $this ] );
    }
    elsif( ref( $this ) ne 'CODE' )
    {
        return( $self->error( "I do not know what to do with '$this'. I was expecing an html string, or an HTML::Object::DOM::Element or an array of element objects or a collection object (HTML::Object::Collection) or a code reference." ) );
    }
    
    if( $self->isa_collection )
    {
        my $failed = 0;
        # Going through each object in the collection
        $self->children->for(sub
        {
            my( $i, $e ) = @_;
            $e->reset(1);
            # will silently fail just like jQuery does
            my $parent = $e->parent;
            return( 1 ) if( !$parent );
            my $pos;
            if( $opts->{action} CORE::eq 'before' )
            {
                $pos = $parent->children->pos( $e );
            }
            elsif( $opts->{action} CORE::eq 'after' )
            {
                # $pos = $parent->children->pos( $e->close_tag ? $e->close_tag : $e );
                $pos = $parent->children->pos( $e );
            }
            $failed++, return( $self->error( "Element with tag \"", $e->tag, "\" has a parent, but I could not find it among its children elements." ) ) if( !defined( $pos ) );
            if( ref( $this ) CORE::eq 'CODE' )
            {
                local $_ = $e;
                my $res = $this->( $pos, $e->as_string );
                $failed++, return( $self->error( "An error occurred while executing code reference to $opts->{action} html element(s). Code reference returned undef." ) ) if( !defined( $res ) );
                if( $self->_is_object( $res ) && $res->isa( 'HTML::Object::DOM::Element' ) )
                {
                    $a = $self->new_array( [ $res ] );
                }
                elsif( overload::Overloaded( $res ) && overload::Method( $res, '""' ) )
                {
                    my $elem = $self->new_parser( "$res" );
                    $failed++, return if( !defined( $elem ) );
                    $a = $self->new_array( [ $elem ] );
                }
                else
                {
                    $failed++, return( $self->error( "Value returned from code reference to be used in $opts->{action}\(\) is neither a string nor a HTML::Object::DOM::Element, so I do not know what to do with it." ) );
                }
            }
            $a->foreach(sub
            {
                my $elem = $_->clone;
                $elem->parent( $e );
                if( $opts->{action} CORE::eq 'before' )
                {
                    $parent->children->splice( $pos, 0, $_ );
                }
                elsif( $opts->{action} CORE::eq 'after' )
                {
                    $parent->children->splice( $pos + 1, 0, $_ );
                }
                $pos++;
            });
        });
        return( $self->pass_error ) if( $failed );
    }
    else
    {
        # will silently fail just like jQuery does
        my $parent = $self->parent;
        return(1) if( !$parent );
        my $pos = $parent->children->pos( $self );
        return( $self->error( "Element with tag \"", $self->tag, "\" has a parent, but I could not find it among its children elements." ) ) if( !defined( $pos ) );
        if( ref( $this ) CORE::eq 'CODE' )
        {
            local $_ = $self;
            my $res = $this->( $pos, $self->as_string );
            return( $self->error( "An error occurred while executing code reference to $opts->{action} html element(s). Code reference returned undef." ) ) if( !defined( $res ) );
            if( $self->_is_object( $res ) && $res->isa( 'HTML::Object::DOM::Element' ) )
            {
                $a = $self->new_array( [ $res ] );
            }
            elsif( overload::Overloaded( $res ) && overload::Method( $res, '""' ) )
            {
                my $elem = $self->new_parser( "$res" );
                return if( !defined( $elem ) );
                $a = $self->new_array( [ $elem ] );
            }
            else
            {
                return( $self->error( "Value returned from code reference to be used in $opts->{action}\(\) is neither a string nor a HTML::Object::DOM::Element, so I do not know what to do with it." ) );
            }
        }
        $a->foreach(sub
        {
            $_->detach();
            $_->parent( $self );
            $_->reset(1);
            if( $opts->{action} CORE::eq 'before' )
            {
                $parent->children->splice( $pos, 0, $_ );
            }
            elsif( $opts->{action} CORE::eq 'after' )
            {
                $parent->children->splice( $pos + 1, 0, $_ );
            }
        });
    }
    return( $self );
}

sub _same_as
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return(0) if( !defined( $this ) || !$self->_is_object( $this ) || !$this->isa( 'HTML::Object::DOM::Element' ) );
    if( $this->isa_collection )
    {
        # We are not a collection, but the other is
        if( !$self->isa_collection )
        {
            return(0);
        }
        # https://css-tricks.com/snippets/jquery/compare-jquery-objects/
        elsif( $self->length == $this->length &&
            $self->length == $self->filter( $this )->length )
        {
            return(1);
        }
        else
        {
            return(0);
        }
    }
    else
    {
        return(0) if( $self->tag CORE::ne $this->tag );
        return( $self->eid CORE::eq $this->eid ? 1: 0 );
    }
}

# If argument is provided, pass a CSS::Object::Builder::Rule object
# If no argument is provided, get a CSS::Object::Builder::Rule of the inline css, if any at all.
# Returns undef if no css attribute is set yet.
sub _css_object
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $rule = shift( @_ );
        my $css  = $rule->css;
        my $style = $rule->as_string;
        $self->css_cache_store( $style, $css );
        $self->attributes->set( css => $style );
        return( $rule );
    }
    else
    {
        my $style = $self->attributes->get( 'css' );
        return if( !defined( $style ) );
        my $css = CSS::Object->new( format => 'CSS::Object::Format::Inline', debug => $self->debug );
        my $cached = $self->css_cache_check( $style );
        if( $cached )
        {
            $css = $cached;
        }
        else
        {
            ## 'inline' here is just a fake selector to serve as a container rule for the inline properties, 
            ## because CSS::Object requires properties to be within a rule
            $css->read_string( 'inline {' . $style . ' }' ) ||
            return( $self->error( "Unable to parse existing style for tag name \"", $self->prop( 'tagName' ), "\":", $css->error ) );
        }
        my $main = $css->rules->first;
        my $rule = defined( $main ) ? $css->builder->select( $main ) : $css->builder->select( 'inline' );
        return( $rule );
    }
}

sub _css_builder
{
    my $self = shift( @_ );
    my $css = CSS::Object->new( format => 'CSS::Object::Format::Inline', debug => $self->debug );
    return( $css->builder->select( 'inline' ) );
}

# Takes selector, html, element or array
# xq( '<p>Test</p>' )->insertBefore( xq( '.inner', $doc ) );
# $elem->insertBefore( '.inner' );
sub _insert_before_after
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "No target was provided to insert element." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !exists( $opts->{action} ) )
    {
        my @caller_info = caller(1);
        my $caller = [split( /::/, $caller_info[3])]->[-1];
        return( $self->error( "No action argument was provided and I am unable to guess it." ) ) if( $caller !~ /^(?:insert|insert_)(?:Before|After)$/i );
        $opts->{action} = lc( ( $caller =~ /^(?:insert|insert_)(?:Before|After)$/i )[0] );
    }
    return( $self->error( "Invalid value for argument \"action\": '$opts->{action}'" ) ) if( $opts->{action} !~ /^(?:before|after)$/ );
    my $a;
    if( !ref( $this ) )
    {
        if( $self->_is_html( $this ) )
        {
            my $p = $self->new_parser;
            $this = $p->parse_data( $this ) || return( $self->pass_error( $p->error ) );
            $a = $self->new_array( [ $this ] );
        }
        # otherwise this has to be a selector
        # TODO: Need to correct this and adjust the object used as a base for the find
        # since $self could very well be a dynamically created dom object
        else
        {
            $this = $self->find( $this ) || return;
            $a = $self->new_array( [ $this ] );
        }
    }
    elsif( $self->_is_array( $this ) )
    {
        # Make sure this is a Module::Generic::Array object
        $a = $self->new_array( $this );
    }
    elsif( $self->_is_object( $this ) )
    {
        return( $self->error( "Object provided '$this' (", overload::StrVal( $this ), ") is not an HTML::Object::DOM::Element object." ) ) if( !$this->isa( 'HTML::Object::DOM::Element' ) );
        $a = $self->new_array( [ $this ] );
    }
    else
    {
        return( $self->error( "I do not know what to do with \"$this\". I was expecting a selector, html data, an element object or an array." ) );
    }
    
    # If the content to be inserted is a collection, we loop through it, duplicate each element and insert them
    if( $self->isa_collection )
    {
        $a->foreach(sub
        {
            my $elem = $_;
            my $parent = $elem->parent;
            return(1) if( !$parent );
            $elem->reset(1);
            my $pos = $parent->children->pos( $elem );
            warn( "Found a parent for tag \"", $elem->tag, "\", but somehow I could not find its position among its children elements.\n" ) if( !defined( $pos ) );
            return( 1 ) if( !defined( $pos ) );
            $self->children->foreach(sub
            {
                my $e = shift( @_ );
                # Making sure the content element is detached from its original parent
                my $clone = $e->detach->clone;
                $clone->parent( $elem );
                if( $opts->{action} CORE::eq 'before' )
                {
                    $parent->children->splice( $pos, 0, $clone );
                }
                elsif( $opts->{action} CORE::eq 'after' )
                {
                    $parent->children->splice( $pos + 1, 0, $clone );
                }
            });
        });
    }
    else
    {
        # If the target is just one element, we do not duplicate them, but simply move them
        if( $a->length == 1 )
        {
            my $elem = $a->first;
            my $parent = $elem->parent;
            return(1) if( !$parent );
            $elem->reset(1);
            my $pos = $parent->children->pos( $elem );
            return( $self->error( "Found a parent for tag \"", $elem->tag, "\", but somehow I could not find its position among its children elements." ) ) if( !defined( $pos ) );
            $self->detach;
            $self->parent( $elem );
            if( $opts->{action} CORE::eq 'before' )
            {
                $parent->children->splice( $pos, 0, $self );
            }
            elsif( $opts->{action} CORE::eq 'after' )
            {
                $parent->children->splice( $pos + 1, 0, $self );
            }
        }
        # However, if the target contain multiple element, we clone the content element
        else
        {
            $a->foreach(sub
            {
                my $elem = $_;
                my $parent = $elem->parent;
                return(1) if( !$parent );
                $elem->reset(1);
                my $pos = $parent->children->pos( $elem );
                warn( "Found a parent for tag \"", $elem->tag, "\", but somehow I could not find its position among its children elements.\n" ) if( !defined( $pos ) );
                return(1) if( !defined( $pos ) );
                my $clone = $self->detach->clone;
                $clone->parent( $elem );
                if( $opts->{action} CORE::eq 'before' )
                {
                    $parent->children->splice( $pos, 0, $clone );
                }
                elsif( $opts->{action} CORE::eq 'after' )
                {
                    $parent->children->splice( $pos + 1, 0, $clone );
                }
            });
        }
    }
    return( $self );
}

sub _is_html { return( $_[1] =~ /^[[:blank:]\h]*<\w+/ ? 1 : 0 ); }

sub _is_same_node { shift( @_ ); return( shift->eid CORE::eq shift->eid ); }

sub _xpath_value { shift( @_ ); return( ref( $_[0] ) ? ${$_[0]} : HTML::Selector::XPath::selector_to_xpath( $_[0] ) ); }

1;
# NOTE: POD
__END__
