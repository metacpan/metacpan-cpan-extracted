##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/TableSection.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2021/12/23
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::TableSection;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :tablesection );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    # could also be tbody o tfoot
    $self->{tag} = 'thead' if( !CORE::length( "$self->{tag}" ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_section_reset} = 1;
    my $callback = sub
    {
        my $def = shift( @_ );
        # Our children were modified from outside our package.
        # We need to check if it affects our rows and reset the cache accordingly
        unless( $def->{caller}->[0] eq ref( $self ) ||
                $def->{caller}->[0] eq 'HTML::Object::DOM::Element::Table' )
        {
            $self->reset(1);
        }
        return(1);
    };
    $self->children->callback( add => $callback );
    $self->children->callback( remove => $callback );
    return( $self );
}

# Note: deprecated property align is inherited

# Note: deprecated property ch
sub ch : lvalue { return( shift->_set_get_property( 'ch', @_ ) ); }

# Note: deprecated property chOff
sub chOff : lvalue { return( shift->_set_get_property( 'choff', @_ ) ); }

sub deleteRow
{
    my $self = shift( @_ );
    my $pos  = shift( @_ );
    return( $self->error({
        message => "Value provided (" . overload::StrVal( $pos // '' ) . ") is not an integer.",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( !defined( $pos ) || !$self->_is_integer( $pos ) );
    my $rows = $self->rows;
    my $size = $rows->size;
    return( $self->error({
        message => "Value provided ($pos) is greater than the zero-based number of rows available (" . $rows->size . ").",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $pos > $size );
    return( $self->error({
        message => "Value provided ($pos) is lower than the zero-based number of rows available (" . $rows->size . "). If you want to specify a negative index, it must be between -1 and -${size}",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $pos < 0 && abs( $pos ) > $size );
    $pos = ( $rows->length + $pos ) if( $pos < 0 );
    my $elem = $rows->index( $pos );
    my $children = $self->children;
    my $kid_pos = $children->pos( $elem );
    return( $self->error({
        message => "Unable to find the row element among this table children!",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $kid_pos ) );
    $children->splice( $kid_pos, 1 );
    $elem->parent( undef );
    $self->reset(1);
    return( $elem );
}

sub insertRow
{
    my $self = shift( @_ );
    my $pos  = shift( @_ );
    my $rows = $self->rows;
    my $size = $rows->size;
    if( defined( $pos ) )
    {
        return( $self->error({
            message => "Value provided (" . overload::StrVal( $pos // '' ) . ") is not an integer.",
            class => 'HTML::Object::IndexSizeError',
        }) ) if( !$self->_is_integer( $pos ) );
        return( $self->error({
            message => "Value provided ($pos) is greater than the zero-based number of rows available (" . $rows->size . ").",
            class => 'HTML::Object::IndexSizeError',
        }) ) if( $pos > $size );
        return( $self->error({
            message => "Value provided ($pos) is lower than the zero-based number of rows available (" . $rows->size . "). If you want to specify a negative index, it must be between -1 and -${size}",
            class => 'HTML::Object::IndexSizeError',
        }) ) if( $pos < 0 && abs( $pos ) > $size );
        $pos = ( $rows->length + $pos ) if( $pos < 0 );
    }
    $self->_load_class( 'HTML::Object::DOM::Element::TableRow' ) || return( $self->pass_error );
    my $children = $self->children;
    my $row = HTML::Object::DOM::Element::TableRow->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Element::TableRow->error ) );
    $row->close;
    # A position was provided
    if( defined( $pos ) )
    {
        # ..., but there are no rows yet
        if( $rows->is_empty )
        {
            $children->push( $row );
        }
        else
        {
            my $elem = $rows->index( $pos );
            my $kid_pos = $children->pos( $elem );
            if( !defined( $kid_pos ) )
            {
                return( $self->error({
                    message => "Could not find a value at offset $pos (translated to $kid_pos among the table children) amazingly enough.",
                    class => 'HTML::Object::HierarchyRequestError',
                }) );
            }
            $children->splice( $kid_pos, 0, $row );
        }
    }
    # otherwise, there are already other rows directly under <table> and the new row is just added at the end of the table, even if there is a <tfoot> element.
    else
    {
        $children->push( $row );
    }
    $row->parent( $self );
    $self->reset(1);
    return( $row );
}

sub reset
{
    my $self = shift( @_ );
    if( scalar( @_ ) )
    {
        $self->_reset_section;
        return( $self->SUPER::reset( @_ ) );
    }
    return( $self );
}

# Note: property rows read-only
sub rows
{
    my $self = shift( @_ );
    return( $self->{_section_rows} ) if( $self->{_section_rows} && !$self->_is_section_reset );
    my $list = $self->children->grep(sub{ $self->_is_a( $_ => 'HTML::Object::DOM::Element::TableRow' ) });
    $self->messagef( 3, "List $list returned %d elements with %d children.", $list->length, $self->children->length );
    unless( $self->{_section_rows} )
    {
        $self->_load_class( 'HTML::Object::DOM::Collection' ) || return( $self->pass_error );
        $self->{_section_rows} = HTML::Object::DOM::Collection->new ||
            return( $self->pass_error( HTML::Object::DOM::Collection->error ) );
    }
    $self->{_section_rows}->set( $list );
    $self->_remove_section_reset;
    return( $self->{_section_rows} );
}

# Note: deprecated property vAlign
sub vAlign : lvalue { return( shift->_set_get_property( 'valign', @_ ) ); }

sub _is_section_reset { return( CORE::length( shift->{_section_reset} ) ); }

sub _remove_section_reset { return( CORE::delete( shift->{_section_reset} ) ); }

sub _reset_section
{
    my $self = shift( @_ );
    $self->{_section_reset}++;
    # Force cells object update
    $self->rows;
    if( my $parent = $self->parent )
    {
        $parent->_reset_table( $self->{tag} ) if( $parent->can( '_reset_table' ) );
    }
    return( $self );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::TableSection - HTML Object DOM TableSection Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::TableSection;
    my $section = HTML::Object::DOM::Element::TableSection->new || 
        die( HTML::Object::DOM::Element::TableSection->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties and methods (beyond the L<HTML::Object::DOM::Element> interface it also has available to it by inheritance) for manipulating the layout and presentation of sections, that is headers, footers and bodies, in an HTML table.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::TableSection |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 rows

Read-only.

Returns a live L<collection|HTML::Object::DOM::Collection> containing the rows in the section. The L<collection|HTML::Object::DOM::Collection> is live and is automatically updated when rows are added or removed.

Note that for performance improvement, the collection is cached until changes are made that would affect the results.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableSectionElement/rows>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 deleteRow

Removes the row, corresponding to the index given in parameter, in the section. If the index value is C<-1> the last row is removed; if it smaller than C<-1> or greater than the amount of rows in the collection, an C<HTML::Object::IndexSizeError> is returned.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableSectionElement/deleteRow>

=head2 insertRow

Returns an L<HTML::Object::DOM::Element::TableRow> representing a new row of the table. It inserts it in the rows collection immediately before the C<tr> element at the given index position, if any was provided.

If the index is not given or is C<-1>, the new row is appended to the collection. If the index is smaller than C<-1>, it will start that far back from the end of the collection array. If index is greater than the number of rows in the collection, an C<HTML::Object::IndexSizeError> error is returned.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableSectionElement/insertRow>

=head2 reset

Reset the cache flag so that some data will be recomputed. The cache is design to avoid doing useless computing repeatedly when there is no change of data.

=head1 DEPRECATED PROPERTIES

=head2 align

Is a string containing an enumerated value reflecting the align attribute. It indicates the alignment of the element's contents with respect to the surrounding context. The possible values are "left", "right", and "center".

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableSectionElement/align>

=head2 ch

Is a string containing one single chararcter. This character is the one to align all the cell of a column on. It reflects the char and default to the decimal points associated with the language, e.g. '.' for English, or ',' for French. This property was optional and was not very well supported.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableSectionElement/ch>

=head2 chOff

Is a string containing a integer indicating how many characters must be left at the right (for left-to-right scripts; or at the left for right-to-left scripts) of the character defined by L<HTML::Object::DOM::Element::C<TableRow>>.ch. This property was optional and was not very well supported.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableSectionElement/chOff>

=head2 vAlign

Is a string representing an enumerated value indicating how the content of the cell must be vertically aligned. It reflects the valign attribute and can have one of the following values: "top", "middle", "bottom", or "baseline".

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableSectionElement/vAlign>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableSectionElement>, L<Mozilla documentation on tbody element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tbody>, L<Mozilla documentation on thead element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/thead>, L<Mozilla documentation on tfoot element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tfoot>, L<W3C specifications|https://html.spec.whatwg.org/multipage/tables.html>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
