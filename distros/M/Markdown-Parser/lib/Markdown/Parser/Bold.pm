## -*- perl -*-
##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Bold.pm
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
package Markdown::Parser::Bold;
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
    $self->{tag_name}   = 'bold';
    $self->{type}       = '';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_markdown })->join( '' );
    my $type = $self->type // '**';
    $type .= $type if( length( $type ) == 1 );
    $type = '**' if( $type ne '**' && $type ne '__' );
    return( "${type}${str}${type}" );
}

sub as_pod
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_pod })->join( '' );
    return( "B<${str}>" );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr  = $self->new_array;
    my $tag  = 'strong';
    my $tag_open = $tag;
    $arr->push( "<${tag_open}" );
    my $attr = $self->new_array;
    $attr->push( $self->format_id ) if( $self->id->length );
    $attr->push( $self->format_class ) if( $self->class->length );
    my $attributes = $self->format_attributes;
    $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    $arr->push( ' ' . $attr->join( ' ' )->scalar ) if( $attr->length );
    $arr->push( ">" );
    $arr->push( $self->children->map(sub{ $_->as_string })->list ) if( $self->children->length );
    $arr->push( "</${tag}>" );
    return( $arr->join( '' )->scalar );
}

sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Bold - Markdown Strong Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Bold->new;
    # or
    $doc->add_element( $o->create_bold( @_ ) );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This class represents a bold formatting. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the bold formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the bold formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the bold formatting.

It returns a plain string.

=head2 type

Sets or gets the markdown type used to declare the bold formatting. The value is stored as a L<Module::Generic::Scalar>

Valid type used to mark some text as bold are C<**> or C<__>

Returns the current value.

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#em>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
