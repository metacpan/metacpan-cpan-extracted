package Lorem::Element::Inline;
{
  $Lorem::Element::Inline::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Lorem::Types qw( MaybeLoremDoesStamp );
extends 'Lorem::Element';

with 'Lorem::Role::HasCoordinates';
with 'Lorem::Role::HasDimensions';

has 'size_allocation' => (
    is => 'rw',
    isa => 'Maybe[HashRef]',
    default => undef,
    writer => 'set_size_allocation',
);




1;
