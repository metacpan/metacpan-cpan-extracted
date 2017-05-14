package HTML::FormatTableCell;

=head1 NAME

HTML::FormatTableCell - Format HTML Table 

=head1 SYNOPSIS

 require HTML::FormatTableCell;
 @ISA=qw(HTML::FormatTableCell);

=head1 DESCRIPTION

The HTML::FormatTableCell is a base class used to record information
about a table entry as part of FormatTable processing. It is necessary
to record information for formatting into languages such as nroff tbl 
which require formatting information ahead of the table data.

=head1 METHODS

=cut

require 5.004;

use strict;
use Carp;

=head2 $cell = new HTML::FormatTableCellNroff(%attr);

Since FormatTableCell is a base class, a derived class constructor
such as L<FormatTableCellNroff> should be called.

The following attributes are supported:

        header - is a header (default is '')
	nowrap - do not wrap if defined
	rowspan - number of rows cell spans (default is 1)
	colspan - number of columns cell spans (default is 1)
	align - alignment of cell contents (default is 'left')
	valign - vertical alignment of cell (default is 'middle')
	contents - contents of cell (default is '')

=cut

sub new {
    my($class, %attr) = @_;

    my $self = bless {	
	header => $attr{'header'} || '',
	nowrap => $attr{'nowrap'} || 'nowrap',
	rowspan => $attr{'rowspan'} || 1,
	colspan => $attr{'colspan'} || 1,
	align => $attr{'align'} || 'left',
	valign => $attr{'valign'} || 'middle',
	contents => $attr{'contents'} || '',

	text => "",
    }, $class;

    return $self;
}

=head2 $cell->add_text($text);

Add additional contents to cell.

=cut

sub add_text {
    my($self, $text) = @_;
    
    $self->{'text'} .= $text;
}

=head2 $alignment = $cell->alignment();

Return cell alignment.

=cut

sub alignment {
    my($self) = @_;

    return $self->{'align'};
}

=head2 $colspan = $cell->colspan();

Return cell colspan.

=cut

sub colspan {
    my($self) = @_;

    return $self->{'colspan'};
}

=head2 $text = $cell->text();

Return cell text.

=cut

sub text {
    my($self) = @_;

    return $self->{'text'};
}

=head2 $width = $cell->width();

Return cell width in characters.

=cut

sub width {
    my($self) = @_;

    length($self->{'text'});
}

=head1 SEE ALSO

L<HTML::FormatNroff>,
L<HTML::FormatTableCellNroff>,
L<HTML::FormatTableRow>,
L<HTML::FormatTableRowNroff>

=head1 COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederick Hirsch <f.hirsch@opengroup.org>

=cut 

1;

