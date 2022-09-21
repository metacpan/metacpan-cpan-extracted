##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/ListItem.pm
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
package Markdown::Parser::ListItem;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use vars qw( $VERSION );
    use Devel::Confess;
    use constant TAB_SPACES => '    ';
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{indent}     = '';
    $self->{order}      = '';
    $self->{type}       = '';
    $self->{tag_name}   = 'list_item';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_markdown })->join( '' );
    my $order_list = $self->order;
    # Set some default value since key information has not been set yet
    unless( $self->type->length )
    {
        if( $order_list )
        {
            $self->type( '1.' );
        }
        else
        {
            $self->type( '*' );
        }
    }
    my $marker = $self->type;
    $marker .= '.' if( $marker =~ /^\d+$/ );
    my $indent = '    ' x $self->indent;
    my $lines = $self->new_array( [split( /\n/, $str )] );
    substr( $lines->[0], 0, 0 ) = "${marker} ";
    # If the list has indentation, indent each lines of the string in this list item
    if( $self->indent > 0 )
    {
        $lines->for(sub
        {
            my( $i, $val ) = @_;
            substr( $lines->[$i], 0, 0 ) = $indent;
        });
    }
    return( $lines->join( "\n" )->scalar );
}

sub as_pod
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_pod })->join( '' );
    my $order_list = $self->order;
    # Set some default value since key information has not been set yet
    unless( $self->type->length )
    {
        if( $order_list )
        {
            $self->type( '1.' );
        }
        else
        {
            $self->type( '*' );
        }
    }
    my $marker = $self->type;
    $marker .= '.' if( $marker =~ /^\d+$/ );
    return( "=item ${marker} ${str}" );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr  = $self->new_array;
    my $tag  = 'li';
    my $tag_open = $tag;
    my $tmp = $self->new_array( [ "<$tag_open" ] );
    my $attr = $self->new_array;
    $attr->push( $self->format_id ) if( $self->id->length );
    $attr->push( $self->format_class ) if( $self->class->length );
    my $attributes = $self->format_attributes;
    $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    $tmp->push( ' ' . $attr->join( ' ' )->scalar ) if( $attr->length );
    $tmp->push( '>' );
    $arr->push( ( TAB_SPACES x $self->indent ) . $tmp->join( '' )->scalar );
    my $text_array = $self->children->map(sub{ $_->as_string });
    $arr->push( $text_array->list ) if( $text_array->length );
    ## We provide indentation on the closing tag if it is not on the same line, typical of a one line enclosed text
    $arr->push( TAB_SPACES x $self->indent ) if( $text_array->length > 1 );
    $arr->push( "</$tag>" );
    ## If the enclosed text has new lines embedded, we position the enclosing <li></li> on a new line each
    ## return( $arr->join( $text_array->length > 1 ? "\n" : '' )->scalar );
    return( $arr->join( '' )->scalar );
}

sub indent { return( shift->_set_get_number_as_object( 'indent', @_ ) ); }

sub order { return( shift->_set_get_boolean( 'order', @_ ) ); }

# sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }
sub type
{
    my $self = shift( @_ );
    if( @_ )
    {
        ## Ex: *, +, -, 1, 2, 3....
        my $char = shift( @_ );
        return( $self->error( "No character provided to set this list item type. Alternatively you can use the order() method to set it directly." ) ) if( !length( $char ) );
        $self->_set_get_scalar_as_object( 'type', $char );
        my $type;
        if( $char =~ /^\+|\-|\*$/ )
        {
            $type = 0;
        }
        elsif( $char =~ /^\d+\.?$/ )
        {
            $type = 1;
        }
        else
        {
            return( $self->error( "Clueless about what type of list corresponds to this character \"$char\"." ) );
        }
        $self->order( $type );
    }
    return( $self->_set_get_scalar_as_object( 'type' ) );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::ListItem - Markdown ListItem Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::ListItem->new;
    # or
    $doc->add_element( $o->create_list_item( @_ ) );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class represents a list item. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the list item formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the list item formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the list item.

It returns a plain string.

=head2 indent

Sets or gets the indent level. This takes an integer as value and stores it as a L<Module::Generic::Number>

Returns the current value.

=head2 order

Takes a boolean value. True when the list is ordered or false otherwise.

The value is stored as a L<Module::Generic::Boolean> and it returns the current value.

=head2 type

Sets or gets the list item type. Value provided should be one of C<+>, C<->, C<*>, or a digit

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#list>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
