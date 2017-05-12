package FieldTest::Binary;

use Elastic::Doc;
use Elastic::Model::Types qw(Binary);

#===================================
has 'basic_attr' => (
#===================================
    is  => 'ro',
    isa => Binary,
);

#===================================
has 'options_attr' => (
#===================================
    is         => 'ro',
    type       => 'binary',
    index_name => 'foo',
    store      => 1,
);

#===================================
has 'multi_attr' => (
#===================================
    is    => 'ro',
    isa   => Binary,
    multi => { one => { type => 'string' }, }
);

#===================================
has 'bad_opt_attr' => (
#===================================
    is       => 'ro',
    isa      => Binary,
    analyzer => 'standard',
);

1;
