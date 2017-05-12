package Excel::Template::Container::KeepLeadingZeros;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Container);

    use Excel::Template::Container;
}

sub render
{
    my $self = shift;
    my ($context) = @_;

    my $worksheet = $context->active_worksheet;

    $worksheet
        ? $worksheet->keep_leading_zeros( 1 )
        : $context->mark( keep_leading_zeros => 1 );

    my $rv = $self->SUPER::render($context);

    $worksheet
        ? $worksheet->keep_leading_zeros( 0 )
        : $context->mark( keep_leading_zeros => 0 );

    return $rv;
}

1;
__END__

=head1 NAME

Excel::Template::Container::KeepLeadingZeros - Excel::Template::Container::KeepLeadingZeros

=head1 PURPOSE

To set the keep_leading_zeros flag for the surrounding worksheet or any worksheets that might be contained within this node.

=head1 NODE NAME

KEEP_LEADING_ZEROS

=head1 INHERITANCE

L<CONTAINER|Excel::Template::Container>

=head1 ATTRIBUTES

None

=head1 CHILDREN

None

=head1 EFFECTS

Alters how leading zeros are interpreted by L<Spreadsheet::WriteExcel>.

=head1 DEPENDENCIES

None

=head1 USAGE

  <worksheet>
    ... Cells here will NOT have leading-zeros preserved
    <keep_leading_zeros>
      ... Cells here will have leading-zeros preserved
    </keep_leading_zeros>
    ... Cells here will NOT have leading-zeros preserved
  </worksheet>

  <keep_leading_zeros>
    <worksheet>
      ... Cells here will have leading-zeros preserved
    </worksheet>
    <worksheet>
      ... Cells here will have leading-zeros preserved
    </worksheet>
  </keep_leading_zeros>

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

L<CELL|Excel::Template::Element::Cell>, L<Spreadsheet::WriteExcel>

=cut
