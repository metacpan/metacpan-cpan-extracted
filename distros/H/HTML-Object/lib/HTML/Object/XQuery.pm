##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/XQuery.pm
## Version v0.4.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/05/01
## Modified 2024/04/27
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
    our $VERSION = 'v0.4.0';
};

use strict;
use warnings;

{
    no warnings 'once';
    *xq = \&HTML::Object::DOM::Element::xq;
}

# NOTE: DateTimeFormat class
# package
#     DateTimeFormat;
# BEGIN
# {
#     use strict;
#     use warnings;
#     use parent qw( HTML::Object::DateTime::Format );
# };
# 
# use strict;
# use warnings;

# NOTE: xQuery class
package xQuery;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
};
use strict;
use warnings;

{
    no warnings 'once';
    # NOTE: clearQueue
    *clearQueue = \&HTML::Object::DOM::Element::clearQueue;
    # NOTE: contains
    *contains = \&HTML::Object::DOM::Element::contains;
}

sub data
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error( "No element was provided to set/get data on it." ) );
    return( $self->error( "Element value provided is not an HTML::Object::DOM::Element" ) ) if( !$self->_is_a( $elem => 'HTML::Object::DOM::Element' ) );
    my $rv = $elem->data( @_ );
    return( $self->pass_error( $elem->error ) ) if( !defined( $rv ) && $elem->error );
    return( $rv );
}

{
    no warnings 'once';
    # NOTE: dequeue
    *dequeue = \&HTML::Object::DOM::Element::dequeue;
}

sub each
{
    my $self = shift( @_ );
    my( $data, $cb ) = @_;
    my $obj;
    if( $self->_is_array( $data ) )
    {
        $obj = $self->new_array( $data );
    }
    elsif( $self->_is_hash( $data ) )
    {
        $obj = $self->new_hash( $data );
    }
    else
    {
        return( $self->error( "Unsupported data type (", overload::StrVal( $data // 'undef' ), ")" ) );
    }
    return( $self->error( "Callback value provided is not a code reference." ) ) if( !$self->_is_code( $cb ) );
    return( $obj->each($cb) );
}

sub extend
{
    my $self = shift( @_ );
    my $deep = 0;
    if( scalar( @_ ) && !$self->_is_hash( $_[0] ) )
    {
        my $bool = shift( @_ );
        $deep = $bool ? 1 : 0;
    }
    # Clean up the arguments
    my @args = ();
    for( my $i = 0; $i < scalar( @_ ); $i++ )
    {
        if( $self->_is_hash( $_[$i] ) )
        {
            push( @args, $_[$i] );
        }
    }
    return( {} ) if( !scalar( @args ) );
    return( { map( %$_, @args ) } ) unless( $deep );
    # Credits: Hash::Merge::Simple
    my $merge;
    $merge = sub
    {
        my( $left, @right ) = @_;
        return( $left ) unless( @right );
        return( $merge->( $left, $merge->( @right ) ) ) if( @right > 1 );
        my( $right ) = @right;
        my $merged = { %$left };
        foreach my $key ( keys( %$right ) )
        {
            my( $hr, $hl ) = map{ ref( $_->{ $key } ) eq 'HASH' } $right, $left;
            # Both hash have the same key pointing to an hash
            if( $hr and $hl )
            {
                $merged->{ $key } = $merge->( $left->{ $key }, $right->{ $key } );
            }
            else
            {
                $merged->{ $key } = $right->{ $key };
            }
        }
        return( $merged );
    };
    return( $merge->( @args ) );
}

sub grep
{
    my $self = shift( @_ );
    my( $ref, $cb, $invert ) = @_;
    return( $self->error( "Value provided is not an array reference." ) ) if( !$self->_is_array( $ref ) );
    return( $self->error( "Callback value provided is not a code reference." ) ) if( !$self->_is_code( $cb ) );
    $invert //= 0;
    $ref = $self->new_array( $ref );
    return( $ref->grep( $cb, $invert ) );
}

sub inArray
{
    my $self = shift( @_ );
    my( $val, $array, $fromIndex ) = @_;
    return( $self->error( "Array value provided is not an array." ) ) if( !$self->_is_array( $array ) );
    return( $self->error( "fromIndex value provided is not an integer." ) ) if( defined( $fromIndex ) && !$self->_is_integer( $fromIndex ) );
    $fromIndex //= 0;
    my $isRe = ( ref( $val ) eq 'Regexp' ? 1 : 0 );
    for( my $i = 0; $i < scalar( @$array ); $i++ )
    {
        next unless( $i >= $fromIndex );
        if( $isRe )
        {
            return( $i ) if( $array->[$i] =~ /$val/ );
        }
        else
        {
            return( $i ) if( $array->[$i] eq $val );
        }
    }
    return(-1);
}

sub isArray { return( shift->_is_array( @_ ) ); }

sub isEmptyObject
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return(0) if( !$self->_is_hash( $this, 'strict' ) );
    return( scalar( keys( %$this ) ) ? 0 : 1 );
}

sub isFunction
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return(0) if( $self->_is_empty( $this ) );
    return(1) if( $self->_is_code( $this ) );
    my $pkg = caller;
    if( $self->_has_symbol( $pkg => "\&${this}" ) &&
        defined( &{"${pkg}\::${this}"} ) )
    {
        return(1);
    }
    return(0);
}

sub isNumeric { return( shift->_is_number( @_ ) ); }

sub isPlainObject { return( shift->_is_hash( shift( @_ ), 'strict' ) ); }

sub isWindow { return( shift->_is_a( shift( @_ ) => 'HTML::Object::DOM::Window' ) ); }

sub makeArray
{
    my $self = shift( @_ );
    my $ref = shift( @_ );
    if( $self->_is_a( $ref => 'HTML::Object::Collection' ) )
    {
        $ref = $ref->children;
    }
    return( $self->error( "Value provided is not an array reference or an array object." ) ) if( !$self->_is_array( $ref ) );
    my $new = [];
    @$new = @$ref;
    return( $new );
}

sub map
{
    my $self = shift( @_ );
    my $ref  = shift( @_ ) || return( $self->error( "No data was provided." ) );
    my $code = shift( @_ ) || return( $self->error( "No code reference was provided." ) );
    return( $self->error( "I was expecting a code reference, but instead I was provided with this: \"", overload::StrVal( $code ), "\"." ) ) if( ref( $code ) ne 'CODE' );
    my $type;
    if( $self->_is_array( $ref ) )
    {
        $type = 'array';
    }
    elsif( $self->_is_hash( $ref => 'strict' ) )
    {
        $type = 'hash';
    }
    my $new = $self->new_array;
    local $@;
    if( defined( $type ) )
    {
        my $each = sub
        {
            if( $type eq 'hash' )
            {
                return( CORE::each( %$ref ) );
            }
            else
            {
                return( CORE::each( @$ref ) );
            }
        };

        # We use a callback, because perl does not accept: each( $type eq 'array' ? @$ref : %$ref )
        while( my( $key, $value ) = $each->() )
        {
            # try-catch
            my @rv = eval
            {
                $code->( $value, $key );
            };
            if( $@ )
            {
                warn( "An error occured while executing callback for key ${key}: $@" ) if( $self->_is_warnings_enabled( 'HTML::Object' ) );
                next;
            }
            # User returned an empty array or undef
            if( !scalar( @rv ) || ( scalar( @rv ) == 1 && !defined( $rv[0] ) ) )
            {
                next;
            }
            if( scalar( @rv ) == 1 )
            {
                # User returned an array reference, such as:
                # my @rv = $.map( $array, sub{ return( [1, 2, 3] ) } );
                if( $self->_is_array( $rv[0] ) )
                {
                    $new->push( @{$rv[0]} );
                }
                else
                {
                    # warn( "Warning only: value returned from the \$.map callback for key ${key} did not return either undef or an array reference: ", join( ', ', map( overload::StrVal( $_ // 'undef' ), @rv ) ) ) if( $self->_is_warnings_enabled( 'HTML::Object' ) );
                    $new->push( $rv[0] );
                }
            }
            # User returned an array of more than 1 item, such as:
            # my @rv = $.map( $array, sub{ return( 1, 2, 3 ) } );
            else
            {
                $new->push( @rv );
            }
        }
        return( $new );
    }
    else
    {
        return( $self->error( "The data provided is neither an array reference, an array object or an hash reference." ) );
    }
}

sub merge
{
    my $self = shift( @_ );
    my( $first, $second ) = @_;
    return( $self->error( "First value provided is not an array reference." ) ) if( !$self->_is_array( $first ) );
    return( $self->error( "Second value provided is not an array reference." ) ) if( !$self->_is_array( $second ) );
    CORE::push( @$first, @$second );
    return( $first );
}

sub noop { return }

sub now
{
    my $self = shift( @_ );
    $self->_load_class( 'DateTime' ) || return( $self->pass_error );
    $self->_load_class( 'DateTime::Format::Strptime' ) || return( $self->pass_error );
    my $fmt = DateTime::Format::Strptime->new(
        pattern => '%s',
    );
    my $dt = DateTime->now(
        formatter => $fmt,
    );
    return( $dt );
}

sub parseHTML
{
    my( $self, $str ) = @_;
    my $res = $self->new_array;
    return( $res ) if( $self->_is_empty( $str ) );
    my $parser = HTML::Object::DOM->new( debug => $self->debug );
    my $doc = $parser->parse_data( "$str" ) ||
        return( $self->pass_error( $parser->error ) );
    $res->push( $doc->children->list );
    return( $res );
}

sub parseJSON
{
    my( $self, $str ) = @_;
    return( $self->error( "No JSON data was provided to parse" ) ) if( $self->_is_empty( $str ) );
    my $j = $self->new_json( allow_tags => 0 );
    # try-catch
    local $@;
    my $rv = eval
    {
        return( $j->decode( "$str" ) );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while parsing ", CORE::length( "$str" ), " bytes of JSON data: $@" ) );
    }
    return( $rv );
}

sub parseXML
{
    my( $self, $str ) = @_;
    return( $self->error( "No XML data was provided to parse" ) ) if( $self->_is_empty( $str ) );
    if( !$self->_load_class( 'XML::LibXML' ) )
    {
        return( $self->pass_error );
    }
    # try-catch
    local $@;
    my $doc = eval
    {
        XML::LibXML->load_xml( string => $str );
    };
    if( $@ )
    {
        return( $self->error( "Error while parsing XML data with XML::LibXML: $@" ) );
    }
    return( $doc );
}

# NOTE: $.proxy() is deprecated
# <https://api.jquery.com/jQuery.proxy/>

# NOTE: $.queue() is unsupported as it has no meaning under perl
# <https://api.jquery.com/jQuery.queue/>

sub removeData
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error( "No element was provided." ) );
    return( $self->error( "Element object provided is not an HTML::Object::DOM::Element" ) ) if( !$self->_is_a( $elem => 'HTML::Object::DOM::Element' ) );
    $elem->removeData( scalar( @_ ) ? @_ : () );
    return( $self->pass_error( $elem->error ) ) if( $elem->error );
    return;
}

# NOTE: support() is not supported
# <https://api.jquery.com/jQuery.support/>

sub trim
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $this ) if( $self->_is_empty( $this ) );
    if( ref( $this ) &&
        !$self->_can_overload( $this => '""' ) )
    {
        return( $self->error( "Value provided is not a string nor a stringifyable object." ) );
    }
    my $str = "$this";
    $str =~ s/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$//gs;
    return( $str );
}

sub type
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    if( !defined( $this ) )
    {
        return( 'undef' );
    }
    elsif( $self->_is_hash( $this => 'strict' ) )
    {
        return( 'hash' );
    }
    elsif( $self->_is_array( $this ) )
    {
        return( 'array' );
    }
    elsif( $self->_is_a( $this => [qw( DateTime Module::Generic::DateTime )] ) )
    {
        return( 'date' );
    }
    elsif( $self->_is_a( $this => [qw( Module::Generic::Boolean JSON::PP::Boolean )] ) )
    {
        return( 'boolean' );
    }
    elsif( $self->_is_a( $this => 'Regexp' ) )
    {
        return( 'regexp' );
    }
    elsif( $self->_is_a( $this => [qw( Module::Generic::Exception Error Throwable::Error )] ) )
    {
        return( 'error' );
    }
    elsif( $self->_is_number( $this ) )
    {
        return( 'number' );
    }
    else
    {
        return( 'string' );
    }
}

sub unique
{
    my $self = shift( @_ );
    my $arr  = shift( @_ ) || return( $self->error( "No array was provided to make unique." ) );
    return( $self->error( "Value provided is not an array reference or an array object." ) ) if( !$self->_is_array( $arr ) );
    my $res = $self->new_array( $arr )->unique;
    return( $res );
}

sub uniqueSort
{
    my $self = shift( @_ );
    my $new = $self->unique( @_ ) || return( $self->pass_error );
    return( $new ) if( $new->is_empty );
    my $root = $new->first->getRootNode;
    # <https://stackoverflow.com/questions/63575333/javascript-replacement-of-sourceindex-in-chromium-browsers>
    # <https://developer.mozilla.org/en-US/docs/Web/API/Document/all>
    # <https://johnresig.com/blog/comparing-document-position/#postcomment>
    # Compare Position - MIT Licensed, John Resig
    # function comparePosition(a, b)
    # {
    #     return a.compareDocumentPosition
    #         ? a.compareDocumentPosition(b)
    #         : a.contains
    #             ? ( a != b && a.contains(b) && 16 ) + 
    #               ( a != b && b.contains(a) && 8 ) + 
    #               ( a.sourceIndex >= 0 && b.sourceIndex >= 0
    #                   ? ( a.sourceIndex < b.sourceIndex && 4 ) + ( a.sourceIndex > b.sourceIndex && 2 )
    #                   : 1
    #               ) + 0
    #             : 0;
    # }
    my $all = $root->querySelectorAll('*');
    for( my $i = 0; $i < scalar( @$all ); $i++ )
    {
        my $e = $all->[$i];
        $e->sourceIndex( $i );
    }
    $new = $new->sort(sub
    {
        my( $a, $b ) = @_;
        return(
            $a->can( 'compareDocumentPosition' )
                ? $a->compareDocumentPosition( $b )
                : $a->can( 'contains' )
                    ? ( $a !=$ b && $a->contains($b) && 16 ) + 
                      ( $a != $b && $b->contains($a) && 8 ) + 
                      ( ( $a->sourceIndex // -1 ) >= 0 && ( $b->sourceIndex // -1 ) >= 0
                          ? ( $a->sourceIndex < $b->sourceIndex && 4 ) + ( $a->sourceIndex > $b->sourceIndex && 2 )
                          : 1
                      ) + 0
                    : 0
        );
    });
    return( $new );
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
    our $LOOK_LIKE_HTML = qr/^[[:blank:]\h\v]*\<\w+.*?\>/;
};

use strict;
use warnings;
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

# To make it look like really like jQuery
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

sub ajax
{
    my $self = shift( @_ );
    my $url = shift( @_ ) ||
        return( $self->error( "No URL was provided." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{async} //= 1;
    $opts->{cache} = 0;
    $opts->{processData} //= 1;
    $opts->{debug} //= 0;
    $self->_load_class( 'HTTP::Promise', { version => 'v0.5.0' } ) ||
        return( $self->pass_error );
    $self->_load_class( 'HTTP::Promise::Request' ) ||
        return( $self->pass_error );
    $self->_load_class( 'URI', { version => '5.21' } ) ||
        return( $self->pass_error );
    if( !$self->_is_empty( $opts->{url} ) )
    {
        $url = $opts->{url};
    }
    my $uri = URI->new( "$url" );
    # Contextual URL that requires a base URL.
    # We check for documentURI of the root element, if any
    my( $doc_root, $doc_uri );
    if( ( substr( $url, 0, 1 ) eq '/' ||
          substr( $url, 0, 2 ) eq './' ||
          substr( $url, 0, 3 ) eq '../' ) &&
        ( $doc_root = $self->getRootNode ) &&
        $doc_root->isa( 'HTML::Object::DOM::Document' ) &&
        ( $doc_uri = $doc_root->documentURI ) )
    {
        $uri = $doc_uri->clone;
        $uri->path( $url );
    }
    # !contents
    # !context
    # converters
    # !crossDomain
    # NOTE dataType
    my $dataType;
    $dataType = $opts->{dataType} if( !$self->_is_empty( $opts->{dataType} ) );
    # NOTE error
    my $error;
    if( $self->_is_code( $opts->{error} ) )
    {
        $error = [$opts->{error}];
    }
    elsif( $self->_is_array( $opts->{error} ) )
    {
        for( my $i = 0; $i < scalar( @{$opts->{error}} ); $i++ )
        {
            my $this = $opts->{error}->[$i];
            if( !$self->_is_code( $opts->{error}->[$i] ) )
            {
                return( $self->error( "Value provided at offset $i with the 'error' argument to ajax method, is not a code reference." ) );
            }
        }
        $error = $opts->{error};
    }
    # NOTE headers
    my $headers = ( ( exists( $opts->{headers} ) && ref( $opts->{headers} // '' ) eq 'HASH' ) ? $opts->{headers} : {} );
    unless( exists( $headers->{X_Requested_With} ) || exists( $headers->{ 'X-Requested-With' } ) )
    {
        $headers->{X_Requested_With} = 'XMLHttpRequest';
    }
    # !global
    # !isLocal
    # !jsonp
    # !jsonpCallback
    my $params =
    {
        use_promise => ( $opts->{async} ? 1 : 0 ),
        # NOTE timeout
        ( $self->_is_integer( $opts->{timeout} ) ? ( timeout => $opts->{timeout} ) : () ),
        ( ( $self->_is_integer( $opts->{debug} ) && $opts->{debug} ) ? ( debug => $opts->{debug} ) : () ),
    };
    # NOTE accepts
    if( !$self->_is_empty( $opts->{accepts} ) )
    {
        $headers->{accept} = $opts->{accepts};
    }
    elsif( !$self->_is_empty( $opts->{accept} ) )
    {
        $headers->{accept} = $opts->{accept};
    }
    # NOTE contentType
    if( !$self->_is_empty( $opts->{contentType} ) )
    {
        $headers->{Content_Type} = $opts->{contentType};
    }
    # NOTE ifModified
    if( exists( $opts->{ifModified} ) &&
        ref( $opts->{ifModified} ) eq 'HASH' )
    {
        my $ifmod = $opts->{ifModified};
        if( exists( $ifmod->{since} ) &&
            defined( $ifmod->{since} ) &&
            CORE::length( $ifmod->{since} ) )
        {
            my $dt;
            if( $ifmod->{since} =~ /^\d{10}$/ )
            {
                # try-catch
                local $@;
                $dt = eval
                {
                    DateTime->from_epoch( epoch => $ifmod->{since} );
                };
                if( $@ )
                {
                    return( $self->error( "Error with the timestamp provided for the option ifModified: $@" ) );
                }
            }
            elsif( $self->_is_a( $ifmod->{since} => [qw( DateTime Module::Generic::DateTime )] ) )
            {
                $dt = $ifmod->{since};
            }
            else
            {
                return( $self->error( "Unsupported value provided to option ifModified->since: '", ( $ifmod->{since} // 'undef' ), "'" ) );
            }

            $self->_load_class( 'DateTime::Format::Strptime' ) ||
                return( $self->pass_error );
            $dt->set_time_zone( 'GMT' );
            my $fmt = DateTime::Format::Strptime->new(
                pattern => '%a, %d %b %Y %H:%M:%S GMT',
                locale  => 'en_GB',
                time_zone => 'GMT',
            );
            $dt->set_formatter( $fmt );
            $headers->{If_Modified_Since} = $dt;
        }
        if( exists( $ifmod->{etag} ) &&
            defined( $ifmod->{etag} ) &&
            CORE::length( $ifmod->{etag} ) )
        {
            if( $ifmod->{etag} =~ /^[\w\-]+$/ )
            {
                $headers->{If_None_Match} = '"' . $ifmod->{etag} . '"';
            }
            # Useless to use the weak prefix since If-None-Match only uses the weak algorithm
            elsif( $ifmod->{etag} =~ m,W/"^[\w\-]+"$, )
            {
                $headers->{If_None_Match} = $ifmod->{etag};
            }
            else
            {
                return( $self->error( "The etag provided for the option ifModified->etag contains illegal characters." ) );
            }
        }
    }
    # !isLocal
    # !jsonp
    # NOTE method, type
    my $method = 'get';
    $opts->{method} = $opts->{type} if( !$self->_is_empty( $opts->{method} ) && !$self->_is_empty( $opts->{type} ) );
    if( exists( $opts->{method} ) &&
        defined( $opts->{method} ) &&
        CORE::length( $opts->{method} // '' ) )
    {
        if( $opts->{method} =~ /^(get|head|options|patch|post|put)$/i )
        {
            $method = lc( $1 );
        }
        else
        {
            return( $self->error( "Unsupported HTTP method '$opts->{method}'" ) );
        }
    }
    # NOTE data, processData
    my $data;
    if( $opts->{data} )
    {
        if( $opts->{processData} )
        {
            $headers->{Content} = $data;
        }
        else
        {
            $headers->{Content} = "$data";
        }
    }
    else
    {
    }

    # NOTE mimeType
    if( !$self->_is_empty( $opts->{mimeType} ) )
    {
        $headers->{Content_Type} = $opts->{mimeType};
    }
    # !scriptAttrs
    # !scriptCharset
    # NOTE statusCode
    my $statusCode;
    if( exists( $opts->{statusCode} ) &&
        defined( $opts->{statusCode} ) &&
        ref( $opts->{statusCode} // '' ) eq 'HASH' )
    {
        foreach my $c ( sort( keys( %{$opts->{statusCode}} ) ) )
        {
            if( !defined( $c ) || !CORE::length( "$c" // '' ) )
            {
                return( $self->error( "The code value provided in the option statusCode is empty!" ) );
            }
            elsif( "$c" !~ /^\d{3}$/ )
            {
                return( $self->error( "The code value provided (${c}) is invalid. It should be a 3 digits code, such as 200" ) );
            }

            my $code_ref = $opts->{statusCode}->{ $c };
            if( !$self->_is_code( $code_ref ) )
            {
                return( $self->error( "The value provided for status code '${c}' is not a code reference." ) );
            }
        }
        $statusCode = $opts->{statusCode};
    }
    # NOTE success
    my $success;
    if( exists( $opts->{success} ) )
    {
        if( $self->_is_code( $opts->{success} ) )
        {
            $success = $opts->{success};
        }
        else
        {
            return( $self->error( "The success callback provided is not a code reference." ) );
        }
    }
    # !traditional

    my $http = HTTP::Promise->new( %$params ) ||
        return( $self->pass_error( HTTP::Promise->error ) );
    my $req = $http->prepare( $method => $uri, %$headers ) ||
        return( $self->pass_error( $http->error ) );
    if( exists( $opts->{xhr} ) && defined( $opts->{xhr} ) )
    {
        if( $self->_is_code( $opts->{xhr} ) )
        {
            my $code_ref = $opts->{xhr};
            # try-catch
            local $@;
            my $this = eval
            {
                $code_ref->( $req );
            };
            if( $@ )
            {
                return( $self->error( "An error occurred while calling the callback code reference for xhr: $@" ) ) if( $self->_is_warnings_enabled( 'HTML::Object' ) );
            }
            if( $self->_is_a( $this => 'HTTP::Promise::Request' ) )
            {
                $req = $this;
            }
            else
            {
                return( $self->error( "The value returned by the callback (", overload::StrVal( $this // '' ), ") is not an HTTP::Promise::Request object." ) );
            }
        }
        else
        {
            return( $self->error( "The value provided for the xhr callback is not a code reference." ) );
        }
    }

    # NOTE password & username
    if( !$self->_is_empty( $opts->{password} ) ||
        !$self->_is_empty( $opts->{username} ) )
    {
        $req->headers->authorization_basic( ( $opts->{username} // '' ), ( $opts->{password} // '' ) );
    }
    # NOTE beforeSend
    my $beforeSend = ( $self->_is_code( $opts->{beforeSend} ) ? $opts->{beforeSend} : sub{ $_[0] } );
    my $complete;
    if( $self->_is_code( $opts->{complete} ) )
    {
        $complete = [$opts->{complete}];
    }
    elsif( $self->_is_array( $opts->{complete} ) )
    {
        for( my $i = 0; $i < scalar( @{$opts->{complete}} ); $i++ )
        {
            my $this = $opts->{complete}->[$i];
            if( !$self->_is_code( $opts->{complete}->[$i] ) )
            {
                return( $self->error( "Value provided at offset $i with the 'complete' argument to ajax method, is not a code reference." ) );
            }
        }
        $complete = $opts->{complete};
    }
    
    # NOTE dataFilter
    my $dataFilter = ( $self->_is_code( $opts->{dataFilter} ) ? $opts->{dataFilter} : sub{ $_[0] } );
    my $code2status = sub
    {
        my $resp = shift( @_ );
        my $code = $resp->code;
        if( $code == 200 )
        {
            return( 'success' );
        }
        elsif( $code == 204 )
        {
            return( 'nocontent' );
        }
        elsif( $code == 304 )
        {
            return( 'notmodified' );
        }
        elsif( $code == 408 )
        {
            return( 'timeout' );
        }
        elsif( $code >= 400 && $code <= 599 )
        {
            return( 'error' );
        }
        else
        {
            return( 'success' );
        }
    };

    my $process = sub
    {
        my $resp = shift( @_ );
        my( $resolve, $reject ) = @_;
        my $status = $code2status->( $resp );
        my $code = $resp->code;
        # TODO: converters
        my $content = $resp->decoded_content;
        $content = $dataFilter->( $content );
        my $decoded;
        unless( defined( $dataType ) )
        {
            my $type = $resp->headers->type;
            if( defined( $type ) )
            {
                if( $type =~ m,^application/json,i )
                {
                    $dataType = 'json';
                }
                elsif( $type =~ m,^text/html,i )
                {
                    $dataType = 'html';
                }
                elsif( $type =~ m,^text/xml,i )
                {
                    $dataType = 'xml';
                }
                elsif( $type =~ m,^text/plain,i )
                {
                    $dataType = 'text';
                }
                else
                {
                    $dataType = 'application/octet-stream';
                }
            }
        }

        if( defined( $dataType ) )
        {
            if( ( $dataType eq 'json' ||
                  $dataType eq 'jsonp' ) &&
                defined( $content ) )
            {
                my $j = $self->new_json->relaxed->utf8;
                # try-catch
                local $@;
                $decoded = eval
                {
                    $j->decode( "$content" );
                };
                if( $@ )
                {
                    $self->error( "Error decoding ", CORE::length( $content ), " bytes of JSON data: $@" );
                    if( defined( $reject ) )
                    {
                        return({ error => $self->error });
                    }
                    else
                    {
                        return( $self->pass_error );
                    }
                }
                else
                {
                    # $resolve->( $decoded );
                    $content = $decoded;
                }
            }
        }
        else
        {
            # Hmm, dataType is still undefined
        }

        if( defined( $statusCode ) )
        {
            my $code_ref = $statusCode->{ $code };
            # try-catch
            local $@;
            eval
            {
                $code_ref->( $content, $status, $resp, $http );
            };
            if( $@ )
            {
                warn( "Error calling statusCode callback for code '${code}': $@" ) if( $self->_is_warnings_enabled( 'HTML::Object' ) );
            }
        }

        if( defined( $complete ) )
        {
            foreach my $coderef ( @$complete )
            {
                $coderef->( $resp, $status, $http );
            }
        }

        if( defined( $success ) )
        {
            # try-catch
            local $@;
            eval
            {
                $success->( $content, $status, $resp, $http );
            };
            if( $@ )
            {
                warn( "Error calling success callback: $@" ) if( $self->_is_warnings_enabled( 'HTML::Object' ) );
            }
        }
        if( defined( $error ) && ( $code >= 400 && $code < 600 ) )
        {
            my $status = $resp->status;
            for( my $i = 0; $i < scalar( @$error ); $i++ )
            {
                my $code_ref = $error->[$i];
                # try-catch
                local $@;
                eval
                {
                    # No exception object, because this is just a regular HTTP error
                    $code_ref->( $req, $status );
                };
                if( $@ )
                {
                    warn( "An error occurred while calling the error callback at offset $i: $@" ) if( $self->_is_warnings_enabled( 'HTML::Object' ) );
                }
            }
        }
        return({
            content => $content,
            status  => $status,
            resp    => $resp,
            http    => $http,
        });
    };

    if( $params->{use_promise} )
    {
        my $p;
        $p = Promise::Me->new(sub
        {
            my( $resolve_main, $reject_main ) = @$_;
            # NOTE: Process beforeSend for asynchronous process
            my $this = $beforeSend->( $req );
            if( !defined( $this ) || !CORE::length( $this // '' ) )
            {
                return( $resolve_main->( '', 'abort', undef, $http ) );
            }
            elsif( !$self->_is_a( $this => 'HTTP::Promise::Request' ) )
            {
                $self->error( "Value returned by the beforeSend callback is not an HTTP::Promise::Request object." );
                my $err = $self->error;
                return( $reject_main->( $err ) );
            }
            $req = $this;
            my $prom = $http->request( $req, 
                ( defined( $opts->{promise_debug} ) ? ( promise_debug => $opts->{promise_debug} ) : () ),
            )->then(sub
            {
                my( $resolve, $reject ) = @$_;
                my $resp = shift( @_ );
                if( !$resp )
                {
                    return( $reject_main->( $http->error ) );
                }
                my $res = $process->( $resp, $resolve_main, $reject_main );
                if( $res->{error} )
                {
                    return( $reject_main->( $res->{error} ) );
                }
                return( $resolve_main->( @$res{qw( content status resp http )} ) );
            })->catch(sub
            {
                my $err = shift( @_ );
                if( defined( $error ) )
                {
                    my $status = 'error';
                    for( my $i = 0; $i < scalar( @$error ); $i++ )
                    {
                        my $code_ref = $error->[$i];
                        # try-catch
                        local $@;
                        eval
                        {
                            $code_ref->( $req, $status, $err );
                        };
                        if( $@ )
                        {
                            warn( "An error occurred while calling the error callback at offset $i: $@" ) if( $self->_is_warnings_enabled( 'HTML::Object' ) );
                        }
                    }
                }
                return( $reject_main->( $err ) );
            });
            return( $reject_main->( $http->error ) ) if( !$prom );
            # return(1);
            return( $prom );
        },
        {
            ( defined( $opts->{promise_debug} ) ? ( debug => $opts->{promise_debug} ) : () ),
        });
        return( $p );
    }
    # No promise
    else
    {
        # NOTE: Process beforeSend for synchronous process
        my $this = $beforeSend->( $req );
        if( !defined( $this ) || !CORE::length( $this // '' ) )
        {
            return( '', 'abort', undef, $http );
        }
        elsif( !$self->_is_a( $this => 'HTTP::Promise::Request' ) )
        {
            return( $self->error( "Value returned by the beforeSend callback is not an HTTP::Promise::Request object." ) );
        }
        $req = $this;
        my $resp = $http->request( $req );
        my $res = $process->( $resp );
        return( $self->pass_error ) if( $res->{error} );
        return( @$res{qw( content status resp http )} );
    }
}

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

sub clearQueue { return( $_[0] ) }

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

sub contains
{
    my $self = shift( @_ );
    my( $container, $contained );
    if( scalar( @_ ) > 1 )
    {
        return( $self->error( "Wrong number of argument: \$el->contains( \$container, \$contained )" ) ) if( scalar( @_ ) > 2 );
        ( $container, $contained ) = @_;
    }
    elsif( scalar( @_ ) )
    {
        $container = $self;
        $contained = shift( @_ );
    }
    elsif( !ref( $self ) && scalar( @_ ) < 2 )
    {
        return( $self->error( "You need to provide 2 arguments when using contains() as a class function: xQuery->contains( \$container, \$contained )" ) );
    }
    else
    {
        return( $self->error( "No contained object provided to check." ) );
    }
    # We need an object to access certain methods
    my $this = ref( $self ) ? $self : HTML::Object::DOM->new;
    return( $self->error( "Container value provided is undefined." ) ) if( !defined( $container ) );
    return( $self->error( "Contained value provided is undefined." ) ) if( !defined( $contained ) );
    return( $this->false ) if( $this->_is_a( $contained => [qw( HTML::Object::DOM::Text HTML::Object::DOM::Comment )] ) );
    return( $self->error( "Container object provided is not an HTML::Object::DOM::Element" ) ) if( !$this->_is_a( $container => 'HTML::Object::DOM::Element' ) );
    return( $self->error( "Contained object provided is not an HTML::Object::DOM::Element" ) ) if( !$this->_is_a( $contained => 'HTML::Object::DOM::Element' ) );
    my $crawl;
    my $seen = {};
    $crawl = sub
    {
        my $kids = shift( @_ );
        my $grand_kids = $this->new_array;
        for( my $i = 0; $i < scalar( @$kids ); $i++ )
        {
            my $e = $kids->[$i];
            # Avoid recursion
            next if( ++$seen->{ $e->eid } > 1 );
            next unless( $this->_is_a( $e => 'HTML::Object::DOM::Element' ) );
            return( $this->true ) if( $e == $contained );
            $grand_kids->push( $e->children->list ) if( !$e->children->is_empty );
        }
        return( $this->false ) if( $grand_kids->is_empty );
        return( $crawl->( $grand_kids ) );
    };
    return( $crawl->( $container->children ) );
}

sub contents
{
    my $self = shift( @_ );
    my $collection = $self->new_collection;
    my $children = $collection->children;
    if( $self->isa_collection )
    {
        $self->children->foreach(sub
        {
            $children->push( $_->children->list );
        });
    }
    else
    {
        $children->push( $self->children->list );
    }
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
    # elsif( $self->tag->substr( 0, 1 ) eq '_' )
    elsif( !$self->_is_a( $self => 'HTML::Object::DOM::Element' ) )
    {
        return( $self->error( "You can only call the data method on HTML elements." ) );
    }
    else
    {
        $elem = $self;
    }
    
    if( $self->_is_hash( $this ) )
    {
        my $changed = 0;
        $this = $self->new_hash( $this )->each(sub
        {
            my( $k, $v ) = @_;
            # Remove leading and trailing spaces if this is not a reference
            $v =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g if( !ref( $v ) );
            # $attr->set( 'data-' . $k, $v );
            if( $elem->setAttribute( 'data-' . $k, $v ) )
            {
                $changed++;
            }
        });
        $elem->reset(1) if( $changed );
        return( $elem );
    }
    elsif( defined( $this ) && scalar( @_ ) > 1 )
    {
        # From jQuery documentation: "undefined is not recognized as a data value. Calls such as .data( "name", undefined ) will return the jQuery object that it was called on, allowing for chaining."
        return( $self ) if( !defined( $val ) );
        return( $self->error( "I was provided data name '$this', but I was expcting a regular string." ) ) if( ref( $this ) && ( !overload::Overloaded( $this ) || ( overload::Overloaded( $this ) && !overload::Method( $this, '""' ) ) ) );
        # $attr->set( 'data-' . $this => $val );
        if( $elem->setAttribute( 'data-' . $this => $val ) )
        {
            $elem->reset(1);
        }
        return( $elem );
    }
    elsif( defined( $this ) && scalar( @_ ) == 1 )
    {
        # return( $attr->get( $this ) );
        return( $elem->getAttribute( 'data-' . $this ) );
    }
    else
    {
        $self->_load_class( 'Module::Generic::Dynamic' ) || return( $self->pass_error );
        my $ref = {};
        my $attr = $elem->attributes;
        $attr->each(sub
        {
            my( $k, $v ) = @_;
            if( substr( $k, 0, 5 ) CORE::eq 'data-' && CORE::length( $k ) > 5 )
            {
                $ref->{ substr( $k, 5 ) } = $v;
            }
        });
        my $obj = Module::Generic::Dynamic->new( $ref ) ||
            return( $self->pass_error( Module::Generic::Dynamic->error ) );
        return( $obj );
    }
}

sub debug
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = $self->SUPER::debug( @_ );
        if( $self->isa_collection )
        {
            $self->children->foreach(sub
            {
                $_->debug( $val );
            });
        }
        return( $val );
    }
    return( $self->SUPER::debug );
}

sub dequeue { return( $_[0] ) }

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
            return(1) if( !$parent );
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
    my $collection = $self->new_collection( end => $self );
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
                # $_->debug( $self->debug ); 
                if( $_->tag->substr( 0, 1 ) ne '_' &&
                    $_->matches( $xpath ) )
                {
                    $collection->children->push( $_ );
                }
                else
                {
                    # No match
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
            $self->children->for(sub
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
                        return(1);
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
        # try-catch
        local $@;
        eval
        {
            my @nodes = $self->findnodes( $xpath );
            $collection->children->push( @nodes );
        };
        if( $@ )
        {
            warn( "Error while calling findnodes on element id \"", $_->id, "\" and tag \"", $_->tag, "\": $@\n" );
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

# <https://api.jquery.com/get/>
sub get
{
    my $self = shift( @_ );
    my $idx = shift( @_ );
    if( $self->isa_collection )
    {
        if( defined( $idx ) )
        {
            return( $self->error( "Index value provided is not an integer." ) ) if( !$self->_is_integer( $idx ) );
            return( $self->children->[ $idx ] );
        }
        else
        {
            my $arr = $self->new_array;
            $arr->push( $self->children->list );
            return( $arr );
        }
    }
    else
    {
        if( defined( $idx ) )
        {
            return( $self );
        }
        else
        {
            return( $self->new_array( $self ) );
        }
    }
}

sub getDataJson
{
    my $self = shift( @_ );
    my $dataName = shift( @_ ) ||
        return( $self->error( "No data name was provided to get its JSON object" ) );
    my $el;
    if( $self->isa_collection )
    {
        $el = $self->children->first;
        return({}) if( !$el );
    }
    else
    {
        $el = $self;
    }
    my $json;
    my $shortName = $dataName;
    if( substr( $dataName, 0, 5 ) eq 'data-' )
    {
        $shortName = substr( $dataName, 5, length( $dataName ) );
    }
    my $data = $self->data( $shortName );
    return({}) if( !defined( $data ) || !length( $data // '' ) );
    if( ref( $data ) eq 'HASH' )
    {
        $json = $data;
    }
    else
    {
        # Taken from URI::Escape
        my $decodeURIComponent = sub
        {
            my $str = shift( @_ );
            if( @_ && wantarray )
            {
                # not executed for the common case of a single argument
                # need to copy
                my @str = ( $str, @_ );
                for( @str )
                {
                    s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                }
                return( @str );
            }
            $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg if( defined( $str ) );
            return( $str );
        };
        # try-catch
        local $@;
        eval
        {
            my $j = $self->new_json;
            if( index( $data, '{' ) != -1 )
            {
                $json = $j->decode( $data );
            }
            else
            {
                $json = $j->decode( $decodeURIComponent->( $data ) );
            }
        };
        if( $@ )
        {
            return( $self->error( "An error occurred while trying to decode the json data: $@" ) );
        }
        # Replace parsed json string by its object representation
        $self->data( $shortName => $json );
    }
    return( $json );
}

sub getJSON
{
    my $self = shift( @_ );
    my $url = shift( @_ ) || return( $self->error( "No URL was provided." ) );
    my @args = @_;
    my( $data, $success );
    for( my $i = 0; $i < scalar( @args ); $i++ )
    {
        if( !defined( $data ) && ref( $args[$i] // '' ) eq 'HASH' )
        {
            $data = $args[$i];
        }
        elsif( !defined( $success ) && ref( $args[$i] // '' ) eq 'CODE' )
        {
            $success = $args[$i];
        }
    }

    $self->_load_class( 'Promise::Me' ) || return( $self->pass_error );
    if( lc( substr( "$url", 0, 7 ) ) eq 'file://' )
    {
        $self->_load_class( 'HTTP::Promise::Response' ) || return( $self->pass_error );
        return( Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            my $f = $self->new_file( $url ) || return( $reject->( $self->error ) );
            if( $f->exists )
            {
                my $ref = $f->load_json || return( $reject->( $f->error ) );
                my $resp2 = HTTP::Promise::Response->new( 200 => 'OK' );
                if( defined( $success ) )
                {
                    my $ua = HTTP::Promise->new;
                    $success->( $ref, 'success', $resp2, $ua );
                }
                return( $resolve->( $ref, 'success', $resp2 ) );
            }
            else
            {
                my $resp2 = HTTP::Promise::Response->new( 404 => 'Not found' );
                my $err = "File $url is not found.";
                if( defined( $success ) )
                {
                    my $ua = HTTP::Promise->new;
                    $success->( $err, 'error', $resp2, $ua );
                }
                $self->error({
                    code => 404,
                    message => $err,
                });
                my $ex = $self->error;
                return( $reject->( $ex ) );
            }
        }) );
    }
    else
    {
        return( Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            my( $uri, $doc_root, $doc_uri );
            if( lc( substr( $url, 0, 7 ) ) eq 'http://' ||
                lc( substr( $url, 0, 7 ) ) eq 'http://' )
            {
                $uri = $url;
            }
            # Contextual URL that requires a base URL.
            # We check for documentURI of the root element, if any
            elsif( ( substr( $url, 0, 1 ) eq '/' ||
                   substr( $url, 0, 2 ) eq './' ||
                   substr( $url, 0, 3 ) eq '../' ) &&
                   ( $doc_root = $self->getRootNode ) &&
                   $doc_root->isa( 'HTML::Object::DOM::Document' ) &&
                   ( $doc_uri = $doc_root->documentURI ) )
            {
                $uri = $doc_uri->clone;
                $uri->path( $url );
            }
            else
            {
                $self->error( "Unsupported URL '${url}'" );
                return( $reject->( $self->error ) );
            }
            $self->ajax( $uri,
                dataType => 'json',
                ( defined( $data ) ? ( data => $data ) : () ),
                ( defined( $success ) ? ( success => $success ) : () ),
            )->catch(sub
            {
                return( $reject->( @_ ) );
            });
        }) );
    }
}

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
        
        my $is_code = ref( $this ) eq 'CODE' ? 1 : 0;
        my $process = sub
        {
            my( $e, $i ) = @_;
            if( $is_code )
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
                    $e->reset(1);
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
                $e->reset(1);
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
                $e->reset(1);
            }
        };

        if( $self->isa_collection )
        {
            $self->children->for(sub
            {
                my( $i, $e ) = @_;
                $process->( $e, $i );
                # Return true at the end to satisfy Module::Generic::Array->for
                return(1);
            });
        }
        else
        {
            $process->( $self, 0 );
        }
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

sub isArray { return( shift->_is_array( @_ ) ); }

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
    
    return( $self->error( "No url was provided to load data" ) ) if( !defined( $url ) || !CORE::length( "$url" ) );
    if( !defined( $complete ) && defined( $data ) && ref( $data ) eq 'CODE' )
    {
        $complete = $data;
        undef( $data );
    }
    if( defined( $data ) && ref( $data ) ne 'HASH' )
    {
        return( $self->error( "Data to be submitted to $url was provided, but I was expecting an hash reference and I got '", overload::StrVal( $data ), "'" ) );
    }
    if( defined( $complete ) && ref( $complete ) ne 'CODE' )
    {
        return( $self->error( "A callback parameter was provided, and I was expecting a code reference, such as an anonymous subroutine, but instead I got '", overload::StrVal( $complete ), "'" ) );
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
    
    if( !$self->_load_class( 'HTTP::Promise', { version => 'v0.5.0' } ) )
    {
        return( $self->error( "HTTP::Promise version v0.5.0 or higher is required to use load()" ) );
    }
    if( !$self->_load_class( 'URI', { version => '1.74' } ) )
    {
        return( $self->error( "URI version 1.74 or higher is required to use load()" ) );
    }
    $opts->{timeout} //= 10;
    $opts->{agent} ||= "HTML::Object/$VERSION";
    # "If one or more space characters are included in the string, the portion of the string following the first space is assumed to be a jQuery selector that determines the content to be loaded."
    # e.g.: $( "#new-projects" )->load( "/resources/load.html #projects li" );
    # <https://api.jquery.com/load/#load-url-data-complete>
    ( $url, my $target ) = split( /[[:blank:]\h]+/, $url, 2 );
    
    my $uri;
    # try-catch
    local $@;
    eval
    {
        $uri = URI->new( "$url" );
    };
    if( $@ )
    {
        return( $self->error( "Bad url provided \"$url\": $@" ) );
    }
    
    my $content;
    my $resp;
    my @http_options = qw(
        accept_encoding accept_language auto_switch_https cookie_jar dnt max_redirect
        proxy
    );
    my $params = {};
    foreach my $k ( @http_options )
    {
        if( exists( $opts->{ $k } ) &&
            defined( $opts->{ $k } ) &&
            CORE::length( $opts->{ $k } ) )
        {
            $params->{ $k } = $opts->{ $k };
        }
    }
    $params->{use_promise} = 0;
    # try-catch
    my $ua = HTTP::Promise->new( %$params );
    
    # Contextual URL that requires a base URL.
    # We check for documentURI of the root element, if any
    my( $doc_root, $doc_uri );
    if( ( substr( $uri, 0, 1 ) eq '/' ||
           substr( $uri, 0, 2 ) eq './' ||
           substr( $uri, 0, 3 ) eq '../' ) &&
           ( $doc_root = $self->getRootNode ) &&
           $doc_root->isa( 'HTML::Object::DOM::Document' ) &&
           ( $doc_uri = $doc_root->documentURI ) )
    {
        my $clone = $doc_uri->clone;
        $clone->path( $uri );
        $uri = $clone;
    }

    if( $uri->scheme eq 'http' || $uri->scheme eq 'https' )
    {
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
        
        if( !$resp )
        {
            $self->_load_class( 'HTTP::Promise::Response' ) || return( $self->pass_error );
            my $err = "Error trying to get url \"${url}\": " . ( $ua->error ? $ua->error->message : 'unknown' );
            my $resp2 = HTTP::Promise::Response->new( 500, "Unexpected error", [], $err );
            $complete->( $err, 'error', $resp2, $ua );
            return( $self->error({
                code => 500,
                message => $err,
            }) );
        }
        $content = $resp->decoded_content;
        
        if( $resp->header( 'Client-Warning' ) || !$resp->is_success )
        {
            $complete->( $content, 'error', $resp, $ua );
            return( $self->error({
                code => $resp->code,
                message => $resp->message,
            }) );
        }
    }
    elsif( $uri->scheme eq 'file' )
    {
        $self->_load_class( 'HTTP::Promise::Response' ) || return( $self->pass_error );
        my $f = $self->new_file( $uri ) || return( $self->pass_error );
        if( $f->exists )
        {
            $resp = HTTP::Promise::Response->new( 200 => 'OK' );
            $content = $f->load;
        }
        else
        {
            my $resp2 = HTTP::Promise::Response->new( 404 => 'Not found' );
            my $err = "File $uri is not found.";
            $complete->( $err, 'error', $resp2, $ua );
            return( $self->error({
                code => 404,
                message => $err,
            }) );
        }
    }
    else
    {
        my $resp2 = HTTP::Promise::Response->new( 400 => 'Bad request' );
        my $err = "The URL provided is unsupported.";
        $complete->( $err, 'error', $resp2, $ua );
        return( $self->error({
            code => 400,
            message => $err,
        }) );
    }

    my $new;
    if( defined( $content ) && CORE::length( $content // '' ) )
    {
        my $parser = $self->new_parser;
        # HTML::Object::DOM::Document
        my $doc = $parser->parse_data( $content ) ||
            return( $self->pass_error( $parser->error ) );
        $new = $doc->children;
        # "When this method executes, it retrieves the content of ajax/test.html, but then jQuery parses the returned document to find the element with an ID of container. This element, along with its contents, is inserted into the element with an ID of result, and the rest of the retrieved document is discarded."
        if( defined( $target ) )
        {
            my $elem = $doc->find( $target ) || return( $self->pass_error( $doc->error ) );
            # $new = $self->new_array( $elem );
            $new = $elem->children;
        }
    }
    # The content returned is empty, so we cannot parse it, and instead we provide a HTML::Object::DOM::Text element with an empty value inside.
    else
    {
        my $txt = $self->new_text( value => '' ) || return( $self->pass_error );
        $new = $self->new_array( $txt );
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

sub new_parser { HTML::Object::DOM->new }

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

sub new_root
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} = $self->debug unless( exists( $opts->{debug} ) );
    my $e = HTML::Object::DOM::Root->new( $opts ) ||
        return( $self->pass_error( HTML::Object::DOM::Root->error ) );
    return( $e );
}

sub normalize_content
{
    my $self = shift( @_ );
    if( $self->isa_collection )
    {
        $self->children->foreach(sub
        {
            $_->normalize_content;
        });
        return( $self );
    }
    else
    {
        $self->SUPER::normalize_content;
    }
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
            # try-catch
            my $rv = eval
            {
                return( !$elem->matches( $xpath ) );
            };
            if( $@ )
            {
                return( $self->error( "Caught an exception while calling matches with xpath '$xpath' for element of class ", ref( $elem ), " and tag '", $elem->tag, "': $@" ) );
            }
            return( $rv );
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

# NOTE: queue is not implemented
# <https://api.jquery.com/queue/>

sub rank { return( shift->_set_get_number_as_object( 'rank', @_ ) ); }

# <https://api.jquery.com/remove/>
# TODO: Need to check again and do some test to ensure this api is compliant
sub remove
{
    my $self = shift( @_ );
    if( $self->isa_collection )
    {
        $self->children->foreach(sub
        {
            my $e = shift( @_ );
            my $pos = $e->pos;
            my $parent = $e->parent;
            $e->delete;
        });
    }
    # xpath provided
    elsif( @_ )
    {
        my $xpath = $self->_xpath_value( shift( @_ ) ) || return;
        $self->find( $xpath )->remove;
    }
    # Equivalent to delete
    else
    {
        $self->delete;
    }
    return( $self );
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

sub removeData
{
    my $self = shift( @_ );
    my $elem;
    if( $self->isa_collection )
    {
        $elem = $self->children->first;
    }
    elsif( !$self->_is_a( $self => 'HTML::Object::DOM::Element' ) )
    {
        return( $self->error( "You can only call the removeData() method on html elements." ) );
    }
    else
    {
        $elem = $self;
    }
    
    my $keys;
    # If no @_ is provided this is undef and it is ok, we would remove all data attributes then
    if( @_ )
    {
        my $this = shift( @_ );
        if( $self->_is_empty( $this ) )
        {
            return( $self->error( "Data name value provided is empty. If you want to remove all data attributes, simply call removeData() without argument." ) );
        }
        elsif( !ref( $this ) ||
               ( ref( $this ) && $self->_can_overload( $this => '""' ) ) )
        {
            $this = "$this";
            if( CORE::index( $this, ' ' ) != -1 )
            {
                $keys = [CORE::split( /[[:blank:]\h]+/, $this )];
            }
            else
            {
                $keys = [$this];
            }
        }
        elsif( $self->_is_array( $this ) )
        {
            $keys = $this;
        }
        else
        {
            return( $self->error( "Data name value to remove is unsupported. You can only provide a string, a space-separated string of names, or an array reference." ) );
        }
    }
    else
    {
        $keys = $elem->attributes_sequence;
    }

    my $changed = 0;
    foreach my $k ( @$keys )
    {
        if( $elem->hasAttribute( 'data-' . $k ) )
        {
            $elem->removeAttribute( 'data-' . $k );
            $changed++;
        }
    }
    $elem->reset(1) if( $changed );
    # Return undef
    return;
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

# This is here and although it has been deprecated, so that $.uniqueSort() works
# <https://stackoverflow.com/questions/63575333/javascript-replacement-of-sourceindex-in-chromium-browsers>
# <https://developer.mozilla.org/en-US/docs/Web/API/Document/all>
sub sourceIndex : lvalue { return( shift->_set_get_lvalue( 'sourceIndex', @_ ) ); }

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

# This method work for absolutely any element, including the root element (html)
sub text
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    # Mutator
    if( defined( $this ) )
    {
        if( !ref( $this ) ||
            ( ref( $this ) && overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) )
        {
            $this = "$this";
        }
        elsif( ref( $this ) ne 'CODE' )
        {
            return( $self->error( "I was expecting some text data or a code reference in replacement of text for this element \"", $self->tag, "\", but instead got '$this'." ) );
        }
        
        my $is_code = ref( $this ) eq 'CODE' ? 1 : 0;
        my $process = sub
        {
            my( $e, $i ) = @_;
            if( $is_code )
            {
                my $current_text = $e->as_text( unescape => 1 );
                my $text = $this->( $i, $current_text );
                if( !defined( $text ) || !CORE::length( $text ) )
                {
                    $e->empty();
                    # Next please
                    return(1);
                }
                elsif( ref( $text ) &&
                       !( overload::Overloaded( $text ) && overload::Method( $text, '""' ) ) )
                {
                    warn( "I was provided a reference '$text' as a result from calling this code reference to get the replacement text for tag \"", $e->tag, "\", but I do not know what to do with it.\n" );
                    return(1);
                }
                $text = "$text";
                $text =~ s/</\&lt;/gs;
                $text =~ s/>/\&gt;/gs;
                $text =~ s,\n,<br />\n,gs;
                if( $self->isa( 'HTML::Object::DOM::Comment' ) ||
                    $self->isa( 'HTML::Object::DOM::Text' ) )
                {
                    $self->value( $text );
                }
                else
                {
                    my $new = $self->new_text( value => $text, parent => $self );
                    # If this is an empty tag, such as <input /> or <img />, the text cannot be added to it.
                    # jQuery actually accepts the text and attach it to the element as a child, but the web browser does not show it, because it is an empty element.
                    # Since this is not a web browser interface, we need to silently ignore it, so it does not end up in the DOM and turn an empty tag into a tag with children and a closing tag, which would be an heresy.
                    if( !$e->is_empty )
                    {
                        $e->children->set( $new );
                    }
                }
            }
            else
            {
                my $new = $self->new_text( value => $this, parent => $e );
                # See comment just above
                if( !$e->is_empty )
                {
                    $e->children->set( $new );
                }
            }
        };

        if( $self->isa_collection )
        {
            $self->children->for(sub
            {
                my( $i, $e ) = @_;
                $process->( $e, $i );
                $e->reset(1);
                # Return true at the end to satisfy Module::Generic::Array->for
                return(1);
            });
        }
        else
        {
            $process->( $self, 0 );
            $self->reset(1);
        }
    }
    # Accessor
    else
    {
        return( $self->as_text( unescape => 1 ) );
    }
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

sub uniqueSort
{
    my $self = shift( @_ );
    my $collection = $self->new_collection;
    if( $self->isa_collection )
    {
        my $elems = xQuery->uniqueSort( $self->children ) ||
            return( $self->pass_error( xQuery->error ) );
        $collection->children->push( $elems->list );
    }
    else
    {
        $collection->children->push( $self );
    }
    return( $collection );
}

sub wrap
{
    my $self = shift( @_ );
    my @args = @_;
    my( $this, $more ) = @args;
    return( $self->error( "Nothing was provided to wrap elements." ) ) if( !$this );
    my( $wrapper, $elems, $is_code );
    # "When you pass a collection object containing more than one element, or a selector matching more than one element, the first element will be used."
    if( $self->_is_a( $this => 'HTML::Object::Collection' ) )
    {
        return( $self->error( "Collection provided as wrapper is actually empty!" ) ) if( $this->children->is_empty );
        $wrapper = $this->children->first;
        return( $self->error( "The first element of the collection provided did not yield an element object." ) ) if( !$self->_is_a( $wrapper => 'HTML::Object::DOM::Element' ) );
    }
    elsif( $self->_is_a( $this => 'HTML::Object::DOM::Element' ) )
    {
        $wrapper = $this;
    }
    elsif( $self->_is_code( $this ) )
    {
        $is_code = 1;
        $wrapper = $this;
    }
    # selector, html to parse
    else
    {
        my $tmp = xq( @args ) || return( $self->pass_error );
        return( $self->error( "Selector or HTML provided as wrapper did not yield any wrapping element." ) ) if( $tmp->children->is_empty );
        $wrapper = $tmp->children->first ||
            return( $self->error( "Collection returned from selector or HTML provided is empty." ) );
        return( $self->error( "Collection returned from selector or HTML provided did not yield an element object." ) ) if( !$self->_is_a( $wrapper => 'HTML::Object::DOM::Element' ) );
    }

    if( $self->isa_collection )
    {
        $elems = $self->children;
    }
    else
    {
        $elems = $self->new_array( $self );
    }

    my $find_nested;
    $find_nested = sub
    {
        my( $el, $kids ) = @_;
        my $n = $kids->length;
        if( !$n )
        {
            return( $el );
        }
        elsif( $n == 1 )
        {
            return( $find_nested->( $kids->[0] => $kids->[0]->children ) );
        }
        else
        {
            return( '' );
        }
    };

    local $@;
    for( my $i = 0; $i < scalar( @$elems ); $i++ )
    {
        my $e = $elems->[$i];
        my $parent = $e->parent;
        my $pos = $parent->children->pos( $e );
        return( $self->error( "Unable to find element No $i position in its parent." ) ) if( !defined( $pos ) );
        my $wrap;
        if( $is_code )
        {
            # try-catch
            my $rv = eval
            {
                local $_ = $e;
                $wrapper->( $i );
            };
            if( $@ )
            {
                return( $self->error( "An error occurred executing the wrapper callback code reference for element at offset $i: $@" ) );
            }
            my $thingy;
            if( $self->_is_a( $rv => 'HTML::Object::Collection' ) )
            {
                return( $self->error( "Collection provided as wrapper is actually empty!" ) ) if( $rv->children->is_empty );
                $thingy = $rv->children->first;
                return( $self->error( "The first element of the collection provided did not yield an element object." ) ) if( !$self->_is_a( $thingy => 'HTML::Object::DOM::Element' ) );
            }
            elsif( $self->_is_a( $rv => 'HTML::Object::DOM::Element' ) )
            {
                $thingy = $rv;
            }
            # selector, html to parse
            else
            {
                my $tmp = xq( $rv, ( defined( $more ) ? $more : () ) ) || return( $self->pass_error );
                return( $self->error( "Selector or HTML returned from callback as wrapper did not yield any wrapping element." ) ) if( $tmp->children->is_empty );
                $thingy = $tmp->children->first ||
                    return( $self->error( "Collection returned from selector or HTML provided is empty." ) );
                return( $self->error( "Collection returned from selector or HTML provided did not yield an element object." ) ) if( !$self->_is_a( $thingy => 'HTML::Object::DOM::Element' ) );
            }
            $wrap = $thingy->clone;
        }
        else
        {
            $wrap = $wrapper->clone;
        }
        my $nested = $find_nested->( $wrap => $wrap->children );
        # $e->detach;
        $wrap->parent( $parent );
        $parent->children->splice( $pos, 1, $wrap );
        $nested->children->set( $e );
        $e->parent( $nested );
    }
    return( $self );
}

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
    my( @args ) = @_;
    # Check if this might be all some HTML::Object::DOM::Element objects passed to form a collection
    my $is_all_objects = 1;
    no warnings 'once';
    my $opts = 
    {
        xq_debug => $HTML::Object::xQuery::DEBUG,
    };
    if( scalar( @args ) > 1 &&
        defined( $args[-1] ) &&
        ref( $args[-1] ) eq 'HASH' && 
        CORE::exists( $args[-1]->{xq_debug} ) )
    {
        $opts = CORE::pop( @args );
    }
    # A dummy accessor
    my $self = HTML::Object::DOM::Element->new( debug => $opts->{xq_debug} );
    # We check if xq was not called with a bunch of HTML::Object::DOM::Element objects, such as:
    # $(@elements) or maybe xq(@elements), which would return a new collection.
    for( my $i = 0; $i < scalar( @args ); $i++ )
    {
        unless( $self->_is_a( $args[$i] => 'HTML::Object::DOM::Element' ) )
        {
            $is_all_objects = 0;
            last;
        }
    }
    # Shortcut
    if( $is_all_objects )
    {
        my $collection = $self->new_collection( debug => $opts->{xq_debug} );
        $collection->children->set( @args );
        return( $collection );
    }
    my( $this, $more ) = @args;
    # e.g. $('<div />', { id => 'pouec', class => 'hello' });
    if( $this =~ /^$LOOK_LIKE_HTML/ )
    {
        my $p = HTML::Object::DOM->new;
        $this = "$this";
        # We trim the string, so that leading and trailing space do not get counted
        $this =~ s/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$//gs;
        my $doc = $p->parse_data( $this ) || do
        {
            $! = $p->error;
            return;
        };
        # $doc is a HTML::Object::DOM::Document, which is not suitable, so we change it to a
        # collection object
        my $collection = $doc->new_collection;
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
    # Hmmm, I wanted to support $.parseXML and consequently allow $($xmlDoc), but our interface is really just tailored for HTML::Object::Element and not for XML::libXML, so all of the HTML::Object::XQuery methods would not work.
    # elsif( $self->_is_a( $this => 'XML::LibXML::Node' ) )
    # {
    #     my $collection = $self->new_collection;
    #     my @childnodes = $this->childNodes;
    #     $collection->children->push( @childNodes );
    #     return( $collection );
    # }
    elsif( ( !ref( $this ) || ( overload::Overloaded( $this ) && overload::Method( $this, '""' ) ) ) && CORE::index( "$this", "\n" ) == -1 )
    {
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
    # For example: $sel->appendTo( 'body', $doc );
    my $context = shift( @_ ) if( $self->_is_a( $_[0] => 'HTML::Object::DOM::Element' ) );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !exists( $opts->{action} ) )
    {
        my @caller_info = caller(1);
        my $caller = [split( /::/, $caller_info[3])]->[-1];
        return( $self->error( "No action argument was provided and I am unable to guess it." ) ) if( $caller !~ /^(appendTo|prependTo|append_to|prepend_to)$/ );
        $opts->{action} = ( $caller =~ /^(append|prepend)(?:To|_to)$/ )[0];
    }
    return( $self->error( "Invalid value for argument \"action\": '$opts->{action}'" ) ) if( $opts->{action} !~ /^(append|prepend)$/ );
    my( $src, $dst );
    # A collection to be returned if there is more than 1 target
    my $collection = $self->new_collection;
    if( !ref( $this ) )
    {
        if( $self->_is_html( $this ) )
        {
            my $p = $self->new_parser;
            $this = $p->parse_data( $this ) || return( $self->pass_error( $p->error ) );
            $dst = $self->new_array( [ $this ] );
        }
        # otherwise this has to be a selector
        # TODO: Need to correct this and adjust the object used as a base for the find
        # since $self could very well be a dynamically created dom object
        else
        {
            if( !defined( $context ) &&
                defined( $HTML::Object::DOM::GLOBAL_DOM ) )
            {
                $context = $HTML::Object::DOM::GLOBAL_DOM;
            }
            elsif( !defined( $context ) &&
                $self->isa_collection &&
                !$self->children->is_empty )
            {
                $context = $self->children->first->getRootNode;
            }
            $this = defined( $context ) ? $context->find( $this ) : $self->find( $this );
            return( $self->pass_error ) unless( $this );
            # $dst = $self->new_array( [ $this ] );
            $dst = $this->children;
        }
    }
    elsif( $self->_is_array( $this ) )
    {
        # Make sure this is a Module::Generic::Array object
        $dst = $self->new_array( $this );
    }
    elsif( $self->_is_object( $this ) )
    {
        return( $self->error( "Object provided '$this' (", overload::StrVal( $this ), ") is not an HTML::Object::DOM::Element object." ) ) if( !$this->isa( 'HTML::Object::DOM::Element' ) );
        $dst = $self->new_array( [ $this ] );
    }
    else
    {
        return( $self->error( "I do not know what to do with \"$this\". I was expecting a selector, html data, an element object or an array." ) );
    }
    
    # If the content to be inserted is a collection, we loop through it, duplicate each element and insert them
    if( $self->isa_collection )
    {
        $src = $self->children;
    }
    else
    {
        $src = $self->new_array( $self );
    }

    # If the target is just one element, we do not duplicate them, but simply move them
    if( $dst->length == 1 )
    {
        my $elem = $dst->first;
        my $parent = $elem->parent;
        return( 1 ) if( !$parent );
        $elem->reset(1);
        my $pos = $parent->children->pos( $elem );
        return( $self->error( "Found a parent for tag \"", $elem->tag, "\", but somehow I could not find its position among its children elements." ) ) if( !defined( $pos ) );
        $src->foreach(sub
        {
            my $e = shift( @_ );
            # Making sure the content element is detached from its original parent
            $e->detach;
            $e->parent( $elem );
            $e->reset(1);
            if( $opts->{action} CORE::eq 'prepend' )
            {
                $elem->children->unshift( $e );
            }
            elsif( $opts->{action} CORE::eq 'append' )
            {
                $elem->children->push( $e );
            }
            $collection->children->push( $e );
        });
    }
    # However, if the target contain multiple element, we clone the content element
    else
    {
        $dst->foreach(sub
        {
            my $elem = $_;
            my $parent = $elem->parent;
            return(1) if( !$parent );
            $elem->reset(1);
            my $pos = $parent->children->pos( $elem );
            warn( "Found a parent for tag \"", $elem->tag, "\", but somehow I could not find its position among its children elements.\n" ) if( !defined( $pos ) );
            return(1) if( !defined( $pos ) );
            $src->foreach(sub
            {
                my $e = shift( @_ );
                # Making sure the content element is detached from its original parent
                my $clone = $e->detach->clone;
                $clone->parent( $elem );
                $clone->reset(1);
                if( $opts->{action} CORE::eq 'prepend' )
                {
                    $elem->children->unshift( $clone );
                }
                elsif( $opts->{action} CORE::eq 'append' )
                {
                    $elem->children->push( $clone );
                }
                $collection->children->push( $clone );
            });
        });
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
