##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/TableRow.pm
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
package Markdown::Parser::TableRow;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use Nice::Try;
    use Devel::Confess;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{cols}           = [];
    $self->{height}         = '';
    $self->{tag_name}       = 'tr';
    $self->{_as_markdown}   = '';
    return( $self->SUPER::init( @_ ) );
}

sub as_css_grid
{
    my $self = shift( @_ );
    return( $self->{_as_css_grid} ) if( $self->{_as_css_grid} );
    ## There is no "row" in css grid. We just get the cells as divs and pass them along
    my $cells = $self->children->map(sub{ $_->as_css_grid });
    $self->{_as_css_grid} = $cells->join( "\n" );
    $self->message( 3, "Returning row '$self->{_as_css_grid}'" );
    return( $self->{_as_css_grid} );
}

sub as_markdown
{
    my $self = shift( @_ );
    return( $self->{_as_markdown} ) if( $self->{_as_markdown} );
    my $cell_data = $self->new_array;
    my $cells = $self->new_array;
    $self->children->foreach(sub
    {
        my $cell = shift( @_ );
        my $data = $cell->formatted_lines;
        $self->message( 3, "Cell formatted line is: ", sub{ $self->dump( $data ) });
        $cell_data->push( $data );
        $cells->push( $cell );
        ## Get the height of the row by takin the highest cell
        $self->height( $data->length ) if( $data->length > $self->height );
    });
    my $row_height = $self->height;
    $self->message( 3, "Row height is '$row_height'." );
    # $row_height->debug( 3 );
    my $row_data = $self->new_array;
    for( my $i = 0; $i < $row_height; $i++ )
    {
        ## Pipes at start of row
        if( $i == 0 )
        {
            $row_data->push( '|' );
        }
        else
        {
            $row_data->push( ':' );
        }
        $cell_data->for(sub
        {
            my( $j, $data ) = @_;
            $self->message( 3, "Array $cell_data: Getting cell obejct at cell offset $j" );
            my $cell = $cells->get( $j );
            ## This cell is bigger or equal to the current height position, push its data
            if( $data->size >= $i )
            {
                $row_data->push( $data->get( $i ) );
            }
            ## We are processing more new lines than there is in this cell, so we put blanks instead
            else
            {
                $row_data->push( ' ' x $cell->width );
            }
            
            ## Pipes after this cell, possibly multiple pipes for cells spanning multiple cells
            if( $i == 0 )
            {
                $row_data->push( '|' x $cell->colspan );
            }
            else
            {
                $row_data->push( ':' x $cell->colspan );
            }
        });
        $row_data->push( "\n" ) if( $row_height > 1 && $i < ( $row_height - 1 ) );
    }
    $self->{_as_markdown} = $row_data->join( '' );
    $self->message( 3, "Returning row '$self->{_as_markdown}'" );
    return( $self->{_as_markdown} );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr  = $self->new_array;
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
    $arr->push( $self->children->map(sub
    {
        $_->as_string;
    })->list );
    $arr->push( "</$tag>" );
    return( $arr->join( "\n" )->scalar );
}

sub height { return( shift->_set_get_number( 'height', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Markdown::Parser::TableRow - Markdown Table Row Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::TableRow->new;
    $o->add_element( $o->create_table_cell( @_ ) );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a class object to represent a table row. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_css_grid

Returns this table row as a CSS grid as a regular string.

This is quite a nifty feature that enables you to transform effortlessly a table into a CSS grid.

See L<Markdown::Parser::Table/as_css_grid>

=head2 as_markdown

Returns a string representation of the table row formatted in markdown.

This method will call each cell L<Markdown::Parser::TableCell> object and get their respective markdown string representation.

It returns a plain string.

=head2 as_string

Returns an html representation of the table row. It calls each of its children that should be L<Markdown::Parser::TableCell> objects to get their respective html representation.

It returns a plain string.

=head2 height

Sets or gets the height of the row as integer. The value is stored as a L<Module::Generic::Number> object.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
