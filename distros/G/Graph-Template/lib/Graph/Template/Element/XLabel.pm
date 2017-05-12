package Graph::Template::Element::XLabel;

use strict;

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

sub render { $_[1]->graph->set(x_label => $_[0]->get_value($_[1], 'TEXT')) }
#{
#    my $self = shift;
#    my ($context) = @_;
#
#    $context->graph->set(
#        x_label => $self->get_value($context, 'TEXT'),
#    );
#}

1;
__END__

=head1 NAME

Graph::Template::Element::XLabel

=head1 PURPOSE

To provide the X-axis label

=head1 NODE NAME

XLABEL

=head1 INHERITANCE

Graph::Template::Element

=head1 ATTRIBUTES

=over 4

=item * TEXT

This is the text for the label.

=back 4

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

None

=head1 USAGE

This will create the label for the X-axis. It calls
$graph->set(x_label => TEXT);

  <xlabel text="Some Title here"/>

I assume the last xlabel found will be used. (Has not been tested.)

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

TITLE, YLABEL

=cut
