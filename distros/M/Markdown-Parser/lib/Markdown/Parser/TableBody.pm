##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/TableBody.pm
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
package Markdown::Parser::TableBody;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use vars qw( $VERSION );
    our $VERSION = 'v0.3.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{rows}           = [];
    $self->{tag_name}       = 'tbody';
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
        my $row_str = $row->as_markdown;
        $row_data->push( $row_str->scalar );
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
        my $row_str = $row->as_pod;
        $row_data->push( $row_str->scalar );
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

Markdown::Parser::TableBody - Markdown Table Body Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::TableBody->new;
    $o->add_element( $o->create_table_row( @_ ) );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This is a class object to represent a table body. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_css_grid

Returns this table body as a CSS grid as a regular string.

This is quite a nifty feature that enables you to transform effortlessly a table into a CSS grid.

See L<Markdown::Parser::Table/as_css_grid>

=head2 as_markdown

Returns a string representation of the table body formatted in markdown.

This method will call each row L<Markdown::Parser::TableRow> object and get their respective markdown string representation.

It returns a plain string.

=head2 as_pod

Returns a string representation of the table body formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the table body. It calls each of its children that should be L<Markdown::Parser::TableRow> objects to get their respective html representation.

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
