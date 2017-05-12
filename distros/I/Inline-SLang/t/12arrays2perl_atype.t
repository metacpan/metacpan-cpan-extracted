#
# test conversion of S-Lang arrays to Perl using the
# Array_Type object
#
# try to keep this up-to-date with 12arrays2perl.t
#

use strict;

use Test::More tests => 146;

use Inline 'SLang';

###
### tell Inline::SLang that we want to convert S-Lang arrays
### into Perl array references
###
Inline::SLang::sl_array2perl( 1 );

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
my ( $dims, $ndims, $atype );

## S-Lang 2 perl: Integers

$ret1 = arrayi2();
is( ref($ret1), 'Array_Type', 'array int returned Array_Type' );
isa_ok( $ret1, 'Inline::SLang::_Type' );
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
is( $ndims, 1, "Array is 1D" );
is( $$dims[0], 1, "  with 1 element" );
is( "$atype", "Integer_Type", "  and datatype Integer_Type" );
is( $ret1->get(0), 2, "  and elem 0 contains 2" );

( $ret1, $ret2 ) = arrayi35();
isa_ok( $ret1, 'Array_Type' );
is( defined $ret2, '', ' and no second item' );
( $dims, $ndims, $atype ) = $ret1->array_info();
is( $ndims, 1, "Array is 1D" );
is( $$dims[0], 2, "  with 2 elements" );
is( "$atype", "Integer_Type", "  and datatype Integer_Type" );
is( $ret1->get(0), 3, "  and elem 0 contains 3" );
is( $ret1->get(1), 5, "  and elem 1 contains 5" );

## S-Lang 2 perl: "uncommon" types

$ret1 = array_ui(2,5);
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 2, "Array is 1D with 2 elements" );
is( "$atype", "UInteger_Type", "  and datatype UInteger_Type" );
ok( $ret1->get(0) == 2 && $ret1->get(1) == 5, "  and values okay" );

$ret1 = array_chars();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 3, "Array is 1D with 3 elements" );
is( "$atype", "UChar_Type", "  and datatype UChar_Type" );
ok( eq_array( $ret1->toPerl(), [97..99] ), "  and values okay" );

my $ltype = Inline::SLang::sl_eval( "Long_Type" );

$ret1 = array_longs();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 3, "Array is 1D with 3 elements" );
is( $atype, $ltype, "  and datatype is correct (Long_Type -> $ltype)" );
ok( eq_array( $ret1->toPerl(), [1000000000,21000000,-4] ),
	"  and values okay" );

## S-Lang 2 perl: Reals
$ret1 = arrayr2_1();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 1, "Array is 1D with 1 elements" );
is( "$atype", "Double_Type", "  and datatype Double_Type" );
approx( $ret1->get(0), 2.1, '  and values okay' );

$ret1 = arrayr3_25_4();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 2, "Array is 1D with 2 elements" );
is( "$atype", "Double_Type", "  and datatype Double_Type" );
approx( $ret1->get(0), 3.2, '  and value [0] == 3.2' );
approx( $ret1->get(1), 5.4, '  and value [1] == 5.4' );

## S-Lang 2 perl: Strings

$ret1 = arraystest1();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 1, "Array is 1D with 1 elements" );
is( "$atype", "String_Type", "  and datatype String_Type" );
is( $ret1->get(0), "this is an array test", '  array [0] okay' );

$ret1 = arraystest2();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 2, "Array is 1D with 2 elements" );
is( "$atype", "String_Type", "  and datatype String_Type" );
is( $ret1->get(0), "", '  array [0] okay' );
is( $ret1->get(1), "this is an array test", '  array [1] okay' );

@ret = arraystest2();
is( $#ret, 0, 'array stack check okay' );

## S-Lang 2 perl: complex numbers

$ret1 = array_cplx();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 3, "Array is 1D with 3 elements" );
is( "$atype", "Complex_Type", "  and datatype Complex_Type" );
isa_ok( $ret1->get(0), "Math::Complex" );
isa_ok( $ret1->get(1), "Math::Complex" );
isa_ok( $ret1->get(2), "Math::Complex" );

# stringify the values as an easy way to check the values
is( "".$ret1->get(0), "1-i",          "  elem 0 = 1-i" );
is( "".$ret1->get(1), "2+3.5i",       "  elem 1 = 2+3.5i" );
is( "".$ret1->get(2), "-47.9-22.45i", "  elem 2 = -47.9-22.45i" );

$ret1 = array_cplx2d();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 2 && $$dims[0] == 2 && $$dims[1] == 3,
  	"Array is 2D with 2x3 elements" );
is( "$atype", "Complex_Type", "  and datatype Complex_Type" );
isa_ok( $ret1->get(0,0), "Math::Complex" );
isa_ok( $ret1->get(0,1), "Math::Complex" );
isa_ok( $ret1->get(1,2), "Math::Complex" );

# stringify the values as an easy way to check the values
is( $ret1->get(0,0) . " " . $ret1->get(0,1) . " " . $ret1->get(0,2),
    "1-i 2+3.5i -47.9-22.45i",
    "  ans[0,*] is correct (3 complex numbers)" );
is( $ret1->get(1,0) . " " . $ret1->get(1,1) . " " . $ret1->get(1,2),
    "1+i -3.5+2i 3-4i",
    "  ans[1,*] is correct (3 complex numbers)" );

## S-Lang 2 perl: datatypes

$ret1 = array_dtypes();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 5, "Array is 1D with 5 elements" );
is( "$atype", "DataType_Type", "  and datatype DataType_Type" );
isa_ok( $ret1->get(0), "DataType_Type" );
isa_ok( $ret1->get(1), "DataType_Type" );
isa_ok( $ret1->get(2), "DataType_Type" );
isa_ok( $ret1->get(3), "DataType_Type" );
isa_ok( $ret1->get(4), "DataType_Type" );

is( join(" ",map { "$_" } @{$ret1->toPerl}),
    "Array_Type UInteger_Type Float_Type Assoc_Type DataType_Type",
    "The datatypes are converted correctly" );

$ret1 = array_dtypes2d();
##print Dumper($ret1), "\n";
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 2 && $$dims[0] == 3 && $$dims[1] == 2,
    "Array is 2D with 3x2 elements" );
is( "$atype", "DataType_Type", "  and datatype DataType_Type" );
isa_ok( $ret1->get(0,0), "DataType_Type" );
isa_ok( $ret1->get(0,1), "DataType_Type" );
isa_ok( $ret1->get(1,0), "DataType_Type" );
isa_ok( $ret1->get(2,1), "DataType_Type" );

is( join(" ",($ret1->get(0,0),$ret1->get(0,1))),
    "String_Type Array_Type",
    "  ans[0,*] is correct (2 datatypes)" );
is( join(" ",($ret1->get(1,0),$ret1->get(1,1))),
    "UInteger_Type Float_Type",
    "  ans[1,*] is correct (2 datatypes)" );
is( join(" ",($ret1->get(2,0),$ret1->get(2,1))),
    "Assoc_Type DataType_Type",
    "  ans[2,*] is correct (2 datatypes)" );

## S-Lang 2 perl: Any_Type
#
# don't have a de-reference method so can't check the values
$ret1 = ret_anytype();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 3, "Array is 1D with 3 elements" );
is( "$atype", "Any_Type", "  and datatype Any_Type" );
isa_ok( $ret1->get(0), "Any_Type" );
isa_ok( $ret1->get(1), "Any_Type" );
isa_ok( $ret1->get(2), "Any_Type" );

## try some > 1D arrays (have already tested some above)

$ret1 = array2Di();
##print "2D integer array:\n" . Dumper($ret1) . "\n";
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 2 && $$dims[0] == 2 && $$dims[1] == 3,
	"Array is 2D with 2x3 elements" );
is( "$atype", "Integer_Type", "  and datatype Integer_Type" );
ok( eq_array( $ret1->toPerl, [[1,2,2],[9,8,7]] ),
     '    and contains the correct values [integers]' );

$ret1 = array2Dr();
##print "2D real array:\n" . Dumper($ret1) . "\n";
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 2 && $$dims[0] == 2 && $$dims[1] == 3,
	"Array is 2D with 2x3 elements" );
is( "$atype", "Double_Type", "  and datatype Double_Type" );
ok( eq_array( $ret1->toPerl(), [[1.1,2.2,2.3],[9.4,8.5,7.6]] ),
                         '    and contains the correct values [reals]' );

$ret1 = array2Ds();
##print "2D string array:\n" . Dumper($ret1) . "\n";
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 2 && $$dims[0] == 2 && $$dims[1] == 3,
	"Array is 2D with 2x3 elements" );
is( "$atype", "String_Type", "  and datatype String_Type" );
ok( eq_array( $ret1->toPerl,
	    [['aa',"cc","x"], ['1','this is a long string', "2"]] ),
                         '    and contains the correct values [strings]' );

# 3D
$ret1 = array3Di();
##print "3D integer array:\n" . Dumper($ret1) . "\n";
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 3 && $$dims[0] == 1 && $$dims[1] == 3 && $$dims[2] == 2,
	"Array is 3D with 1x3x2 elements" );
is( "$atype", "Integer_Type", "  and datatype Integer_Type" );
ok( eq_array( $ret1->toPerl,
              [[[1,2],[2,9],[8,7]]] ),
                         '    and contains the correct values [integers]' );

## multi-dimensional but only containing 1 element
$ret1 = ret_1elem(1);
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 1,
	"Array is 1D with 1 elements" );
is( $ret1->get(0), -2.4,     "     and contents okay" );

$ret1 = ret_1elem(2);
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 2 && $$dims[0] == 1 && $$dims[1] == 1,
	"Array is 2D with 1x1 elements" );
is( $ret1->get(0,0), -2.4,     "     and contents okay" );

$ret1 = ret_1elem(3);
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 3 && $$dims[0] == 1 && $$dims[1] == 1 && $$dims[2] == 1,
	"Array is 3D with 1x1x1 elements" );
is( $ret1->get(0,0,0), -2.4,     "     and contents okay" );

$ret1 = ret_1elem(4);
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 4 &&
    $$dims[0] == 1 && $$dims[1] == 1 && $$dims[2] == 1 && $$dims[3] == 1,
	"Array is 4D with 1x1x1x1 elements" );
is( $ret1->get(0,0,0,0), -2.4,     "     and contents okay" );

$ret1 = ret_1elem(5);
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 5 &&
    $$dims[0] == 1 && $$dims[1] == 1 && $$dims[2] == 1 && $$dims[3] == 1 &&
    $$dims[4] == 1,
	"Array is 5D with 1x1x1x1x1 elements" );
is( $ret1->get(0,0,0,0,0), -2.4,     "     and contents okay" );

$ret1 = ret_1elem(6);
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 6 &&
    $$dims[0] == 1 && $$dims[1] == 1 && $$dims[2] == 1 && $$dims[3] == 1 &&
    $$dims[4] == 1 && $$dims[5] == 1,
	"Array is 6D with 1x1x1x1x1x1 elements" );
is( $ret1->get(0,0,0,0,0,0), -2.4,     "     and contents okay" );

# seems to be some complication when using 7D arrays
# - which appears to be a bug in S-Lang v1.4.9 and earlier
#$ret1 = ret_1elem(7);
#is( ref($ret1), "ARRAY", "7D - 1 element returned an array reference" );
#is( $$ret1[0][0][0][0][0][0][0], -2.4,     "     and contents okay" );

## arrays of a named struct
$ret1 = ret_foofoo(2);
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 2,
	"Array is 1D with 2 elements" );
is( "$atype", "FooFoo_Struct", "  and contains FooFoo_Struct" );
is( join( " ", @{ $ret1->toPerl() } ),
    "FooFoo_Struct FooFoo_Struct", "  [repeat the check]" );
ok( $ret1->get(0)->{foo1} == 0 &&
    $ret1->get(0)->{foo2} == 0 &&
    $ret1->get(1)->{foo1} == 1 &&
    $ret1->get(1)->{foo2} == 100,
    "  and values okay" );

## Check out some stack handling

( $ret1, $ret2 ) = array_scalar();
isa_ok( $ret1, 'Array_Type' );
( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 1 && $$dims[0] == 3,
	"  1st element is an array [1D] with 3 elements" );
is( "$atype", "Double_Type", "  and datatype Double_Type" );
ok( eq_array( $ret1->toPerl(), [-3.0, 0.0, 42.1] ),
                         '    and contains the correct values [reals]' );
is( ref($ret2), "", "  2nd element is a scalar" );
is( $ret2, "aa", "  - and it's value is okay" );

my $ret3;
($ret1,$ret2,$ret3) = array_multi();
isa_ok( $ret1, 'Array_Type' );
isa_ok( $ret2, 'Array_Type' );
isa_ok( $ret3, 'Array_Type' );

( $dims, $ndims, $atype ) = $ret1->array_info();
ok( $ndims == 2 && $$dims[0] == 2 && $$dims[1] == 3,
	"  1st element is an array [2D] with 2x3 elements" );
is( "$atype", "Integer_Type", "  and datatype Integer_Type" );
ok( eq_array($ret1->toPerl,[[3,4,-2],[3,9,0]]), "  array 1 okay" );

( $dims, $ndims, $atype ) = $ret2->array_info();
ok( $ndims == 1 && $$dims[0] == 2,
	"  2nd element is an array [1D] with 2 elements" );
is( "$atype", "Struct_Type", "  and datatype Struct_Type" );
isa_ok( $ret2->get(0), "Struct_Type" );
isa_ok( $ret2->get(1), "Struct_Type" );
ok( eq_array( [ keys %{$ret2->get(0)} ], [ "foo", "bar" ] ),
    "  keys of 1st struct okay" );
ok( $ret2->get(0)->{foo} == 1 && $ret2->get(0)->{bar} eq "x",
    "    as are the values" );
ok( eq_array( [ keys %{$ret2->get(1)} ], [ "baz" ] ),
    "  keys of 2nd struct okay" );
my $aref = $ret2->get(1)->{baz};
isa_ok( $aref, "Array_Type" );
( $dims, $ndims, $atype ) = $aref->array_info();
ok( $ndims == 1 && $$dims[0] == 3,
	"  2nd struct contains an array [1D] with 3 elements" );
is( "$atype", "Integer_Type", "  and datatype Integer_Type" );
ok( eq_array($aref->toPerl,[1,2,-4]), "    and values okay" );

##print Dumper($ret3), "\n";
isa_ok( $ret3, "Array_Type" );
( $dims, $ndims, $atype ) = $ret3->array_info();
ok( $ndims == 6 && eq_array( $dims, [4,1,1,1,1,1] ),
	"  3rd element is an array [6D] with 4x1x1x1x1x1 elements" );
is( "$atype", "String_Type", "  and datatype String_Type" );
ok( eq_array($ret3->toPerl,
    [[[[[["aa"]]]]],[[[[["q q"]]]]],[[[[["elo"]]]]],[[[[["bob"]]]]]]),
    "  and values are okay" );

__END__
__SLang__

%% convert S-Lang to perl

% integers
define arrayi2 () { return [2]; }
define arrayi35 () { return [3,5]; }

% force the data types into "uncommon" ones
define array_ui () {
  variable array = UInteger_Type [_NARGS];
  variable i;
  for ( i=_NARGS-1; i>=0; i-- ) { % note: reverse order
    variable var = ();
    array[i] = var;
  }
  return array;
}
define array_chars () { return ['a','b','c']; }
define array_longs () { return typecast([1e9,2.1e7,-4],Long_Type); }

% reals
define arrayr2_1 () { return [2.1]; }
define arrayr3_25_4 () { return [ 3.2, 5.4 ]; }

% strings
define arraystest1() { return [ "this is an array test" ]; }
define arraystest2() { return [ "", "this is an array test" ]; }

% complex numbers
define array_cplx () {
  variable a = Complex_Type [3];
  a[0] = 1 - 1i;
  a[1] = 2 + 3.5i;
  a[2] = -47.9 - 22.45i;
  return a;
}

define array_cplx2d () {
  variable a = Complex_Type [2,3];
  a[0,0] = 1 - 1i;
  a[0,1] = 2 + 3.5i;
  a[0,2] = -47.9 - 22.45i;
  a[1,0] = a[0,0] * 1i; % 1 + 1i
  a[1,1] = a[0,1] * 1i; % -3.5 + 2i
  a[1,2] = 3-4i; % ensure that we have completely different numbers
  return a;
}

% datatypes
define array_dtypes () {
  return [ Array_Type, UInt_Type, Float_Type, Assoc_Type, DataType_Type ];
}
define array_dtypes2d () {
  variable a = [ String_Type, Array_Type, UInt_Type, Float_Type, Assoc_Type, DataType_Type ];
  reshape( a, [3,2] );
  return a;
}

% mixed
define array_scalar() { return ( [-3,0,42.1], "aa" ); }

% Any_Type
define ret_anytype() {
  variable a = Any_Type [3];
  a[0] = 23.4;
  a[1] = [1,2,3];
  a[2] = Integer_Type;
  return a;
}

% return a 2D array
define array2Di() {
  variable a = [1,2,2,9,8,7];
  reshape(a,[2,3]);
  return a;
}

define array2Dr() {
  variable a = [1.1,2.2,2.3,9.4,8.5,7.6];
  reshape(a,[2,3]);
  return a;
}

define array2Ds() {
  variable a = ["aa","cc","x","1","this is a long string", "2"];
  reshape(a,[2,3]);
  return a;
}

% return a 3D array
define array3Di() {
  variable a = [1,2,2,9,8,7];
  reshape(a,[1,3,2]);
  return a;
}

define array_multi () {
  variable x = Int_Type [6];
  x = [3,4,-2,3,9,0];
  reshape(x,[2,3]);

  variable y = Struct_Type [2];
  y[0] = struct { foo, bar };
  y[1] = struct { baz };
  y[0].foo = 1;
  y[0].bar = "x";
  y[1].baz = [1,2,-4];

  variable z = String_Type [4];
  z = [ "aa", "q q", "elo", "bob" ];
  reshape(z,[4,1,1,1,1,1]);

  return x,y,z;
}

typedef struct { foo1, foo2 } FooFoo_Struct;
define ret_foofoo(n) {
  variable out = FooFoo_Struct [n];
  foreach ( [0:n-1] ) {
    variable i = ();
    out[i].foo1 = i;
    out[i].foo2 = i*100;
  }
  return out;
}

% some "simple" array cases
define ret_1elem(n) {
  variable out = [-2.4];
  reshape(out, [1:n]-[0:n-1]);
  return out;
}

%% Convert perl to S-Lang

define add2 (a) { return a+2; }

define sum_nelems () {
  variable sum = 0;
  foreach ( __pop_args(_NARGS) ) {
    variable arg = ();
    sum += length(arg.value);
  }
  return sum;
}

