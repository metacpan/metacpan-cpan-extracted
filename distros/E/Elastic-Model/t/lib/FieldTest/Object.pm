package Foo;
use Moose;

#===================================
has 'foo' => (
#===================================
    is  => 'ro',
    isa => 'Str',
);

package Bar;

use Moose;

#===================================
has 'bar' => (
#===================================
    is  => 'ro',
    isa => 'Str',
);

#===================================
has 'foo' => (
#===================================
    is             => 'ro',
    isa            => 'Foo',
    traits         => ['Elastic::Model::Trait::Field'],
    include_in_all => 0,
);

package FieldTest::Object;

use Elastic::Doc;

#===================================
has 'basic_attr' => (
#===================================
    is  => 'ro',
    isa => 'Bar',
);

#===================================
has 'disabled_attr' => (
#===================================
    is      => 'ro',
    isa     => 'Bar',
    enabled => 0
);

#===================================
has 'options_attr' => (
#===================================
    is               => 'ro',
    isa              => 'Bar',
    'dynamic'        => 'true',
    'path'           => 'full',
    'include_in_all' => 0,
);

#===================================
has 'multi_attr' => (
#===================================
    is    => 'ro',
    isa   => 'Bar',
    multi => { one => { type => 'string' } }
);

1;
