package HTML::Robot::Scrapper::Parser::XML::XPath;
use Moose::Role;
use XML::XPath;

has xml => (
    is => 'rw',
);

=head2 parse_xml

you must indicate which method will be used to parse the received content.

see HTML::Robot::Scrapper::Parser::Default

=cut

sub parse_xml {
    my ($self, $content ) = @_;
    $content = $self->robot->encoding->safe_encode( $content );
    my $xml = XML::XPath->new( xml => $content );
    $self->xml( $xml );
}

1;

