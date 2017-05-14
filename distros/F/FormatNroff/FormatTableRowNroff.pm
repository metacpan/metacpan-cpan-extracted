package HTML::FormatTableRowNroff;

=head1 NAME

HTML::FormatTableRowNroff - Format HTML Table row for nroff

=head1 SYNOPSIS

 require HTML::FormatTableRowNroff;
 $row = new HTML::FormatTableRowNroff(%attr);

=head1 DESCRIPTION

The HTML::FormatTableRowNroff class is used to store information
about a single row of a table. Once information about all the rows of
the table has been recorded, an nroff tbl table may be created.

The following attributes are supported:
  align: 'left','center', or 'right' alignment of table row entries
  valign: vertical alignment, 'top' or 'middle'

=head1 METHODS

=cut

require 5.004;

require HTML::FormatTableRow;
@ISA = qw(HTML::FormatTableRow);

require HTML::FormatTableCellNroff;

use strict;
use Carp;

=head2 $nroff_row->output_format($last_row, $formatter, @widths);

Create a tbl format line for the row. $last_row is true if this is the last row in the table. 

$formatter is the formatter being used (e.g. 
C<HTML::FormatNroff>).

@widths is an array of width information for each cell in the current row,
specified in inches.

=cut

sub output_format {
    my($self, $final, $formatter, @widths) = @_;

    my $cell;
    my $index = 0;
    foreach $cell ( @ { $self->{'cells'} }) {
	my $str = $cell->format_str($widths[$index]);
	$formatter->out("$str ");
	$index++;
    }
    $cell = $self->{'current_cell'};
    if(defined $cell && $cell ne "") {
	my $str = $cell->format_str($widths[$index]);
	$formatter->out("$str");
    }
    if($final) {
	$formatter->out(".\n");
    } else {
	$formatter->out("\n");
    }
}

=head2 $nroff_row->add_element(%attr);

Add a new cell to the current row. %attr are the cell attributes,
as defined in C<HTML::FormatTableCellNroff>.

=cut

sub add_element {
    my($self, %attr) = @_;

    if(defined($self->{'current_cell'})) {
	push(@ {$self->{'cells'}},  $self->{'current_cell'});
    }

    $self->{'ended'} = 0;
    $self->{'current_cell'} = new HTML::FormatTableCellNroff(%attr);
}

=head2 $nroff_row->end_element();

Finish the current cell.

=cut

sub end_element {
    my($self) = @_;

    $self->{'ended'} = 1;
}

=head1 SEE ALSO

L<HTML::FormatTable>, L<HTML::FormatTableNroff>
L<HTML::FormatTableRow>
L<HTML::FormatTableCell>
L<HTML::FormatTableCellNroff>

=head1 COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederick Hirsch <f.hirsch@opengroup.org>

=cut 

1;
