package FieldTest::Date;

use Elastic::Doc;

#===================================
has 'basic_attr' => (
#===================================
    is  => 'ro',
    isa => 'DateTime',
);

#===================================
has 'options_attr' => (
#===================================
    is             => 'ro',
    type           => 'date',
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
    isa   => 'DateTime',
    boost => 2,
    multi => { one => { precision_step => 2, }, }
);

#===================================
has 'bad_opt_attr' => (
#===================================
    is       => 'ro',
    isa      => 'DateTime',
    analyzer => 'standard',
);

#===================================
has 'bad_multi_attr' => (
#===================================
    is    => 'ro',
    isa   => 'DateTime',
    multi => { one => { analyzer => 'standard' } }
);

1;
