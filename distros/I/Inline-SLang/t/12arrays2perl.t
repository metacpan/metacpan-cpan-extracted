#
# test conversion of S-Lang arrays to Perl
#
# many of these tests shouldn't be direct equality
# since it's floating point
#

use strict;

use Test::More tests => 101;

use Inline 'SLang';

###
### tell Inline::SLang that we want to convert S-Lang arrays
### into Perl array references
###
Inline::SLang::sl_array2perl( 0 );

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

## S-Lang 2 perl: Integers

$ret1 = arrayi2();
is( ref($ret1), 'ARRAY', 'array int returned an array reference' );
is( $#$ret1, 0,          '                   1 item' );
is( $$ret1[0], 2,        '                   == 2' );

( $ret1, $ret2 ) = arrayi35();
is( $#$ret1, 1,        'array int returned 2 items' );
is( $$ret1[0], 3,      '                   [0] == 3' );
is( $$ret1[1], 5,      '                   [0] == 5' );
is( defined $ret2, '', '                   and no second item' );

## S-Lang 2 perl: 'indexed' arrays

$ret1 = array_index();
ok( eq_array( $ret1, [4,12,10,18] ), 'check of indexed array 1D' );
$ret1 = array_index_x(0);
ok( eq_array( $ret1, [2,4,6] ), 'check of indexed array x[0]' );
$ret1 = array_index_x(2);
ok( eq_array( $ret1, [14,16,18] ), 'check of indexed array x[2]' );
$ret1 = array_index_y(1);
ok( eq_array( $ret1, [4,10,16] ), 'check of indexed array y[1]' );

## S-Lang 2 perl: "uncommon" types

$ret1 = array_ui(2,5);
ok( eq_array( $ret1, [2,5] ), 'UInteger_Type converted to perl arrays' );
$ret1 = array_chars();
print "UChar_Type [97..99] == ", Dumper($ret1), "\n";
ok( eq_array( $ret1, [97..99] ), 'UChar_Type converted to perl arrays' );
$ret1 = array_longs();
ok( eq_array( $ret1, [1000000000,21000000,-4] ), 'Long_Type converted to perl arrays' );

## S-Lang 2 perl: Reals
$ret1 = arrayr2_1();
approx( $$ret1[0], 2.1, 'array real [0] 2.1' );

$ret1 = arrayr3_25_4();
approx( $#$ret1, 1,     'array real returned 2 items' );
approx( $$ret1[0], 3.2, 'array real [0] == 3.2' );
approx( $$ret1[1], 5.4, 'array real [1] == 5.4' );

## S-Lang 2 perl: Strings

$ret1 = arraystest1();
is( $$ret1[0], "this is an array test", 'array string [0] okay' );

$ret1 = arraystest2();
is( $#$ret1,   1,                       'array string okay' );
is( $$ret1[0], "",                      'array string [0] == ""' );
is( $$ret1[1], "this is an array test", 'array string [1] okay' );

@ret = arraystest2();
is( $#ret, 0, 'array stack check okay' );

## S-Lang 2 perl: complex numbers

$ret1 = array_cplx();
is( ref($ret1), "ARRAY", "1D array of complex returned as an array reference" );
is( $#$ret1, 2, "and contains 3 elements" );
isa_ok( $$ret1[0], "Math::Complex" );
isa_ok( $$ret1[1], "Math::Complex" );
isa_ok( $$ret1[2], "Math::Complex" );
is( "$$ret1[0]", "1-i",          "  elem 0 = 1-i" );
is( "$$ret1[1]", "2+3.5i",       "  elem 1 = 2+3.5i" );
is( "$$ret1[2]", "-47.9-22.45i", "  elem 2 = -47.9-22.45i" );

$ret1 = array_cplx2d();
##print Dumper($ret1), "\n";
is( ref($ret1), "ARRAY", "2D array of complex returned as an array reference" );
is( $#$ret1, 1, "and nx = 2" );
is( $#{$$ret1[0]}, 2, "and ny = 3" );

isa_ok( $$ret1[0][0], "Math::Complex" );
isa_ok( $$ret1[0][2], "Math::Complex" );
isa_ok( $$ret1[1][2], "Math::Complex" );

# stringify the values as an easy way to check the values
is( "$$ret1[0][0] $$ret1[0][1] $$ret1[0][2]",
    "1-i 2+3.5i -47.9-22.45i",
    "  ans[0,*] is correct (3 complex numbers)" );
is( "$$ret1[1][0] $$ret1[1][1] $$ret1[1][2]",
    "1+i -3.5+2i 3-4i",
    "  ans[1,*] is correct (3 complex numbers)" );

## S-Lang 2 perl: datatypes

$ret1 = array_dtypes();
is( ref($ret1), "ARRAY", "1D array of DataType_Type's returned as an array reference" );
is( $#$ret1, 4, "and contains 5 elements" );
isa_ok( $$ret1[0], "DataType_Type" );
isa_ok( $$ret1[1], "DataType_Type" );
isa_ok( $$ret1[2], "DataType_Type" );
isa_ok( $$ret1[3], "DataType_Type" );
isa_ok( $$ret1[4], "DataType_Type" );
is( join(" ",map { "$_" } @$ret1), "Array_Type UInteger_Type Float_Type Assoc_Type DataType_Type",
	"The datatypes are converted correctly" );

$ret1 = array_dtypes2d();
##print Dumper($ret1), "\n";
is( ref($ret1), "ARRAY", "2D array of data ypes returned as an array reference" );
is( $#$ret1, 2, "and nx = 3" );
is( $#{$$ret1[0]}, 1, "and ny = 2" );

isa_ok( $$ret1[0][0], "DataType_Type" );
isa_ok( $$ret1[0][1], "DataType_Type" );
isa_ok( $$ret1[1][0], "DataType_Type" );
isa_ok( $$ret1[2][1], "DataType_Type" );

# stringify the values as an easy way to check the values
is( "$$ret1[0][0] $$ret1[0][1]",
    "String_Type Array_Type",
    "  ans[0,*] is correct (2 datatypes)" );
is( "$$ret1[1][0] $$ret1[1][1]",
    "UInteger_Type Float_Type",
    "  ans[1,*] is correct (2 datatypes)" );
is( "$$ret1[2][0] $$ret1[2][1]",
    "Assoc_Type DataType_Type",
    "  ans[2,*] is correct (2 datatypes)" );

## S-Lang 2 perl: Any_Type
#
# don't have a de-reference method so can't check the values
$ret1 = ret_anytype();
is( ref($ret1), "ARRAY", 'Any_Type array returned as an array' );
is( $#$ret1, 2, "  with 3 elems" );
ok( ref($$ret1[0]) && UNIVERSAL::isa($$ret1[0],"Any_Type"), "  and elem0 = Any_Type" );
ok( ref($$ret1[1]) && UNIVERSAL::isa($$ret1[1],"Any_Type"), "  and elem1 = Any_Type" );
ok( ref($$ret1[2]) && UNIVERSAL::isa($$ret1[2],"Any_Type"), "  and elem2 = Any_Type" );

## try some > 1D arrays

$ret1 = array2Di();
print "2D integer array:\n" . Dumper($ret1) . "\n";
is( ref($ret1), "ARRAY", '2D: returned an array reference' );
ok( eq_array( $ret1, [[1,2,2],[9,8,7]] ),
                         '    and contains the correct values [integers]' );

$ret1 = array2Dr();
print "2D real array:\n" . Dumper($ret1) . "\n";
is( ref($ret1), "ARRAY", '2D: returned an array reference' );
ok( eq_array( $ret1, [[1.1,2.2,2.3],[9.4,8.5,7.6]] ),
                         '    and contains the correct values [reals]' );

$ret1 = array2Ds();
print "2D string array:\n" . Dumper($ret1) . "\n";
is( ref($ret1), "ARRAY", '2D: returned an array reference' );
ok( eq_array( $ret1,
	    [['aa',"cc","x"], ['1','this is a long string', "2"]] ),
                         '    and contains the correct values [strings]' );

# 3D
$ret1 = array3Di();
print "3D integer array:\n" . Dumper($ret1) . "\n";
is( ref($ret1), "ARRAY", '3D: returned an array reference' );
ok( eq_array( $ret1, [[[1,2],[2,9],[8,7]]] ),
                         '    and contains the correct values [integers]' );

## multi-dimensional but only containing 1 element
$ret1 = ret_1elem(1);
is( ref($ret1), "ARRAY", "1D - 1 element returned an array reference" );
is( $$ret1[0], -2.4,     "     and contents okay" );
$ret1 = ret_1elem(2);
is( ref($ret1), "ARRAY", "2D - 1 element returned an array reference" );
is( $$ret1[0][0], -2.4,     "     and contents okay" );
$ret1 = ret_1elem(3);
is( ref($ret1), "ARRAY", "3D - 1 element returned an array reference" );
is( $$ret1[0][0][0], -2.4,     "     and contents okay" );
$ret1 = ret_1elem(4);
is( ref($ret1), "ARRAY", "4D - 1 element returned an array reference" );
is( $$ret1[0][0][0][0], -2.4,     "     and contents okay" );
$ret1 = ret_1elem(5);
is( ref($ret1), "ARRAY", "5D - 1 element returned an array reference" );
is( $$ret1[0][0][0][0][0], -2.4,     "     and contents okay" );
$ret1 = ret_1elem(6);
is( ref($ret1), "ARRAY", "6D - 1 element returned an array reference" );
is( $$ret1[0][0][0][0][0][0], -2.4,     "     and contents okay" );

# seems to be some complication when using 7D arrays
# - which appears to be a bug in S-Lang v1.4.9 and earlier
#$ret1 = ret_1elem(7);
#is( ref($ret1), "ARRAY", "7D - 1 element returned an array reference" );
#is( $$ret1[0][0][0][0][0][0][0], -2.4,     "     and contents okay" );

## arrays of a named struct
$ret1 = ret_foofoo(2);
is( ref($ret1), "ARRAY", 'arrays of FooFoo_Struct as an array' );
is( $#$ret1, 1, '  2 elem' );
ok( $$ret1[0]->typeof eq Inline::SLang::FooFoo_Struct() &&
    $$ret1[1]->typeof == Inline::SLang::FooFoo_Struct() , "  both FooFoo_Struct's" );
ok( $$ret1[0]{foo1} == 0 && $$ret1[0]{foo2} == 0 &&
    $$ret1[1]{foo1} == 1 && $$ret1[1]{foo2} == 100,
    "  and values okay" );

## Check out some stack handling

( $ret1, $ret2 ) = array_scalar();
is( ref($ret1), "ARRAY", 'mixed types: returned an array' );
is( ref($ret2), "",      '             returned a scalar' );
approx( $$ret1[0],  -3.0,    '             mixed types: array [0] okay' );
approx( $$ret1[1],   0.0,    '             mixed types: array [1] okay' );
approx( $$ret1[2],  42.1,    '             mixed types: array [2] okay' );
is( $ret2,      "aa",    '             scalar okay' );

my $ret3;
($ret1,$ret2,$ret3) = array_multi();
is( ref($ret1), "ARRAY", 'stack handling: returned an array ref 1' );
is( ref($ret2), "ARRAY", 'stack handling: returned an array ref 2' );
is( ref($ret3), "ARRAY", 'stack handling: returned an array ref 3' );
ok( eq_array($ret1,[[3,4,-2],[3,9,0]]), "  array 1 okay" );
is( $#$ret2, 1, "  array 2 has 2 elements" );
ok( ref($$ret2[0]) && UNIVERSAL::isa($$ret2[0],"Struct_Type"), "  contents=Struct_Type" );
ok( $$ret2[0]{foo} == 1 && $$ret2[0]{bar} eq "x", "    first struct okay" );
ok( eq_array($$ret2[1]{baz},[1,2,-4]), "    second struct okay" );
print Dumper($ret3), "\n";
ok( eq_array($ret3,
    [[[[[["aa"]]]]],[[[[["q q"]]]]],[[[[["elo"]]]]],[[[[["bob"]]]]]]),
    "  and third array okay" );

__END__
__SLang__

%% convert S-Lang to perl

% integers
define arrayi2 () { return [2]; }
define arrayi35 () { return [3,5]; }

% check we can handle "indexed" arrays
%
private variable long_array1D = [1:9] * 2;
private variable long_array2D = _reshape( long_array1D, [3,3] );
define array_index ()    { return long_array1D[[1,5,4,8]]; }
define array_index_x (x) { return long_array2D[x,*]; }
define array_index_y (y) { return long_array2D[*,y]; }

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

