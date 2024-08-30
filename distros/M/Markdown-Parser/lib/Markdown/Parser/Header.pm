##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Header.pm
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
package Markdown::Parser::Header;
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
    $self->{id}         = [];
    $self->{level}      = 0;
    $self->{tag_name}   = 'header';
    $self->SUPER::init( @_ );
    # If the header level is not set yet and we have some raw data, let's guess it from the raw data provided
    if( !$self->level && $self->raw->length )
    {
        # # is level 1, ## is level 2, etc...
        my $raw = $self->raw;
        $self->level( length( ( $raw =~ /^(\#+)/ )[0] ) );
    }
    return( $self );
}

sub append { return( shift->_append_text( @_ ) ); }

sub as_markdown
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_markdown })->join( '' );
    my $level = $self->level;
    my $marker = '#' x $level;
    return( "${marker} ${str}" );
}

sub as_pod
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_pod })->join( '' );
    my $level = $self->level;
    my $marker = '=head' . $level;
    return( "${marker} ${str}\n" );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr  = $self->new_array;
    my $tag  = 'h' . $self->level;
    my $tag_open = $tag;
    if( $self->id->length )
    {
        $tag_open .= ' ' . $self->id->map(sub{ sprintf( 'id="%s"', $_ ) })->join( ' ' )->scalar;
    }
    if( $self->class->length )
    {
        $tag_open .= ' class="' . $self->class->join( ' ' )->scalar . '"';
    }
    $arr->push( "<$tag_open" );
    my $attr = $self->new_array;
    $attr->push( $self->format_id ) if( $self->id->length );
    $attr->push( $self->format_class ) if( $self->class->length );
    my $attributes = $self->format_attributes;
    $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    $arr->push( ' ' . $attr->join( ' ' )->scalar ) if( $attr->length );
    $arr->push( '>' );
    $arr->push( $self->children->map(sub
    {
        $_->as_string;
    })->list );
    $arr->push( "</$tag>" );
    return( $arr->join( '' )->scalar );
}

sub id { return( shift->_set_get_array_as_object( 'id', @_ ) ); }

sub level { return( shift->_set_get_number_as_object( 'level', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Header - Markdown Header Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Header->new;
    # or
    $doc->add_element( $o->create_header( @_ ) );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This class represents a header formatting. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 append

Provided with a L<Markdown::Element::Text> object, or a text string, and this will add it to stack of elements or append it to the last text element if any.

=head2 as_markdown

Returns a string representation of the header formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the header formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the header.

It returns a plain string.

=head2 class

Sets or gets the array object of css class for this header.

Returns a L<Module::Generic::Array> object.

=head2 id

Sets or gets the array object of css id for this header. There should only be one set.

Returns a L<Module::Generic::Array> object.

=head2 level

Sets or gets the level for this header. It takes an integer which is stored as a L<Module::Generic::Number> object.

Valid values are from 1 to 6.

Returns the current value set.

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#header>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
