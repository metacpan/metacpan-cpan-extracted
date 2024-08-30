##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Element.pm
## Version v0.3.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/08/23
## Modified 2024/08/30
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Markdown::Parser::Element;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    use CSS::Object;
    our $VERSION = 'v0.3.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    ## print( STDERR ref( $self ), "::new: Markdown::Parser::Element::init() Parameters provided are: '", join( "', '", @_ ), "'\n" );
    my $opts = {};
    $opts = shift( @_ ) if( $self->_is_hash( $_[0] ) );
    if( !( scalar( @_ ) % 2 ) && scalar( keys( %$opts ) ) )
    {
        my $hash = { @_ };
        my @keys = keys( %$hash );
        @$opts{ @keys } = @$hash{ @keys };
    }
    elsif( !( scalar( @_ ) % 2 ) )
    {
        $opts = { @_ };
    }
    $self->{attr}       = {} unless( CORE::exists( $self->{attr} ) );
    $self->{children}   = [] unless( CORE::exists( $self->{children} ) );
    $self->{class}      = [] unless( CORE::exists( $self->{class} ) );
    ## To contain the CSS::Object
    $self->{css}        = '' unless( CORE::exists( $self->{css} ) );
    ## Dictionary hash object of abbreviations
    $self->{dict}       = {} unless( CORE::exists( $self->{dict} ) );
    $self->{parent}     = '' unless( CORE::exists( $self->{parent} ) );
    $self->{pos}        = '' unless( CORE::exists( $self->{pos} ) );
    $self->{raw}        = '' unless( CORE::exists( $self->{raw} ) );
    $self->{tag_name}   = '' unless( CORE::exists( $self->{tag_name} ) );
    $self->{_init_strict_use_sub} = 1;
    ## print( STDERR ref( $self ), "::new: Calling SUPER::init with: ", $self->dump( $opts ) );
    return( $self->SUPER::init( $opts ) );
    ## $self->SUPER::init( $opts );
    ## print( STDERR ref( $self ), "::new: Debug value: ", $self->debug, "\n" );
    ## return( $self );
}

sub add_attributes
{
    my $self = shift( @_ );
    ## A string something like {#id1} or {.cl} or {#id.cl.class}
    my $def  = shift( @_ );
    return if( !length( $def ) );
    my( @ids, @classes, @attributes );
    while( $def =~ s/
                    [[:blank:]\h]*
                    (?<attr_name>[a-zA-Z][\w\-]+)
                    [[:blank:]\h]*
                    =
                    [[:blank:]\h]*
                    (?<quote>["'])?
                    (?(<quote>)
                        (?:(?<attr_value>.*?)\g{quote})
                        |
                        (?<attr_value>\S+)
                    )
                    //xs )
    {
        push( @attributes, [ $+{attr_name} => $+{attr_value} ] );
    }
    while( $def =~ s/[[:blank:]\h]*\#(?<id>[^[:space:]\h\.\#]+)//s )
    {
        push( @ids, $+{id} );
    }
    while( $def =~ s/[[:blank:]\h]*\.(?<class>[^[:space:]\h\.\#]+)//s )
    {
        push( @classes, $+{class} );
    }
    $self->id->push( @ids );
    $self->class->push( @classes ) if( scalar( @classes ) );
    if( scalar( @attributes ) )
    {
        foreach my $ref ( @attributes )
        {
            ## If the user had defined it twice, it might very well override previous data set
            $self->attributes->set( $ref->[0] => $ref->[1] );
        }
    }
    return( $self );
}

sub add_element
{
    my $self = shift( @_ );
    my $obj  = shift( @_ );
    my $base = $self->base_class;
    return( $self->error( "Element provided \"$obj\" is not an Markdown::Parser::Element object." ) ) if( !$self->_is_a( $obj, "${base}::Element" ) );
    $obj->parent( $self );
    $self->children->push( $obj );
    return( $self );
}

sub add_to
{
    my $self = shift( @_ );
    my $obj  = shift( @_ );
    return( $self->error( "Element provided \"$obj\" is not an Markdown::Parser::Element object." ) ) if( !$self->_is_a( $obj, 'Markdown::Parser::Element' ) );
    $obj->children->push( $self );
    return( $self );
}

sub as_markdown
{
    my $self = shift( @_ );
    warn( "as_markdown method not implemented for ", ref( $self ), "\n" );
    return;
}

sub as_pod
{
    my $self = shift( @_ );
    warn( "as_pod method not implemented for ", ref( $self ), "\n" );
    return;
}

sub as_string
{
    my $self = shift( @_ );
    warn( "as_string method not implemented for ", ref( $self ), "\n" );
    return;
}

sub attr { return( shift->_set_get_hash_as_mix_object( 'attr', @_ ) ); }

# Alias
sub attributes { return( shift-> _set_get_hash_as_mix_object( 'attr', @_ ) ); }

sub base_class
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my @frag  = split( /\::/, $class );
    return( join( '::', @frag[ 0..( $#frag-1 ) ] ) );
}

sub children { return( shift->_set_get_array_as_object( 'children', @_ ) ); }

sub class { return( shift->_set_get_array_as_object( 'class', @_ ) ); }

# Returns the closest non-new line element or the one specified
sub closest
{
    my $self = shift( @_ );
    my $target;
    $target = shift( @_ ) if( @_ );
    my $elem;
    # Starting from the latest to the oldest
    $self->children->reverse->foreach(sub
    {
        return(1) if( $_->tag_name eq 'nl' );
        # We exit (return false) after the first element we found if there is no target specified
        if( !defined( $target ) ||
            ( defined( $target ) && $_->tag_name eq $target ) )
        {
            $elem = $_;
            return;
        }
        return(1);
    });
    return( $elem );
}

sub create_abbreviation { return( shift->_create_element( 'Abbr', @_ ) ); }

sub create_blockquote { return( shift->_create_element( 'Blockquote', @_ ) ); }

sub create_bold { return( shift->_create_element( 'Bold', @_ ) ); }

sub create_checkbox { return( shift->_create_element( 'Checkbox', @_ ) ); }

sub create_code { return( shift->_create_element( 'Code', @_ ) ); }

sub create_em { return( shift->_create_element( 'Emphasis', @_ ) ); }

sub create_footnote { return( shift->_create_element( 'Footnote', @_ ) ); }

sub create_footnote_ref { return( shift->_create_element( 'FootnoteReference', @_ ) ); }

sub create_header { return( shift->_create_element( 'Header', @_ ) ); }

sub create_image { return( shift->_create_element( 'Image', @_ ) ); }

sub create_html { return( shift->_create_element( 'HTML', @_ ) ); }

sub create_insertion { return( shift->_create_element( 'Insertion', @_ ) ); }

sub create_line { return( shift->_create_element( 'Line', @_ ) ); }

sub create_link_definition { return( shift->_create_element( 'LinkDefinition', @_ ) ); }

sub create_link { return( shift->_create_element( 'Link', @_ ) ); }

sub create_list { return( shift->_create_element( 'List', @_ ) ); }

sub create_list_item { return( shift->_create_element( 'ListItem', @_ ) ); }

sub create_new_line { return( shift->_create_element( 'NewLine', @_ ) ); }

sub create_paragraph { return( shift->_create_element( 'Paragraph', @_ ) ); }

sub create_strikethrough { return( shift->_create_element( 'StrikeThrough', @_ ) ); }

sub create_subscript { return( shift->_create_element( 'Subscript', @_ ) ); }

sub create_superscript { return( shift->_create_element( 'Superscript', @_ ) ); }

sub create_table { return( shift->_create_element( 'Table', @_ ) ); }

sub create_table_body { return( shift->_create_element( 'TableBody', @_ ) ); }

sub create_table_caption { return( shift->_create_element( 'TableCaption', @_ ) ); }

sub create_table_cell { return( shift->_create_element( 'TableCell', @_ ) ); }

sub create_table_column { return( shift->_create_element( 'TableColumn', @_ ) ); }

sub create_table_header { return( shift->_create_element( 'TableHeader', @_ ) ); }

sub create_table_row { return( shift->_create_element( 'TableRow', @_ ) ); }

sub create_text { return( shift->_create_element( 'Text', @_ ) ); }

sub css { return( shift->_set_get_object( 'css', 'CSS::Object', @_ ) ); }

sub css_inline
{
    return( CSS::Object->new( format => 'CSS::Object::Format::Inline' ) );
}

sub detach
{
    my $self = shift( @_ );
    my $arr  = $self->children->clone;
    $self->children->reset;
    return( $arr );
}

sub document { return( shift->_set_get_object( 'document', 'Markdown::Parser::Document', @_ ) ); }

sub empty
{
    my $self = shift( @_ );
    $self->children->reset;
    return( $self );
}

sub encode_html
{
    my $self = shift( @_ );
    my( $what, $text ) = @_;
    return if( !defined( $text ) );
    my $map =
    {
    '<' => '&lt;',
    '>' => '&gt;',
    ## Also &#38;
    '&' => '&amp;',
    ## Also &#63;
    '?' => '&quest;',
    ## Also known as &num;
    '#' => '&#35;',
    '"' => '&quot;',
    "'" => '&#39;',
    };
    my $data = $self->_is_scalar( $text ) ? $text : \$text;
    $what = [keys( %$map )] if( $what eq 'all' );
    return( $self->error( "List of items to encode is not an array reference." ) ) if( !$self->_is_array( $what ) );
    return( $$data ) if( !scalar( @$what ) );
    ## return( $self->error( "Text to encode is not a scalar reference." ) ) if( !$self->_is_scalar( $text ) );
    my $todo = {};
    ## Make a hash of characters to encode
    @$todo{ @$what } = ( 1 ) x scalar( @$what );
    if( my $amp = delete( $todo->{ '&' } ) )
    {
        ## 1 while( $$data =~ s/(?<!\\)(\&)(?!\d+\;)/$map->{ $1 }/gs );
        $$data =~ s/(?<!\\)(\&)(?!(?:amp|gt|lt)\;)/$map->{ $1 }/gs;
    }
    if( my $amp = delete( $todo->{ '#' } ) )
    {
        ## 1 while( $$data =~ s/(?<!\\)(\#)(?!(?:amp|gt|lt)\;)/$map->{ $1 }/gs );
        $$data =~ s/(?:(?<!\\)|(?<!\&))(\#)(?!\d+\;)/$map->{ $1 }/gs;
    }
    if( scalar( %$todo ) )
    {
        my $re = join( '|', map( quotemeta( $_ ), keys( %$todo ) ) );
        ## 1 while( $$data =~ s/(?<!\\)($re)/$map->{ $1 }/gs );
        $$data =~ s/(?<!\\)($re)/$map->{ $1 }/gs;
    }
    # return( $self );
    return( $$data );
}

sub extract_links
{
    my $self = shift( @_ );
#     my $links = $self->new_array;
#     $self->children->for(sub
#     {
#         my( $i, $link ) = @_;
#         if( $self->_is_a( $link => 'Markdown::Parser::Link' ) )
#         {
#             $links->push( $link );
#         }
#         if( $link->children->length > 0 )
#         {
#             my $more_links = $link->extract_links;
#             $links->push( $more_links->list ) if( $more_links->length );
#         }
#     });
    my $links = $self->look_down( tag => 'link' );
    return( $links );
}

sub format_attributes
{
    my $self = shift( @_ );
    my $attr = $self->attributes;
    ## Return an empty array if there is nothing
    return( $self->new_array ) if( !$attr->length );
    return( $attr->map_array(sub{ sprintf( '%s="%s"', $_, $attr->{ $_ } ) }) );
}

sub format_class
{
    my $self = shift( @_ );
    if( $self->class->length )
    {
        return( sprintf( 'class="%s"', $self->class->join( ' ' )->scalar ) );
    }
    return( '' );
}

sub format_id
{
    my $self = shift( @_ );
    if( $self->id->length )
    {
        return( sprintf( 'id="%s"', $self->id->join( ' ' )->scalar ) );
    }
    return( '' );
}

sub id { return( shift->_set_get_array_as_object( 'id', @_ ) ); }

sub insert_after
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    return if( !length( $elem ) );
    my $base_class = $self->base_class;
    return( $self->error( "Element provided is not ${base_class}::Element object." ) ) if( !$self->_is_a( "${base_class}::Element", $elem ) );
    return if( !$self->parent );
    my $children = $self->parent->children;
    my $pos = $children->pos( $self );
    return if( !defined( $pos ) );
    $children->splice( $pos + 1, 0, $elem );
    return( $elem );
}

sub insert_before
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    return if( !length( $elem ) );
    my $base_class = $self->base_class;
    return( $self->error( "Element provided is not ${base_class}::Element object." ) ) if( !$self->_is_a( "${base_class}::Element", $elem ) );
    return if( !$self->parent );
    my $children = $self->parent->children;
    my $pos = $children->pos( $self );
    return if( !defined( $pos ) );
    $children->splice( $pos, 0, $elem );
    return( $elem );
}

sub look
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{direction} //= 'down';
    unless( $opts->{direction} eq 'down' ||
            $opts->{direction} eq 'up' )
    {
        return( $self->error( "Unknown direction provided '$opts->{direction}'" ) );
    }
    my $a = $self->new_array;
    my( $check_elem, $crawl_down );
    $check_elem = sub
    {
        my $e = shift( @_ );
        my $def = shift( @_ );
        $def->{level} //= 0;
        # Assume not ok, then check otherwise
        my $ok = 0;
        if( defined( $opts->{tag} ) && length( $opts->{tag} ) )
        {
            if( ref( $opts->{tag} ) eq 'Regexp' )
            {
                $ok = 1 if( $e->tag_name =~ /$opts->{tag}/ );
            }
            else
            {
                $ok = 1 if( $e->tag_name eq $opts->{tag} );
            }
        }
        if( defined( $opts->{class} ) && length( $opts->{class} ) )
        {
            $ok = $self->_is_a( $e => $opts->{class} ) ? 1 : 0;
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
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{direction} = 'down';
    return( $self->look( $opts ) );
}

sub look_up
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{direction} = 'up';
    return( $self->look( $opts ) );
}

sub make_html_parser
{
    my $self = shift( @_ );
    require HTML::Object;
    return( HTML::Object->new );
}

sub object_id
{
    my $self = shift( @_ );
    return( $self->{object_id} ) if( length( $self->{object_id} ) );
    $self->{object_id} = Scalar::Util::refaddr( $self );
    return( $self->{object_id} );
}

sub package { return( ref( $_[0] ) ); }

sub parent { return( shift->_set_get_object( 'parent', 'Markdown::Parser::Element', @_ ) ); }

sub parse_html
{
    my $self = shift( @_ );
    my $html = shift( @_ ) || return;
    my $p = $self->make_html_parser;
    my $doc = $p->parse_data( $html ) ||
        return( $self->pass_error( $p->error ) );
    return( $doc );
}

sub pos { return( shift->_set_get_number_as_object( 'pos', @_ ) ); }

sub raw { return( shift->_set_get_scalar_as_object( 'raw', @_ ) ); }

sub remove
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $elem = shift( @_ );
        return if( !length( $elem ) );
        my $base_class = $self->base_class;
        return( $self->error( "Element provided is not a ${base_class}::Element object." ) ) if( !$self->_is_a( "${base_class}::Element", $elem ) );
        my $pos = $self->children->pos( $elem );
        return if( !defined( $pos ) );
        return( $self->children->delete( $pos, 1 ) );
    }
    ## Called without argument: remove itself from its parent
    elsif( $self->_is_object( $self->parent ) )
    {
        return( $self->parent->remove( $self ) );
    }
    return;
}

sub remove_children { return( shift->children->reset ); }

sub tag_name { return( shift->_set_get_scalar_as_object( 'tag_name', @_ ) ); }

sub wrap
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    my $base_class = $self->base_class;
    return( $self->error( "Element provided to wrap children is not a ${base_class}::Element object." ) ) if( !$self->_is_a( $elem, "${base_class}::Element" ) );
    ## Copy our children to the element provided and set the parent property accordingly
    $self->children->foreach(sub
    {
        $elem->add_element( $_ );
    });
    $self->remove_children;
    ## Set this element as our only child and set the parent property accordingly
    $self->add_element( $elem );
    return( $self );
}

sub _append_text
{
    my $self = shift( @_ );
    my $what = shift( @_ ) || return;
    my $elem_class = $self->base_class . '::Element';
    if( $self->_is_a( $what, $elem_class ) )
    {
        $self->children->push( $what );
    }
    elsif( ref( $what ) )
    {
        return( $self->error( "I do not know what to do with this reference \"$what\". I was expecting either a string or a $elem_class class object." ) );
    }
    ## Simple string, i.e. a text chunk
    else
    {
        if( $self->children->last->tag_name eq 'text' )
        {
            $self->children->last->append( " $what" );
        }
        else
        {
            $self->children->push( $self->create_text({
                text => $what,
                raw => $what,
            }) );
        }
    }
    return( $self );
}

sub _create_element
{
    my $self = shift( @_ );
    my $mod  = shift( @_ );
    my $base = $self->base_class;
    my $class = "${base}::${mod}";
    $self->_load_class( $class ) || return;
    my $obj = $class->new( @_, debug => $self->debug ) || return( $self->pass_error( $class->error ) );
    ## Assign the top document object, which is used by children element to access the document object methods
    if( $self->isa( 'Markdown::Parser::Document' ) )
    {
        $obj->document( $self );
    }
    elsif( my $doc = $self->document )
    {
        $obj->document( $doc );
    }
    return( $obj );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Element - Markdown Element Object Class

=head1 SYNOPSIS

    my $o = Markdown::Parser::Code->new;
    # or
    $doc->add_element( $o->create_code( @_ ) );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This is the base class from which all other elements inherit.

=head1 METHODS

=head2 add_attributes

Provided with an attributes definition string such as the one below, and this will parse it and set the corresponding classes and/or id for the element.

    ````` {.html #codeid}
    <b>bold</b>
    `````

Returns the current object for chaining.

=head2 add_element

Provided with an element object, and this will add it to the children stack.

    my $bq = $doc->create_blockquote;
    $bq->add_element( $doc->create_text( "Hello world" ) );

It sets the L</parent> value of the object to the current object.

Returns the current object for chaining.

=head2 add_to

Provided with an element object, and this will add it to the children stack.

    my $bq = $doc->create_blockquote;
    my $txt = $doc->create_text( "Hello world" );
    $txt->add_to( $bq );

=head2 as_markdown

Returns a string representation of the code formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the code formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the code.

It returns a plain string.

=head2 attr

Sets or gets the hash object used to contain the key-value pair for attributes.

Returns a L<Module::Generic::Hash> object.

=head2 attributes

Alias for L</attr>

=head2 base_class

Returns the computed base class for this object.

This is used to enable inheriting this class L<Module::Parser>

=head2 children

Sets or get the array object containing all the element contained inside the object.

Returns a L<Module::Generic::Array> object.

=head2 class

Read only. Returns the current class name for this object.

=head2 closest

Returns the closest element within an object children elements which is either anything but not non-new line element or the one specified, if found

=head2 create_abbreviation

Create a L<Markdown::Parser::Abbr> object and return it.

=head2 create_blockquote

Create a L<Markdown::Parser::Blockquote> object and return it.

=head2 create_bold

Create a L<Markdown::Parser::Bold> object and return it.

=head2 create_checkbox

Create a L<Markdown::Parser::Checkbox> object and return it.

=head2 create_code

Create a L<Markdown::Parser::Code> object and return it.

=head2 create_em

Create a L<Markdown::Parser::Emphasis> object and return it.

=head2 create_footnote

Create a L<Markdown::Parser::Footnote> object and return it.

=head2 create_footnote_ref

Create a L<Markdown::Parser::FootnoteReference> object and return it.

=head2 create_header

Create a L<Markdown::Parser::Header> object and return it.

=head2 create_html

Create a L<Markdown::Parser::HTML> object and return it.

=head2 create_image

Create a L<Markdown::Parser::Image> object and return it.

=head2 create_insertion

Create a L<Markdown::Parser::Insertion> object and return it.

=head2 create_line

Create a L<Markdown::Parser::Line> object and return it.

=head2 create_link_definition

Create a L<Markdown::Parser::LinkDefinition> object and return it.

=head2 create_link

Create a L<Markdown::Parser::Link> object and return it.

=head2 create_list

Create a L<Markdown::Parser::List> object and return it.

=head2 create_list_item

Create a L<Markdown::Parser::ListItem> object and return it.

=head2 create_new_line

Create a L<Markdown::Parser::NewLine> object and return it.

=head2 create_paragraph

Create a L<Markdown::Parser::Paragraph> object and return it.

=head2 create_strikethrough

Create a L<Markdown::Parser::StrikeThrough> object and return it.

=head2 create_subscript

Create a L<Markdown::Parser::Subscript> object and return it.

=head2 create_superscript

Create a L<Markdown::Parser::Superscript> object and return it.

=head2 create_table

Create a L<Markdown::Parser::Table> object and return it.

=head2 create_table_body

Create a L<Markdown::Parser::TableBody> object and return it.

=head2 create_table_caption

Create a L<Markdown::Parser::TableCaption> object and return it.

=head2 create_table_cell

Create a L<Markdown::Parser::TableCell> object and return it.

=head2 create_table_column

Create a L<Markdown::Parser::TableColumn> object and return it.

=head2 create_table_header

Create a L<Markdown::Parser::TableHeader> object and return it.

=head2 create_table_row

Create a L<Markdown::Parser::TableRow> object and return it.

=head2 create_text

Create a L<Markdown::Parser::Text> object and return it.

=head2 css

Sets or gets the L<CSS::Object> object.

=head2 css_inline

Get a new L<CSS::Object> with formater set to L<CSS::Object::Format::Inline>

=head2 detach

Remove all the children element and returns them as an array object (L<Module::Generic::Array> object)

=head2 dict

Sets or gets the dictionary hash object, which is a L<Module::Generic::Hash> object.

It is used to contain word-definition pairs.

=head2 document

Sets or gets a L<Markdown::Parser::Document> object.

=head2 empty

Empty the object of any children.

Returns the current object for chaining.

=head2 encode_html

Provided with an array reference of characters to encode and a string of text or a reference to a string of text, and this will encode those characters in their html entity equivalent. For example:

    < => &lt;
    < => &gt;
    & => &amp;

Returns the text encoded.

=head2 extract_links

Returns an L<array object|Module::Generic::Array> of L<link objects|Markdown::Parser::Link>

=head2 format_attributes

Provided with attributes object (L<Module::Generic::Hash>) such as set by L</attr> and this will retur a new L<Module::Generic::Array> object of attribute name-attribute value pairs.

=head2 format_class

If L</class> is set, then this will return a formatted C<class> attribute with the class separated by comma, otherwise it returns an empty string.

=head2 format_id

If L</id> is set, then this will return a formatted C<id> attribute with its value set to the L</id> value, otherwise it returns an empty string.

=head2 get_link_by_id

Provided with a link id, and this will return its corresponding value.

=head2 id

Sets or gets an array reference of C<id> attribute value.

Returns a L<Module::Generic::Array> object.

=head2 insert_after

Provided with an element and this will add it to the stack of elements, right after the current object.

Returns the element object being added for chaining.

=head2 insert_before

Provided with an element and this will add it to the stack of elements, right before the current object.

Returns the element object being added for chaining.

=head2 links

Returns an L<array object|Module::Generic::Array> of L<Markdown::Parser::Link> objects.

=head2 look

    my $array = $e->look(
        tag => $tag,
        # or 'up'
        direction => 'down',
        class => $class,
    );

This will crawl the element tree in search of matching elements, and returns an L<array object|Module::Generic::Array>.

Upon error, it sets an L<exception object|Module::Generic::Exception> and returns C<undef> in scalar context and an empty list in list context.

It takes the following options:

=over 4

=item * C<class>

An element class.

=item * C<direction>

The direction to crawl. Either C<down> or C<up>.

=item * C<tag>

A tag to look for.

=back

=head2 look_down

    my $array = $e->look(
        tag => $tag,
        class => $class,
    );

This will crawl down the element tree in search of matching elements, and returns an L<array object|Module::Generic::Array>.

Upon error, it sets an L<exception object|Module::Generic::Exception> and returns C<undef> in scalar context and an empty list in list context.

It takes the following options:

=over 4

=item * C<class>

An element class.

=item * C<tag>

A tag to look for.

=back

=head2 look_up

    my $array = $e->look(
        tag => $tag,
        class => $class,
    );

This will crawl up the element tree in search of matching elements, and returns an L<array object|Module::Generic::Array>.

Upon error, it sets an L<exception object|Module::Generic::Exception> and returns C<undef> in scalar context and an empty list in list context.

It takes the following options:

=over 4

=item * C<class>

An element class.

=item * C<tag>

A tag to look for.

=back

=head2 make_html_parser

Returns a L<HTML::TreeBuilder> object with the proper parameters set. This means I<ignore_unknown> set to false, I<store_comments> set to true, I<no_space_compacting> set to true, I<implicit_tags> set to false, I<implicit> set to true, and I<tighten> set to false.

=head2 object_id

Returns the object reference id generated using L<Scalar::Util/refaddr>

=head2 package

Returns the current object package name.

=head2 parent

Sets or gets the parent object for the current object.

The value provided must be a subclass of L<Markdown::Parser::Element>

=head2 parse_html

Provided with some html data, and this will use a L<HTML::Object> object to parse the data.

Returns the resulting L<HTML::Object::Document> object, which inherits from L<HTML::Object::Element>.

=head2 pos

Sets or get the current cursor position in the string being parsed, as a L<Module::Generic::Number> object.

Returns the current value.

=head2 raw

Sets or gets the raw data found using regular expression and before any processing was made. This is used essentially for debugging.

The value is stored as a L<Module::Generic::Scalar> object.

=head2 remove

Provided with an element object, and this will look up within all its children if it exists, and if it does, will remove it.

It returns the object removed.

When no value is provided, ie. when called in void context, this method will remove the current object from its parent.

=head2 remove_children

Remove all element objects contained.

=head2 tag_name

Sets or gets the tag name value as a L<Module::Generic::Scalar> object.

=head2 wrap

Provided with an element object to wrap, and this will wrap all current elements contained using the wrapping object.

For example:

    my $bq = $doc->create_blockquote;
    $bq->add_element( $doc->create_text( "Hello world" ) ); # Hello world is now contained within the blockquotes
    # Now, wrap Hello world inside a paragraph
    $bq->wrap( $doc->create_paragraph );
    # Data would now be <p>Hello world</p>

=head1 PRIVATE METHODS

=head2 _append_text

Provided with an element object, and this will ad it to the stack of children elements.

If the value provided is just a string, it will append it to the previous text element, if any, or create one

Returns the element object being added for chaining.

=head2 _create_element

This private method is used to create various elements. It is called from methods like L</create_paragraph>.

It will automatically load the module if not already loaded and instantiate an object, setting the debug value same as our current object.

=head1 SEE ALSO

L<Markdown::Parser>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
