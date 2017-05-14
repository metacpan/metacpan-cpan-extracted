package HTML::FormatTableNroff;

=head1 NAME

HTML::FormatTableNroff - Format HTML Table as nroff

=head1 SYNOPSIS

 require HTML::FormatTableNroff;
 $table =  new HTML::FormatTableNroff($self, %attr);

=head1 DESCRIPTION

The HTML::FormatTableNroff is a formatter that outputs tbl, nroff and man
macro source for HTML tables. It is called by the HTML::FormatNroff
formatter to process HTML tables.

=head1 METHODS

=cut

require 5.004;

require HTML::FormatTable;
require HTML::FormatTableRowNroff;

@ISA = qw(HTML::FormatTable);

use strict;
use Carp;

sub rnd {
    my($num) = @_;

    my $result = int $num;
    my $frac = $num - $result;

    print STDERR "frac $frac\n";
    if($frac > .5) {
	$result++;
    }
    return $result;
}

my $_width_used = 0;

=head2 $width = $nroff_table->calculate_width($total, $num);

Calculate the width to use for the cell, using the following data:

    $nroff_table->{'page_width'} is the number of inches available
       on the page (6 if not set)

    $nroff_table->{'width'} specifies the percent of this available to 
       the table (e.g. "75%") 

    $total is calculated by determining the maximum width cell for each 
column and then adding these maximums for each column.

    $num is the maximum width cell for this column.

The algorithm attempts to allocate the available table width (the percentage
of the page width) to the rows as the percentage the max width of the column
has with respect to the total. 

In order to make a small width column avoid unnecessary wrapping, if the
result width is less than an inch, a width corresponding to the max number of
characters is used ( aproximately the number/12 since 1em is about 12 points)
(See "A TROFF tutorial", by Kernighan)

The global HTML::FormatTableNroff::$_width_used is use to track the amount of 
page width used by previous columns.

=cut


sub calculate_width {
    my($self, $total, $num) = @_;

    my $page_width = $self->{'page_width'};
    unless($page_width) { $page_width = 6; };

    my $width = $page_width;

    my $table_width = $self->{'width'};
    if($table_width) {
	$table_width =~ s/([0-9]*)%/$1/;

	$width = $page_width * $table_width / 100;
    }

    my $start = $num * $width / $total;

    if($start < 1) {
# try to make this column as big as the biggest string
	$start = int $num/12;
    }

    if(($_width_used + $start) <= $width) {
	$_width_used += $start;
	return $start;
    }

    return $width - $_width_used;
}

=head2 $nroff_table->attributes();

Return tbl attributes associated with table itself as a string.
expand will be specified if the table width is not explicitly specified
or is not 100%. If centering is specified for the document region containing
the table, then the table will have the center attribute.

=cut

sub attributes {
    my($self) = @_;

    my @attributes;

    my $tab_attr = 'tab(' . $self->{'tab'} . ')';
    push(@attributes, $tab_attr);

    unless($self->{'width'} and $self->{'width'} ne '100%' )  {
	push(@attributes, 'expand');
    }

    if($self->{'align'} eq 'center') {
	push(@attributes, $self->{'align'});
    }
    return(@attributes);
}

=head2 $nroff_table->output();

Output the entire table, using the formatter associated with the table, 
unless there is no table content - just put out a .sp in this case.

A table is output as follows:

 .sp
 .TS
 table attributes;
 row specification
 row specification.
 row
 row
 .TE

=cut

sub output {
    my($self) = @_;

    # if the table is empty, forget it.
    unless(defined $self->{"current_row"}) { 
	$self->{'formatter'}->out("\n.sp\n");
	return; 
    }

    # start the table
    $self->{'formatter'}->out("\n.in 0\n.sp\n.TS\n");

    # put out attributes, if any
    my $attribute;
    my @atts = $self->attributes();
    my $cnt = @atts;

    foreach $attribute ($self->attributes()) {
	$self->{'formatter'}->out("$attribute");
	if($cnt > 1) {
	    $self->{'formatter'}->out(", ");	    
	}
	$cnt--;
    }
    $self->{'formatter'}->out(";\n");    	

    # put out data
    my @row_widths;
    $self->row_iterator('widths', \@row_widths);

    my $arrayref;
    my @maxvals;
#    my @sum;

    foreach $arrayref (@row_widths) {
	my $i;
#	print STDERR "ROW\n";

	for $i (0 .. $#{$arrayref} ) {
#	    print STDERR "$i -> ", $$arrayref[$i], " max is ",
#	    $maxvals[$i], "\n";

	    unless((defined $maxvals[$i]) and ($maxvals[$i] > $$arrayref[$i]))
	    {
		$maxvals[$i] = $$arrayref[$i];
	    }
#	    $sum[$i] += $$arrayref[$i];
	}
    }

    my $total = 0;
    map { $total += $_; } @maxvals;

    $_width_used = 0;
    my @widths = map { sprintf("%.2f", $self->calculate_width($total, $_)); }
                 @maxvals; 

    # put out format
    $self->row_iterator('output_format', $self->{'formatter'}, @widths);

    # put out data
    $self->row_iterator('output', $self->{'formatter'}, $self->{'tab'});

    # end the table
    $self->{'formatter'}->out(".TE\n");
}

=head2 $nroff_table->add_row(%attr);

Add a row to the table, with row attributes specified in %attr.

=cut

sub add_row {
    my($self, %attr) = @_;

    if(defined($self->{"current_row"})) {
	push(@{$self->{'previous_rows'}}, $self->{"current_row"});
    }
    $self->{"current_row"} = new HTML::FormatTableRowNroff(%attr);
}

=head2 $nroff_table->row_iterator($method, @args);

Apply $method to each row of the table, passing @args, as follows:
    $row->$method($last_row, @args);

$last_row is set appropriately and used to signal to method
whether this is the last row in the table.

=cut

sub row_iterator {
    my($self, $method, @args) = @_;

    my $row;
    foreach $row (@{$self->{'previous_rows'}}) {
	$row->$method(0, @args);
    }

    if(defined $self->{"current_row"}) {
	$self->{"current_row"}->$method(1, @args);
    }
}

=head1 SEE ALSO

L<HTML::FormatNroff>
L<HTML::FormatTable>
L<HTML::FormatTableRow>
L<HTML::FormatTableRowNroff>

=head1 COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederick Hirsch <f.hirsch@opengroup.org>

=cut 

1;





