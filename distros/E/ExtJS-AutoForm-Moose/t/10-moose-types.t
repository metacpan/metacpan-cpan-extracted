#!perl -T

use Test::More tests => 23;
use Data::Dumper;
use JSON::Any;

use lib "t/lib";

my @class;
my @obj;

# load test class
use_ok("MooseTests::Class0");

# Generate extjs form fields directly through class
eval("\@class = MooseTests::Class0\-\>extjs_fields;");
ok( !$@, "Reflection of MooseTests::Class0 through package" )
    or diag("Error: $@");

is_deeply( $class[0], { name => "str", fieldLabel => "str", xtype => "textfield" }, "Simple string attribute" );
is_deeply( $class[1], { name => "num", fieldLabel => "num", xtype => "numberfield", allowDecimals => JSON::Any::true }, "Simple number attribute" );
is_deeply( $class[2], { name => "int", fieldLabel => "int", xtype => "numberfield", allowDecimals => JSON::Any::false }, "Simple integer attribute" );
is_deeply( $class[3], { name => "bool", fieldLabel => "bool", xtype => "checkbox" }, "Simple boolean attribute" );
is_deeply( $class[4], { name => "tenum", fieldLabel => "tenum", xtype => "combo", store => [ qw(val1 val2 val3) ] }, "Simple boolean attribute" );

is_deeply( $class[5], { name => "str_ro", fieldLabel => "str_ro", xtype => "textfield", readOnly => JSON::Any::true }, "Read-only string attribute" );
is_deeply( $class[6], { name => "num_ro", fieldLabel => "num_ro", xtype => "numberfield", readOnly => JSON::Any::true, allowDecimals => JSON::Any::true }, "Read-only number attribute" );
is_deeply( $class[7], { name => "int_ro", fieldLabel => "int_ro", xtype => "numberfield", readOnly => JSON::Any::true, allowDecimals => JSON::Any::false }, "Read-only integer attribute" );
is_deeply( $class[8], { name => "bool_ro", fieldLabel => "bool_ro", xtype => "checkbox", readOnly => JSON::Any::true }, "Read-only boolean attribute" );
is_deeply( $class[9], { name => "tenum_ro", fieldLabel => "tenum_ro", xtype => "combo", readOnly => JSON::Any::true, store => [ qw(val1 val2 val3) ] }, "Read-only boolean attribute" );


# Generate extjs fields through an object instance
eval("\@obj = MooseTests::Class0\-\>new()\-\>extjs_fields;");
ok( !$@, "Reflection of MooseTests::Class0 through object instance" )
    or diag("Error: $@");

#diag(Dumper(\@obj));

is_deeply( $obj[0], { name => "str", fieldLabel => "str", xtype => "textfield" }, "Simple string attribute on instance" );
is_deeply( $obj[1], { name => "num", fieldLabel => "num", xtype => "numberfield", allowDecimals => JSON::Any::true }, "Simple number attribute on instance" );
is_deeply( $obj[2], { name => "int", fieldLabel => "int", xtype => "numberfield", allowDecimals => JSON::Any::false }, "Simple integer attribute on instance" );
is_deeply( $obj[3], { name => "bool", fieldLabel => "bool", xtype => "checkbox" }, "Simple boolean attribute on instance" );
is_deeply( $obj[4], { name => "tenum", fieldLabel => "tenum", xtype => "combo", store => [ qw(val1 val2 val3) ] }, "Simple boolean attribute on instance" );

is_deeply( $obj[5], { name => "str_ro", fieldLabel => "str_ro", xtype => "textfield", readOnly => JSON::Any::true }, "Read-only string attribute on instance" );
is_deeply( $obj[6], { name => "num_ro", fieldLabel => "num_ro", xtype => "numberfield", readOnly => JSON::Any::true, allowDecimals => JSON::Any::true }, "Read-only number attribute on instance" );
is_deeply( $obj[7], { name => "int_ro", fieldLabel => "int_ro", xtype => "numberfield", readOnly => JSON::Any::true, allowDecimals => JSON::Any::false }, "Read-only integer attribute on instance" );
is_deeply( $obj[8], { name => "bool_ro", fieldLabel => "bool_ro", xtype => "checkbox", readOnly => JSON::Any::true }, "Read-only boolean attribute on instance" );
is_deeply( $obj[9], { name => "tenum_ro", fieldLabel => "tenum_ro", xtype => "combo", readOnly => JSON::Any::true, store => [ qw(val1 val2 val3) ] }, "Read-only boolean attribute on instance" );


