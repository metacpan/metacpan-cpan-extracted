##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Paragraph.pm
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
package Markdown::Parser::Paragraph;
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
    $self->{tag_name}   = 'p';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_markdown })->join( '' );
    # Add an additional new line
    return( "$str\n" );
}

# Basically, same as markdown
sub as_pod
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_pod })->join( '' );
    # Add an additional new line
    return( "$str\n" );
}

sub as_string
{
    my $self = shift( @_ );
    my $tag = 'p';
    my $tag_open = $tag;
    my $arr = $self->new_array;
    my $tmp = $self->new_array;
    $tmp->push( "<$tag_open" );
    my $attr = $self->new_array;
    $attr->push( $self->format_id ) if( $self->id->length );
    $attr->push( $self->format_class ) if( $self->class->length );
    my $attributes = $self->format_attributes;
    $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    $tmp->push( ' ' . $attr->join( ' ' )->scalar ) if( $attr->length );
    $tmp->push( '>' );
    $arr->push( $tmp->join( '' )->scalar );
    $arr->push( $self->children->map(sub{ $_->as_string })->join( '' )->scalar );
    $arr->push( "</$tag>" );
    ## return( $arr->join( $self->children->length > 1 ? "\n" : '' )->scalar );
    return( $arr->join( "\n" )->scalar );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Paragraph - Markdown Paragraph Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Paragraph->new;
    # or
    $doc->add_element( $o->create_paragraph( @_ ) );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This class represents a paragraph. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the paragraph formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the paragraph formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the paragraph.

It returns a plain string.

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#p>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
