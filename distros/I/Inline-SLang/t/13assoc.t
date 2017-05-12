# -*-perl-*-
#
# test in/out of associative arrays
#

use strict;

use Test::More tests => 107;

use Inline 'SLang' => Config => EXPORT => [ '!types' ];
use Inline 'SLang';

use Data::Dumper;

# check for approximately equal
# - for these operations an absolute tolerance is okay
#
# really want to be able to test arrays easily
#
use constant ABSTOL => 1.0e-10;
sub approx ($$$) {
    my ( $a, $b, $text ) = @_;
    my $delta = $a-$b;
    ok( abs($delta) < ABSTOL, "$text [delta=$delta]" );
}

## Tests

my ( $ret1, $ret2, @ret );

# use array references for ALL arrays (even if we
# have PDL support)
#
Inline::SLang::sl_array2perl( 0 );

## S-Lang 2 perl

$ret1 = assocarray_uchar();
#print "Assoc array:\n" . Dumper($ret1), "\n";
is( ref($ret1), "Assoc_Type", "Assoc_Array [UChar_Type] converted to Assoc_Type object" );
ok( UNIVERSAL::isa($ret1,"Assoc_Type"), "  checking the same thing" );
is( $ret1->_typeof(), UChar_Type(), "  and contains UChar_Type vars" );
ok( eq_array( [sort keys %$ret1], [ "1", "a", "b b" ] ),
     "   keys for assoc array are okay" );
is( $$ret1{"a"},     1, "  key   a == 1" );
is( $$ret1{"b b"}, 120, "  key b b == 120" );
is( $$ret1{"1"},   255, "  key   1 == 255" );

$$ret1{"a"} = 23;
is( $$ret1{"a"}, 23, "  and can change key a to 23" );

# don't really want users to use these, but may a well check them
# - note: no guarantee of order of keys
ok( eq_array( [sort @{ $ret1->get_keys }], [sort ("a", "b b", "1")] ),
	      "get_keys() works" );
is( $ret1->get_value("b b"), 120, "and get_key(\"b b\") works" );

# get the order of the keys
$ret1->set_value("1",24);
my @order = keys %$ret1;
my %vals = ( "a" => 23, "b b" => 120, "1" => 24 );
ok( eq_array( $ret1->get_values(), [map { $vals{$_} } @order] ),
    "get_values() seems to work as an object method" );

# can we add a value?
$$ret1{"foo foo"} = 96;
is( $@, "", "Can set new field 'foo foo'" );
is( $ret1->get_value("foo foo"), 96, "  and value is correct" );

is( $ret1->length, 4, "Can call length() on object" );

ok( exists $$ret1{"foo foo"},  "exists works for a key that exists" );
ok( !exists $$ret1{"foo-foo"}, "exists works for a key that exists" );

ok( $ret1->key_exists("foo foo"),  "key_exists() works for a key that exists" );
ok( !$ret1->key_exists("foo-foo"), "key_exists() works for a key that don't exist" );

$ret1->delete_key( "1" );
ok( eq_array( [sort keys %$ret1], [sort ( "a", "b b", "foo foo" )] ),
    "Can delete a key with delete_key()" );

delete $$ret1{"b b"};
ok( eq_array( [sort keys %$ret1], [sort ( "a", "foo foo" )] ),
    "Can delete a key with delete" );

# can we clear the array?
%$ret1 = ();
ok( eq_array( [keys %$ret1], [] ), "Clearing array clears the array" );

$ret1 = assocarray_string();
#print "Assoc array:\n" . Dumper($ret1), "\n";
is( ref($ret1), "Assoc_Type", "Assoc_Array [String_Type] converted to Assoc_Array ref" );
ok( eq_array( [sort keys %$ret1], [ "1", "a", "b b" ] ),
     "   keys for assoc array are okay" );
is( $$ret1{"a"},      "aa", '  key   a == "aa"' );
is( $$ret1{"b b"},   "1.2", '  key b b == "1.2"' );
is( $$ret1{"1"},   "[1:4]", '  key   1 == "[1:4]"' );

# check we don't mess up the stack
my $ret3;
( $ret1, $ret2, $ret3 ) = ret_multi();
is( $ret1, "a string",  'Returned: 1st elem = string' );
is( ref($ret2), "Assoc_Type", 'Returned: 2nd elem = assoc array' );
is( $$ret2{"a b q"}, 23, '  and "a b q" = 23' );
is( $$ret2{"1"},     -4, '  and "1"     = -4' );
is( $ret3, 22.4,        'Returned: 3rd elem = real' );

# can we have an assoc array of assoc arrays?
# [ really check out the stack handling ;]
( $ret1, $ret2, $ret3 ) = ret_assoc2();

is( "$ret1", "Assoc_Type", "Assoc_Type [Assoc_Type] returned an Assoc_Type" );
is( $ret1->_typeof, Assoc_Type(), "  and contains Assoc_Type" );

is( "$$ret1{any2}", "Assoc_Type", "  any2 contains Assoc_Type" );
is( $$ret1{any2}->_typeof, Any_Type(), "    and it contans Any_Type" );

is( $$ret1{any2}{a}, "aa", "  and field a contains 'aa'" );
is( $$ret1{any2}{"b b"}, 1.2, "  and field 'b b' contains 1.2" );

ok( eq_array( $$ret1{any2}{1}, [1,2,3,4] ),
    "  and field 1 contains [1:4]" );

is( "$$ret1{uchar}", "Assoc_Type", "  uchar contains Assoc_Type" );
is( $$ret1{uchar}->_typeof, UChar_Type(), "    and it contans UChar_Type" );
is( $$ret1{uchar}{1}, 255, "  and field 1 contains 255" );

ok( UNIVERSAL::isa($ret2,"DataType_Type"), "Stack handling good so far" );

is( ref($ret3), "Assoc_Type", "Last item is an Assoc_Type array" );
is( $ret3->_typeof, Struct_Type(), "  and contains Struct_Type" );
ok( eq_array( [ sort keys %{ $ret3 } ], ["a struct","foo"] ),
    "  with correct keys" );
ok( $$ret3{foo}->is_struct_type, "  and foo is a struct" );
ok( eq_array( [ keys %{ $$ret3{foo} } ], [ "x1" ] ) &&
    $$ret3{foo}{x1} == 2.3,
    "  and foo contents are okay" );
ok( $$ret3{"a struct"}->is_struct_type, "  and 'a struct' is a struct" );
ok( eq_array( [ keys %{ $$ret3{"a struct"} } ], [ "qq", "pp" ] ) &&
    $$ret3{"a struct"}{qq} eq "alpha" &&
    UNIVERSAL::isa($$ret3{"a struct"}{pp},"DataType_Type") &&
    $$ret3{"a struct"}{pp} eq UInteger_Type(),
    "  and 'a struct' contents are okay" );

# and send it back to S-Lang
ok( check_assoc2( $ret1, $ret2, $ret3 ), "And can convert stuff back to S-Lang" );

# check using array references
Inline::SLang::sl_array2perl( 1 );
$ret1 = assocarray_array();
#print "Assoc array:\n" . Dumper($ret1), "\n";
is( ref($ret1), "Assoc_Type", "Assoc_Array [Array_Type] converted to Assoc_Type" );
is( $ret1->_typeof, Array_Type(), "  and contents are Array_Type" );
ok( eq_array( [sort keys %$ret1], [ "1", "a", "b b" ] ),
    "   keys for assoc array are okay" );

ok( eq_array( $$ret1{"a"}->toPerl,   [0,1,2,3] ),
    '  key   a == [0,1,2,3]' );
ok( eq_array( $$ret1{"b b"}->toPerl, [1,2,3,4] ),
    '  key b b == [1,2,3,4]' );
ok( eq_array( $$ret1{"1"}->toPerl,   [0.5,1.0,1.5,2.0] ),
    '  key   1 == [1,2,3,4]/2' );

$ret1 = assocarray_any1();
#print "Assoc array:\n" . Dumper($ret1), "\n";
is( ref($ret1), "Assoc_Type", "Assoc_Array [] converted to Assoc_Type" );
is( $ret1->_typeof, Any_Type(), "  and it contains Any_Type" );
ok( eq_array( [sort keys %$ret1], [ "1", "a", "b b" ] ),
    "   keys for assoc array are okay" );

is( $$ret1{"a"},   "aa", '  key   a == "aa"' );
is( $$ret1{"b b"},  1.2, '  key b b == 1.2' );

ok( eq_array( $$ret1{"1"}->toPerl, [1,2,3,4] ),
    '  key   1 == [1,2,3,4]' );
Inline::SLang::sl_array2perl( 0 );

# and piddles
SKIP: {
    skip 'No PDL support', 12 unless Inline::SLang::sl_have_pdl();

    Inline::SLang::sl_array2perl( 2 );
    $ret1 = assocarray_array();
    ##print "Assoc array:\n" . Dumper($ret1), "\n";
    is( ref($ret1), "Assoc_Type", "Assoc_Array [Array_Type] converted to Assoc_Type" );
    is( $ret1->_typeof, Array_Type(), "  and contents are Array_Type" );
    ok( eq_array( [sort keys %$ret1], [ "1", "a", "b b" ] ),
	"   keys for assoc array are okay" );

    # note: we define a S-Lang routine called all below but want to use PDL's version
    ok( PDL::all( $$ret1{"a"} == PDL::long(0,1,2,3) ),
	'  key   a == [0,1,2,3]' );
    ok( PDL::all( $$ret1{"b b"} == PDL::long(1,2,3,4) ),
	'  key b b == [1,2,3,4]' );
    ok( PDL::all( $$ret1{"1"} == PDL::double(0.5,1.0,1.5,2.0) ),
	'  key   1 == [1,2,3,4]/2' );

    $ret1 = assocarray_any1();
    #print "Assoc array:\n" . Dumper($ret1), "\n";
    is( ref($ret1), "Assoc_Type", "Assoc_Array [] converted to Assoc_Type" );
    is( $ret1->_typeof, Any_Type(), "  and it contains Any_Type" );
    ok( eq_array( [sort keys %$ret1], [ "1", "a", "b b" ] ),
	"   keys for assoc array are okay" );

    is( $$ret1{"a"},   "aa", '  key   a == "aa"' );
    is( $$ret1{"b b"},  1.2, '  key b b == 1.2' );

    ok( PDL::all( $$ret1{"1"} == PDL::long(1,2,3,4) ),
	'  key   1 == [1,2,3,4]' );
    Inline::SLang::sl_array2perl( 0 );
}

## check conversion of Perl hash references
#
# these are shortform for Assoc_Type->new( "Any_Type" );
#

# this test includes checking the stack handling
my $href = { aa => 'a a', 23 => 2, "a string" => 2.3 };
ok( check_hashref( DataType_Type->new(), $href, undef ),
    "Can convert a hash reference to S-Lang Assoc_Type [Any_Type]" );
$ret1 = return_hashref($href);
ok( UNIVERSAL::isa($ret1,"Assoc_Type"), "hash ref to S-Lang to Perl -> Assoc_Type" );
is( $ret1->_typeof, Any_Type(), "  and type=Any_Type" );

is( $$ret1{aa}, "a a", "  and field 'aa' eq 'a a'" );
is( $$ret1{"a string"}, 2.3, "  and field 'a string' == 2.3" );
is( $$ret1{23}, 2, "  and field 'aa' == 2" );

# check that other 'array convresion' strategies work okay
#
# Array_Type
Inline::SLang::sl_array2perl( 1 );
$ret1 = assocarray_array();
##print "Assoc array:\n" . Dumper($ret1), "\n";
is( ref($ret1), "Assoc_Type", "Assoc_Array [Array_Type] converted to Assoc_Type" );
is( $ret1->_typeof, Array_Type(), "  and contents are Array_Type" );
ok( eq_array( [sort keys %$ret1], [ "1", "a", "b b" ] ),
    "   keys for assoc array are okay" );

isa_ok( $$ret1{"a"},   "Array_Type" );
isa_ok( $$ret1{"b b"}, "Array_Type" );
isa_ok( $$ret1{"1"},   "Array_Type" );

my ( $dims, $ndims, $atype );
( $dims, $ndims, $atype ) = $$ret1{"a"}->array_info();
is( $ndims, 1, "Array is 1D" );
is( $$dims[0], 4, "  with 4 elements" );
is( "$atype", "Integer_Type", "  and datatype Integer_Type" );
ok( eq_array( $$ret1{"a"}->toPerl, [0,1,2,3] ),
    '  key   a == [0,1,2,3]' );

( $dims, $ndims, $atype ) = $$ret1{"b b"}->array_info();
is( $ndims, 1, "Array is 1D" );
is( $$dims[0], 4, "  with 4 elements" );
is( "$atype", "Integer_Type", "  and datatype Integer_Type" );
ok( eq_array( $$ret1{"b b"}->toPerl, [1,2,3,4] ),
    '  key b b == [1,2,3,4]' );

( $dims, $ndims, $atype ) = $$ret1{"1"}->array_info();
is( $ndims, 1, "Array is 1D" );
is( $$dims[0], 4, "  with 4 elements" );
is( "$atype", "Double_Type", "  and datatype Double_Type" );
ok( eq_array( $$ret1{"1"}->toPerl,   [0.5,1.0,1.5,2.0] ),
    '  key   1 == [1,2,3,4]/2' );

$ret1 = assocarray_any1();
##print "Assoc array:\n" . Dumper($ret1), "\n";
is( ref($ret1), "Assoc_Type", "Assoc_Array [] converted to Assoc_Type" );
is( $ret1->_typeof, Any_Type(), "  and it contains Any_Type" );
ok( eq_array( [sort keys %$ret1], [ "1", "a", "b b" ] ),
    "   keys for assoc array are okay" );

is( $$ret1{"a"},   "aa", '  key   a == "aa"' );
is( $$ret1{"b b"},  1.2, '  key b b == 1.2' );

( $dims, $ndims, $atype ) = $$ret1{"1"}->array_info();
is( $ndims, 1, "Array is 1D" );
is( $$dims[0], 4, "  with 4 elements" );
is( "$atype", "Integer_Type", "  and datatype Integer_Type" );
ok( eq_array( $$ret1{"1"}->toPerl, [1,2,3,4] ),
    '  key   1 == [1,2,3,4]' );


__END__
__SLang__

%% S-Lang 2 perl: associative arrays

define assocarray_uchar () {
  variable foo = Assoc_Type [UChar_Type];
  foo["a"]   = 1;
  foo["b b"] = 'x';
  foo["1"]   = 255;
  return foo;
}

define assocarray_string () {
  variable foo = Assoc_Type [String_Type];
  foo["a"]   = "aa";
  foo["b b"] = "1.2";
  foo["1"]   = "[1:4]";
  return foo;
}

define assocarray_array () {
  variable foo = Assoc_Type [Array_Type];
  foo["a"]   = [0:3];
  foo["b b"] = foo["a"] + 1; % want to try a 2D array
  foo["1"]   = foo["b b"] / 2.0;
  return foo;
}

define assocarray_any1 () {
  variable foo = Assoc_Type [];
  foo["a"]   = "aa";
  foo["b b"] = 1.2;
  foo["1"]   = [1:4];
  return foo;
}

define assocarray_any2 () {
  variable foo = Assoc_Type [Any_Type];
  foo["a"]   = "aa";
  foo["b b"] = 1.2;
  foo["1"]   = [1:4];
  return foo;
}

define ret_multi() {
  variable foo = Assoc_Type [Integer_Type];
  foo["a b q"] = 23;
  foo["1"]     = -4;
  return "a string", foo, 22.4;
}

%
% As of version 0.26 of Inline::SLang we guarantee that
% sum is part of the S-Lang tun-time library
%
define all(x) { return sum(typecast(x,Int_Type)!=0) == length(x); }
define any(x) { return sum(typecast(x,Int_Type)!=0) != 0; }

define check_assoc2(x,y,z) {
  % split checks up
  if ( orelse
       { typeof(y) != DataType_Type }
       { y != String_Type }
       ) return 0;
  if ( orelse
       { typeof(x) != Assoc_Type }
       { typeof(z) != Assoc_Type }
       ) return 0;

  variable keys = assoc_get_keys(x);
  variable indx = array_sort(keys);
  if ( any( keys[indx] != ["any2","uchar"] ) ) return 0;
  if ( orelse
       { typeof(x["any2"]) != Assoc_Type }
       { x["any2"]["a"] != "aa" }
       { x["any2"]["b b"] != 1.2 }
       { any( x["any2"]["1"] != [1:4] ) }
       ) return 0;
  if ( orelse
       { typeof(x["uchar"]) != Assoc_Type }
       { x["uchar"]["a"] != 1 }
       { x["uchar"]["b b"] != 'x' }
       { x["uchar"]["1"] != 255 }
       ) return 0;

  keys = assoc_get_keys(z);
  indx = array_sort(keys);
  if ( any( keys[indx] != ["a struct","foo"] ) ) return 0;
  if ( orelse
       { typeof(z["a struct"]) != Struct_Type }
       { any( get_struct_field_names(z["a struct"]) != ["qq","pp"] ) }
       { z["a struct"].qq != "alpha" }
       { z["a struct"].pp != UInteger_Type }
       ) return 0;
  if ( orelse
       { typeof(z["foo"]) != Struct_Type }
       { any( get_struct_field_names(z["foo"]) != ["x1"] ) }
       { z["foo"].x1 != 2.3 }
       ) return 0;

  return 1;
} % check_assoc2

define ret_assoc2() {
  variable foo = Assoc_Type [Assoc_Type];
  foo["any2"] = assocarray_any2();
  foo["uchar"] = assocarray_uchar();
  variable bar = Assoc_Type [Struct_Type];
  bar["a struct"] = struct { qq, pp };
  bar["a struct"].qq = "alpha";
  bar["a struct"].pp = UInt_Type;
  bar["foo"] = struct { x1 };
  bar["foo"].x1 = 2.3;

  return foo, String_Type, bar;
} % ret_assoc2

define check_hashref(z,x,y) {
  if ( orelse
       { typeof(z) != DataType_Type }
       { z != DataType_Type }
       ) return 0;
  if ( y != NULL ) return 0;

  % check in stages
  % no way to check the assoc_type type being any_type directly
  if ( typeof(x) != Assoc_Type ) return 0;

  variable keys = assoc_get_keys(x);
  variable indx = array_sort(keys);
  if ( any( keys[indx] != ["23","a string","aa"] ) ) return 0;
  if ( orelse
       { typeof(x["aa"]) != String_Type }
       { x["aa"] != "a a" }
       { typeof(x["a string"]) != Double_Type }
       { x["a string"] != 2.3 }
       { typeof(x["23"]) != Integer_Type }
       { x["23"] != 2 }
       ) return 0;

  return 1;
} % check_hashref

define return_hashref(x) { return x; }

