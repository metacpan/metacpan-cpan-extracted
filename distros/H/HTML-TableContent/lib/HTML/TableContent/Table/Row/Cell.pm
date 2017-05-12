package HTML::TableContent::Table::Row::Cell;

use Moo;

our $VERSION = '0.18';

extends 'HTML::TableContent::Element';

has header => ( is => 'rw' );

has '+html_tag' => (
    default => 'td',
);

around _render_element => sub {
    my ( $orig, $self ) = (shift, shift); 

    my $text = $self->$orig(@_);

    if ($self->has_nested) {
        my @nested = map { $_->render } $self->all_nested;
        my $nest = sprintf '%s' x @nested, @nested;
        $text = sprintf '%s%s', $text, $nest;
    } 
        
    return $text;
};

sub header_template_attr {
    return $_[0]->header->template_attr;
}

sub header_text {
    return $_[0]->header->text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::TableContent::Table::Row::Cell - base class for table cells.

=head1 VERSION

Version 0.18

=head1 SYNOPSIS

    use HTML::TableContent;
    my $t = HTML::TableContent->new()->parse($string);

    my $cell = $t->get_first_table->get_first_row->get_first_cell;
    
    $cell->data;
    $cell->text;

    $cell->header;

    $cell->attributes;
    $cell->class;
    $cell->id;

=cut

=head1 DESCRIPTION

base class for table cells

=head1 SUBROUTINES/METHODS

=head1 METHODS

=head2 raw

Return underlying data structure

    $row->raw

=head2 data

ArrayRef of Text elements

    $cell->data;

=head2 text

data as a string joined with a  ' '

    $cell->text;

=head2 header

Column Header, L<HTML::TableContent::Table::Header>.

    $cell->header;

=head2 attributes

HashRef consiting of the tags attributes

    $cell->attributes;

=head2 class

Cell tag class if found.

    $cell->class;

=head2 id

Cell tag id if found.

    $cell->id;

=head2 nested

ArrayRef of nested Tables.

    $cell->nested

=head2 all_nested

Array of nested Tables.

    $cell->all_nested

=head2 has_nested

Boolean check, returns true if the cell has nested tables.

    $cell->has_nested

=head2 count_nested

Count number of nested tables.

    $cell->count_nested

=head2 get_first_nested

Get the first nested table.

    $cell->get_first_nested

=head2 get_nested

Get Nested table by index.

    $cell->get_nested(1);

=head2 add_nested

Add nested L<HTML::TableContent::Table> to the Cell.

    $cell->add_nested({ id => 'nested-table-id', class => 'nested-table-class' }); 

=head2 links

ArrayRef of href links.

    $cell->links;

=head2 all_links

Array of links.

    $cell->links

=head2 has_links

Boolean check, returns true if the element has links.

    $cell->has_links

=head2 count_links

Count number of links.

    $cell->count_links

=head2 get_first_link

Get the first nested table.

    $cell->get_first_link

=head2 get_last_link

Get the first nested table.

    $cell->get_last_link

=head2 get_link

Get Nested table by index.

    $cell->get_link(1);

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

=head1 SUPPORT

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT 

=head1 INCOMPATIBILITIES

=head1 DEPENDENCIES

L<Moo>,
L<HTML::Parser>,
L<HTML::TableContent::Parser>,
L<HTML::TableContent::Table>,
L<HTML::TableContent::Table::Caption>,
L<HTML::TableContent::Table::Header>,
L<HTML::TableContent::Table::Row>,
L<HTML::TableContent::Table::Row::Cell>

=head1 BUGS AND LIMITATIONS

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2016 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
