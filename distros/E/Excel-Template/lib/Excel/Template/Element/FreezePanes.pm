package Excel::Template::Element::FreezePanes;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Element);

    use Excel::Template::Element;
}

sub render {
    my $self = shift;
    my ($context) = @_;

    my ($row, $col) = map { $context->get( $self, $_ ) } qw( ROW COL );
    $context->active_worksheet->freeze_panes( $row, $col );

    return 1;
}

1;
__END__

=head1 NAME

Excel::Template::Element::FreezePanes - Excel::Template::Element::FreezePanes

=head1 PURPOSE

To insert an image into the worksheet

=head1 NODE NAME

FREEZEPANES

=head1 INHERITANCE

L<ELEMENT|Excel::Template::Element>

=head1 EFFECTS

This will not conume any columns or rows. It is a zero-width assertion.

=head1 DEPENDENCIES

None

=head1 USAGE

  <freezepanes />

This will do a Freeze Pane at the current cell.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

Nothing

=cut
