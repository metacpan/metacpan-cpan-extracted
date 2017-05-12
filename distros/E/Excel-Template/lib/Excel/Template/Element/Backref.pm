package Excel::Template::Element::Backref;

use strict;
use Spreadsheet::WriteExcel::Utility;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Element);

    use Excel::Template::Element;
}

sub resolve
{ 
    my $self = shift;
    my ($context) = @_;

    my $ref_name = $context->resolve($self, 'REF');

    my ($row, $col) = $context->get_last_reference( $ref_name );
    return '' unless defined $row && defined $col;

    return xl_rowcol_to_cell( $row, $col );
}

1;
__END__

=head1 NAME

Excel::Template::Element::Backref - Excel::Template::Element::Backref

=head1 PURPOSE

Returns the cell location (i.e. B2) of the last cell to name this reference.  To
return the location of the entire range of cells to name this reference see RANGE.

=head1 NODE NAME

BACKREF

=head1 INHERITANCE

Excel::Template::Element

=head1 ATTRIBUTES

=over 4

=item * REF

This is the name of the reference to look up.

=back

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

This will only be used within CELL tags.

=head1 USAGE

In the example...

  <row>
    <cell ref="this_cell"/><cell ref="that_cell"><cell ref="that_cell">
  </row>
  <row>
    <formula>=<backref ref="this_cell">+<backref ref="that_cell"></formula>
  </row>

The formula in row 2 would be =A1+C1.  C1 is the last to reference "that_cell".

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

CELL, RANGE

=cut
