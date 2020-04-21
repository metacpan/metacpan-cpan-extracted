package HTML::TableContent::Table;

use Moo;

use HTML::TableContent::Table::Caption;
use HTML::TableContent::Table::Header;
use HTML::TableContent::Table::Row;

our $VERSION = '1.00';

extends 'HTML::TableContent::Element';

has caption => ( is => 'rw', lazy => 1 );

has [qw(headers rows)] => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] },
);

has '+html_tag' => (
    default => 'table',
);

my @html5 = qw/html5 thead tbody vertical/;
for (@html5) {
    has $_ => (
        is => 'rw',
        lazy => 1,
        builder => 1,
    );
}

sub _build_html5 {
    return defined $_[0]->attributes->{html5} 
        ? delete $_[0]->attributes->{html5}
        : undef;
}

sub _build_thead {
    return defined $_[0]->attributes->{thead} 
        ? delete $_[0]->attributes->{thead}
        : undef;
}

sub _build_tbody {
    return defined $_[0]->attributes->{tbody} 
        ? delete $_[0]->attributes->{tbody}
        : undef;
}

sub _build_vertical {
    return defined $_[0]->attributes->{vertical}
        ? delete $_[0]->attributes->{vertical}
        : undef;
}

around raw => sub {
    my ( $orig, $self ) = ( shift, shift );

    my $table = $self->$orig(@_);

    if ( defined $self->caption ) { $table->{caption} = $self->caption->text }

    my @headers =  map { $_->raw } $self->all_headers;
    $table->{headers} = \@headers;

    my @rows =  map { $_->raw} $self->all_rows;
    $table->{rows} = \@rows;

    return $table;
};

sub aoa {
    my $aoa = [ ];
    
    my @headers = map { $_->data->[0] } $_[0]->all_headers;
    if ( scalar @headers > 0 ) {
        push @{ $aoa }, \@headers;
    }

    for ( $_[0]->all_rows ) {
       my @row = $_->array;
       push @{ $aoa }, \@row; 
    }
    
    return $aoa;
};

sub aoh {
    my $aoh = [ ];
    for ($_[0]->all_rows) {
        my $hash = $_->hash;
        push @{ $aoh }, $hash;
    }
    return $aoh;
};

sub add_caption { 
    my $caption = HTML::TableContent::Table::Caption->new($_[1]);   
    $_[0]->caption($caption);
    return $caption;
}

sub has_caption { return $_[0]->caption ? 1 : 0 };

sub all_rows { return @{ $_[0]->rows }; }

sub add_row { 
    my $row = HTML::TableContent::Table::Row->new($_[1]);
    push @{ $_[0]->rows }, $row;
    return $row;
}

sub row_count { return scalar @{ $_[0]->rows }; }

sub get_row { return $_[0]->rows->[ $_[1] ]; }

sub get_first_row { return $_[0]->get_row(0); }

sub get_last_row { return $_[0]->get_row( $_[0]->row_count - 1 ); }

sub clear_row { return splice @{ $_[0]->rows }, $_[1], 1;  }

sub clear_first_row { return shift @{ $_[0]->rows }; }

sub clear_last_row { return $_[0]->clear_row($_[0]->row_count - 1); }

sub all_headers { return @{ $_[0]->headers }; }

sub add_header { 
    my $header = HTML::TableContent::Table::Header->new($_[1]);
    push @{ $_[0]->headers }, $header;
    return $header;
}

sub header_count { return scalar @{ $_[0]->headers }; }

sub get_header { return $_[0]->headers->[ $_[1] ]; }

sub get_first_header { return $_[0]->get_header(0); }

sub get_last_header { return $_[0]->get_header($_[0]->header_count - 1); }

sub clear_header { return splice @{ $_[0]->headers }, $_[1], 1; }

sub clear_first_header { return shift @{ $_[0]->headers } }

sub clear_last_header { return $_[0]->clear_header( $_[0]->header_count - 1 ); }

sub _render_element {
   return defined $_[0]->vertical ? $_[0]->_render_vertical_table : $_[0]->_render_horizontal_table;
}

sub _render_vertical_table {
    my $args = $_[0]->attributes;

    my @table_rows = ( );

    if ( $_[0]->has_caption ) {
        push @table_rows, $_[0]->caption->render;
    }
    
    for my $header ($_[0]->all_headers) {
        my @row = ( );
        push @row, $header->render;
        for ($header->all_cells) {
            push @row, $_->render;
        }
        push @table_rows, sprintf '<tr>%s</tr>', join( '', @row);
    }

    my $table = join '', @table_rows;

    return $table;
}

sub _render_horizontal_table {
    my $args = $_[0]->attributes;
    
    my @table_rows = ( );
    
    if ( $_[0]->has_caption ) {
        push @table_rows, $_[0]->caption->render;    
    }

    if ( $_[0]->header_count ) {
        my @headers = map { $_->render } $_[0]->all_headers;
        my $headers = sprintf '%s' x @headers, @headers;
        my $header_row = sprintf '<tr>%s</tr>', $headers; 
        if ( $_[0]->html5 ) {
            my $attr = $_[0]->_generate_element_attr('thead');
            $header_row = sprintf '<thead %s>%s</thead>', $attr, $header_row;
        }
        push @table_rows, $header_row;
    }
    
    if ($_[0]->row_count) {
        my @rows = map { $_->render } $_[0]->all_rows;
        my $row = sprintf '%s' x @rows, @rows;
        if ( $_[0]->html5 ) {
            my $attr = $_[0]->_generate_element_attr('tbody');
            $row = sprintf '<tbody %s>%s</tbody>', $attr, $row;
        }
        push @table_rows, $row;
    }
        
    my $table = sprintf '%s' x @table_rows, @table_rows;
    return $table;
}

sub _generate_element_attr {
    my ($self, $element) = @_;
    my $attr = '';
    if ( my $attributes = $self->$element ) {
        for ( keys %{ $attributes } ) {
            $attr .= sprintf '%s="%s" ', $_, $attributes->{$_};
        }
    }
    return $attr;
}

sub headers_spec {
    my $headers = {};
    map { $headers->{ $_->lc_text }++ } $_[0]->all_headers;
    return $headers;
}

sub header_exists {
    my ( $self, @headers ) = @_;

    my $headers_spec = $self->headers_spec;
    for (@headers) { return 1 if $headers_spec->{ lc $_ } }
    return 0;
}

sub get_col {
    my %args = ( header => $_[1] );
    return $_[0]->get_header_column(%args);
}

sub get_col_text {
    my %args = ( header => $_[1] );
    return $_[0]->get_header_column_text(%args);
}

sub get_header_column {
    my ( $self, %args ) = @_;

    my @cells  = ();
    my $column = $args{header};
    foreach my $header ( $self->all_headers ) {
        if ( $header->lc_text =~ m{$column}ixms ) {
            for ( $header->all_cells ) {
                push @cells, $_;
            }
        }
    }

    if ( defined $args{dedupe} ) {
        @cells = $self->_dedupe_object_array_not_losing_order(@cells);
    }

    return \@cells;
}

sub parse_to_column {
    my ($self, $cell) = @_;
    
    my $row = $self->get_last_row;

    my $header;
    if ( my $row_header = $row->header ) {
        $header = $row_header;
    }
    else {
        my $cell_index = $row->cell_count;
        $header = $self->headers->[$cell_index - 1];
    }

    return unless $header;

    $cell->header($header);
    push @{ $header->cells }, $cell;

    return 1;
}

sub get_header_column_text {
    my ( $self, %args ) = @_;
    my $cells = $self->get_header_column(%args);
    my @cell_text = map { $_->text } @{$cells};
    return \@cell_text;
}

sub has_nested_table_column {
    my $self = shift;
    for my $header ( $self->all_headers ) {
        for ( $header->all_cells ) {
            return 1 if $_->has_nested;
        }
    }
    return 0;
}

sub nested_column_headers {
    my $self = shift;

    my $columns = {};
    for my $header ( $self->all_headers ) {
        my $cell = $header->get_first_cell;
        if ( $cell->has_nested ) {
            $columns->{ $header->lc_text }++;
        }
    }
    return $columns;
}

sub _dedupe_object_array_not_losing_order {
    my ( $self, @items ) = @_;

    # someone could probably do this in one line :)
    my %args;
    my @new_items = ();
    foreach my $item (@items) {
        if ( !defined $args{ $item->text } ) {
            $args{ $item->text }++;
            push @new_items, $item;
        }
    }

    return @new_items;
}

sub _filter_headers {
    my ( $self, @headers ) = @_;

    my $headers = [];
    foreach my $header ( $self->all_headers ) {
        for (@headers) {
            if ( $header->lc_text =~ m/$_/ims ) {
                push @{$headers}, $header;
            }
        }
    }

    $self->headers($headers);

    foreach my $row ( $self->all_rows ) {
        $row->_filter_headers($headers);
    }

    return 1;
}

sub clear_column {
    my ($self, @headers) = @_;

    my @remove_cell;
    for my $index (0 .. $self->header_count - 1) {
        for (@headers) {
            if ( $self->headers->[$index]->lc_text =~ m/$_/ims ){
                $self->clear_header($index);
                push @remove_cell, $index;
            }
        }
    }

    foreach my $row ($self->all_rows ) {
        for (@remove_cell) {
            $row->clear_cell($_);
         }
    }

    return 1;
}

sub sort { 
    my ($self, $options) = @_;

    if ( my $order = $options->{order}) {
        my $headers = [ ];
        foreach my $header (@{ $order }) {
            push @{ $headers }, map { $_ } grep { $_->text =~ m/$header/ixms } $self->all_headers;
        }
        $self->headers($headers);
        
        foreach my $row ( $self->all_rows ) {
            my $cells = [ ];
            foreach my $header (@{ $order }) {
                push @{ $cells }, grep { $_->header->text =~ m/$header/ixms } $row->all_cells;
            }
            $row->cells($cells); 
        }
    }

    if ( my $order = $options->{order_template}) {
        my $headers = [ ];
        foreach my $header (@{ $order }) {
            push @{ $headers }, map { $_ } grep { $_->template_attr =~ m/$header/ixms } $self->all_headers;
        }
        $self->headers($headers);
        
        foreach my $row ( $self->all_rows ) {
            my $cells = [ ];
            foreach my $header (@{ $order }) {
                push @{ $cells }, grep { $_->header->text =~ m/$header/ixms } $row->all_cells;
            }
            $row->cells($cells); 
        }
    }


    return $self;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::TableContent::Table - Base class for table's 

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS
    
    use HTML::TableContent;
    my $t = HTML::TableContent->new()->parse($string);

    my $table = $t->get_first_table;
    $table->caption;
    $table->header_count;
    $table->row_count;

    foreach my $header ($table->all_headers) {
        ...
    }

    foreach my $row ($table->all_rows) {
        ...
    }

    my $columns_obj = $table->get_col('Savings');
    my $columns = $table->get_header_column_text(header => 'Savings', dedupe => 1);

=head1 DESCRIPTION

Base class for Table's. 

=head1 SUBROUTINES/METHODS

=head2 raw

Return underlying data structure

    $table->raw

=head2 render

Render the table as HTML.

    $table->render;

=head2 aoa

Return table as Array of Arrays.

    $table->aoa;

=head2 aoh

Return table as Array of Hashes.

    $table->aoh;

=head2 attributes

HashRef of Table attributes

    $table->attributes

=head2 class

Table tag class if found.

    $table->class;

=head2 id

Table id if found.

    $table->id;

=head2 caption

Table caption if found, see L<HTML::TableContent::Caption>.

    $table->caption;

=head2 add_caption

Add a caption to the table.

    $table->add_caption({})

=head2 has_caption

Boolean check, returns true if table has a caption.

    $table->has_caption;

=head2 headers

Array Ref of L<HTML::TableContent::Header>'s

    $table->headers;

=head2 all_headers

Array of L<HTML::TableContent::Header>'s

    $table->all_headers;

=head2 add_header

Add a L<HTML::TableContent::Header> to the table.

    $table->add_header({});

=head2 header_count

Number of headers found in table

    $table->header_count;

=head2 get_header

Get header from table by index.

    $table->get_header($index);

=head2 get_first_header

Get first header in the table.

    $table->get_first_header;

=head2 get_last_header

Get last header in the table.

    $table->get_last_header;

=head2 clear_header

Clear header by array index.

    $table->clear_header($index);

=head2 clear_first_header

Clear first header in table.

    $table->clear_first_header;

=head2 clear_last_header

Clear last header in table.

    $table->clear_last_header;

=head2 headers_spec 

Hash containing headers and their occurence count..

    $table->headers_spec;

=head2 header_exists 

Boolean check to see if passed in headers exist.

    $table->header_exists(qw/Header/);

=head2 get_header_column

Returns an array that contains L<HTML::TableContent::Table::Row::Cell>'s which belong to that column.

    $table->get_header_column(header => $string);

Sometimes you may want to dedupe the column that is returned. This is done based on the cell's text value.

    $table->get_header_column(header => 'Email', dedupe => 1)

=head2 get_header_column_text

Return an array of the cell's text.

    $table->get_header_column_text(header => 'Email', dedupe => 1);

=head2 get_col

Shorthand for get_header_column(header => '');

    $table->get_col('Email');

=head2 get_col_text

Shorthand for get_header_column_text(header => '')

    $table->get_col_text('Email');

=head2 rows

Array Ref of L<HTML::TableContent::Row>'s

    $table->rows;

=head2 add_row

Add a L<HTML::TableContent::Row> to the table.

    $table->add_row({});

=head2 all_rows

Array of L<HTML::TableContent::Row>'s

    $table->all_rows;

=head2 row_count

Number of rows found in table

    $table->row_count;

=head2 get_row

Get row from table by index.

    $table->get_row($index);

=head2 get_first_row

Get first row in the table.

    $table->get_first_row;

=head2 get_last_row

Get last row in the table.

    $table->get_last_row;

=head2 clear_row

Clear row by index.

    $table->clear_row($index);

=head2 clear_first_row

Clear first row in the table.

    $table->clear_first_row;

=head2 clear_last_row

Clear last row in the table.

    $table->clear_last_row;

=head2 nested

ArrayRef of all nested Tables found within the current table.

    $table->nested

=head2 all_nested

Array of all nested Tables found within the current table.

    $table->all_nested

=head2 has_nested

Boolean check, returns true if the table has nested tables.

    $table->has_nested

=head2 count_nested

Count number of nested tables within current table.

    $table->count_nested

=head2 get_first_nested

Get the first nested table.

    $table->get_first_nested

=head2 get_nested

Get Nested table by index.

    $table->get_nested(1);

=head2 has_nested_table_column 

Boolean Check, returns 1 if a headers cells consists of nested tables.

    $table->has_nested_table_column;

=head2 nested_column_headers

Returns a hash,the header that contains nested tables and the a count of occurence.

    $table->nested_column_headers;

=head2 parse_to_column

Magical. just call it if you want the header columns to work. 
    
    my $cell = $row->add_cell({ text => 'hacked' });
    $table->parse_to_column($cell);
    
=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

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

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT 

=head1 INCOMPATIBILITIES

=head1 LICENSE AND COPYRIGHT

Copyright 2020->2016 LNATION.

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

