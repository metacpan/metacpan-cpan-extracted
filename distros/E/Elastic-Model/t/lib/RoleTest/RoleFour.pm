package RoleTest::RoleFour;

use Moose::Role;

#===================================
has 'four' => (
#===================================
    traits => ['ElasticField'],
    is     => 'ro',
    isa    => 'Str',
    index  => 'not_analyzed',
);

1;
