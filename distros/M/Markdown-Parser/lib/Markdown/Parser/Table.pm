##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Table.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/08/23
## Modified 2021/08/23
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Markdown::Parser::Table;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use Nice::Try;
    use POSIX ();
    use Scalar::Util ();
    use Devel::Confess;
    use constant CHAR2PIXELS => 8;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{bodies}         = [];
    $self->{caption}        = '';
    $self->{headers}        = [];
    $self->{tag_name}       = 'table';
    $self->{use_css_grid}   = 0;
    return( $self->SUPER::init( @_ ) );
}

sub as_css_grid
{
    my $self = shift( @_ );
    $self->message( 3, "Returning table as css grid." );
    return( $self->{_as_css_grid} ) if( $self->{_as_css_grid} );
    ## css(9 method is inherited from Markdown::Parser::Element
    my $css  = $self->css || return( $self->error( "No CSS::Object was set using the css() method. This should be set by Markdown::Parser::parse_table" ) );
    my $b = $css->builder;
    my $id = Scalar::Util::refaddr( $self );
    my $stat = $self->stat;
    my $cols = $self->new_array;
    my $total_cols = $stat->{cols}->{total};
    my $total_rows = $stat->{rows}->{total};
    for( my $i = 0; $i < $total_cols; $i++ )
    {
        $cols->push( sprintf( '%dpx', int( $stat->{cols}->{ $i } ) * 8 ) )
    }
# .grid
# {
#     display: grid;
#     grid-template-columns: repeat( 4, 1fr );
#     grid-template-rows: repeat( 3, 1fr );
#     gap: 1px 1px;
# }
    ## Create the css for this table
    my $grid = $b->select( [".grid-${id}"] )
        ->display( 'grid' )
        ->grid_template_columns( $cols->join( ' ' ) )
        ->grid_template_rows( sprintf( 'repeat %d, 1fr', $total_rows ) )
        ->gap( '1px 1px' );
    ## Set the table header css rule
    my $hdr_rule = $css->get_rule_by_selector( '.table-header' );
    unless( $hdr_rule )
    {
        $b->select( ['.table-header'] )
            ->font_weight( 'bold' );
    }
    my $arr  = $self->new_array;
    my $cap  = $self->caption;
    my $hdr  = $self->header;
    my $bodies = $self->bodies;
    $arr->push( $cap->as_css_grid ) if( $cap );
    $arr->push( "<div class=\"grid-${id}\">" );
    if( $hdr )
    {
        $self->message( 3, "Generating header" );
        $arr->push( $hdr->as_css_grid );
    }
    $bodies->for(sub
    {
        my( $i, $body ) = @_;
        $self->message( 3, "Generating a table body" );
        ## If there is more than one body, we separate them with one blank line
        $arr->push( "\n" ) if( $i > 0 );
        $arr->push( $body->as_css_grid );
        $arr->push( "\n" );
    });
    $arr->push( "</div>" );
    $self->{_as_css_grid} = $arr->join( "\n" )->scalar;
    return( $self->{_as_css_grid} );
}

sub as_markdown
{
    my $self = shift( @_ );
    return( $self->{_as_mardown} ) if( $self->{_as_mardown} );
    my $arr  = $self->new_array;
    my $cap  = $self->caption;
    my $hdr  = $self->header;
    my $bodies = $self->bodies;
    
    $arr->push( ' ' . $cap->as_markdown ) if( $cap && $cap->position eq 'top' );
    my $tag = $self->tag_name;
    my $tag_open = $tag;
    my $tmp  = $self->new_array;
    $tmp->push( "<$tag_open" );
    my $attr = $self->new_array;
    $attr->push( $self->format_id ) if( $self->id->length );
    $attr->push( $self->format_class ) if( $self->class->length );
    my $attributes = $self->format_attributes;
    $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    $tmp->push( ' ' . $attr->join( ' ' )->scalar ) if( $attr->length );
    $tmp->push( '>' );
    $arr->push( $tmp->join( '' )->scalar );
    if( $hdr )
    {
        $self->message( 3, "Generating header" );
        $arr->push( $hdr->as_markdown );
    }
    $arr->push( "\n" ) if( $bodies->length );
    
    $bodies->for(sub
    {
        my( $i, $body ) = @_;
        $self->message( 3, "Generating a table body" );
        ## If there is more than one body, we separate them with one blank line
        $arr->push( "\n" ) if( $i > 0 );
        $arr->push( $body->as_markdown );
        $arr->push( "\n" );
    });
    $arr->push( ' ' . $cap->as_markdown ) if( $cap && $cap->position eq 'bottom' );
    $self->{_as_mardown} = $arr->join( '' )->scalar;
    return( $self->{_as_mardown} );
}

## Ref: https://www.w3schools.com/TAgs/tag_col.asp
sub as_string
{
    my $self = shift( @_ );
    return( $self->as_css_grid ) if( $self->use_css_grid );
    my $arr  = $self->new_array;
    my $tag = $self->tag_name;
    my $tag_open = $tag;
    my $caption = $self->caption;
    $arr->push( "<$tag_open>" );
    $arr->push( $caption->as_string ) if( $caption );
    if( $self->header->children->length )
    {
        $arr->push( $self->header->as_string );
    }
    if( $self->bodies->length )
    {
        $self->bodies->foreach(sub
        {
            $arr->push( $_->as_string );
        });
    }
    $arr->push( "</$tag>" );
    return( $arr->join( "\n" )->scalar );
}

sub add_body
{
    my $self = shift( @_ );
    my $val  = shift( @_ ) || return;
    my $base = $self->base_class;
    return( $self->error( "Value provided (", overload::StrVal( $val ), ") is not a ${base}::TableBody object" ) ) if( !$self->_is_a( $val, "${base}::TableBody" ) );
    $val->parent( $self );
    $self->bodies->push( $val );
    return( $val );
}

sub bodies { return( shift->_set_get_object_array_object( 'bodies', 'Markdown::Parser::TableBody', @_ ) ); }

## Alias
sub body { return( shift->bodies( @_ ) ); }

sub caption
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        my $base = $self->base_class;
        return( $self->error( "Value provided (", overload::StrVal( $val ), ") is not a ${base}::TableCaption object" ) ) if( !$self->_is_a( $val, "${base}::TableCaption" ) );
        $val->parent( $self );
        $self->_set_get_object( 'caption', "${base}::TableCaption", $val );
    }
    return( $self->_set_get_object( 'caption', "${base}::TableCaption" ) );
}

sub header
{
    my $self = shift( @_ );
    my $base = $self->base_class;
    if( @_ )
    {
        my $val = shift( @_ ) || return;
        return( $self->error( "Value provided (", overload::StrVal( $val ), ") is not a ${base}::TableHeader object" ) ) if( !$self->_is_a( $val, "${base}::TableHeader" ) );
        $val->parent( $self );
        $self->_set_get_object( 'header', "${base}::TableHeader", $val );
    }
    return( $self->_set_get_object( 'header', "${base}::TableHeader" ) );
}

sub remove_body
{
    my $self = shift( @_ );
    my $val = shift( @_ ) || return;
    my $base = $self->base_class;
    return( $self->error( "Value provided (", overload::StrVal( $val ), ") is not a ${base}::TableBody object" ) ) if( !$self->_is_a( $val, "${base}::TableBody" ) );
    my $pos = $self->bodies->pos( $val );
    return if( !defined( $pos ) );
    ## Returned an array object of element removed
    my $removed = $self->bodies->delete( $pos, 1 );
    return( $removed->[0] );
}

sub reset_stat
{
    my $self = shift( @_ );
    $self->stat->reset;
    return( $self );
}

## Contains an hash of property and values providing stats on the table and collected upon parsing
## They are used to produce the html table or css grid
## sub stat { return( shift->_set_get_hash_as_mix_object( 'stat', @_ ) ); }
sub stat
{
    my $self = shift( @_ );
    my $info = $self->_set_get_hash_as_mix_object( 'stat' );
    return( $info ) if( $info && $info->length );
    local $get_width = sub
    {
        my $row = shift( @_ );
        $row->children->for(sub
        {
            my( $j, $cell ) = @_;
            $info->{cols} = {} if( !ref( $info->{cols} ) );
            return( 1 ) if( length( $info->{cols}->{ $j } ) );
            ## Cells are merged into 1, so we cannot get an accurate width of each cell
            return( 1 ) if( $cell->colspan > 1 );
            if( $cell->width )
            {
                $info->{cols}->{ $j } = $cell->width;
            }
            ## Find out the width of the cell based on its content
            else
            {
                my $cell_data = $cell->children->map(sub{ $_->as_markdown });
                ## Find the longest string in each line within this cell
                my $max = 0;
                $cell_data->foreach(sub
                {
                    ## Split the string into lines
                    my $lines = $self->new_array( [split( /\n/, $_ )] );
                    $lines->foreach(sub
                    {
                        my $l = shift( @_ );
                        $max = length( $l ) if( length( $l ) > $max );
                    });
                });
                ## Add 1 space on each side
                $max += 2;
                $info->{cols}->{ $j } = $max;
                $cell->width( $max );
            }
        });
    };
    ## Or else, collect stats
    if( my $hdr = $self->header )
    {
        $hdr->children->for(sub
        {
            my( $i, $row ) = @_;
            $get_width->( $row );
        });
        ## Number of rows in the header
        $info->{header}->{rows} = $hdr->children->length;
    }
    $self->bodies->foreach(sub
    {
        my $body = shift( @_ );
        $body->children->foreach(sub
        {
            my $row = shift( @_ );
            $get_width->( $row );
        });
        $info->{rows} = {} if( !ref( $info->{rows} ) );
        ## Number of rows in the body
        $info->{rows}->{total} += $body->children->length;
    });
    $info->{cols}->{total} = scalar( keys( %{$info->{cols}} ) );
    foreach my $col_n ( keys( %{$info->{cols}} ) )
    {
        $info->{table}->{width} += $info->{cols}->{ $col_n };
    }
    return( $info );
}

sub use_css_grid { return( shift->_set_get_boolean( 'use_css_grid', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Table - Markdown Table Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Table->new;
    $o->caption( $o->create_table_caption( @_ ) );
    $o->head( $o->create_table_head( @_ ) );
    $o->add_body( $o->create_table_body( @_ ) );
    print $o->as_string, "\n"; # returns html representation of the data
    print $o->as_markdown, "\n"; # returns markdown representation of the data

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a class object to represent an entire table. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

For example:

=begin text

    |               |            Grouping            ||
    +---------------+---------------------------------+
    | First Header  |  Second Header  |  Third Header |
    +---------------+-----------------+---------------+
    | Content       |           *Long Cell*          ||
    : continued     :                                ::
    : content       :                                ::
    | Content       |    **Cell**     |          Cell |
    : continued     :                 :               :
    : content       :                 :               :

    | New section   |      More       |          Data |
    | And more      |             And more           ||
     [Prototype table]

=end text

=head1 METHODS

=head2 new

Instantiate a new table object, which can take the following parameters:

=over 4

=item css

This is a L<CSS::Object> object

=item tag_name

This is the internal value to identify the table object. It is set to C<table> and should not be changed

=item use_css_grid

A boolean value to set whether to return the table as a L<css grid|https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Grid_Layout> rather than as an L<html table|https://developer.mozilla.org/en-US/docs/Learn/HTML/Tables/Basics>.

When set to true, L</as_string> returns L</as_css_grid> instead

=back

=head2 add_body

Provided with a L<Markdown::Parser::TableBody> object, and this adds it to the stack of L<Markdown::Parser::TableBody> objects.

=head2 as_css_grid

Returns this table as a CSS grid as a regular string.

This is quite a nifty feature that enables you to transform effortlessly a table into a CSS grid.

=head2 as_markdown

Returns a string representation of the table formatted in markdown.

This method will call L</caption> if one is set, L</header> and L</bodies> and get their respective markdown representation of their part.

It returns a plain string.

=head2 as_string

Returns an html representation of the table. It calls L</caption> if one is set, L</header> and L</bodies> to get their respective html representation.

It returns a plain string.

=head2 bodies

Sets or gets a L<Module::Generic::Array> object containing L<Markdown::Parser::TableBody> objects.

=head2 body

Alias for L</bodies>

=head2 caption

Sets or gets a L<Markdown::Parser::TableCaption> object.

When an L<Markdown::Parser::TableCaption> object is provided, this method automatically sets the object L<Markdown::Parser::Element/parent> property to the current table object.

Returns the current value set.

=head2 header

Sets or gets a L<Markdown::Parser::TableHeader> object.

When an L<Markdown::Parser::TableHeader> object is provided, this method automatically sets the object L<Markdown::Parser::Element/parent> property to the current table object.

Returns the current value set.

=head2 remove_body

Provided with a L<Markdown::Parser::TableBody> object, and this will remove it from the stack of L<Markdown::Parser::TableBody> objects.

Returns the object removed if it was found, or undef otherwise.

=head2 reset_stat

Reset the hash reference containing general computed data on the table.

=head2 stat

Returns a hash object from L<Module::Generic::Hash> containing table computed data information.

Available information are:

=over 4

=item cols

=over 8

=item 0, 1, 2...

This field key is an integer starting from zero like an array offset. The field value is the width of the cell

In the example above, cell 0 could be, for example, having a width of 10 characters, while cell 1 could be 12 characters and cell 3 too.

    $stat->{cols}->{0}; # 10 characters wide

=item total

This field contains an integer representing the total number of columns for a row in the table

=back

=item header

=over 8

=item rows

This field contains the number of rows in the header

=back

=item rows

=over 8

=item total

This field contains the total number of rows in the table bodies. So its value is an integer.

=back

=item table

=over 8

=item width

This field contains an integer representing the table width. However, the width here is in number of characters, not in pixel, so you would need to convert it. The conversion ratio is 8 pixels per character.

=back

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
