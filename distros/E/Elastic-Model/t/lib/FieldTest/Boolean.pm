package FieldTest::Boolean;

use Elastic::Doc;

#===================================
has 'basic_attr' => (
#===================================
    is  => 'ro',
    isa => 'Bool',
);

#===================================
has 'options_attr' => (
#===================================
    is             => 'ro',
    type           => 'boolean',
    index          => 'no',
    index_name     => 'foo',
    store          => 1,
    boost          => 2,
    null_value     => 'nothing',
    include_in_all => 0,
);

#===================================
has 'multi_attr' => (
#===================================
    is    => 'ro',
    isa   => 'Bool',
    boost => 2,
    multi => { one => { type => 'string' }, }
);

#===================================
has 'bad_opt_attr' => (
#===================================
    is       => 'ro',
    isa      => 'Bool',
    analyzer => 'standard',
);

#===================================
has 'bad_multi_attr' => (
#===================================
    is    => 'ro',
    isa   => 'Bool',
    multi => { one => { analyzer => 'standard' } }
);

1;
