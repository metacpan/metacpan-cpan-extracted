##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/TableCell.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/07
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::TableCell;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :tablecell );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    # Could be also <th>
    $self->{tag} = 'td' if( !defined( $self->{tag} ) || !CORE::length( "$self->{tag}" ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_set_get_internal_attribute_callback( headers => sub
    {
        my( $this, $val ) = @_;
        my $list;
        return if( !( $list = $this->{_headers_list} ) );
        # $list->debug( $self->debug );
        $list->update( $val );
    });
    return( $self );
}

# Note: property abbr
sub abbr : lvalue { return( shift->_set_get_property( 'abbr', @_ ) ); }

# Note: deprecated property align is inherited

# Note: deprecated property axis
sub axis : lvalue { return( shift->_set_get_property( 'axis', @_ ) ); }

# Note: deprecated property bgColor
sub bgColor : lvalue { return( shift->_set_get_property( 'bgcolor', @_ ) ); }

sub bgcolor : lvalue { return( shift->bgColor( @_ ) ); }

# Note: property cellIndex read-only
sub cellIndex
{
    my $self = shift( @_ );
    my $parent = $self->parent || return;
    my $siblings = $parent->children;
    my $pos = $siblings->pos( $self );
    return( $pos );
}

# Note: deprecated property ch
sub ch : lvalue { return( shift->_set_get_property( 'ch', @_ ) ); }

# Note: deprecated property chOff
sub chOff : lvalue { return( shift->_set_get_property( 'choff', @_ ) ); }

sub choff : lvalue { return( shift->chOff( @_ ) ); }

# Note: property colSpan
sub colSpan : lvalue { return( shift->_set_get_property( 'colspan', @_ ) ); }

sub colspan : lvalue { return( shift->colSpan( @_ ) ); }

# Note: property colgroup
sub colgroup : lvalue { return( shift->_set_get_property( 'colgroup', @_ ) ); }

# Note: property headers read-only
sub headers
{
    my $self = shift( @_ );
    unless( $self->{_headers_list} )
    {
        my $headers  = $self->attr( 'headers' );
        require HTML::Object::TokenList;
        $self->{_headers_list} = HTML::Object::TokenList->new( $headers, element => $self, attribute => 'headers', debug => $self->debug ) ||
            return( $self->pass_error( HTML::Object::TokenList->error ) );
    }
    return( $self->{_headers_list} );
}

# Note: deprecated property height is inherited

# Note: deprecated property noWrap
sub noWrap : lvalue { return( shift->_set_get_property( 'nowrap', @_ ) ); }

sub nowrap : lvalue { return( shift->noWrap( @_ ) ); }

# Note: property rowSpan
sub rowSpan : lvalue { return( shift->_set_get_property( 'rowspan', @_ ) ); }

sub rowspan : lvalue { return( shift->rowSpan( @_ ) ); }

# Note: property scope
sub scope : lvalue { return( shift->_set_get_property( 'scope', @_ ) ); }

# Note: deprecated property vAlign
sub vAlign : lvalue { return( shift->_set_get_property( 'valign', @_ ) ); }

sub valign : lvalue { return( shift->vAlign( @_ ) ); }

# Note: deprecated property width is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::TableCell - HTML Object DOM TableCell Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::TableCell;
    my $cell = HTML::Object::DOM::Element::TableCell->new( tag => 'th' ) || 
        die( HTML::Object::DOM::Element::TableCell->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties and methods (beyond the regular L<HTML::Object::DOM::Element> interface it also has available to it by inheritance) for manipulating the layout and presentation of table cells, either header (C<th>) or data cells (C<td>), in an HTML document.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::TableCell |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 abbr

A string which can be used on C<th> elements (not on C<td>), specifying an alternative label for the header cell. This alternate label can be used in other contexts, such as when describing the headers that apply to a data cell. This is used to offer a shorter term for use by screen readers in particular, and is a valuable accessibility tool. Usually the value of abbr is an abbreviation or acronym, but can be any text that's appropriate contextually.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/abbr>

=head2 cellIndex

Read-only.

A long integer representing the cell's position in the cells collection of the C<tr> the cell is contained within. If the cell does not belong to a C<tr>, it returns C<undef> (C<-1> normally under JavaScript).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/cellIndex>

=head2 colSpan

An unsigned long integer indicating the number of columns this cell must span; this lets the cell occupy space across multiple columns of the table. It reflects the colspan HTML attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/colSpan>

=head2 colspan

Alias for L</colSpan>

=head2 headers

Read-only.

A L<TokenList|HTML::Object::TokenList> describing a list of id of C<th> elements that represents headers associated with the cell. It reflects the headers HTML attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/headers>

=head2 rowSpan

An unsigned long integer indicating the number of rows this cell must span; this lets a cell occupy space across multiple rows of the table. It reflects the rowspan HTML attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/rowSpan>

=head2 rowspan

Alias for L</rowSpan>

=head2 scope

A string indicating the scope of a C<th> cell. Header cells can be configured, using the scope property, the apply to a specified row or column, or to the not-yet-scoped cells within the current row group (that is, the same ancestor L<thead|HTML::Object::DOM::Element::TableSection>, L<tbody|HTML::Object::DOM::Element::TableSection>, or L<tfoot|HTML::Object::DOM::Element::TableSection> element). If no value is specified for scope, the header is not associated directly with cells in this way. Permitted values for scope are:

Note that, under perl, those values are not enforced.

=over 4

=item col

The header cell applies to the following cells in the same column (or columns, if colspan is used as well), until either the end of the column or another C<th> in the column establishes a new scope.

=item colgroup

The header cell applies to all cells in the current column group that do not already have a scope applied to them. This value is only allowed if the cell is in a column group.

=item row

The header cell applies to the following cells in the same row (or rows, if rowspan is used as well), until either the end of the row or another C<th> in the same row establishes a new scope.

=item rowgroup

The header cell applies to all cells in the current row group that do not already have a scope applied to them. This value is only allowed if the cell is in a row group.

=item The empty string ("")

The header cell has no predefined scope; the user agent will establish the scope based on contextual clues.

=back

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/scope>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 DEPRECATED PROPERTIES

=head2 align

A string containing an enumerated value reflecting the align attribute. It indicates the alignment of the element's contents with respect to the surrounding context. The possible values are C≤left>, C<right>, and C<center>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/align>

=head2 axis

A string containing a name grouping cells in virtual. It reflects the obsolete axis attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/axis>

=head2 bgColor

A string containing the background color of the cells. It reflects the obsolete bgcolor attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/bgColor>

=head2 bgcolor

Alias for L</bgColor>

=head2 ch

A string containing one single chararcter. This character is the one to align all the cell of a column on. It reflects the char and default to the decimal points associated with the language, e.g. '.' for English, or ',' for French. This property was optional and was not very well supported.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/ch>

=head2 chOff

A string containing a integer indicating how many characters must be left at the right (for left-to-right scripts; or at the left for right-to-left scripts) of the character defined by L</ch>. This property was optional and was not very well supported.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/chOff>

=head2 choff

Alias for L</chOff>

=head2 height

A string containing a length of pixel of the hinted height of the cell. It reflects the obsolete height HTML attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/height>

=head2 noWrap

A boolean value reflecting the nowrap HTML attribute and indicating if cell content can be broken in several lines.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/noWrap>

=head2 nowrap

Alias for L</noWrap>

=head2 vAlign

A string representing an enumerated value indicating how the content of the cell must be vertically aligned. It reflects the valign HTML attribute and can have one of the following values: C<top>, C<middle>, C<bottom>, or C<baseline>. Use the CSS vertical-align property instead.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/vAlign>

=head2 valign

Alias for L</vAlign>

=head2 width

A string specifying the number of pixels wide the cell should be drawn, if possible. This property reflects the also obsolete width HTML attribute. Use the CSS width property instead.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement/width>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableCellElement>, L<Mozilla documentation on tablecell element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tablecell>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
