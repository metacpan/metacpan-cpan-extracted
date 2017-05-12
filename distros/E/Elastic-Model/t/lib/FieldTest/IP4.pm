package FieldTest::IP4;

use Elastic::Doc;

#===================================
has 'basic_attr' => (
#===================================
    is   => 'ro',
    isa  => 'Str',
    type => 'ip',
);

#===================================
has 'options_attr' => (
#===================================
    is               => 'ro',
    isa              => 'Str',
    type             => 'ip',
    'index_name'     => 'foo',
    'store'          => 1,
    'index'          => 'no',
    'precision_step' => 2,
    'boost'          => 3,
    'null_value'     => 'nothing',
    'include_in_all' => 1,
);

#===================================
has 'multi_attr' => (
#===================================
    is    => 'ro',
    isa   => 'Str',
    type  => 'ip',
    multi => { one => { precision_step => 2 } }
);

#===================================
has 'bad_opt_attr' => (
#===================================
    is       => 'ro',
    isa      => 'Str',
    type     => 'ip',
    analyzer => 'standard',
);

#===================================
has 'bad_multi_attr' => (
#===================================
    is    => 'ro',
    isa   => 'Str',
    type  => 'ip',
    multi => { one => { analyzer => 'standard' } }
);

1;
