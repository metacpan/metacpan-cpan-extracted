##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/TableRow.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/07
## Modified 2022/01/07
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::TableRow;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :tablerow );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'tr' if( !CORE::length( "$self->{tag}" ) );
    $self->{_row_reset} = 1;
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

# Note: deprecated property bgColor
sub bgColor : lvalue { return( shift->_set_get_property( 'bgcolor', @_ ) ); }

sub bgcolor : lvalue { return( shift->bgColor( @_ ) ); }

# Note: property cells read-only
sub cells
{
    my $self = shift( @_ );
    return( $self->{_row_cells} ) if( $self->{_row_cells} && !$self->_is_row_reset );
    my $list = $self->children->grep(sub{ $self->_is_a( $_ => 'HTML::Object::DOM::Element::TableCell' ) });
    $self->messagef( 3, "List $list returned %d elements with %d children.", $list->length, $self->children->length );
    # The content of the collection is refreshed, but the collection object itself does not change, so the user can poll it
    unless( $self->{_row_cells} )
    {
        $self->_load_class( 'HTML::Object::DOM::Collection' ) || return( $self->pass_error );
        $self->{_row_cells} = HTML::Object::DOM::Collection->new || 
            return( $self->pass_error( HTML::Object::DOM::Collection->error ) );
    }
    $self->{_row_cells}->set( $list );
    $self->_remove_row_reset;
    return( $self->{_row_cells} );
}

# Note: deprecated property ch
sub ch : lvalue { return( shift->_set_get_property( 'ch', @_ ) ); }

# Note: deprecated property chOff
sub chOff : lvalue { return( shift->_set_get_property( 'choff', @_ ) ); }

sub choff : lvalue { return( shift->chOff( @_ ) ); }

sub deleteCell
{
    my $self = shift( @_ );
    my $pos  = shift( @_ );
    return( $self->error({
        message => "Value provided (" . overload::StrVal( $pos // '' ) . ") is not an integer.",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( !defined( $pos ) || !$self->_is_integer( $pos ) );
    my $cells = $self->cells;
    my $size = $cells->cells;
    return( $self->error({
        message => "Value provided ($pos) is greater than the zero-based number of cells available (${size}).",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $pos > $size );
    return( $self->error({
        message => "Value provided ($pos) is lower than the zero-based number of cells available (${size}). If you want to specify a negative index, it must be between -1 and -${size}",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $pos < 0 && abs( $pos ) > $size );
    $pos = ( $cells->length + $pos ) if( $pos < 0 );
    my $elem = $cells->index( $pos );
    my $children = $self->children;
    my $kid_pos = $children->pos( $elem );
    return( $self->error({
        message => "Unable to find the cell element among this row children!",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $kid_pos ) );
    $children->splice( $kid_pos, 1 );
    $elem->parent( undef );
    $self->reset(1);
    return( $elem );
}

sub insertCell
{
    my $self = shift( @_ );
    my $pos  = shift( @_ );
    my $cells = $self->cells;
    my $size = $cells->size;
    if( defined( $pos ) )
    {
        return( $self->error({
            message => "Value provided (" . overload::StrVal( $pos // '' ) . ") is not an integer.",
            class => 'HTML::Object::IndexSizeError',
        }) ) if( !$self->_is_integer( $pos ) );
        return( $self->error({
            message => "Value provided ($pos) is greater than the zero-based number of cells available (${size}).",
            class => 'HTML::Object::IndexSizeError',
        }) ) if( $pos > $size );
        return( $self->error({
            message => "Value provided ($pos) is lower than the zero-based number of cells available (${size}). If you want to specify a negative index, it must be between -1 and -${size}",
            class => 'HTML::Object::IndexSizeError',
        }) ) if( $pos < 0 && abs( $pos ) > $size );
        $pos = ( $cells->length + $pos ) if( $pos < 0 );
    }
    $self->_load_class( 'HTML::Object::DOM::Element::TableCell' ) || return( $self->pass_error );
    my $children = $self->children;
    my $cell = HTML::Object::DOM::Element::TableCell->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Element::TableCell->error ) );
    $cell->close;
    # A position was provided
    if( defined( $pos ) )
    {
        # ..., but there are no cells yet
        if( $cells->is_empty )
        {
            $children->push( $cell );
        }
        else
        {
            my $elem = $cells->index( $pos );
            return( $self->error({
                message => "No element could be found at row index $pos",
                class => 'HTML::Object::HierarchyRequestError',
            }) ) if( !defined( $elem ) );
            my $kid_pos = $children->pos( $elem );
            if( !defined( $kid_pos ) )
            {
                return( $self->error({
                    message => "Could not find a value at offset $pos (translated to $kid_pos among the row children) amazingly enough.",
                    class => 'HTML::Object::HierarchyRequestError',
                }) );
            }
            $children->splice( $kid_pos, 0, $cell );
        }
    }
    # otherwise, there are already other cells directly under <tr> and the new cell is just added at the end of the row.
    else
    {
        $children->push( $cell );
    }
    $cell->parent( $self );
    $self->reset(1);
    return( $cell );
}

sub reset
{
    my $self = shift( @_ );
    if( scalar( @_ ) )
    {
        $self->_reset_row;
        return( $self->SUPER::reset( @_ ) );
    }
    return( $self );
}

# Note: property rowIndex read-only
sub rowIndex
{
    my $self = shift( @_ );
    my $parent = $self->parent || return;
    my $siblings = $parent->children;
    my $pos = $siblings->pos( $self );
    return( $pos );
}

# Note: property sectionRowIndex read-only
sub sectionRowIndex
{
    my $self = shift( @_ );
    my $parent = $self->parent || return;
    if( $self->_is_a( $parent => 'HTML::Object::DOM::Element::TableSection' ) )
    {
        return( $parent->children->pos( $self ) );
    }
    return;
}

# Note: deprecated property vAlign
sub vAlign : lvalue { return( shift->_set_get_property( 'valign', @_ ) ); }

sub valign : lvalue { return( shift->vAlign( @_ ) ); }

sub _is_row_reset { return( CORE::length( shift->{_row_reset} ) ); }

sub _remove_row_reset { return( CORE::delete( shift->{_row_reset} ) ); }

sub _reset_row
{
    my $self = shift( @_ );
    $self->{_row_reset}++;
    # Force it to recompute
    $self->cells;
    if( my $parent = $self->parent )
    {
        $parent->_reset_section if( $parent->can( '_reset_section' ) );
    }
    return( $self );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::TableRow - HTML Object DOM TableRow Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::TableRow;
    my $tablerow = HTML::Object::DOM::Element::TableRow->new || 
        die( HTML::Object::DOM::Element::TableRow->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties and methods (beyond the L<HTML::Object::DOM::Element> interface it also has available to it by inheritance) for manipulating the layout and presentation of rows (i.e. C<tr>) in an HTML table.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::TableRow |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 cells

Read-only.

Returns a L<collection|HTML::Object::DOM::Collection> containing the cells in the row, but only the ones directly under the row element.

Note that for performance improvement, the collection is cached until changes are made that would affect the results.

Example:

    <table id="myTable1">
        <tr>
            <td>
                <table id="myTable2">
                    <tr><td></td></tr>
                </table>
            </td>
            <td></td>
        </tr>
    </table>

    say getElementById('myTable1')->rows->[0]->cells->length; # 2
    say getElementById('myTable2')->rows->[0]->cells->length; # 1

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement/cells>

=head2 rowIndex

Read-only.

Returns a long value which gives the logical position of the row within the entire table. If the row is not part of a table, returns C<undef> (C<-1> under JavaScript).

Example:

    <table>
        <thead>
            <tr><th>Item</th>        <th>Price</th></tr>
        </thead>
        <tbody>
            <tr><td>Bananas</td>     <td>$2</td></tr>
            <tr><td>Oranges</td>     <td>$8</td></tr>
            <tr><td>Top Sirloin</td> <td>$20</td></tr>
        </tbody>
        <tfoot>
            <tr><td>Total</td>       <td>$30</td></tr>
        </tfoot>
    </table>

Another example:

    my $rows = $doc->querySelectorAll('tr');

    $rows->forEach(sub
    {
        my $row = shift( @_ );
        my $z = $doc->createElement('td');
        $z->textContent = "(row #" . $row->rowIndex . ")";
        row->appendChild($z);
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement/rowIndex>

=head2 sectionRowIndex

Read-only.

Returns a long value which gives the logical position of the row within the table section it belongs to. If the row is not part of a section, returns C<undef> (C<-1> under JavaScript).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement/sectionRowIndex>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 deleteCell

Removes the cell corresponding to the C<index> given in parameter. If the C<index> value is C<-1> the last cell is removed; if it smaller than C<-1> or greater than the amount of cells in the collection, an C<HTML::Object::IndexSizeError> is returned.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement/deleteCell>

=head2 insertCell

Returns an L<HTML::Object::DOM::Element::TableCell> representing a new cell of the table. It inserts it in the L<cells collection|/cells> immediately before a C<td> or C<th> element at the given C<index> position, if any was provided.

If the C<index> is not given or is C<-1>, the new cell is appended to the collection. If the C<index> is smaller than C<-1>, it will start that far back from the end of the collection array. If C<index> is greater than the number of cells in the collection, an C<HTML::Object::IndexSizeError> error is returned.

Example:

    <table id="my-table">
        <tr><td>Row 1</td></tr>
        <tr><td>Row 2</td></tr>
        <tr><td>Row 3</td></tr>
    </table>

    sub addRow
    {
        my $tableID = shift( @_ );
        # Get a reference to the table
        my $tableRef = $doc->getElementById( $tableID );

        # Insert a row at the end of the table
        my $newRow = $tableRef->insertRow( -1 );

        # Insert a cell in the row at index 0
        my $newCell = $newRow->insertCell( 0 );

        # Append a text node to the cell
        my $newText = $doc->createTextNode('New bottom row');
        $newCell->appendChild( $newText );
    }

    # Call addRow() with the table's ID
    addRow( 'my-table' );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement/insertCell>

=head1 DEPRECATED PROPERTIES

=head2 align

Is a string containing an enumerated value reflecting the align attribute. It indicates the alignment of the element's contents with respect to the surrounding context. The possible values are "left", "right", and "center".

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement/align>

=head2 bgColor

Is a string containing the background color of the cells. It reflects the obsolete bgcolor attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement/bgColor>

=head2 bgcolor

Alias for L</bgColor>

=head2 ch

Is a string containing one single character. This character is the one to align all the cell of a column on. It reflects the char and default to the decimal points associated with the language, e.g. '.' for English, or ',' for French. This property was optional and was not very well supported.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement/ch>

=head2 chOff

Is a string containing a integer indicating how many characters must be left at the right (for left-to-right scripts; or at the left for right-to-left scripts) of the character defined by L<HTML::Object::DOM::Element::C<TableRow>>.ch. This property was optional and was not very well supported.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement/chOff>

=head2 choff

Alias for L</chOff>

=head2 reset

When called, this will set a boolean value indicating the cached data must be recomputed. This allow the saving of computational power,

=head2 vAlign

Is a string representing an enumerated value indicating how the content of the cell must be vertically aligned. It reflects the valign attribute and can have one of the following values: "top", "middle", "bottom", or "baseline".

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement/vAlign>

=head2 valign

Alias for L</vAlign>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableRowElement>, L<Mozilla documentation on tablerow element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tablerow>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

