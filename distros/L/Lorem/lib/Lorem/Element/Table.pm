package Lorem::Element::Table;
{
  $Lorem::Element::Table::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Cairo;
use Pango;

use Lorem::Element::TableRow;
extends 'Lorem::Element::Box';

with 'Lorem::Role::ConstructsElement' => {
    name => 'row',
    class => 'Lorem::Element::TableRow'
};

sub append_row {
    my ( $self, $row ) = @_;
    $row ||= Lorem::Element::TableRow->new;
    $self->append_element( $row );
    return $row;
}


1;

