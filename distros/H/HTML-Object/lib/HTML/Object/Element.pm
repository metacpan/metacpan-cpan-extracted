##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Element.pm
## Version v0.3.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/25
## Modified 2025/10/16
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Element;
BEGIN
{
    # For smart match
    use v5.10.1;
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $LOOK_LIKE_HTML $LOOK_LIKE_IT_HAS_HTML $ATTRIBUTE_NAME_RE $VERSION );
    use Data::UUID;
    use Digest::MD5 ();
    use Encode ();
    use Scalar::Util ();
    use Wanted;
    use overload (
        'eq'    => \&_same_as,
        '=='    => \&_same_as,
        fallback => 1,
    );
    our $LOOK_LIKE_HTML = qr/^[[:blank:]\h]*\<\w+.*?\>/;
    our $LOOK_LIKE_IT_HAS_HTML = qr/\<\w+.*?\>/;
    our $ATTRIBUTE_NAME_RE = qr/\w[\w\-]*/;
    our $VERSION = 'v0.3.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    for( qw( attributes attributes_sequence ) )
    {
        delete( $opts->{ $_ } ) if( !defined( $opts->{ $_ } ) );
    }
    my $parent = delete( $opts->{parent} );
    $opts->{parent}     = $parent;
    $self->{attr}       = {} unless( exists( $self->{attr} ) );
    $self->{attr_seq}   = [] unless( exists( $self->{attr_seq} ) );
    $self->{checksum}   = '';
    $self->{close_tag}  = '' unless( exists( $self->{close_tag} ) );
    $self->{column}     = 0;
    # Was there a closing tag for non-void tags?
    $self->{is_closed}  = 0 unless( exists( $self->{is_closed} ) );
    $self->{is_empty}   = 0 unless( exists( $self->{is_empty} ) );
    $self->{line}       = 0;
    $self->{modified}   = 0;
    $self->{offset}     = 0;
    $self->{original}   = undef;
    $self->{parent}     = undef;
    $self->{rank}       = undef;
    $self->{tag}        = '' unless( exists( $self->{tag} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'HTML::Object::Exception';
    $self->SUPER::init( $opts ) || return( $self->pass_error );
    $self->{children} = [];
    # uuid
    $self->{eid} = $self->_generate_uuid();
    # The user is always right, so we check if the tag has a forward slash as attribute
    # If there is one, this means this tag is an empty (void) tag.
    # We issue a warning if our dictionary-derived value 'is_empty' says different
    $opts->{is_empty} = 0 if( !exists( $opts->{is_empty} ) );
    $opts->{attributes} = {} if( !exists( $opts->{attributes} ) );
    my $attr = $opts->{attributes};
    if( !$opts->{is_empty} && exists( $attr->{'/'} ) )
    {
        warnings::warn( "Tag initiated \"$opts->{tag}\" is marked as non-empty (non-void), but ends with \"/>\" at line $opts->{line} and column $opts->{column}: $opts->{original}\n" ) if( warnings::enabled() );
        $self->is_empty(1);
    }
    $self->checksum( $self->set_checksum );
    $self->{_cache_value} = '';
    $self->{_internal} = {};
    return( $self );
}

# Note: HTML::Element compatibility
sub address
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $addr = shift( @_ );
        my $path = $self->new_array( [split( /\./, $addr )] );
        my $root;
        # relative path, such as .2.5.3
        if( !length( $path->[0] ) )
        {
            $root = $self;
        }
        else
        {
            $root = $self->root;
            return( $self->error( "First offset position should be 0 for root or a relative path." ) ) if( $path->shift != 0 );
        }
        my $offset;
        while( $path->length && ( $offset = $path->shift ) )
        {
            return( $self->error( "Invalid offset '$offset' in path '$addr'. Value is bigger than the actual size of elements (", $root->children->size, "); starting from 0." ) ) if( $offset > $root->children->size );
            $root = $root->children->get( $offset );
        }
        return( $root );
    }
    else
    {
        my $line = $self->new_array;
        my $pos = $self->pos || 0;
        $line->push( $pos );
        $line->push( $self->lineage->list );
        return( $line->reverse->join( '.' ) );
    }
}

# Note: HTML::Element compatibility
sub all_attr
{
    my $self = shift( @_ );
    my $ref  = $self->attributes;
    return( %$ref );
}

# Note: HTML::Element compatibility
sub all_attr_names
{
    my $self = shift( @_ );
    return( $self->attributes->keys->list );
}

sub as_html { return( shift->as_string( @_ ) ); }

sub as_string
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    # If the element is called from within a collection, although it still has its
    # parent, we do not know exactly where is its closing tag, if any.
    # So this option makes it possible to return the tag and its closing tag, if any.
    $opts->{inside_collection} = 0 if( !CORE::exists( $opts->{inside_collection} ) );
    $opts->{inside_collection} //= 0;
    $opts->{recursive} //= 0;
    return( $self->{_cache_value} ) if( $self->{_cache_value} && !CORE::length( $self->{_reset} ) );
    my $tag  = $self->tag;
    my $res  = $self->new_array;
    my $a = $self->new_array( ["<${tag}"] );
    my $hash1 = $self->checksum;
    my $hash2 = $self->set_checksum;
    if( $self->original->defined && $hash1 eq $hash2 )
    {
        $a->set( [ $self->original->scalar ] );
    }
    else
    {
        if( !$self->attributes_sequence->is_empty )
        {
            my $attr = $self->new_array;
            $self->attributes_sequence->foreach(sub
            {
                my $k = shift( @_ );
                return( 1 ) if( $k eq '/' );
                my $v = $self->attributes->get( $k );
                # Ensure double quotes are escaped
                $v =~ s/(?<!\\)\"/\\\"/gs;
                $attr->push( sprintf( '%s="%s"', $k, $v ) );
            });
            $a->push( $attr->join( ' ' )->scalar );
        }
    }
    if( !$self->children->is_empty )
    {
        if( $self->is_empty )
        {
            warnings::warn( "This tag \"$tag\" is supposed to be an empty / void one, but it has " . $self->children->length . " children.\n" ) if( warnings::enabled() );
        }
        # The user is alway right, so let's add those children
        $res->push( $a->join( ' ' )->scalar );
        $res->push( '>' ) unless( $self->original->defined && $hash1 eq $hash2 );
        $self->children->foreach(sub
        {
            my $e = shift( @_ );
            my $v;
            if( $opts->{as_xml} )
            {
                $v = $e->as_xml( recursive => 1 );
            }
            else
            {
                $v = $e->as_string( recursive => 1 );
            }
            $res->push( defined( $v ) ? $v->scalar : $v );
        });
        # $res->push( "</${tag}>" );
        # $res->push( "</${tag}>" ) if( !$self->parent && !$self->is_empty );
        # if( ( $opts->{inside_collection} || !$opts->{recursive} ) && $self->close_tag )
        if( my $close = $self->close_tag )
        {
            my $parent = $self->parent;
            unless( $parent && defined( my $pos = $parent->children->pos( $close ) ) )
            {
                $res->push( $close->as_string );
            }
        }
    }
    else
    {
        if( $self->is_empty )
        {
            # No need to add this, because we are re-using the original tag data since it has not changed
            $a->push( '/>' ) unless( $hash1 eq $hash2 );
            $res->push( $a->join( ' ' )->scalar );
        }
        else
        {
            $res->push( $a->join( ' ' )->scalar );
            $res->push( '>' ) unless( $self->original->defined && $hash1 eq $hash2 );
            # If it has a parent, the parent will contain the closing tag, but
            # If this element is an element created with a find, such as $('body'), it has no
            # parent.
            # $res->push( "</${tag}>" ) if( !$self->parent && !$self->is_empty );
            if( my $close = $self->close_tag )
            {
                my $parent = $self->parent;
                unless( $parent && defined( my $pos = $parent->children->pos( $close ) ) )
                {
                    $res->push( $close->as_string );
                }
            }
        }
    }
    my $elem = $res->join( '' );
    $self->{_cache_value} = $elem;
    CORE::delete( $self->{_reset} );
    return( $elem );
}

# Note: HTML::Element compatibility
sub as_text
{
    my $self = shift( @_ );
    return( $self->{_cache_text} ) if( $self->{_cache_text} && !CORE::length( $self->{_reset} ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{unescape} //= 0;
    my $a = $self->new_array;
    my $seen = {};
    my $crawl;
    $crawl = sub
    {
        my $elem = shift( @_ );
        $elem->children->foreach(sub
        {
            my $e = shift( @_ );
            my $addr = Scalar::Util::refaddr( $e );
            return(1) if( CORE::exists( $seen->{ $addr } ) );
            $seen->{ $addr }++;
            if( $e->isa( 'HTML::Object::Text' ) ||
                $e->isa( 'HTML::Object::Space' ) )
            {
                if( exists( $opts->{callback} ) && ref( $opts->{callback} ) eq 'CODE' )
                {
                    # If value returned is not true, we skip this element
                    $opts->{callback}->( $e ) || return(1);
                }
                if( $opts->{unescape} )
                {
                    my $txt = $e->as_string->scalar;
                    $txt =~ s,<br[[:blank:]]*/>\n,\n,gs;
                    $txt =~ s/\&gt;/>/gs;
                    $txt =~ s/\&lt;/</gs;
                    $a->push( $txt );
                }
                else
                {
                    $a->push( $e->as_string->scalar );
                }
            }
            
            unless( $e->isa( 'HTML::Object::Text' ) ||
                    $e->isa( 'HTML::Object::Space' ) )
            {
                $crawl->( $e );
            }
        });
    };
    if( $self->isa( 'HTML::Object::Text' ) ||
        $self->isa( 'HTML::Object::Space' ) )
    {
        if( $opts->{unescape} )
        {
            my $txt = $self->value->scalar;
            $txt =~ s,<br[[:blank:]]*/>\n,\n,gs;
            $txt =~ s/\&gt;/>/gs;
            $txt =~ s/\&lt;/</gs;
            $a->push( $txt );
        }
        else
        {
            $a->push( $self->value->scalar );
        }
    }
    else
    {
        $crawl->( $self );
    }
    $self->{_cache_text} = $a->join( '' );
    CORE::delete( $self->{_reset} );
    return( $self->{_cache_text} );
}

# Note: HTML::Element compatibility
sub as_trimmed_text
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $text = $self->as_text( $opts ) || return;
    $text->replace( qr/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$/, '' );
    return( $text );
}

# Note: HTML::Element compatibility
# This does the same as for html. Sub classes take care of the differences
# sub as_xml { return( shift->as_string( @_ ) ); }
sub as_xml
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{as_xml} = 1;
    return( $self->as_string( $opts ) );
}

sub attr
{
    my $self = shift( @_ );
    my $attr = shift( @_ ) || return( $self->error( "No attribute name provided." ) );
    return( $self->error( "Attribute provided \"${attr}\" contains illegal characters. Only alphanumeric and _ are supported." ) ) if( $attr !~ /^\w+$/ );
    if( @_ )
    {
        my $v = shift( @_ );
        my $old;
        if( defined( $v ) )
        {
            $old = $self->attributes->get( $attr );
            # We do not want to force stringification, because for attribute like 'href' it could have an URI object as a value.
            # When stringification will be required, it will be done automatically anyway.
            # $v = "$v" if( ref( $v ) && overload::Method( $v, '""' ) );
            $v =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g if( !ref( $v ) );
            $self->attributes->set( $attr => $v );
            $self->attributes_sequence->push( $attr ) if( !$self->attributes_sequence->has( $attr ) );
        }
        else
        {
            $self->attributes_sequence->remove( $attr );
            $old = $self->attributes->delete( $attr );
        }
        
        # Check for attributes callback and execute it.
        # This is typically used for HTML::Object::TokenList by HTML::Object::DOM::Element and HTML::Object::DOM::AnchorElement
        my $callbacks = $self->{_internal_attribute_callbacks};
        $callbacks = {} if( ref( $callbacks ) ne 'HASH' );
        if( CORE::exists( $callbacks->{ $attr } ) && ref( $callbacks->{ $attr } ) eq 'CODE' )
        {
            my $cb = $callbacks->{ $attr };
            # try-catch
            local $@;
            eval
            {
                $cb->( $self, $v );
            };
            if( $@ )
            {
                return( $self->error( "Error executing attribute callback for attribute \"$attr\" for element with tag \"", $self->tag, "\": $@" ) );
            }
        }
        $self->reset(1);
        return( $old );
    }
    else
    {
        return( $self->attributes->get( $attr ) );
    }
}

sub attributes { return( shift->reset(@_)->_set_get_hash_as_mix_object( 'attr', @_ ) ); }

sub attributes_sequence
{
    my $self = shift( @_ );
    unless( @_ )
    {
        if( $self->_set_get_array_as_object( 'attr_seq' )->sort != $self->attributes->keys->sort )
        {
            $self->_set_get_array_as_object( 'attr_seq', $self->attributes->keys->sort );
        }
    }
    return( $self->reset(@_)->_set_get_array_as_object( 'attr_seq', @_ ) );
}

sub checksum { return( shift->reset(@_)->_set_get_scalar_as_object( 'checksum', @_ ) ); }

sub children { return( shift->reset(@_)->_set_get_object_array_object( 'children', 'HTML::Object::Element', @_ ) ); }

sub class { return( ref( $_[0] ) ); }

# Note: HTML::Element compatibility
sub clone
{
    my $self = shift( @_ );
    my $new = $self->SUPER::clone();
    $new->{eid} = $self->_generate_uuid();
    my $children = $self->clone_list;
    $new->children( $children );
    $children->foreach(sub
    {
        shift->parent( $new );
    });
    $new->parent( undef );
    $new->reset(1);
    return( $new );
}

# Note: HTML::Element compatibility
sub clone_list
{
    my $self = shift( @_ );
    my $a = $self->new_array;
    $self->children->foreach(sub
    {
        my $e = shift( @_ );
        $a->push( $e->clone );
    });
    return( $a );
}

sub close
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    # No need to close
    return( $self ) if( $self->is_empty );
#     if( !$parent )
#     {
#         warnings::warn( "No parent set for this element \"" . $self->tag . "\".\n" ) if( warnings::enabled( 'HTML::Object' ) );
#         return( $self );
#     }
    my $e = $self->new_closing({
        attributes => $opts->{attr},
        attributes_sequence => $opts->{seq},
        column   => $opts->{col},
        line     => $opts->{line},
        offset   => $opts->{offset},
        original => $opts->{raw},
        tag      => $self->tag,
        debug    => $self->debug,
    }) || return( $self->pass_error );
    my $parent = $self->parent;
    if( $parent )
    {
        my $pos = $parent->children->pos( $self );
        return( $self->error( "Could not find the opening tag '", $self->tag, "' in our parent." ) ) if( !defined( $pos ) );
        # We place the closing tag in the parent's child right after our opening tag
        # $parent->children->splice( $pos + 1, 0, $e );
    }
    $self->is_closed(1);
    $self->close_tag( $e );
    $self->reset(1);
    return( $self );
}

sub close_tag { return( shift->reset(@_)->_set_get_object( 'close_tag', 'HTML::Object::Element', @_ ) ); }

sub column { return( shift->reset(@_)->_set_get_number_as_object( 'column', @_ ) ); }

# Note: HTML::Element compatibility
sub content { return( shift->children ); }

# Note: HTML::Element compatibility
sub content_array_ref { return( shift->children ); }

# Note: HTML::Element compatibility
sub content_list
{
    my $self = shift( @_ );
    if( want( 'LIST' ) )
    {
        return( $self->children->list );
    }
    else
    {
        return( $self->children->length );
    }
}

# Note: HTML::Element compatibility
sub delete
{
    my $self = shift( @_ );
    $self->delete_content;
    $self->detach;
    %$self = ();
    return;
}

# Note: HTML::Element compatibility
sub delete_content
{
    my $self = shift( @_ );
    $self->children->foreach(sub
    {
        $_->delete;
    });
    $self->reset(1);
    return( $self );
}

# Note: HTML::Element compatibility
# Does not do anything by design
sub delete_ignorable_whitespace {}

sub depth
{
    my $self = shift( @_ );
    my $n = 0;
    my $parent = $self;
    $n++ while( $parent = $parent->parent );
    return( $self->new_number( $n ) );
}

sub descendants
{
    my $self = shift( @_ );
    my $a = $self->new_array;
    $self->traverse(sub
    {
        my $e = shift( @_ );
        my $class = $e->class;
        return(1) unless( $class eq 'HTML::Object::Element' );
        $a->push( $e );
    });
    return( $a );
}

# Note: HTML::Element compatibility
sub destroy { return( shift->delete( @_ ) ); }

sub destroy_content { return( shift->delete_content( @_ ) ); }

# Note: HTML::Element compatibility
sub detach
{
    my $self = shift( @_ );
    my $parent = $self->parent;
    return if( !$parent );
    my $id  = $self->eid;
    my $pos = $parent->children->pos( $self );
    if( defined( $pos ) )
    {
        $parent->children->splice( $pos, 1 );
        $self->parent( undef() );
        $parent->reset(1);
    }
    return( $parent );
}

# Note: HTML::Element compatibility
sub detach_content
{
    my $self = shift( @_ );
    $self->children->foreach(sub
    {
        shift->parent( undef() );
    });
    my @removed = $self->children->list;
    $self->children->reset;
    return( @removed );
}

sub dump
{
    my $self  = shift( @_ );
    my $depth = shift( @_ ) || 0;
    my $prefix = '.' x $depth;
    $depth++;
    my $tag = $self->tag;
    printf( STDOUT "${prefix} Tag '$tag' has %d children.\n", $self->children->length ) if( $self->children->length );
    my %esc = (
        "\a" => "\\a",
        "\b" => "\\b",
        "\t" => "\\t",
        "\n" => "\\n",
        "\f" => "\\f",
        "\r" => "\\r",
        "\e" => "\\e",
    );
    $self->children->foreach(sub
    {
        my $e = shift( @_ );
        my $str = $e->original->scalar;
        $str =~ s/([\a\b\t\n\f\r\e])/$esc{$1}/gs;
        $str =~ s/([\0-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;
        $str =~ s/([\0-\037\177-\377])/sprintf('\\x%02X',ord($1))/eg;
        $str =~ s/([^\040-\176])/sprintf('\\x{%X}',ord($1))/eg;
        print( STDOUT "${prefix}. ${str}\n" );
        $e->dump( $depth ) if( !$e->is_empty || $e->children->length );
    });
    return( $self );
}

sub eid { return( shift->{eid} ); }

# Returns self, but is overriden in HTML::Object::Collection
# See <https://api.jquery.com/end/#end>
sub end { return( shift( @_ ) ); }

sub extract_links
{
    my $self = shift( @_ );
    my @tags = @_;
    for( @tags )
    {
        $_ = lc( $_ );
    }
    my $wants = {};
    @$wants{ @tags } = (1) x scalar( @tags );
    my $has_expectation = scalar( keys( %$wants ) );
    my $a = $self->new_array;
    my $crawl;
    my $seen = {};
    $crawl = sub
    {
        my $kids = shift( @_ );
        $kids->foreach(sub
        {
            my $e = shift( @_ );
            my $def;
            my $tag = $e->tag;
            $def = $HTML::Object::LINK_ELEMENTS->{ "$tag" } if( exists( $HTML::Object::LINK_ELEMENTS->{ "$tag" } ) );
            # return(1) if( !defined( $def ) );
            # return(1) if( $has_expectation && !exists( $wants->{ "$tag" } ) );
            if( defined( $def ) && 
                (
                    !$has_expectation || 
                    ( $has_expectation && !exists( $wants->{ "$tag" } ) )
                ) )
            {
                foreach my $attr ( @$def )
                {
                    my $val;
                    if( $e->attributes->exists( $attr ) && length( $val = $e->attributes->get( $attr ) ) )
                    {
                        $a->push( $self->new_hash({
                            attribute => $attr,
                            element   => $e,
                            tag       => $tag,
                            value     => $val,
                        }) );
                    }
                }
            }
            my $addr = Scalar::Util::refaddr( $e );
            if( ++$seen->{ $addr } > 1 )
            {
                return(1);
            }
            $crawl->( $e->children );
            return(1);
        });
    };
    $crawl->( $self->children );
    return( $a );
}

# Note: HTML::Element compatibility
# sub find { return( shift->find_by_tag_name( @_ ) ); }
# find() is a xpath method

sub find_by_attribute
{
    my $self = shift( @_ );
    my( $att, $val ) = @_;
    $att = lc( $att );
    return( $self->error( "No attribute was provided." ) ) if( !length( $att ) );
    my $a = $self->new_array;
    $a->push( $self ) if( $self->attributes->exists( $att ) && $self->attributes->get( $att ) eq $val );
    my $crawl;
    $crawl = sub
    {
        my $elems = shift( @_ );
        $elems->foreach(sub
        {
            my $e = shift( @_ );
            return(1) if( $e->class ne 'HTML::Object::Element' );
            $a->push( $e ) if( $e->attributes->exists( $att ) && $e->attributes->get( $att ) eq $val );
            $crawl->( $e->children ) if( $e->children->length > 0 );
        });
    };
    $crawl->( $self->children ) if( $self->children->length > 0 );
    return( $a );
}

sub find_by_tag_name
{
    my $self = shift( @_ );
    my @tags = @_;
    for( @tags )
    {
        $_ = lc( $_ );
    }
    my $tags = {};
    @$tags{ @tags } = (1) x scalar( @tags );
    my $a = $self->new_array;
    $a->push( $self ) if( exists( $tags->{ $self->tag } ) );
    my $crawl;
    $crawl = sub
    {
        my $elems = shift( @_ );
        $elems->foreach(sub
        {
            my $e = shift( @_ );
            # return(1) if( $e->class ne 'HTML::Object::Element' );
            return(1) if( !$self->_is_a( $e => 'HTML::Object::Element' ) );
            $a->push( $e ) if( exists( $tags->{ $e->tag } ) );
            $crawl->( $e->children ) if( $e->children->length > 0 );
        });
    };
    $crawl->( $self->children ) if( $self->children->length > 0 );
    return( $a );
}

sub has_children { return( shift->children->is_empty ? 0 : 1 ); }

sub id : lvalue { return( shift->_set_get_id( @_ ) ); }

# Note: Similar to HTML::ELement, but not quite, because we have no concept of pos(), so this just add to the stack of children
sub insert_element
{
    my $self = shift( @_ );
    my $e = shift( @_ ) || return( $self->error( "No html element was provided to insert." ) );
    return( $self->error( "Element provided (", overload::StrVal( $e ), ") is not an object." ) ) if( !$self->_is_object( $e ) );
    return( $self->error( "Element provided (", overload::StrVal( $e ), ") is not an HTML::Object::Element." ) ) if( !$e->isa( 'HTML::Object::Element' ) );
    $self->push_content( $e );
    $self->reset(1);
    return( $e );
}

# Used to store arbitrarily data for internal purpose
sub internal { return( shift->reset(@_)->_set_get_hash_as_mix_object( '_internal', @_ ) ); }

sub is_closed { return( shift->reset(@_)->_set_get_boolean( 'is_closed', @_ ) ); }

# Note: Different from HTML::Element in that this is a flag derived from the dictionary. To get the equivalent, one must use has_children()
sub is_empty { return( shift->reset(@_)->_set_get_boolean( 'is_empty', @_ ) ); }

sub is_valid_attribute { return( $_[1] =~ /^$ATTRIBUTE_NAME_RE$/ ? 1 : 0 ); }

sub is_void { return( shift->reset(@_)->is_empty( @_ ) ); }

# Note: Compatibility with HTML::Element
sub left
{
    my $self = shift( @_ );
    my $offset = @_ ? int( shift( @_ ) ) : 0;
    my $pos  = $self->pos;
    # We return empty if we could not find our object within our parent's children; or
    # the requested offset position is higher than the position of our object
    return( $self->new_array ) if( !defined( $pos ) || $offset > $pos );
    my $kids = $self->parent->children;
    # I am my parent's only child; no need to bother
    return( $self->new_array ) if( $kids->length == 1 );
    # We use position as offset length which will put us right before our own element
    return( $kids->offset( $offset, ( $pos - $offset ) ) );
}

sub line { return( shift->_set_get_number_as_object( 'line', @_ ) ); }

# Note: HTML::Element compatibility
sub lineage
{
    my $self = shift( @_ );
    my $parent = $self;
    my $lineage = $self->new_array;
    while( $parent = $parent->parent )
    {
        $lineage->push( $parent );
    }
    return( $lineage );
}

sub lineage_tag_names
{
    my $self = shift( @_ );
    my $a = $self->new_array;
    my $parent = $self;
    while( $parent = $parent->parent )
    {
        $a->push( $parent->tag->scalar );
    }
    return( $a );
}

sub look
{
    my $self = shift( @_ );
    my $opts = {};
    $opts    = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $p = [];
    for( my $i = 0; $i < scalar( @_ ); )
    {
        if( ref( $_[$i] ) )
        {
            return( $self->error( "Reference provided (", overload::StrVal( $_[$i] ), "), but the only reference I accept is code reference." ) ) if( ref( $_[$i] ) ne 'CODE' );
            push( @$p, $_[ $i++ ] );
        }
        else
        {
            push( @$p, {
                key => $_[$i],
                val => $_[$i + 1],
            });
            $i += 2;
        }
    }
    my $a = $self->new_array;
    my( $check_elem, $crawl_down );
    $check_elem = sub
    {
        my $e = shift( @_ );
        my $def = shift( @_ );
        my $attr = $e->attributes;
        # Assume ok, then check otherwise
        my $ok = 1;
        foreach my $this ( @$p )
        {
            if( ref( $this ) eq 'CODE' )
            {
                local $_ = $e;
                my $rc = $this->( $e );
                $ok = 0, last if( !$rc );
            }
            else
            {
                if( $this->{key} eq '_tag' )
                {
                    if( ref( $this->{val} ) eq 'Regexp' )
                    {
                        $ok = 0, last if( $e->tag !~ /$this->{val}/ );
                    }
                    else
                    {
                        $ok = 0, last if( $e->tag ne $this->{val} );
                    }
                }
                elsif( !$attr->exists( $this->{key} ) )
                {
                    if( !defined( $this->{val} ) )
                    {
                        # Good to go; the user searches for an attribute with an undefined value
                        # in other term, the user wants an element whose attribute does not exist
                    }
                    else
                    {
                        $ok = 0, last;
                    }
                }
                else
                {
                    my $val = $attr->get( $this->{key} );
                    if( defined( $val ) )
                    {
                        if( ref( $this->{val} ) eq 'Regexp' )
                        {
                            $ok = 0, last if( $val !~ /$this->{val}/ );
                        }
                        elsif( (
                            ref( $this->{val} ) &&
                            ref( $this->{val} ) ne ref( $val )
                            ) ||
                            (
                                ( !ref( $val ) || overload::Method( $val. '""' ) ) && 
                                lc( "$val" ) ne lc( "$this->{val}" )
                            ) )
                        {
                            $ok = 0, last;
                        }
                    }
                    else
                    {
                        $ok = 0, last if( defined( $this->{val} ) );
                    }
                }
            }
        }
        
        # We passed all checks, no checking our children
        $a->push( $e ) if( $ok );
        # Stop here since we reached the maximum number of matches
        return if( CORE::exists( $opts->{max_match} ) && $a->length >= $opts->{max_match} );
        # Don't go down or up further if we reached the maximum level
        return(1) if( CORE::exists( $opts->{max_level} ) && ( $def->{level} + 1 ) > $opts->{max_level} );
        $def->{level}++;
        if( $opts->{direction} eq 'down' )
        {
            $crawl_down->( $e->children, $def ) if( $e->children->length > 0 );
        }
        elsif( $opts->{direction} eq 'up' )
        {
            $check_elem->( $e->parent ) if( $e->parent );
        }
        $def->{level}--;
        return(1);
    };
    
    $crawl_down = sub
    {
        my $kids = shift( @_ );
        my $def = shift( @_ );
        # $kids->foreach( $check_elem );
        $kids->foreach(sub
        {
            $check_elem->( $_, $def );
        });
    };
    
    my $def = { level => 0 };
    $check_elem->( $self, $def );
    # return( $a->length > 0 ? $a : '' );
    return( $a );
}

sub look_down
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{direction} = 'down';
    return( $self->look( @_, $opts ) );
}

sub look_up
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{direction} = 'up';
    return( $self->look( @_, $opts ) );
}

sub looks_like_html { return( $_[1] =~ /$LOOK_LIKE_HTML/ ? 1 : 0 ); }

# sub looks_like_it_has_html { return( $_[1] =~ /$LOOK_LIKE_IT_HAS_HTML/ ? 1 : 0 ); }
sub looks_like_it_has_html
{
    my $self = shift( @_ );
    return( $_[0] =~ /$LOOK_LIKE_IT_HAS_HTML/ ? 1 : 0 );
}

sub modified { return( shift->_set_get_boolean( 'modified', @_ ) ); }

sub new_attribute
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::Attribute' ) || return( $self->pass_error );
    my $att = HTML::Object::Attribute->new( @_ ) ||
        return( $self->pass_error( HTML::Object::Attribute->error ) );
    return( $att );
}

sub new_closing
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::Closing' ) || return( $self->pass_error );
    my $e = HTML::Object::Closing->new( @_ ) ||
        return( $self->pass_error( HTML::Object::Closing->error ) );
    return( $e );
}

sub new_document
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::Document' ) || return( $self->pass_error );
    my $e = HTML::Object::Document->new( debug => $self->debug ) ||
        return( $self->pass_error( HTML::Object::Document->error ) );
    return( $e );
}

sub new_element
{
    my $self = shift( @_ );
    my $tag  = shift( @_ ) || return( $self->error( "No tag was provided to create an element." ) );
    my $dict = HTML::Object->get_definition( $tag ) || return( $self->pass_error( HTML::Object->error ) );
    my $e = HTML::Object::Element->new({
        is_empty    => $dict->{is_empty},
        tag         => $dict->{tag},
        debug       => $self->debug,
    }) || return( $self->pass_error( HTML::Object::Element->error ) );
    return( $e );
}

sub new_from_lol
{
    my $self = shift( @_ );
    my $a = $self->new_array;
    my @args = @_;
    my $crawl;
    $crawl = sub
    {
        my $ref = shift( @_ );
        my $parent;
        $parent = shift( @_ ) if( scalar( @_ ) );
        my $elem;
        foreach my $this ( @$ref )
        {
            if( $self->_is_array( $this ) )
            {
                my $e = $crawl->( $this, ( $elem // $parent ) ) || return;
                if( defined( $elem ) || defined( $parent ) )
                {
                    $e->parent( $elem // $parent );
                    ( $elem // $parent )->children->push( $e );
                }
            }
            elsif( $self->_is_hash( $this ) )
            {
                return( $self->error( "Hash of attributes set found before tag name definition" ) ) if( !defined( $elem ) );
                $elem->attributes( $this );
            }
            elsif( $self->_is_object( $this ) && $this->isa( 'HTML::Object::Element' ) )
            {
                my $custodian = ( $elem // $parent );
                my $e = $this->parent ? $this->clone : $this;
                return( $self->error( "Found an element object \"", $e->tag, "\" to add to the tree, but no parent was provided nor any element was initiated yet." ) ) if( !defined( $custodian ) );
                $e->parent( $custodian );
                $custodian->children->push( $e );
            }
            else
            {
                return( $self->error( "Found an object ($this), but I do not know what to do with it." ) ) if( $self->_is_object( $this ) && ( !overload::Overloaded( $this ) || ( overload::Overloaded( $this ) && !overload::Method( $this => '""' ) ) ) );
                # This is the element tag name
                if( !defined( $elem ) && "$this" =~ /^\w+$/ )
                {
                    $elem = $self->new_element( "$this" ) || return;
                    if( defined( $parent ) )
                    {
                        $elem->parent( $parent );
                        $parent->children->push( $elem );
                    }
                }
                # Text node added as a child
                else
                {
                    my $custodian = ( $elem // $parent );
                    return( $self->error( "Found a text to add to the tree, but no parent was provided nor any element was initiated yet." ) ) if( !defined( $custodian ) );
                    my $t = $self->new_text( "$this" ) || return;
                    $t->parent( $custodian );
                    $custodian->children->push( $t );
                }
            }
        }
        return( $elem );
    };
    
    foreach my $this ( @args )
    {
        return( $self->error( "I was expecting an array reference, but instead got '$this'." ) ) if( !$self->_is_array( $this ) );
        # There are more than one elements provided in this array definition, i.e. multiple html tags at the top level
        # so we create a special document html element to contain them
        if( scalar( @$this ) > 0 )
        {
            my $doc = $self->new_document || return;
            $crawl->( $this => $doc ) || return;
            $a->push( $doc );
        }
        else
        {
            my $e = $crawl->( $this ) || return;
            $a->push( $e );
        }
    }
    return( $a );
}

sub new_parser
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object' ) || return( $self->pass_error );
    my $p = HTML::Object->new( debug => $self->debug ) ||
        return( $self->pass_error( HTML::Object->error ) );
    return( $p );
}

sub new_text
{
    my $self = shift( @_ );
    my $p = {};
    if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
    {
        $p = shift( @_ );
    }
    else
    {
        $p->{value} = join( '', @_ );
    }
    $p->{debug} = $self->debug;
    $self->_load_class( 'HTML::Object::Text' ) || return( $self->pass_error );
    my $e = HTML::Object::Text->new( $p ) ||
        return( $self->pass_error( HTML::Object::Text->error ) );
    return( $e );
}

# TODO: next()

# Note: HTML::Element compatibility
sub normalize_content
{
    my $self = shift( @_ );
    my $children = $self->children;
    my $new = $self->new_array;
    my $prev;
    $children->foreach(sub
    {
        if( ( defined( $_ ) && $self->_is_a( $_ => 'HTML::Object::Text' ) && defined( $prev ) && $self->_is_a( $prev => 'HTML::Object::Text' ) ) ||
            ( defined( $_ ) && $self->_is_a( $_ => 'HTML::Object::Space' ) && defined( $prev ) && $self->_is_a( $prev => 'HTML::Object::Space' ) ) )
        {
            $prev->value->append( $_->value );
            return(1);
        }
        $prev = $_;
        $new->push( $_ );
    });
    $self->children( $new );
    return( $self );
}

sub offset { return( shift->reset(@_)->_set_get_number_as_object( 'offset', @_ ) ); }

sub original { return( shift->_set_get_scalar_as_object( 'original', @_ ) ); }

sub parent { return( shift->_set_get_object_without_init( 'parent', 'HTML::Object::Element', @_ ) ); }

# Note: Different from the one in HTML::Element
sub pos
{
    my $self = shift( @_ );
    my $parent = $self->parent;
    return( $self->new_null ) if( !$parent );
    my $kids = $parent->children;
    #my $id   = $self->eid;
    #my( $pos ) = grep{ $kids->[$_]->eid eq $id } 0..$#$kids;
    #return( $pos );
    return( $kids->pos( $self ) );
}

sub pindex { return( shift->pos( @_ ) ); }

# TODO: previous()

# Note: HTML::Element compatibility
sub postinsert
{
    my $self = shift( @_ );
    my $parent = $self->parent;
    return( $self->error( "Element has no parent." ) ) if( !$parent );
    my $pos = $parent->children->pos( $self );
    return( $self->error( "Element is not found among parent's children elements." ) ) if( !defined( $pos ) );
    my $new = $self->_get_elements_list( @_ ) || return( $self->pass_error );
    $new->foreach(sub
    {
        $_->detach if( $_->parent );
        $_->parent( $parent );
    });
    $parent->children->splice( $pos + 1, 0, $new->list );
    $parent->reset(1);
    return( $self );
}

# Note: HTML::Element compatibility
sub preinsert
{
    my $self = shift( @_ );
    my $parent = $self->parent;
    return( $self->error( "Element has no parent." ) ) if( !$parent );
    my $pos = $parent->children->pos( $self );
    return( $self->error( "Element is not found among parent's children elements." ) ) if( !defined( $pos ) );
    my $new = $self->_get_elements_list( @_ ) || return( $self->pass_error );
    $new->foreach(sub
    {
        $_->detach if( $_->parent );
        $_->parent( $parent );
    });
    $parent->children->splice( $pos, 0, $new->list );
    $parent->reset(1);
    return( $self );
}

# Note: HTML::Element compatibility
sub push_content
{
    my $self = shift( @_ );
    return( $self ) unless( @_ );
    my $children = $self->children;
    my $new = $self->_get_elements_list( @_ ) || return( $self->pass_error );
    $new->foreach(sub
    {
        $_->detach if( $_->parent );
        $_->parent( $self );
        $children->push( $_ );
    });
    $self->reset(1);
    return( $self );
}

# Note: HTML::Element compatibility
sub replace_with
{
    my $self = shift( @_ );
    my $parent = $self->parent;
    return( $self->error( "Element has no parent." ) ) if( !$parent );
    my $pos = $parent->children->pos( $self );
    return( $self->error( "Element is not found among parent's children elements." ) ) if( !defined( $pos ) );
    my $new = $self->_get_elements_list( @_ ) || return( $self->pass_error );
    $new->foreach(sub
    {
        $_->detach if( $_->parent );
        $_->parent( $parent );
    });
    $parent->children->splice( $pos, 1, $new->list );
    $parent->reset(1);
    return( $self );
}

sub replace_with_content
{
    my $self = shift( @_ );
    my $parent = $self->parent;
    my $children = $self->children;
    return( $self->error( "This element has no parent." ) ) if( !$parent );
    my $pos = $parent->children->pos( $self );
    return( $self->error( "Unable to find the current element among its parent's children." ) ) if( !defined( $pos ) );
    $children->foreach(sub
    {
        $_->parent( $parent );
    });
    $parent->splice( $pos, 1, $children->list );
    $self->parent( undef() );
    $parent->reset(1);
    return( $self );
}

sub reset
{
    my $self = shift( @_ );
    if( !CORE::length( $self->{_reset} ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
        if( my $parent = $self->parent )
        {
            $parent->reset(1);
        }
    }
    return( $self );
}

# Note: HTML::Element compatibility
sub right
{
    my $self = shift( @_ );
    my $parent = $self->parent;
    return( $self->new_null ) if( !$parent );
    my $kids = $parent->children;
    my $pos  = $self->pos;
    my $offset = @_ ? int( shift( @_ ) ) : $kids->size;
    return( $self->new_array ) if( !defined( $pos ) || $offset < $pos );
    return( $self->new_array ) if( $kids->length == 1 );
    # my $results = $kids->offset( $pos + 1, ( $offset - $pos ) );
    return( $kids->offset( $pos + 1, ( $offset - $pos ) ) );
}

# Note: HTML::Element compatibility
sub root
{
    my $self = shift( @_ );
    my $root = $self;
    my $parent;
    while( $parent = $root->parent )
    {
        $root = $parent;
    }
    # Typically a HTML::Object::Document
    return( $root );
}

sub same_as
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error( "No element object was provided to compare against." ) );
    return( $self->error( "Element provided (", overload::StrVal( $elem ), ") is not an object." ) ) if( !$self->_is_object( $elem ) );
    return( $self->error( "Element provided (", overload::StrVal( $elem ), ") is not an HTML::Object::Element object." ) ) if( !$elem->isa( 'HTML::Object::Element' ) );
    my $my_attr  = $self->attributes->keys->sort;
    my $her_attr = $elem->attributes->keys->sort;
    return(0) unless( $my_attr eq $her_attr );
    $my_attr->foreach(sub
    {
        return(0) if( $self->attributes->get( $_ ) ne $elem->attributes->get( $_ ) );
    });
    return(0) if( $self->children->length != $elem->children->length );
    my $her_kids = $elem->children;
    $self->children->for(sub
    {
        my( $i, $e ) = @_;
        return(0) if( !$e->same_as( $her_kids->[$i] ) );
    });
    return(1);
}

sub set_checksum
{
    my $self = shift( @_ );
    my $tag  = $self->_tag;
    my $a = $self->new_array( [$tag] );
    $self->attributes_sequence->foreach(sub
    {
        my $attr = shift( @_ );
        $a->push( $self->attributes->get( $attr ) );
    });
    return( $self->_get_md5_hash( $a->join( ';' )->scalar ) );
}

# Note: HTML::Element compatibility
sub splice_content
{
    my $self = shift( @_ );
    my $offset = shift( @_ );
    my $length = shift( @_ );
    return( $self ) unless( @_ );
    return( $self->error( "Offset value provided '$offset' is not an integer." ) ) if( !$self->_is_integer( $offset ) );
    return( $self->error( "Length value provided '$length' is not an integer." ) ) if( !$self->_is_integer( $length ) );
    my $children = $self->children;
    my $new = $self->_get_elements_list( @_ ) || return( $self->pass_error );
    $new->foreach(sub
    {
        $_->detach if( $_->parent );
        $_->parent( $self );
    });
    $children->splice( $offset, $length, $new->list );
    $self->reset(1);
    return( $self );
}

sub tag { return( shift->reset(@_)->_set_get_scalar_as_object( 'tag', @_ ) ); }

# Note: HTML::Element compatibility
sub traverse
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No code provided to traverse the html tree." ) );
    return( $self->error( "The argument provided (", overload::StrVal( $code ), ") is not an anonymous subroutine." ) ) if( ref( $code ) ne 'CODE' );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{bottom_up} //= 0;
    my $seen = {};
    my $crawl;
    $crawl = sub
    {
        my $e = shift( @_ );
        my $addr = Scalar::Util::refaddr( $e );
        # Duplicate
        return if( ++$seen->{ $addr } > 1 );
        local $_ = $e;
        $code->( $e ) unless( $opts->{bottom_up} );
        $e->children->foreach(sub
        {
            $crawl->( $_[0] );
        });
        $code->( $e ) if( $opts->{bottom_up} );
    };
    $crawl->( $self );
    return( $self );
}

# Note: HTML::Element compatibility
sub unshift_content
{
    my $self = shift( @_ );
    return( $self ) unless( @_ );
    my $children = $self->children;
    my $new = $self->_get_elements_list( @_ ) || return( $self->pass_error );
    $new->foreach(sub
    {
        $_->parent( $self );
    });
    $children->splice( 0, 0, $new->list );
    $self->reset(1);
    return( $self );
}

# called on a parent, with a child as second argument and its rank as third
# returns the child if it is already an element, or
# a new HTML::Object::Text element if it is a plain string
sub _child_as_object
{
    my( $self, $elt_or_text, $rank ) = @_;
    return unless( defined( $elt_or_text ) );
    if( !ref( $elt_or_text ) )
    {
        require HTML::Object::Text;
        # $elt_or_text is a string, turn it into a TextNode object
        $elt_or_text = HTML::Object::Text->new(
            parent  => $self,
            value   => $elt_or_text,
        );
    }
    warn( "rank is a ", ref( $rank ), " elt_or_text is a ", ref( $elt_or_text ) ) if( ref( $rank ) && !$self->_is_a( $rank, 'Module::Generic::Number' ) ); 
    # used for sorting
    $elt_or_text->rank( $rank );
    return( $elt_or_text );
}

sub _generate_uuid
{
    return( lc( Data::UUID->new->create_str ) );
}

sub _get_elements_list
{
    my $self = shift( @_ );
    my $new = $self->new_array;
    my $seen = {};
    my $prev;
    my $self_addr = Scalar::Util::refaddr( $self );
    my $parent_addr;
    my $parent = $self->parent;
    $parent_addr = Scalar::Util::refaddr( $parent ) if( defined( $parent ) );
    for( @_ )
    {
        return( $self->error( "Replacement element is not an HTML::Object::Element" ) ) if( !$self->_is_a( $_ => 'HTML::Object::Element' ) );
        my $addr = Scalar::Util::refaddr( $_ );
        if( ++$seen->{ $addr } > 1 )
        {
            warnings::warn( "Warnings only: found duplicate element with tag '" . $_->tag . "' provided in replace_with()\n" ) if( warnings::enabled( 'HTML::Object' ) );
            next;
        }
        return( $self->error( "Replacement list contains a copy of target!" ) ) if( $self_addr eq $addr );
        return( $self->error( "Cannot replace an item with its parent!" ) ) if( defined( $parent_addr ) && $addr eq $parent_addr );
        if( ( $_->isa( 'HTML::Object::Text' ) && defined( $prev ) && $prev->isa( 'HTML::Object::Text' ) ) ||
            ( $_->isa( 'HTML::Object::Space' ) && defined( $prev ) && $prev->isa( 'HTML::Object::Space' ) ) )
        {
            $prev->value->append( $_->value );
            next;
        }
        $new->push( $_ );
        $prev = $_;
    }
    return( $new );
}

# Used by after, append, before
sub _get_from_list_of_elements_or_html
{
    my $self = shift( @_ );
    my $list = $self->new_array;
    my $prev;
    foreach my $this ( @_ )
    {
        if( $self->_is_a( $this => 'HTML::Object::Element' ) )
        {
            if( $self->_is_a( $this => 'HTML::Object::DOM::DocumentFragment' ) )
            {
                my $clone = $this->children->clone;
                $list->push( $clone->list );
                $this->children->reset;
                undef( $prev );
            }
            elsif( $self->_is_a( $this => 'HTML::Object::Text' ) )
            {
                if( defined( $prev ) && $self->_is_a( $prev => 'HTML::Object::Text' ) )
                {
                    $prev->value->append( $this->value );
                }
                else
                {
                    my $clone = $this->clone;
                    $list->push( $clone );
                    $prev = $clone;
                }
            }
            else
            {
                my $clone = $this->clone;
                $list->push( $clone );
                # $list->push( $clone->close_tag ) if( $clone->close_tag );
                undef( $prev );
            }
        }
        else
        {
            if( ref( $this ) && ( !$self->_is_object( $this ) || ( $self->_is_object( $this ) && !overload::Method( $this, '""' ) ) ) )
            {
                return( $self->error( "I was expecting some HTML data, but got '", overload::StrVal( $this ), "'" ) );
            }
            
            # if( "$this" =~ /$LOOK_LIKE_HTML/ )
            # LOOK_LIKE_HTML check for html tag starting at the beginning of the string
            # LOOK_LIKE_IT_HAS_HTML checks for tag anywhere
            if( "$this" =~ /$LOOK_LIKE_IT_HAS_HTML/ )
            {
                my $p = $self->new_parser( debug => 4 );
                my $res = $p->parse_data( "$this" ) || 
                    return( $self->error( "Error while parsing html data provided: ", $p->error ) );
                $list->push( $res->children->list ) if( !$res->children->is_empty );
            }
            # Maybe just some text provided, and in that case, the parser would return nothing unfortunately
            else
            {
                if( defined( $prev ) && $self->_is_a( $prev => 'HTML::Object::Text' ) )
                {
                    $prev->value->append( "$this" );
                }
                else
                {
                    my $e = $self->new_text({ value => "$this" });
                    $list->push( $e );
                    $prev = $e;
                }
            }
        }
    }
    return( $list );
}

sub _get_md5_hash
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    return( $self->error( "No data was provided to compute a md5 hash." ) ) if( !defined( $data ) || !length( "$data" ) );
    # try-catch
    local $@;
    my $rv = eval
    {
        return( Digest::MD5::md5_hex( Encode::encode( 'utf8', $data, Encode::FB_CROAK ) ) );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while calculating the md5 hash for tag \"", $self->tag, "\": $@" ) );
    }
    return( $rv );
}

# For other modules to use
sub _is_reset { return( CORE::length( shift->{_reset} ) ); }

# For other modules to use
sub _remove_reset { return( CORE::delete( shift->{_reset} ) ); }

# Method shared with HTML::Object::XQuery
sub _set_get_id : lvalue { return( shift->_set_get_callback({
    get => sub
    {
        my $self = shift( @_ );
        my $id = $self->new_scalar( $self->attributes->get( 'id' ) );
        return( $id );
    },
    set => sub
    {
        my $self = shift( @_ );
        my $id = shift( @_ );
        if( !defined( $id ) || !CORE::length( $id ) )
        {
            if( $self->attributes->exists( 'id' ) )
            {
                $self->attributes->delete( 'id' );
                $self->attributes_sequence->remove( 'id' );
                $self->reset(1);
                return(1);
            }
            return(0);
        }
        else
        {
            $self->attributes->set( id => $id );
            $self->reset(1);
            return(1);
        }
    }
}, @_ ) ); }

sub _same_as
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return(0) if( !defined( $this ) || ( defined( $this ) && !$self->_is_a( $this, 'HTML::Object::Element' ) ) );
    return( $self->eid CORE::eq $this->eid ? 1 : 0 );
}

# Used to register callbacks for some properties like rel, sizes, controlslist that we trigger and that update the attribute's HTML::Object::TokenList
sub _set_get_internal_attribute_callback
{
    my $self = shift( @_ );
    $self->{_internal_attribute_callbacks} = {} if( ref( $self->{_internal_attribute_callbacks} ) ne 'HASH' );
    my $ref = $self->{_internal_attribute_callbacks};
    # get mode
    if( scalar( @_ ) == 1 )
    {
        my $attr = shift( @_ );
        return( $ref->{ $attr } );
    }
    elsif( scalar( @_ ) )
    {
        return( $self->error( "Odd number of parameters for attribute callback assignment." ) ) if( ( @_ % 2 ) );
        for( my $i = 0; $i < scalar( @_ ); $i += 2 )
        {
            $ref->{ $_[ $i ] } = $_[ $i + 1 ];
        }
        return( $self );
    }
    return;
}

# A private method for internal use when the tag method has been overriden for example as it is the case in HTML::Object::XQuery
sub _tag { return( shift->reset(@_)->_set_get_scalar_as_object( 'tag', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Element - HTML Element Object

=head1 SYNOPSIS

    use HTML::Object::Element;
    my $this = HTML::Object::Element->new ||
        die( HTML::Object::Element->error, "\n" );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This interface implement a core element for L<HTML::Object> parser. An element can be one or more space, a text, a tag, a comment, or a document, all of the above inherit from this core interface.

For a more elaborate interface and a close implementation of the Web Document Object Model (a.k.a. DOM), see L<HTML::Object::DOM::Element> and the L<DOM parser|HTML::Object::DOM>

=head1 METHODS

=for Pod::Coverage add

=for Pod::Coverage addClass

=for Pod::Coverage appendTo

=for Pod::Coverage align

=for Pod::Coverage compact

=for Pod::Coverage crossOrigin

=for Pod::Coverage currentSrc

=for Pod::Coverage defaultValue

=for Pod::Coverage download

=for Pod::Coverage form

=for Pod::Coverage hash

=for Pod::Coverage host

=for Pod::Coverage hostname

=for Pod::Coverage href

=for Pod::Coverage hreflang

=for Pod::Coverage origin

=for Pod::Coverage password

=for Pod::Coverage pathname

=for Pod::Coverage port

=for Pod::Coverage protocol

=for Pod::Coverage referrerPolicy

=for Pod::Coverage rel

=for Pod::Coverage relList

=for Pod::Coverage search

=for Pod::Coverage setCustomValidity

=for Pod::Coverage target

=for Pod::Coverage useMap

=for Pod::Coverage username

=head2 address

This method is purely for compatibility with L<HTML::Element/address>. Please, refer to its documentation for its use.

=head2 all_attr

Returns an hash (B<not> an hash reference) of the element's attributes as a key-value pairs.

This is provided in compatibility with C<HTML::Element>

    my %attributes = $e->all_attr;

=head2 all_attr_names

Returns a list of all the element's attributes in no particular order.

    my @attributes = $e->all_attr_names;

=head2 as_html

This is an alias for L</as_string>

=head2 as_string

Returns a string representation of the current element and its underlying descendants.

If a cached version of that string exists, it is returned instead.

=head2 as_text

Returns a string representation of the text content of the current element and its descendant.

If a cached version of that string exists, it is returned instead.
 
It takes an optional hash or hash reference of parameters:

=over 4

=item * C<callback>

This is a callback subroutine reference of anonymous subroutine. It is called for each textual element found and is passed as its sole argument, the element object.

=item * C<unescape>

Boolean. If true, the value of textual elements found will be unescaped before being returned. This means that C<< &lt; >> will be converted back to C<< < >> and C<< &gt; >> to C<< > >> and C<< <br > >> followed by a new line will be removed to only leave the new line.

=back

See also L<HTML::Object::DOM::Element/innerText>, L<HTML::Object::Node/textContent> and L<HTML::Object::XQuery/text>

=head2 as_trimmed_text

Return the value returned by L</as_text>, only its leading and trailing spaces, if any, are trimmed.

=head2 as_xml

This is merely an alias for L<as_string>

=head2 attr

Provided with an attribute C<name> and this will return it. If an attribute C<value> is also provided, it will set or replace the attribute valu accordingly. If that attribute value provided is C<undef>, this will remove the attribute altogether.

=head2 attributes

Returns an L<hash object|Module::Generic::Hash> of all the attributes key-value pairs.

Be careful this is a 'live' object, and if you make change to it directly, you could damage the hierarchy or introduce errors.

=head2 attributes_sequence

Returns an L<array object|Module::Generic::Array> containing the attribute names in their order of appearance.

=head2 checksum

Returns the element checksum, used to determine if any change was made.

=head2 children

Returns an L<array object|Module::Generic::Array> containing all the element's children.

=head2 class

Returns this element class, e.g. C<HTML::Object::Element> or C<HTML::Object::Document>

=head2 clone

Returns a copy of the current element, and recursively all of its descendants,

The cloned element, that is returned, has no parent.

=head2 clone_list

Clone all the element children and return a new L<array object|Module::Generic::Array> of the cloned children.

This is quite different from C<HTML::Element> equivalent that is accessed as a class method and takes an arbitrary list of elements.

=head2 close

Close the current tag, if necessary. It returns the current object upon success, or C<undef> upon error and sets an L<error|Module::Generic/error>

=head2 close_tag

Set or get a L<closing element object|HTML::Object::Closing> that is used to close the current element.

=head2 column

Returns the column at which this element was found in the original HTML text string, by the L<parser|HTML::Object>.

=head2 content

This is an alias for L</children>. It returns an L<array object|Module::Generic::Array> of the current element's children objects.

=head2 content_array_ref

This is an alias for L</children>. It returns an L<array object|Module::Generic::Array> of the current element's children objects.

This is provided in compatibility with C<HTML::Element>

=head2 content_list

In list context, this returns the list of the curent element's children, if any, and in scalar context, this returns the number of children elements it contains.

This is provided in compatibility with C<HTML::Element>

=head2 delete

Remove all of its content by calling L</delete_content>, detach the current object, and destroy the object.

=head2 delete_content

Remove the content, i.e. all the children, of the current element, effectively calling L</delete> on each one of them.

It returns the current element.

=head2 delete_ignorable_whitespace

Does not do anything by design. There is no much value into this method under L<HTML::Object> in the first place.

=head2 depth

Returns an L<integer|Module::Generic::Number> representing the depth level of the current element in the hierarchy.

=head2 descendants

Returns an L<array object|Module::Generic::Array> of all the element's descendants throughout its hierarchy.

=head2 destroy

An alias for L</delete>

=head2 destroy_content

An alias for L</delete_content>

=head2 detach

This method takes no parameter and removes the current element from its parent's list of children element, and unset its parent object value.

It returns the element parent object.

=head2 detach_content

This method takes no argument and will remove the parent value for each of its children, set the children list for the current element to an empty list and return the list of those children elements thus removed.

    my @removed = $e->detach_content;

This is provided in compatibility with C<HTML::Element>

=head2 dump

Print out on the stdout a representation of the hierarchy of element objects.

=head2 eid

Returns the element unique id, which is automatically generated for any element. This is actually a uuid. For example:

    my $eid = $e->eid; # e.g.: 971ef725-e99b-4869-b6ac-b245794e84e2

=head2 end

Returns the current object.

Actually, I am not sure this should be here, and rather it should be in L<HTML::Object::XQuery> since it simulates jQuery.

=head2 extract_links

Returns links found by traversing the element and all of its children and looking for attributes (like C<href> in an C<<a>> element, or C<src> in an C<<img>> element) whose values represent links.

You may specify that you want to extract links from just some kinds of elements (instead of the default, which is to extract links from all the kinds of elements known to have attributes whose values represent links). For instance, if you want to extract links from only C<<a>> and C<<img>> elements, you could code it like this:

    my $links = $elem->extract_links( qw( a img ) ) ||
        die( $elem->error );
    foreach( @$links )
    {
        say "Hey, there is a ", $_->{tag}, " that links to ", $_->{value}, "in its ", $_->{attribute}, " attribute, at ", $_->{element}->address;
    }

The dictionary definition hash reference of all tags and their attributes containing potential links is available as C<$HTML::Object::LINK_ELEMENTS>

This method returns an L<array object|Module::Generic::Array> containing L<hash objects|Module::Generic::Hash>, for each attribute of an element containing a link, with the following properties:

=over 4

=item * C<attribute>

The attribute containing the link

=item * C<element>

The L<element object|HTML::Object::Element>

=item * C<tag>

The element tag name.

=item * C<value>

The attribute value, which would typically contain the link value.

=back

Nota bene: this method has been implemented to provide similar API as L<HTML::Element> and the 2 first paragraphs of this method description are taken from this module.

=head2 find_by_attribute

Returns an L<array object|Module::Generic::Array> of all the elements (including potentially the current element itself) in the element's hierarchy who have an attribute that matches the given attribute name.

    my $list = $e->find_by_attribute( 'data-dob' );

=head2 find_by_tag_name

Returns an L<array object|Module::Generic::Array> of all the elements (including potentially the current element itself) in the element's hierarchy who matches any of the specified tag names. Tag names can be provided n case insensitive.

    my $list = $e->find_by_tag_name( qw( div p span ) );

=head2 has_children

Returns true if the current element has children, i.e. it contains other elements within itself.

=head2 id

Set or get the id HTML attribute of the element.

=head2 insert_element

Provided with an element object and this will add it to the current element's children.

It returns the current element object.

=head2 internal

Returns the internal hash of key-value paris used internally by this package. This is primarily used to handle the C<data-*> special attributes.

=head2 is_closed

Returns true if the current element has a L<closing tag|HTML::Object::Closing> that is accessible with L</close_tag>

=head2 is_empty

Returns true if this is an element who, by HTML standard, does not contain any other elements, and false otherwise.

To check if the element has children, use L</has_children>

=head2 is_inside

Provided with a list of tag names or element objects, and this will check if the current element is contained in any of the element objects, or elements whose tag name is provided. It returns true if it is contained, or false otherwise.

Example:

    say $e->is_inside( qw( span div ), $elem1, 'p', $elem2 ) ? 'yes' : 'no';

=head2 is_valid_attribute

Provided with an attribute name and this returns true if it is valid of false otherwise.

=head2 is_void

Returns true if, by standard, this tag is void, meaning it does not contain any children. For example: C<<br />>, C<<link />>, or C<<input />>

=head2 left

Returns an L<array object|Module::Generic::Array> of all the sibling objects before the current element.

=head2 line

Returns the line at which this element was found in the original HTML text string, by the L<parser|HTML::Object>.

=head2 lineage

Returns an L<array object|Module::Generic::Array> of the current element's parent and parent's parent up to the L<root of the hierarchy|HTML::Object::Document>

=head2 lineage_tag_names

Returns an L<array object|Module::Generic::Array> of the current element's parent tag name and parent's parent tag name up to the L<root of the hierarchy|HTML::Object::Document>

This is equivalent to:

    my $list = $self->lineage->map(sub{ $_->tag });

=head2 look

This is the method that does the heavy work for L</look_down> and L</look_up>

=head2 look_down

Provided with some criterias, and an optional hash reference of options, and this will crawl down the current element hierarchy to find any matching element.

    my $list = $e->look_down( _tag => 'div' ); # returns an Module::Generic::Array object
    my $list = $e->look_down( class => qr/\bclass_name\b/, { max_level => 3, max_match => 1 });

The options you can specify are:

=over 4

=item I<max_level>

Takes an integer that sets the maximum lower or upper level beyond which, this wil stop searching.

=item I<max_match>

Takes an integer that sets the maximum number of matches after which, this will stop recurring and return the result.

=back

There are three kinds of criteria you can specify:

=over 4

=item 1. C<attr_name>, C<attr_value>

This is used when you are looking for an element with a particular attribute name and value. For example:

    my $list = $e->look_down( id => 'hello' );

This will look for any element whose attribute C<id> has a value of C<hello>

If you want to search for an attribute that does B<not> exist, set the attribute value being searched to C<undef>

To search for a tag, use the special attribute C<_tag>. For example:

    my $list = $e->look_down( _tag => 'div' );

This will return an L<array object|Module::Generic::Array> of all the C<div> elements.

=item 2. C<attr_name>, qr//

Same as above, except the attribute value of the element being checked will be evaluated against this regular expression and if true will be added into the resulting array object.

For example:

    my $list = $e->look_down( 'data-dob' => qr/^\d{4}-\d{2}-\d{2}$/ );

This will search for all element who have an attribute C<data-dob> and with value something that looks like a date.

=item 3. \&my_check or sub{ # some code here }

Provided with a code reference (i.e. a reference to an existing subroutine, or an anonymous one), and it will be evaluated for each element found. If it returns C<undef>, C<look_down> will interrupt its crawling, and if it returns true, it will signal the need to add the element to the resulting array object of elements.

For example:

    my $list = $e->look_down(
        _tag => 'img',
        class => qr/\bactive\b/,
        sub
        {
            return( $_->attr( 'width' ) > 350 ? 1 : 0 );
        }
    );

When executing the code, the current element being evaluated will be made available via C<$_>

=back

Those criteria are called and evaluated in the order they are provided. Thus, if you specify, for example:

    my $list = $e->look_down(
        _tag => 'img',
        class => qr/\bactive\b/,
        sub
        {
            return( $_->attr( 'width' ) > 350 ? 1 : 0 );
        }
    );

Each element will be evaluated first to see if their tag is C<img> and discarded if they are not. Then, if they have a class attribute and its content match the regular expression provided, and the element gets discarded if it does not match. Finally, the code will be evaluated.

Thus, the order of the criteria is important.

It returns an L<array object|Module::Generic::Array> of all the elements found.

This is provided as a compatibility with C<HTML::Element>

=head2 look_up

Provided with some criterias, and an optional hash reference of options, and this will crawl up the current element ascendants starting with its parent to find any matching element.

The options that can be used are the same ones that for L</look_down>, i.e. C<max_level> and C<max_match>

It returns an L<array object|Module::Generic::Array> of all the elements found.

This is provided as a compatibility with C<HTML::Element>

=head2 looks_like_html

Provided with a string and this returns true if the string starts with an HTML tag, or false otherwise.

=head2 looks_like_it_has_html

Provided with a string and this returns true if the string contains HTML tags, or false otherwise.

=head2 modified

Set or get a boolean of whether the element was modified. Actually this is not used.

This returns a L<DateTime> object.

=head2 new_attribute

This creates a new L<HTML::Object::Attribute> object passing it any arguments provided, and returns the object thus created, or C<undef> if an L<error|Module::Generic/error> occurred.

=head2 new_closing

This creates a new L<HTML::Object::Closing> object passing it any arguments provided, and returns the object thus created, or C<undef> if an L<error|Module::Generic/error> occurred.

=head2 new_document

Instantiate a new L<HTML document|HTML::Object::Document>, passing it whatever argument was provided, and return the resulting object.

=head2 new_element

Instantiate a new L<element|HTML::Object::Element>, passing it whatever argument was provided, and return the resulting object.

=head2 new_from_lol

This is a legacy from C<HTML::Element>, but is not actually used.

This recursively constructs a tree of nodes.

It returns an L<array object|Module::Generic::Array> of elements.

=head2 new_parser

Instantiate a new L<parser object|HTML::Object>, passing it whatever argument was provided, and return the resulting object.

=head2 new_text

Instantiate a new L<text object|HTML::Object::Text>, passing it whatever argument was provided, and return the resulting object.

=head2 normalize_content

Check each of the current element child element and concatenate any adjacent text or space element.

It returns the current object.

=head2 offset

Returns the offset value, i.e. the byte position, at which the tag was found in the original HTML data.

=head2 original

Returns the original raw string data as it was captured initially by the parser.

This is an important feature of L<HTML::Object> since that, if nothing was changed, L<HTML::Object> will return the element objects in their C<original> text version.

Whereas, other HTML parser, decode all the HTML elements parsed and rebuild them, often badly and even though they have not been changed, which of course, incur a heavy speed penalty.

=head2 parent

Returns the current element's L<parent element|HTML::Object::Element>, if any. The value returned could very well be empty if, for example, it is the L<top element|HTML::Object::Document> or if the element was created independently of any parsing.

=head2 pindex

This is an alias for L</pos>

=head2 pos

Read-only.

Returns the position L<integer|Module::Generic::Number> of the current element among its parent's children elements.

It returns a L<smart undef|Module::Generic/new_null> if the element has no parent.

If the current element, somehow, could not be found among its parent, this would return C<undef>

Contrary to the C<HTML::Element> equivalent, you cannot manually change this value.

=head2 postinsert

Provided with a list of L<elements|HTML::Object::Element> and this will add them right after the current element in its parent's children.

It returns the current element object for chaining upon success, and upon error, it returns C<undef> and sets an L<error|HTML::Object::Exception>

=head2 preinsert

Provided with a list of L<elements|HTML::Object::Element> and this will add them right before the current element in its parent's children.

It returns the current element object for chaining upon success, and upon error, it returns C<undef> and sets an L<error|HTML::Object::Exception>

=head2 push_content

Provided with a list of L<elements|HTML::Object::Element> and this will add them as children to the current element.

Contrary to the C<HTML::Element> equivalent, this requires that only object be provided, which is easy to do anyhow.

If consecutive text or space objects are provided they are automatically merged with their immediate text or space objects, if any.

For example:

    $e->push_content( $elem1, HTML::Object::Element->new( value => q{some text} ), $elem2 );

And if two consecutive text objects were provided the second one would have its L<value|HTML::Object::Text/value> merged with the previous one.

It returns the current element object for chaining.

=head2 replace_with

Provided with a list of L<element objects|HTML::Object::Element> and this will replace the current element in its parent's children with the element objects provided.

This will return an L<error|HTML::Object::Exception> if the current element has no parent, or if the current element cannot be found among its parent's children elements.

Also, this method will filter out any duplicate objects, and return an error if the element being replaced is also among the objects provided for replacement or if the current element's parent is among the replacement objects.

Each replacement object is detached from its previous parent and re-attach to the current element's parent before being added to its children.

It returns the current element object.

=head2 replace_with_content

Replaces the current element in its parent's children by its own children element, which, in other words, means that the current element children will be moved up and replace the current element itself.

It returns the current element object, which will then, have no more parent.

=head2 reset

Enable the reset flag for this element, which has the effect of instructing L</as_string> to not use its cache.

=head2 right

Returns an L<array object|Module::Generic::Array> of all the sibling objects after the current element.

=head2 root

Returns the top most element in the hierarchy, which usually is L<HTML::Object::Document>

=head2 same_as

This method will check that 2 element objects are similar, in the sense that they can have different L</eid>, but have identical structure.

I you want to check if 2 element object are actually the same, by comparing their C<eid>, you can use the comparison signs that have been overloaded. For example:

    say $a eq $b ? 'same' : 'nope';

=head2 set_checksum

Calculate and returns the md5 checksum of the current element based on all its attributes.

=head2 splice_content

Provided with an C<offset> and a C<length>, and a list of L<element objects|HTML::Object::Element> and this will replace the elements children at offset position C<offset> and for a C<length> number of items by the list of objects supplied.

If consecutive L<text element|HTML::Object::Text> or L<space element|HTML::Object::Space> are provided they will be merged with their immediate previous sibling of the same type.

For example:

    $e->splice_content( 3, 2, $elem1, $elem2, HTML::Object::Text->new( value => 'Hello world' ) );

It returns an error if the C<offset> or C<length> provided is not a valid integer.

Upon success, it returns the current object for chaining.

=head2 tag

Returns the tag name of the current element as a L<scalar object|Module::Generic::Scalar>. Be careful at any change you would make as it would directly change the element tag name.

Non-element tag, such as L<text|HTML::Object::Text> or L<space|HTML::Object::Space> have a pseudo tag starting with an underscore ("_"), such as C<_text> and C<_space>

=head2 traverse

Provided with a reference to an existing subroutine, or an anonymous one, and this will crawl through every element of the descending hierarchy and call the callback code, passing it the element object being evaluated. The local variable C<$_> is also made available and set to the element being evaluated.

=head2 unshift_content

This acts like L</push_content>, except that instead of appending the elements, this prepends the given element on top of the element children.

It returns the current element.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

L<Mozilla Element documentation|https://developer.mozilla.org/en-US/docs/Web/API/Element>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
