## -*- perl -*-
##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/LinkDefinition.pm
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
package Markdown::Parser::LinkDefinition;
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
    $self->{id}         = '';
    $self->{link_id}    = '';
    $self->{tag_name}   = 'link_def';
    $self->{title}      = '';
    $self->{url}        = '';
    return( $self->SUPER::init( @_ ) );
}

# [foo]: http://example.com/  "Optional Title Here"
sub as_markdown
{
    my $self = shift( @_ );
    my $arr = $self->new_array;
    $arr->push( sprintf( '[%d]: %s', $self->link_id, $self->url ) );
    $arr->push( sprintf( ' "%s"', $self->title ) ) if( $self->title->length );
    if( $self->class->length || $self->id->length )
    {
        my $def = $self->new_array;
        $def->push( $self->id->map(sub{ "\#${_}" })->list );
        $def->push( $self->class->map(sub{ ".$_" })->list );
        $arr->push( '{' . $def->join( ' ' )->scalar . '}' );
    }
    return( $arr->join( '' )->scalar );
}

sub as_pod
{
    my $self = shift( @_ );
    my $arr = $self->new_array;
    if( $self->url && $self->title )
    {
        $arr->push( sprintf( '[%d]: L<%s|%s>', $self->link_id, $self->url, $self->title ) );
    }
    elsif( $self->url )
    {
        $arr->push( sprintf( '[%d]: L<%s>', $self->link_id, $self->url ) );
    }
    return( $arr->join( '' )->scalar );
}

sub as_string
{
    my $self = shift( @_ );
    return( '' ) if( !$self->id );
    my $arr  = $self->new_array;
    $arr->push( sprintf( '[%s]:', $self->link_id ) );
    $arr->push( $self->url . '' ) if( $self->url );
    $arr->push( sprintf( '"%s"', $self->title ) ) if( $self->title );
    if( $self->class->length || $self->id->length )
    {
        my $def = $self->new_array;
        $def->push( $self->id->map(sub{ "\#${_}" })->list );
        $def->push( $self->class->map(sub{ ".$_" })->list );
        $arr->push( '{' . $def->join( ' ' )->scalar . '}' );
    }
    return( $arr->join( ' ' ) ) if( $arr->length );
    return( '' );
}

## Copy the link definition information to the target object, such as a Link or an Image
sub copy_to
{
    my $self = shift( @_ );
    my $obj  = shift( @_ ) || return( $self->error( "No object was provided to copy the link definition information to." ) );
    return( $self->error( "The object provided \"", overload::StrVal( $obj ), "\" is not an Markdown::Parser::Element object or one of its inheriting modules." ) ) if( !$self->_is_a( $obj, 'Markdown::Parser::Element' ) );
    $obj->url( $self->url ) if( $obj->can( 'url' ) );
    $obj->title( $self->title ) if( $obj->can( 'title' ) );
    $obj->id( $self->id ) if( $obj->can( 'id' ) && $self->id->length );
    $obj->class( $self->class ) if( $obj->can( 'class' ) && $self->class->length );
    $obj->attributes( $self->attributes ) if( $obj->can( 'attributes' ) && $self->attributes->length );
    ## For chaining
    return( $obj );
}

sub link_id { return( shift->_set_get_scalar_as_object( 'link_id', @_ ) ); }

sub title { return( shift->_set_get_scalar_as_object( 'title', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::LinkDefinition - Markdown Link Definition Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::LinkDefinition->new;
    # or
    $doc->add_element( $o->create_link_definition( @_ ) );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This class represents a link definition. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

In markdown, a link definition would look like this:

    [foo]: http://example.com/  "Optional Title Here"

=head1 METHODS

=head2 as_markdown

Returns a string representation of the link definition formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the link definition formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the link definition.

It returns a plain string.

=head2 copy_to

Provided with a L<Markdown::Parser::Element>, and this will copy the link definition information to the target object, such as a L<Markdown::Parser::Link> or an L<Markdown::Parser::Image>.

Effectively, this will copy:

=over 4

=item * the I<url> if the target element supports this method.

=item * the I<title> if the target element supports this method.

=item * the I<id> if the target element supports this method and there is an L</id> set.

=item * the I<class> if the target element supports this method and there is a class set.

=item * the I<attributes> if the target element supports this method and there are attributes set.

=back

It returns the target object provided, for chaining purpose.

=head2 id

Sets or gets the array object of css id for this link. There should only be one set. Stores the value as an L<Module::Generic::Array> object.

=head2 link_id

Sets or gets the link definition id. Stores the value as an L<Module::Generic::Scalar> object.

Returns the current value.

=head2 title

Sets or gets the link definition title. Stores the value as an L<Module::Generic::Scalar> object.

Returns the current value.

=head2 url

Sets or gets the link definition url. This stores the value as an L<URL> object.

Returns the current value.

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#link>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
