##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/TableCell.pm
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
package Markdown::Parser::TableCell;
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
    $self->{tag_name}       = 'td';
    return( $self->SUPER::init( @_ ) );
}

sub align { return( shift->_set_get_scalar_as_object( 'align', @_ ) ); }

sub as_css_grid
{
    my $self = shift( @_ );
    return( $self->{_as_css_grid} ) if( $self->{_as_css_grid} );
    my $css = $self->css_inline;
    ## Dummy rule container to contain all the inline rules
    my $sel = $css->builder->select( ['#dummy'] );
    my $arr = $self->new_array;
    my $span = $self->colspan;
    my $align = $self->align;
    my $tag;
    if( $span > 1 )
    {
        $sel->grid_column( "span $span" );
    }
    if( $align eq 'center' )
    {
        $sel->justify_self( 'center' );
    }
    elsif( $align eq 'right' )
    {
        $sel->justify_self( 'right' );
    }
    
    my $elem = $self->new_array( [qw( <div )] );
    if( $sel->elements->length )
    {
        my $style = $css->builder->as_string;
        $elem->push( "style=\"$style\"" );
    }
    if( $self->class->length > 0 )
    {
        $elem->push( sprintf( 'class="%s"', $self->class->join( ' ' ) ) );
    }
    $elem->push( '>' );
    
    $arr->push( $elem->join( ' ' ) );
    $arr->push( $self->children->map(sub{ $_->as_markdown })->join( "\n" )->scalar );
    $arr->push( "</div>" );
    $self->{_as_css_grid} = $arr->join( "\n" )->scalar;
    return( $self->{_as_css_grid} );
}

sub as_markdown { return( shift->formatted_lines->join( "\n" ) ); }

sub as_string
{
    my $self = shift( @_ );
    return( $self->{_as_string} ) if( $self->{_as_string} );
    my $tag = $self->tag_name;
    my $tag_open = $tag;
    my $arr = $self->new_array;
    $arr->push( "<$tag_open" );
    my $attr = $self->new_array;
    $attr->push( $self->format_id ) if( $self->id->length );
    $attr->push( $self->format_class ) if( $self->class->length );
    my $attributes = $self->format_attributes;
    $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    $arr->push( ' ' . $attr->join( ' ' )->scalar ) if( $attr->length );
    $arr->push( '>' );
    $arr->push( $self->children->map(sub{ $_->as_string })->join( "\n" )->scalar );
    $arr->push( "</$tag>" );
    $self->{_as_string} = $arr->join( '' )->scalar;
    return( $self->{_as_string} );
}

sub class { return( shift->_set_get_array_as_object( 'class', @_ ) ); }

sub colspan { return( shift->_set_get_number( 'colspan', @_ ) ); }

## For Markdown formatting
sub formatted_lines
{
    my $self = shift( @_ );
    my $content = $self->children->map(sub{ $_->as_markdown })->join( "\n" )->split( "\n" );
    my $align = $self->align || 'left';
    my $width = $self->width;
    my $colspan = $self->colspan;
    ## We need to make room for the additional pipes for colspan
    ## Those space in width were added upon parsing, so now, we need to give it back
    $width -= ( $colspan > 1 ? ( $colspan - 1 ) : 0 );
    $self->message( 3, "Cell has a width of '$width' characters, an alignment of '$align' and content of '", $content->join( "\n" ), "'." );
    my $cell_data = $self->new_array;
    $content->foreach(sub
    {
        my $l = shift( @_ );
        if( length( $l ) == 0 )
        {
            $cell_data->push( '' );
        }
        elsif( $align eq 'left' )
        {
            $cell_data->push( ' ' . $l . ( ' ' x ( $width - ( length( $l ) + 1 ) ) ) );
        }
        elsif( $align eq 'right' )
        {
            ## Remove 1 from the width to leave a blank space on the right hand side before the column pip separator
            $cell_data->push( ( ' ' x ( ( $width - 1 ) - length( $l ) ) ) . $l . ' ' );
        }
        elsif( $align eq 'center' )
        {
            my $remain = $width - length( $l );
            my $left = POSIX::round( $remain / 2 );
            my $right = $remain - $left;
            $cell_data->push( ( ' ' x $left ) . $l . ( ' ' x $right ) );
        }
    });
    return( $cell_data );
}

sub width { return( shift->_set_get_number( 'width', @_ ) ); }

1;

# XXX POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::TableCell - Markdown Table Cell Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::TableCell->new;
    $o->add_element( $o->create_text( @_ ) );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a class object to represent a table cell. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 align

Sets or get the alignment of the cell content. Valid values are I<left>, I<center> or I<right>

=head2 as_css_grid

Returns this table cell as a CSS grid as a regular string.

This is quite a nifty feature that enables you to transform effortlessly a table into a CSS grid.

See L<Markdown::Parser::Table/as_css_grid>

=head2 as_markdown

Returns a string representation of the table formatted in markdown.

It returns a plain string.

=head2 as_string

Returns an html representation of the table body. It calls each of its children to get their respective html representation.

It returns a plain string.

=head2 class

Sets or gets the class attribute for this table cell.

=head2 colspan

Provided with an integer greater than 0 and this sets the number of column this cell spans. Default should be 1.

Value is stored as L<Module::Generic::Number> object.

It returns the current value set, which is a L<Module::Generic::Number> object.

=head2 formatted_lines

This returns a L<Module::Generic::Array> object representing the lines of data properly formatted for this cell.

This method is only used for L</as_markdown> method.

=head2 width

Sets or gets the width of the cell as an integer. The value is stored as a L<Module::Generic::Number> object and it represents the number of characters, not the number of pixels. There are 8 pixels per character.

It is important that this value be set, or else, L</formatted_lines> would not know how to align the cells content.

This method is also accessed by L<Markdown::Parser::TableRow/as_markdown>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
