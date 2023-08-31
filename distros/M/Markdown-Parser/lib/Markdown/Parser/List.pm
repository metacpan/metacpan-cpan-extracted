##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/List.pm
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
package Markdown::Parser::List;
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
    $self->{tag_name}   = 'list';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    my $base_class = $self->base_class;
    my $order_list = $self->order;
    my $n = 0;
    $self->children->foreach(sub
    {
        my $li = shift( @_ );
        # Skip unless this child it a list item
        return(1) unless( $li->isa( "${base_class}::ListItem" ) );
        $n++;
        if( $order_list )
        {
            $li->type( "${n}." );
        }
        elsif( !$li->type->length )
        {
            $li->type( '*' );
        }
    });
    return( $self->children->map(sub{ $_->as_markdown })->join( "\n" )->scalar );
}

# Basically same as markdown
sub as_pod
{
    my $self = shift( @_ );
    my $base_class = $self->base_class;
    my $order_list = $self->order;
    my $n = 0;
    $self->children->foreach(sub
    {
        my $li = shift( @_ );
        # Skip unless this child it a list item
        return(1) unless( $li->isa( "${base_class}::ListItem" ) );
        $n++;
        if( $order_list )
        {
            $li->type( "${n}." );
        }
        elsif( !$li->type->length )
        {
            $li->type( '*' );
        }
    });
    my $indent = $self->indent;
    $indent = 4 unless( $indent > 0 );
    return( "=over ${indent}\n\n" . $self->children->map(sub{ $_->as_pod })->join( "\n\n" )->scalar . "\n\n=back" );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr  = $self->new_array;
    my $tag = $self->order ? 'ol' : 'ul';
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
    # my $ct = $self->new_array;
    $arr->push( $self->children->map(sub
    {
        $_->as_string;
    })->list );
    $arr->push( ( TAB_SPACES x $self->indent ) . "</$tag>" );
    return( $arr->join( "\n" )->scalar );
}

sub indent { return( shift->_set_get_number_as_object( 'indent', @_ ) ); }

sub order { return( shift->_set_get_boolean( 'order', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::List - Markdown List Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::List->new;
    # or
    $doc->add_element( $o->create_list( @_ ) );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class represents a list. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the list formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the list formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the list.

It returns a plain string.

=head2 indent

Sets or gets the indent level. This takes an integer as value and stores it as a L<Module::Generic::Number>

Returns the current value.

=head2 order

Takes a boolean value. True when the list is ordered or false otherwise.

The value is stored as a L<Module::Generic::Boolean> and it returns the current value.

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#list>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
