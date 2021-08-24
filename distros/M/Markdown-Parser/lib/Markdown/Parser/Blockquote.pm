## -*- perl -*-
##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Blockquote.pm
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
package Markdown::Parser::Blockquote;
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
    $self->{tag_name}   = 'blockquote';
    return( $self->SUPER::init( @_ ) );
}

sub append { return( shift->_append_text( @_ ) ); }

sub as_markdown
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_markdown })->join( "\n" );
    my $lines = $str->split( "\n" );
    $lines->for(sub
    {
        my( $i, $val ) = @_;
        substr( $lines->[ $i ], 0, 0 ) = '> ';
    });
    return( $lines->join( "\n" )->scalar );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr  = $self->new_array;
    my $tag  = $self->tag_name;
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
    $arr->push( "</$tag>\n" );
    return( $arr->join( "\n" )->scalar );
}

1;

__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Blockquote - Markdown Blockquote Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Blockquote->new;
    # or
    $doc->add_element( $o->create_blockquote( @_ ) );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a blockquote. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 append

Provided with some text, and this will append it to the existing text data stored as children element.

=head2 as_markdown

Returns a string representation of the blockquote formatted in markdown.

It returns a plain string.

=head2 as_string

Returns an html representation of the blockquote.

It returns a plain string.

=head1 SEE ALSO

Markdown original author reference on blockquotes: L<https://daringfireball.net/projects/markdown/syntax#blockquote>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
