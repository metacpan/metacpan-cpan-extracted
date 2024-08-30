## -*- perl -*-
##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Image.pm
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
package Markdown::Parser::Image;
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
    $self->{alt}        = '';
    $self->{id}         = [];
    $self->{link_id}    = '';
    $self->{tag_name}   = 'img';
    $self->{title}      = '';
    $self->{url}        = '';
    return( $self->SUPER::init( @_ ) );
}

sub alt { return( shift->_set_get_scalar_as_object( 'alt', @_ ) ); }

sub as_markdown
{
    my $self = shift( @_ );
    my $arr = $self->new_array;
    $arr->push( sprintf( '![%s]', $self->alt ) );
    if( $self->id )
    {
        $arr->push( sprintf( '[%s]', $self->id ) );
    }
    elsif( $self->uri || $self->title )
    {
        $arr->push( '(' );
        $arr->push( sprintf( '%s', $self->uri ) ) if( $self->uri );
        $arr->push( ' ' ) if( $self->uri && $self->title );
        $arr->push( sprintf( '"%s"', $self->title ) );
        $arr->push( ')' );
    }
    return( $arr->join( '' )->scalar );
}

sub as_pod
{
    my $self = shift( @_ );
    my $arr = $self->new_array;
    $arr->push( "=begin html\n" );
    $arr->push( $self->as_string );
    $arr->push( "\n=end html" );
    return( $arr->join( "\n" )->scalar );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr  = $self->new_array;
    my $tag  = 'img';
    my $tag_open = $tag;
    $arr->push( "<${tag_open} src=\"" . $self->url . "\"" );
    if( $self->alt->length )
    {
        $arr->push( sprintf( 'alt="%s"', $self->encode_html( 'all', $self->alt ) ) );
    }
    if( $self->title->length )
    {
        $arr->push( sprintf( 'title="%s"', $self->encode_html( 'all', $self->title ) ) );
    }
    my $attr = $self->new_array;
    $attr->push( $self->format_id ) if( $self->id->length );
    $attr->push( $self->format_class ) if( $self->class->length );
    my $attributes = $self->format_attributes;
    $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    $arr->push( $attr->join( ' ' )->scalar ) if( $attr->length );
    $arr->push( '/>' );
    return( $arr->join( ' ' )->scalar );
}

sub copy_from
{
    my $self = shift( @_ );
    my $def  = shift( @_ ) || return( $self->error( "No link definition object was provided." ) );
    return( $self->error( "Link definition object provided to copy information from \"", overload::StrVal( $def ), "\" is not a Markdown::Parser::LinkDefinition object." ) ) if( !$self->_is_a( $def, 'Markdown::Parser::LinkDefinition' ) );
    return( $def->copy_to( $self ) );
}

sub link_id { return( shift->_set_get_scalar_as_object( 'link_id', @_ ) ); }

sub title { return( shift->_set_get_scalar_as_object( 'title', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Image - Markdown Image Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Image->new;
    # or
    $doc->add_element( $o->create_image( @_ ) );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This class represents an image formatting. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 alt

Sets o gets the alternative text. Stores the value as an L<Module::Generic::Scalar> object.

Returns the current value.

=head2 as_markdown

Returns a string representation of the image formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the image formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the image.

It returns a plain string.

=head2 copy_from

Provided with a L<Markdown::Parser::LinkDefinition> object and this will call L<Markdown::Parser::LinkDefinition/copy_to>

=head2 id

Sets or gets the array object of css id for this image. There should only be one set. Stores the value as an L<Module::Generic::Array> object.

=head2 link_id

Sets or gets the link definition id for this image. Stores the value as an L<Module::Generic::Scalar> object.

=head2 title

Sets o gets the image title. Stores the value as an L<Module::Generic::Scalar> object.

Returns the current value.

=head2 url

Sets or gets the image url. This stores the value as an L<URL> object.

Returns the current value.

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#img>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
