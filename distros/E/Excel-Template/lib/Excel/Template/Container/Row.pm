package Excel::Template::Container::Row;

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

    $context->{COL} = 0;

    # Apply the height to the current row
    if (my $height = $context->get($self, 'HEIGHT'))
    {
        $height =~ s/\D//g;
        $height *= 1;
        if ($height > 0)
        {
            $context->active_worksheet->set_row(
                $context->get( $self, 'ROW' ),
                $height,
            );
        }
    }

    return $self->SUPER::render($context);
}

sub deltas
{
    return {
        ROW => +1,
    };
}

1;
__END__

=head1 NAME

Excel::Template::Container::Row - Excel::Template::Container::Row

=head1 PURPOSE

To provide a row context for CELL tags

=head1 NODE NAME

ROW

=head1 INHERITANCE

Excel::Template::Container

=head1 ATTRIBUTES

=over 4

=item * HEIGHT

Sets the height of the row. The last setting for a given row will win out.

=back

=head1 CHILDREN

None

=head1 EFFECTS

Each ROW tag will consume one row of the workbook. When the ROW tag starts, it
will set the COL value to 0.

=head1 DEPENDENCIES

None

=head1 USAGE

  <row>
    ... Children here
  </row>

Generally, you will have CELL and/or FORMULA tags within a ROW.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

CELL, FORMULA

=cut
