package Excel::Template::Element::Var;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Excel::Template::Element);

    use Excel::Template::Element;
}

sub resolve { ($_[1])->param($_[1]->resolve($_[0], 'NAME')) }

1;
__END__

=head1 NAME

Excel::Template::Element::Var - Excel::Template::Element::Var

=head1 PURPOSE

To provide parameter substitution.

=head1 NODE NAME

VAR

=head1 INHERITANCE

Excel::Template::Element

=head1 ATTRIBUTES

=over 4

=item * NAME

This is the name of the parameter to substitute here.

=back

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

This will only be used within CELL tags.

=head1 USAGE

This is used exactly like HTML::Template's TMPL_VAR. There is one exception -
since you can have variable names inside the parameters, you can do something
like:

  <loop name="LOOPY">
    <var name="$SomeParam"/>
  </loop>

Where the actual name to be substituted is, itself, a parameter.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

CELL

=cut
