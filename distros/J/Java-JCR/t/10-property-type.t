# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 38;

use_ok('Java::JCR');

no warnings 'once';

is($Java::JCR::PropertyType::UNDEFINED, 0);
is($Java::JCR::PropertyType::STRING, 1);
is($Java::JCR::PropertyType::BINARY, 2);
is($Java::JCR::PropertyType::LONG, 3);
is($Java::JCR::PropertyType::DOUBLE, 4);
is($Java::JCR::PropertyType::DATE, 5);
is($Java::JCR::PropertyType::BOOLEAN, 6);
is($Java::JCR::PropertyType::NAME, 7);
is($Java::JCR::PropertyType::PATH, 8);
is($Java::JCR::PropertyType::REFERENCE, 9);

is($Java::JCR::PropertyType::TYPENAME_STRING, "String");
is($Java::JCR::PropertyType::TYPENAME_BINARY, "Binary");
is($Java::JCR::PropertyType::TYPENAME_LONG, "Long");
is($Java::JCR::PropertyType::TYPENAME_DOUBLE, "Double");
is($Java::JCR::PropertyType::TYPENAME_DATE, "Date");
is($Java::JCR::PropertyType::TYPENAME_BOOLEAN, "Boolean");
is($Java::JCR::PropertyType::TYPENAME_NAME, "Name");
is($Java::JCR::PropertyType::TYPENAME_PATH, "Path");
is($Java::JCR::PropertyType::TYPENAME_REFERENCE, "Reference");

is(Java::JCR::PropertyType->name_from_value(1), "String");
is(Java::JCR::PropertyType->name_from_value(2), "Binary");
is(Java::JCR::PropertyType->name_from_value(3), "Long");
is(Java::JCR::PropertyType->name_from_value(4), "Double");
is(Java::JCR::PropertyType->name_from_value(5), "Date");
is(Java::JCR::PropertyType->name_from_value(6), "Boolean");
is(Java::JCR::PropertyType->name_from_value(7), "Name");
is(Java::JCR::PropertyType->name_from_value(8), "Path");
is(Java::JCR::PropertyType->name_from_value(9), "Reference");

is(Java::JCR::PropertyType->value_from_name("String"), 1);
is(Java::JCR::PropertyType->value_from_name("Binary"), 2);
is(Java::JCR::PropertyType->value_from_name("Long"), 3);
is(Java::JCR::PropertyType->value_from_name("Double"), 4);
is(Java::JCR::PropertyType->value_from_name("Date"), 5);
is(Java::JCR::PropertyType->value_from_name("Boolean"), 6);
is(Java::JCR::PropertyType->value_from_name("Name"), 7);
is(Java::JCR::PropertyType->value_from_name("Path"), 8);
is(Java::JCR::PropertyType->value_from_name("Reference"), 9);
