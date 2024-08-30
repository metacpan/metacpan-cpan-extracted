## -*- perl -*-
##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Checkbox.pm
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
package Markdown::Parser::Checkbox;
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
    $self->{tag_name}   = 'checkbox';
    $self->{checked}    = 0;
    $self->{disabled}   = 0;
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    my $checked = $self->checked;
    return( ' [' . ( $checked ? 'X' : ' ' ) . '] ' );
}

sub as_pod
{
    my $self = shift( @_ );
    my $checked = $self->checked;
    return( ' [' . ( $checked ? 'X' : ' ' ) . '] ' );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr  = $self->new_array( [' <input type="checkbox"'] );
    my $checked = $self->checked;
    my $disabled = $self->disabled;
    my $attr = $self->new_array;
    $attr->push( $self->format_id ) if( $self->id->length );
    $attr->push( $self->format_class ) if( $self->class->length );
    my $attributes = $self->format_attributes;
    $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    $arr->push( ' ' . $attr->join( ' ' )->scalar ) if( $attr->length );
    $arr->push( 'disabled' ) if( $disabled );
    $arr->push( 'checked' ) if( $checked );
    $arr->push( '/> ' );
    return( $arr->join( ' ' )->scalar );
}

sub checked { return( shift->_set_get_boolean( 'checked', @_ ) ); }

sub disabled { return( shift->_set_get_boolean( 'disabled', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Checkbox - Markdown Extended Checkbox Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Checkbox->new;
    # or
    $doc->add_element( $o->create_checkbox( @_ ) );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This class represents a checkbox formatting. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the checkbox formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the checkbox formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the checkbox.

It returns a plain string.

=head2 checked

Boolean value that sets the checked status of the checkbox.

=head2 disabled

Boolean value that sets the disabled status of the checkbox.

=head1 SEE ALSO

Markdown original author reference on checkbox: L<https://github.github.com/gfm/#task-list-items-extension->

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
