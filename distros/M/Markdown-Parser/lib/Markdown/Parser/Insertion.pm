## -*- perl -*-
##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Insertion.pm
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
package Markdown::Parser::Insertion;
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
    $self->{tag_name}   = 'ins';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_markdown })->join( '' );
    return( "++${str}++" );
}

sub as_pod
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_markdown })->join( '' );
    return( "${str}" );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr  = $self->new_array;
    my $tag  = $self->tag_name;
    my $tag_open = $tag;
    $arr->push( "<${tag_open}" );
    my $attr = $self->new_array;
    $attr->push( $self->format_id ) if( $self->id->length );
    $attr->push( $self->format_class ) if( $self->class->length );
    my $attributes = $self->format_attributes;
    $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    $arr->push( ' ' . $attr->join( ' ' )->scalar ) if( $attr->length );
    $arr->push( '>' );
    $arr->push( $self->children->map(sub{ $_->as_string })->list ) if( $self->children->length );
    $arr->push( "</${tag}>" );
    return( $arr->join( '' )->scalar );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Insertion - Markdown Insertion Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Insertion->new;
    # or
    $doc->add_element( $o->create_subscript( @_ ) );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class represents an insertion formatting. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

For example:

    Tickets for the event are ~~€5~~ ++€10++

Which would become:

    Tickets for the event are <del>€5</del> <ins>€10</ins>

With C<€5> being stroken through and C<€10> being highlighted as being added. The actual representation depends on the web browser of course.

=head1 METHODS

=head2 as_markdown

Returns a string representation of the insertion formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the insertion formatted in L<pod|perlpod>.

It returns a plain string, but it actually returns the original string whatever it was, because there is no equivalent to C<insertion> in pod.

=head2 as_string

Returns an html representation of the insertion formatting.

It returns a plain string.

=head1 SEE ALSO

L<Mozilla explanation of the tag|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ins>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
