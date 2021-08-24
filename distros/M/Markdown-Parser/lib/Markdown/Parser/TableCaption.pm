##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/TableCaption.pm
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
package Markdown::Parser::TableCaption;
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
    $self->{position}   = 'top';
    $self->{tag_name}   = 'caption';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    return( $self->{_as_markdown} ) if( $self->{_as_markdown} );
    $self->{_as_markdown} = sprintf( ' [%s]', $self->children->map(sub{ $_->as_markdown })->join( '' )->scalar );
    return( $self->{_as_markdown} );
}

sub as_string
{
    my $self = shift( @_ );
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
    return( $arr->join( '' )->scalar );
}

## 'top' or 'bottom' of the table
sub position { return( shift->_set_get_scalar_as_object( 'position', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Markdown::Parser::TableCaption - Markdown Table Caption Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::TableCaption->new;
    $o->add_element( $o->create_text( @_ ) );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a class object to represent a L<table caption|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/caption>. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the table formatted in markdown.

This method will call each row L<Markdown::Parser::TableRow> object and get their respective markdown string representation.

It returns a plain string.

=head2 as_string

Returns an html representation of the table body. It calls each of its children that should be L<Markdown::Parser::TableRow> objects to get their respective html representation.

It returns a plain string.

=head2 position

Sets or get the position value for this caption. Valid value are I<top> or I<bottom>. This only affects how the table is displayed in Markdown.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
