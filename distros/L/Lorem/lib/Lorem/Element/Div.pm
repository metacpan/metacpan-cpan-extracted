package Lorem::Element::Div;
{
  $Lorem::Element::Div::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Cairo;
use Pango;

use Lorem::Types qw(  );
extends 'Lorem::Element::Box';

with 'Lorem::Role::ConstructsElement' => {
    name => 'text',
    class => 'Lorem::Element::Text'
};










1;



#with 'Lorem::Role::Stamp';

#has 'macro' => (
#    is => 'rw',
#    isa => 'Maybe[CodeRef]',
#    default => sub { },
#);
#
#sub imprint {
#    my ($self, $doc) = @_;    
#    &{$self->macro}(@_);
#}


1;
