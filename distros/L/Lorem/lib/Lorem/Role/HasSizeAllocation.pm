package Lorem::Role::HasSizeAllocation;
{
  $Lorem::Role::HasSizeAllocation::VERSION = '0.22';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

has 'size_allocation' => (
    is => 'rw',
    isa => 'Maybe[HashRef]',
    default => undef,
    writer => 'set_size_allocation',
);



1;
