package RoleTest::RoleTwo;

use Moose::Role;
with 'RoleTest::RoleThree';

#===================================
has 'two' => (
#===================================
    is => 'ro',
    isa => 'Str',
);

1;