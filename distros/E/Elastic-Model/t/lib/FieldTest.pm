package FieldTest;

use Elastic::Model;

#===================================
has_namespace 'foo' => {
#===================================
    string   => 'FieldTest::String',
    number   => 'FieldTest::Number',
    date     => 'FieldTest::Date',
    boolean  => 'FieldTest::Boolean',
    binary   => 'FieldTest::Binary',
    object   => 'FieldTest::Object',
    nested   => 'FieldTest::Nested',
    ip       => 'FieldTest::IP4',
    geopoint => 'FieldTest::GeoPoint'
};

no Elastic::Model;

1;
