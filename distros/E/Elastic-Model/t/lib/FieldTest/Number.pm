package FieldTest::Number;

use Elastic::Doc;

#===================================
has 'basic_attr' => (
#===================================
    is  => 'ro',
    isa => 'Int',
);

#===================================
has 'options_attr' => (
#===================================
    is             => 'ro',
    type           => 'integer',
    index          => 'no',
    index_name     => 'foo',
    store          => 1,
    boost          => 2,
    null_value     => 'nothing',
    include_in_all => 0,
    precision_step => 2,
);

#===================================
has 'multi_attr' => (
#===================================
    is    => 'ro',
    isa   => 'Num',
    boost => 2,
    multi => { one => { precision_step => 4, }, }
);

#===================================
has 'bad_opt_attr' => (
#===================================
    is       => 'ro',
    isa      => 'Int',
    analyzer => 'standard',
);

#===================================
has 'bad_multi_attr' => (
#===================================
    is    => 'ro',
    isa   => 'Int',
    multi => { one => { analyzer => 'standard' } }
);

1;

