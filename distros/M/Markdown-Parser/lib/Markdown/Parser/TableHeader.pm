##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/TableHeader.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/08/23
## Modified 2022/09/19
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Markdown::Parser::TableHeader;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use vars qw( $VERSION );
    use Devel::Confess;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{rows}           = [];
    $self->{tag_name}       = 'thead';
    $self->{_as_markdown}   = '';
    return( $self->SUPER::init( @_ ) );
}

sub as_css_grid
{
    my $self = shift( @_ );
    return( $self->{_as_css_grid} ) if( $self->{_as_css_grid} );
    my $row_data = $self->new_array;
    ## Check each row
    $self->children->for(sub
    {
        my( $i, $row ) = @_;
        ## Set the class header for cell of the header row
        $row->children->map(sub{ $_->class( 'table-header' ) });
        $row_data->push( $row->as_css_grid->scalar );
    });
    $self->{_as_css_grid} = $row_data->join( "\n" )->scalar;
    return( $self->{_as_css_grid} );
}

sub as_markdown
{
    my $self = shift( @_ );
    return( $self->{_as_markdown} ) if( $self->{_as_markdown} );
    my $row_data = $self->new_array;
    # Check each row
    $self->children->for(sub
    {
        my( $i, $row ) = @_;
        my $sep = $self->new_array;
        $sep->push( '+' );
        $row->children->foreach(sub
        {
            my $cell = shift( @_ );
            $sep->push( ( '-' x $cell->width ) . '+' );
        });
        # Push top horizontal line if this is the first upper line
        $row_data->push( $sep->join( '' )->scalar ) if( $i == 0 );
        my $row_str = $row->as_markdown;
        $row_data->push( $row_str->scalar );
        $row_data->push( $sep->join( '' )->scalar );
    });
    $self->{_as_markdown} = $row_data->join( "\n" )->scalar;
    return( $self->{_as_markdown} );
}

sub as_pod
{
    my $self = shift( @_ );
    return( $self->{_as_pod} ) if( $self->{_as_pod} );
    my $row_data = $self->new_array;
    # Check each row
    $self->children->for(sub
    {
        my( $i, $row ) = @_;
        my $sep = $self->new_array;
        $sep->push( '+' );
        $row->children->foreach(sub
        {
            my $cell = shift( @_ );
            $sep->push( ( '-' x $cell->width ) . '+' );
        });
        # Push top horizontal line if this is the first upper line
        $row_data->push( $sep->join( '' )->scalar ) if( $i == 0 );
        my $row_str = $row->as_pod;
        $row_data->push( $row_str->scalar );
        $row_data->push( $sep->join( '' )->scalar );
    });
    $self->{_as_pod} = $row_data->join( "\n" )->scalar;
    return( $self->{_as_pod} );
}

sub as_string
{
    my $self = shift( @_ );
    return( $self->{_as_string} ) if( $self->{_as_string} );
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
    $self->{_as_string} = $arr->join( "\n" )->scalar;
    return( $self->{_as_string} );
}

sub reset
{
    my $self = shift( @_ );
    delete( @$self{ qw( _as_css_grid _as_markdown _as_string ) } );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::TableHeader - Markdown Table Header Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::TableHeader->new;
    $o->add_element( $o->create_table_row( @_ ) );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This is a class object to represent a table header. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_css_grid

Returns a string representation of the table headers formatted in markdown.

This method will call each row L<Markdown::Parser::TableRow> object and get their respective markdown string representation.

It returns a plain string.

=head2 as_markdown

Returns a string representation of the table formatted in markdown.

This method will call each row L<Markdown::Parser::TableRow> object and get their respective markdown string representation.

It will place a horizontal line separator between each row and returns a plain string.

=head2 as_pod

This performs the same as L</as_markdown>, but for pod.

Returns a string representation of the table header formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the table header. It calls each of its children that should be L<Markdown::Parser::TableRow> objects to get their respective html representation.

It returns a plain string.

=head2 reset

Reset any cache generated to allow for re-computation of css grid, markdown or stringification

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
