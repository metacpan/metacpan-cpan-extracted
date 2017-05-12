package RoleTest::RoleOne;

use Moose::Role;

#===================================
has 'one' => (
#===================================
    is => 'ro',
    isa => 'Str',
);

1;