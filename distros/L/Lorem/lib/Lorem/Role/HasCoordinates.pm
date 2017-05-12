package Lorem::Role::HasCoordinates;
{
  $Lorem::Role::HasCoordinates::VERSION = '0.22';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

has 'x' => (
    is => 'rw',
    isa => 'Maybe[Num]',
    default => undef,
);

has 'y' => (
    is => 'rw',
    isa => 'Maybe[Num]',
    default => undef,
);



1;
