package HTML::TableContent::Table::Row;

use Moo;

our $VERSION = '0.18';

use HTML::TableContent::Table::Header;
use HTML::TableContent::Table::Row::Cell;

extends 'HTML::TableContent::Element';

has cells => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] },
);

has header => (
    is   => 'rw',
    lazy => 1,
);

has '+html_tag' => (
    default => 'tr',
);

around raw => sub {
    my ( $orig, $self ) = ( shift, shift );

    my $row = $self->$orig(@_);

    my @cells = map { $_->raw } $self->all_cells;
    $row->{cells} = \@cells;
    
    return $row;
};

around has_nested => sub {
    my ( $orig, $self ) = ( shift, shift );

    my $nested = $self->$orig(@_);

    foreach my $cell ( $self->all_cells ) {
        if ( $cell->has_nested ) {
            $nested = 1;
        }
    }

    return $nested;
};

sub hash {
    my $hash = { };
    map { $hash->{$_->header->text} = $_->text } $_[0]->all_cells;
    return $hash;
}

sub array {
    my @row = map { $_->text } $_[0]->all_cells;
    return @row;
}

sub add_header { 
    my $header = HTML::TableContent::Table::Header->new($_[1]);
    $_[0]->header($header); 
    return $header;
}

sub add_cell { 
    my $cell = HTML::TableContent::Table::Row::Cell->new($_[1]);
    push @{ $_[0]->cells }, $cell;
    return $cell;
}

sub cell_count { return scalar @{ $_[0]->cells }; }

sub all_cells { return @{ $_[0]->cells }; }

sub get_cell { return $_[0]->cells->[ $_[1] ]; }

sub get_first_cell { return $_[0]->get_cell(0); }

sub get_last_cell { return $_[0]->get_cell( $_[0]->cell_count - 1 ); }

sub clear_cell { return splice @{ $_[0]->cells }, $_[1], 1; }

sub clear_first_cell { return shift @{ $_[0]->cells }; }

sub clear_last_cell { return $_[0]->clear_cell( $_[0]->cell_count - 1 ); }

sub _filter_headers {
    my ( $self, $headers ) = @_;
    my $cells = [];
    foreach my $cell ( $self->all_cells ) {
        for ( @{$headers} ) {
            if ( $cell->header->text eq $_->text ) {
                push @{$cells}, $cell;
            }
        }
    }
    return $self->cells($cells);
}

sub _render_element {
    my @cells = map { $_->render } $_[0]->all_cells;
    my $cell = sprintf '%s' x @cells, @cells;
    return $cell;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::TableContent::Table::Row - base class for table rows.

=head1 VERSION

Version 0.18

=head1 SYNOPSIS

    use HTML::TableContent;
    my $t = HTML::TableContent->new()->parse($string);

    my $row = $t->get_first_table->get_first_row;

    $row->attributes;
    $row->class;
    $row->id;

    $row->cell_count;
    foreach my $cell ( $row->all_cells ) {
        ...
    }

=cut

=head1 DESCRIPTION

base class for rows

=head1 SUBROUTINES/METHODS

=head2 raw

Return underlying data structure

    $row->raw;

=head2 render

Render the row as html.

    $row->render;

=head2 attributes

HashRef consiting of the tags attributes

    $row->attributes;

=head2 class

Row tag class if found.

    $row->class;

=head2 id

Row tag id if found.

    $row->id;

=head2 cells

ArrayRef of L<HTML::TableContent::Row::Cell>'s

    $row->cells;

=head2 all_cells

Array of L<HTML::TableContent::Row::Cell>'s

    $row->all_cells;

=head2 add_cell

Add a L<HTML::TableContent::Row::Cell> to the row.

    $row->add_cell({ id => 'cell-1', text => 'some text' });

=head2 cell_count

Count number of Cell's inside the Row.

    $row->cell_count

=head2 get_cell

Get Cell from Row by index.

    $row->get_cell($index);

=head2 get_first_cell

Get the first Cell from the Row.

    $row->get_first_cell;

=head2 get_last_cell

Get the last Cell from the Row.

    $row->get_last_cell;

=head2 clear_cell

Clear cell from row by index.

    $row->clear_cell($index);

=head2 clear_first_cell

Clear the first cell from the Row.

    $row->clear_first_cell;

=head2 clear_last_cell

Clear the last cell from the Row.

    $row->clear_last_cell;

=head2 has_nested

Boolean returns true if the row cell's has nested tables.

    $row->has_nested;

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

=head1 SUPPORT

=head1 ACKNOWLEDGEMENTS

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


