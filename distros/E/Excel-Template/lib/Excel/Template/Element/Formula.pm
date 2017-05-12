package Excel::Template::Element::Formula;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Element::Cell);

    use Excel::Template::Element::Cell;
}

sub render { $_[0]->SUPER::render( $_[1], 'write_formula' ) }
#{
#    my $self = shift;
#    my ($context) = @_;
#
#    return $self->SUPER::render( $context, 'write_formula' );
#}

1;
__END__

=head1 NAME

Excel::Template::Element::Formula - Excel::Template::Element::Formula

=head1 PURPOSE

To write formulas to the worksheet

=head1 NODE NAME

FORMULA

=head1 INHERITANCE

Excel::Template::Element::Cell

=head1 ATTRIBUTES

All attributes a CELL can have, a FORMULA can have, including the ability to be
referenced using the 'ref' attribute.

=head1 CHILDREN

None

=head1 EFFECTS

This will consume one column on the current row. 

=head1 DEPENDENCIES

None

=head1 USAGE

  <formula text="=(1 + 2)"/>
  <formula>=SUM(A1:A5)</formula>

  <formula text="$Param2"/>
  <formula>=(A1 + <var name="Param">)</formula>

In the above example, four formulas are written out. The first two have the
formula hard-coded. The second two have variables. The third and fourth items
have another thing that should be noted. If you have a formula where you want a
variable in the middle, you have to use the latter form. Variables within
parameters are the entire parameter's value.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

CELL

=cut
