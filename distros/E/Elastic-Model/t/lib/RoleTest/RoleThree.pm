package RoleTest::RoleThree;

use Moose::Role;

#===================================
has 'three' => (
#===================================
    is => 'ro',
    isa => 'Str',
);

1;