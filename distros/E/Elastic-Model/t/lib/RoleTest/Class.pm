package RoleTest::Class;

use Elastic::Doc;

#===================================
has 'top' => (
#===================================
    is  => 'ro',
    isa => 'Str',
);

with 'RoleTest::RoleOne';
apply_field_settings '-exclude';

with 'RoleTest::RoleTwo';
with 'RoleTest::RoleFour';

apply_field_settings {
    two   => { type => 'date' },
    three => { type => 'integer' }
};

1;