package Graph::Template::Element::DataPoint;

BEGIN {
    use vars qw( @ISA );

    @ISA = qw( Graph::Template::Element );
    use Graph::Template::Element;
}

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{TXTOBJ} = Graph::Template::Factory->create('TEXTOBJECT');

    return $self;
}

sub render { $_[1]->add_data($_[0]->get_value($_[1], 'VALUE')) }

1;
__END__

=head1 NAME

Graph::Template::Element::DataPoint

=head1 PURPOSE

To provide parameter substitution.

=head1 NODE NAME

DATAPOINT

=head1 INHERITANCE

Graph::Template::Element

=head1 ATTRIBUTES

=over 4

=item * VALUE

This is the value for this datapoint

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

    <datapoint value="$SomeParam_2"/>

  </loop>

This will create a graph with the X-axis being SomeParam and the Y-axis as
SomeParam_2. The data structure to be used here is identical to the looping
structure for TMPL_LOOP.

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

DATA

=cut
