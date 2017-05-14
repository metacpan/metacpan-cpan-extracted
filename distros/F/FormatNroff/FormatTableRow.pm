package HTML::FormatTableRow;

=head1 NAME

HTML::FormatTableRow - Format HTML Table row

=head1 SYNOPSIS

 require HTML::FormatTableRow;
 @ISA = qw(HTML::FormatTableRow);

=head1 DESCRIPTION

The HTML::FormatTableRow is used to record information and process
a table row. This is a base class.

The following attributes are supported:
  align: 'left','center', or 'right' alignment of table row entries
  valign: vertical alignment, 'top' or 'middle'

=head1 METHODS

=cut

require 5.004;

use strict;
use Carp;

=head2 $table_row = new HTML::FormatTableRow(%attr);

The following attributes are supported:
  align: 'left','center', or 'right' alignment of table row entries
  valign: vertical alignment, 'top' or 'middle'

=cut

sub new {
    my($class, %attr) = @_;

    my $self = bless {	
	align => $attr{'align'} || 'left',
	valign => $attr{'valign'} || 'middle',
	current_cell => undef,
	ended => 1,
	cells => [],
    }, $class;

    return $self;
}
 
=head2 $table_row->add_element(%attr);

Add table element - should be subclassed.

=cut

sub add_element {
    my($self, %attr) = @_;

    croak "Should be subclassed.\n";
}

 
=head2 $table_row->end_element();

End table element - should be subclassed.

=cut

sub end_element {
    my($self) = @_;

    croak "Should be subclassed.\n";
}

=head2 $table_row->add_text($text);

Add text to cell.

=cut

sub add_text {
    my($self, $text) = @_;

    if($self->{'ended'} != 0) { 
	return;
    }

    my $cell = $self->{'current_cell'};
    if(defined($cell)) {
	$cell->add_text($text);
    } else {
	return 0;
    }
}

=head2 $table_row->text();

Return text associated with current table cell.

=cut

sub text {
    my($self) = @_;

    my $cell = $self->{'current_cell'};
    if(defined($cell)) {
	return $cell->text();
    } else {
	return 0;
    }
}

=head2 $table_row->widths($final, $array_ref);

push the array of cell widths (in characters) 
onto the array specified using the array reference $array_ref.

=cut

sub widths {
    my($self, $final, $array_ref) = @_;

    my @widths;
    my $cell;
    foreach $cell ( @{ $self->{'cells'} }) {
	push(@widths, $cell->width());
    }

    $cell = $self->{'current_cell'};
    if(defined($cell)) {
	push(@widths, $cell->width());
    }

    push(@$array_ref, [ @widths ]);
}

=head2 $table_row->output($final, $formatter, $tab);

Output the row data using the $formatter to do the output,
and separating each cell using the $tab character. $final is not used.

=cut

sub output {
    my($self, $final, $formatter, $tab) = @_;

    my $cell;
    foreach $cell ( @{ $self->{'cells'} }) {
	$cell->output($formatter);
	$formatter->out("$tab");
    }

    if(defined($self->{'current_cell'})) {
	$self->{'current_cell'}->output($formatter);
    }
    $formatter->out("\n.sp\n");
}

=head1 SEE ALSO

L<HTML::FormatTable>

=head1 COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederick Hirsch <f.hirsch@opengroup.org>

=cut 

1;



