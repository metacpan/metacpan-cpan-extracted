package Excel::Template::Element::Range;

use strict;
use Spreadsheet::WriteExcel::Utility;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Element);

    use Excel::Template::Element;
}

sub min { $_[0] < $_[1] ? $_[0] : $_[1] }
sub max { $_[0] > $_[1] ? $_[0] : $_[1] }

sub resolve
{ 
    my $self = shift;
    my ($context) = @_;

    my $ref_name = $context->resolve($self, 'REF');

    my @refs = $context->get_all_references( $ref_name );
    return '' unless @refs;

    return $self->_join_refs(@refs);
}

sub _join_refs {
    my ($self, @refs) = @_;
    
    my ($top, $left, $bottom, $right) =
        ( $refs[0][0], $refs[0][1] ) x 2;

    shift @refs;
    foreach my $ref ( @refs )
    {
        $top    = min( $top,    $ref->[0]);
        $bottom = max( $bottom, $ref->[0]);
        $left   = min( $left,   $ref->[1]);
        $right  = max( $right,  $ref->[1]);
    }

    return join( ':',
        xl_rowcol_to_cell($top, $left),
        xl_rowcol_to_cell($bottom, $right)
    );
}

1;
__END__

=head1 NAME

Excel::Template::Element::Range - Excel::Template::Element::Range

=head1 PURPOSE

Returns a range of cell locations (i.e. B2:C2) that contains all calls using
this reference. To return the location of the last cell, use BACKREF.

=head1 NODE NAME

RANGE

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
    <formula>=SUM(<range ref="that_cell">)</formula>
  </row>

The formula in row 2 would be =SUM(B1:C1).

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

CELL, BACKREF

=cut
