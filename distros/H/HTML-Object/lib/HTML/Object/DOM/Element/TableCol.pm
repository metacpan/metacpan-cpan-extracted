##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/TableCol.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/08
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::TableCol;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :tablecol );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    # Can either be col or colgroup
    $self->{tag} = 'colgroup' if( !defined( $self->{tag} ) || !CORE::length( "$self->{tag}" ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Note: deprecated property align is inherited

# Note: deprecated property ch
sub ch : lvalue { return( shift->_set_get_property( 'ch', @_ ) ); }

# Note: deprecated property chOff
sub chOff : lvalue { return( shift->_set_get_property( 'choff', @_ ) ); }

sub choff : lvalue { return( shift->chOff( @_ ) ); }

# Note: property span
sub span : lvalue { return( shift->_set_get_property( 'span', @_ ) ); }

# Note: deprecated property vAlign
sub vAlign : lvalue { return( shift->_set_get_property( 'valign', @_ ) ); }

sub valign : lvalue { return( shift->vAlign( @_ ) ); }

# Note: deprecated property width is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::TableCol - HTML Object DOM TableCol Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::TableCol;
    my $col = HTML::Object::DOM::Element::TableCol->new || 
        die( HTML::Object::DOM::Element::TableCol->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties (beyond the L<HTML::Object::DOM::Element> interface it also has available to it inheritance) for manipulating single or grouped table column elements using the C<colgroup> or C<col> HTML tag.

The <colgroup> HTML element defines a group of columns within a table. The <col> HTML element defines a column within a table and is used for defining common semantics on all common cells. It is generally found within a <colgroup> element.

    <table>
        <colgroup span="4">Countries information</colgroup>
            <col>
            <col class="economic">
            <col span="2" class="people">
        </colgroup>
        <tr>
            <th>Countries</th>
            <th>Capitals</th>
            <th>Population</th>
            <th>Language</th>
        </tr>
        <tr>
            <td>Japan</td>
            <td>Tokyo</td>
            <td>126 million</td>
            <td>Japanese</td>
        </tr>
        <tr>
            <td>Taiwan</td>
            <td>Taipei</td>
            <td>23 million</td>
            <td>Traditional Chinese</td>
        </tr>
    </table>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::TableCol |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 span

Is an unsigned long that reflects the span HTML attribute, indicating the number of columns to apply this object's attributes to. Must be a positive integer.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableColElement/span>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 DEPRECATED PROPERTIES

=head2 align

Is a string that indicates the horizontal alignment of the cell data in the column.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableColElement/align>

=head2 ch

Is a string representing the alignment character for cell data.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableColElement/ch>

=head2 chOff

Is a string representing the offset for the alignment character.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableColElement/chOff>

=head2 choff

Alias for L</chOff>

=head2 vAlign

Is a string that indicates the vertical alignment of the cell data in the column.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableColElement/vAlign>

=head2 valign

Alias for L</vAlign>

=head2 width

Is a string representing the default column width.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableColElement/width>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableColElement>, L<Mozilla documentation on tablecol element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tablecol>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
