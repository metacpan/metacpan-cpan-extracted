## -*- perl -*-
##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Abbr.pm
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
package Markdown::Parser::Abbr;
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
    $self->{name}       = '';
    $self->{tag_name}   = 'abbr';
    $self->{value}      = '';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    return( sprintf( '*[%s]: %s', $self->name, $self->value ) );
}

sub as_string
{
    my $self = shift( @_ );
    my $val = $self->value->scalar;
    $self->encode_html( [qw( < > & " ' )], \$val );
    my $tag_open = $self->tag_name;
    my $arr  = $self->new_array;
    $arr->push( "<${tag_open}" );
    $arr->push( $self->format_id ) if( $self->id->length );
    $arr->push( $self->format_class ) if( $self->class->length );
    $arr->push( sprintf( 'title="%s"', $val ) );
    my $attributes = $self->format_attributes;
    $arr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    ## e.g. <abbr title="Hyper Text Markup Language">HTML</abbr>
    return( sprintf( '%s>%s</abbr>', $arr->join( ' ' )->scalar, $self->name->scalar ) );
}

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub value { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Abbr - Markdown Abbreviation Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Abbr->new;
    # or
    $doc->add_element( $o->create_abbr( @_ ) );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents an abbreviation. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

For example:

    *[HTML]: Hyper Text Markup Language
    *[W3C]:  World Wide Web Consortium

Then, anywhere in the markdown document, one can write:

    The HTML specification is maintained by the W3C.

And this would produce the following html:

    The <abbr title="Hyper Text Markup Language">HTML</abbr> specification
    is maintained by the <abbr title="World Wide Web Consortium">W3C</abbr>.

=head1 METHODS

=head2 as_markdown

Returns a string representation of the abbreviation formatted in markdown.

It returns a plain string.

=head2 as_string

Returns an html representation of the abbreviation.

It returns a plain string.

=head2 name

Sets or gets the name of the abbreviation. The value is stored as an L<Module::Generic::Scalar> object.

=head2 value

Sets or gets the value of the abbreviation. The value is stored as an L<Module::Generic::Scalar> object.

=head1 SEE ALSO

L<https://michelf.ca/projects/php-markdown/extra/#abbr>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
