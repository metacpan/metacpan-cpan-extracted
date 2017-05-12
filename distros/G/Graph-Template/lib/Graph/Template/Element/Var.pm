package Graph::Template::Element::Var;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(Graph::Template::Element);

    use Graph::Template::Element;
}

sub resolve { ($_[1])->param($_[1]->resolve($_[0], 'NAME')) }

1;
__END__

=head1 NAME

Graph::Template::Element::Var

=head1 PURPOSE

To provide parameter substitution.

=head1 NODE NAME

VAR

=head1 INHERITANCE

Graph::Template::Element

=head1 ATTRIBUTES

=over 4

=item * NAME

This is the name of the parameter to substitute here.

=back 4

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

None

=head1 USAGE

This is used exactly like HTML::Template's TMPL_VAR. There is one exception -
since you can have variable names inside the parameters, you can do something
like:

<loop name="LOOPY">

    <datapoint><var name="$SomeParam"/></datapoint>

</loop>

Where the actual name to be substituted is, itself, a parameter.

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

CELL

=cut
