# -*-perl-*-
#
# test conversion of S-Lang arrays to Perl using piddles
#

use strict;

use Inline 'SLang';

use constant NTESTS => 170;
use Test::More tests => NTESTS;

if ( Inline::SLang::sl_have_pdl() ) {
    is( Inline::SLang::sl_array2perl(), 2, "Default conversion is to piddles & array refs" );
} else {
    is( Inline::SLang::sl_array2perl(), 0, "Default conversion is to array refs" );
}

SKIP: {
    skip 'PDL support is not available', NTESTS-1
      unless Inline::SLang::sl_have_pdl();

    eval "use PDL;";

    ###
    ### tell Inline::SLang that we want to convert S-Lang arrays
    ### into piddles and non-numeric arrays into array references
    ### [we do change this setting later on]
    ###
    Inline::SLang::sl_array2perl(2);

    use Data::Dumper;

    ## Tests

    my ( $ret1, $ret2, $ret3, @ret );
    my ( $dims, $ndims, $atype );

    ## S-Lang 2 perl: Integers

    $ret1 = arrayi2();
    is( ref($ret1), 'PDL', 'array int returned piddle' );
    isa_ok( $ret1, 'PDL' );
    is( $ret1->ndims, 1, "Array is 1D" );
    is( $ret1->getdim(0), 1, "  with 1 element" );
    is( $ret1->type->symbol, "PDL_L", "  and Integer_Type converted to PDL_L" );
    is( $ret1->at(0), 2, "  and elem 0 contains 2" );

    ( $ret1, $ret2 ) = arrayi35();
    isa_ok( $ret1, 'PDL' );
    is( defined $ret2, '', ' and no second item' );
    is( $ret1->ndims, 1, "Array is 1D" );
    is( $ret1->getdim(0), 2, "  with 2 elements" );
    is( $ret1->type->symbol, "PDL_L", "  and Integer_Type converted to PDL_L" );
    is( $ret1->at(0), 3, "  and elem 0 contains 3" );
    is( $ret1->at(1), 5, "  and elem 1 contains 5" );

    ## S-Lang 2 perl: 'indexed' arrays

    $ret1 = array_index();
    ok( all( $ret1 == long(4,12,10,18) ), 'check of indexed array 1D' );
    $ret1 = array_index_x(0);
    ok( all( $ret1 == long(2,4,6) ), 'check of indexed array x[0]' );
    $ret1 = array_index_x(2);
    ok( all( $ret1 == long(14,16,18) ), 'check of indexed array x[2]' );
    $ret1 = array_index_y(1);
    ok( all( $ret1 == long(4,10,16) ), 'check of indexed array y[1]' );

    ## S-Lang 2 perl: "uncommon" types

    $ret1 = array_ui(2,5);
    isa_ok( $ret1, 'PDL' );
    is( $ret1->ndims, 1, "Array is 1D" );
    is( $ret1->getdim(0), 2, "  with 2 elements" );
    is( $ret1->type->symbol, "PDL_L", "  and UInteger_Type converted to PDL_L" );
    ok( all($ret1 == long(2,5)), "  and values okay" );

    $ret1 = array_chars();
    isa_ok( $ret1, 'PDL' );
    is( $ret1->ndims, 1, "Array is 1D" );
    is( $ret1->getdim(0), 3, "  with 3 elements" );
    is( $ret1->type->symbol, "PDL_B", "  and UChar_Type converted to PDL_B" );
    ok( all($ret1 == byte(97..99)), "  and values okay" );

##    my $ltype = Inline::SLang::sl_eval( "Long_Type" );

    $ret1 = array_longs();
    isa_ok( $ret1, 'PDL' );
    is( $ret1->ndims, 1, "Array is 1D" );
    is( $ret1->getdim(0), 3, "  with 3 elements" );
    is( $ret1->type->symbol, "PDL_L", "  and Long_Type converted to PDL_L" );
    ok( all($ret1 == long(1000000000,21000000,-4)), "  and values okay" );

    ## S-Lang 2 perl: Reals
    $ret1 = arrayr2_1();
    isa_ok( $ret1, 'PDL' );
    is( $ret1->ndims, 1, "Array is 1D" );
    is( $ret1->getdim(0), 1, "  with 1 element" );
    is( $ret1->type->symbol, "PDL_D", "  and Double_Type converted to PDL_D" );
    is( $ret1->at(0), 2.1, '  and values okay' );

    $ret1 = arrayr3_25_4();
    isa_ok( $ret1, 'PDL' );
    is( $ret1->ndims, 1, "Array is 1D" );
    is( $ret1->getdim(0), 2, "  with 2 elements" );
    is( $ret1->type->symbol, "PDL_D", "  and Double_Type converted to PDL_D" );
    ok( all($ret1 == double(3.2,5.4)), '  and values okay' );

    ## Let's test all the numeric types we can think of
    #
    # - need to make the tests portable across different architectures
    $ret1 = array_types("Char");
    is( $ret1->type->symbol, "PDL_B", "Char_Type -> PDL_B" );
    is( $ret1->at(0), 20, '  val==20' );
    $ret1 = array_types("UChar");
    is( $ret1->type->symbol, "PDL_B", "UChar_Type -> PDL_B" );
    is( $ret1->at(0), 20, '  val==20' );
    $ret1 = array_types("Short");
    is( $ret1->type->symbol, "PDL_S", "Short_Type -> PDL_S" );
    is( $ret1->at(0), 20, '  val==20' );
    $ret1 = array_types("UShort");
    is( $ret1->type->symbol, "PDL_US", "UShort_Type -> PDL_US" );
    is( $ret1->at(0), 20, '  val==20' );
    $ret1 = array_types("Int");
    is( $ret1->type->symbol, "PDL_L", "Int_Type -> PDL_L" );
    is( $ret1->at(0), 20, '  val==20' );
    $ret1 = array_types("UInt");
    is( $ret1->type->symbol, "PDL_L", "UInt_Type -> PDL_L" );
    is( $ret1->at(0), 20, '  val==20' );
    $ret1 = array_types("Long");
    is( $ret1->type->symbol, "PDL_L", "Long_Type -> PDL_L" );
    is( $ret1->at(0), 20, '  val==20' );
    $ret1 = array_types("ULong");
    is( $ret1->type->symbol, "PDL_L", "ULong_Type -> PDL_L" );
    is( $ret1->at(0), 20, '  val==20' );
    $ret1 = array_types("Float");
    is( $ret1->type->symbol, "PDL_F", "Float_Type -> PDL_F" );
    is( $ret1->at(0), 20, '  val==20'.0 );
    $ret1 = array_types("Double");
    is( $ret1->type->symbol, "PDL_D", "Double_Type -> PDL_D" );
    is( $ret1->at(0), 20, '  val==20'.0 );

    ## S-Lang 2 perl: Strings

    $ret1 = arraystest1();
    isa_ok( $ret1, 'ARRAY' );
    is( $$ret1[0], "this is an array test", 'array string [0] okay' );

    $ret1 = arraystest2();
    isa_ok( $ret1, 'ARRAY' );
    is( $#$ret1,   1,                       'array string okay' );
    is( $$ret1[0], "",                      'array string [0] == ""' );
    is( $$ret1[1], "this is an array test", 'array string [1] okay' );

    @ret = arraystest2();
    is( $#ret, 0, 'array stack check okay' );

    Inline::SLang::sl_array2perl( 3 );
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
    Inline::SLang::sl_array2perl( 2 );

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

    ## S-Lang 2 perl: Any_Type
    #
    # don't have a de-reference method so can't check the values
    $ret1 = ret_anytype();
    is( ref($ret1), "ARRAY", 'Any_Type array returned as an array' );
    is( $#$ret1, 2, "  with 3 elems" );
    ok( ref($$ret1[0]) && UNIVERSAL::isa($$ret1[0],"Any_Type"), "  and elem0 = Any_Type" );
    ok( ref($$ret1[1]) && UNIVERSAL::isa($$ret1[1],"Any_Type"), "  and elem1 = Any_Type" );
    ok( ref($$ret1[2]) && UNIVERSAL::isa($$ret1[2],"Any_Type"), "  and elem2 = Any_Type" );

    Inline::SLang::sl_array2perl( 3 );
    $ret1 = ret_anytype();
    isa_ok( $ret1, 'Array_Type' );
    ( $dims, $ndims, $atype ) = $ret1->array_info();
    ok( $ndims == 1 && $$dims[0] == 3, "Array is 1D with 3 elements" );
    is( "$atype", "Any_Type", "  and datatype Any_Type" );
    isa_ok( $ret1->get(0), "Any_Type" );
    isa_ok( $ret1->get(1), "Any_Type" );
    isa_ok( $ret1->get(2), "Any_Type" );
    Inline::SLang::sl_array2perl( 2 );

    ## try some > 1D arrays (have already tested some above)

    $ret1 = array2Di();
    ##print "2D integer array:\n" . Dumper($ret1) . "\n";
    isa_ok( $ret1, 'PDL' );
    is( $ret1->ndims, 2, "Array is 2D" );

    ok( $ret1->getdim(0) == 3 && $ret1->getdim(1) == 2, "  with 3x2 elements (flipped)" );

    is( $ret1->type->symbol, "PDL_L", "  and Integer_Type converted to PDL_L" );
    ok( all($ret1 == long([1,2,2],[9,8,7])), "  and contains the correct values [integers]" );

    $ret1 = array2Dr();
    ##print "2D real array:\n" . Dumper($ret1) . "\n";
    isa_ok( $ret1, 'PDL' );

    ok( $ret1->ndims == 2 && $ret1->getdim(0) == 3 && $ret1->getdim(1) == 2, "Array is 2D with 3x2 elements (flipped)" );

    is( $ret1->type->symbol, "PDL_D", "  and Double_Type converted to PDL_D" );

    ok( all($ret1 == double([1.1,2.2,2.3],[9.4,8.5,7.6])), "  and contains the correct values [reals]" );

    Inline::SLang::sl_array2perl(1);
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
    Inline::SLang::sl_array2perl(2);

    # 3D
    $ret1 = array3Di();
    ##print "3D integer array:\n" . Dumper($ret1) . "\n";
    isa_ok( $ret1, 'PDL' );

    ok( $ret1->ndims == 3 &&
	$ret1->getdim(0) == 2 && $ret1->getdim(1) == 3 &&
	$ret1->getdim(2) == 1, "Array is 3D with 2x3x1 elements (flipped)" );

    ok( all($ret1 == long([[[1,2],[2,9],[8,7]]])), "  and contains the correct values [integers]" );

    ## multi-dimensional but only containing 1 element
    # - these tests aren't as useful as they first look since
    #     sum(double([[[-2.4]]]) == double(-2.4))
    #
    $ret1 = ret_1elem(1);
    ok( $ret1->ndims == 1 &&
	$ret1->getdim(0) == 1, "Array is 1D with 1 element" );
    ok( all($ret1 == double(-2.4)), "  and contains the correct value" );

    $ret1 = ret_1elem(2);
    ok( $ret1->ndims == 2 && $ret1->getdim(0) == 1 &&
	$ret1->getdim(1) == 1, "Array is 2D with 1x1 elements" );
    ok( all($ret1 == double([-2.4])), "  and contains the correct value" );

    $ret1 = ret_1elem(3);
    ok( $ret1->ndims == 3 && $ret1->getdim(0) == 1 && $ret1->getdim(1) == 1 &&
	$ret1->getdim(2) == 1, "Array is 3D with 1x1x1 elements" );
    ok( all($ret1 == double([[-2.4]])), "  and contains the correct value" );

    $ret1 = ret_1elem(4);
    ok( $ret1->ndims == 4 && $ret1->getdim(0) == 1 && $ret1->getdim(1) == 1 &&
	$ret1->getdim(2) == 1 && $ret1->getdim(3) == 1, "Array is 4D with 1x1x1x1 elements" );
    ok( all($ret1 == double([[[-2.4]]])), "  and contains the correct value" );

    $ret1 = ret_1elem(5);
    ok( $ret1->ndims == 5 && $ret1->getdim(0) == 1 && $ret1->getdim(1) == 1 &&
	$ret1->getdim(2) == 1 && $ret1->getdim(3) == 1 && $ret1->getdim(4) == 1,
	"Array is 5D with 1x1x1x1x1 elements" );
    ok( all($ret1 == double([[[[-2.4]]]])), "  and contains the correct value" );

    $ret1 = ret_1elem(6);
    ok( $ret1->ndims == 6 && $ret1->getdim(0) == 1 && $ret1->getdim(1) == 1 &&
	$ret1->getdim(2) == 1 && $ret1->getdim(3) == 1 && $ret1->getdim(4) == 1 &&
	$ret1->getdim(5) == 1, "Array is 6D with 1x1x1x1x1x1 elements" );
    ok( all($ret1 == double([[[[[-2.4]]]]])), "  and contains the correct value" );

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

    Inline::SLang::sl_array2perl(3);
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
    Inline::SLang::sl_array2perl(2);

    ## Check out some stack handling

    ( $ret1, $ret2 ) = array_scalar();
    is( ref($ret1), "PDL", 'mixed types: returned a piddle' );
    is( ref($ret2), "",    '             returned a scalar' );
    ok( all($ret1 == double(-3,0,42.1)), '             mixed types: array okay' );
    is( $ret2,      "aa",    '             scalar okay' );

    ($ret1,$ret2,$ret3) = array_multi();
    is( ref($ret1), "PDL", 'stack handling: returned an array ref 1' );
    is( ref($ret2), "ARRAY", 'stack handling: returned an array ref 2' );
    is( ref($ret3), "ARRAY", 'stack handling: returned an array ref 3' );
    ok( all($ret1 == long([3,4,-2],[3,9,0])), "  array 1 okay" );
    is( $#$ret2, 1, "  array 2 has 2 elements" );
    ok( ref($$ret2[0]) && UNIVERSAL::isa($$ret2[0],"Struct_Type"), "  contents=Struct_Type" );
    ok( $$ret2[0]{foo} == 1 && $$ret2[0]{bar} eq "x", "    first struct okay" );
    isa_ok( $$ret2[1]{baz}, 'PDL' );
    ok( all($$ret2[1]{baz} == long(1,2,-4)), "    second struct okay" );
    ##print Dumper($ret3), "\n";
    ok( eq_array($ret3,
		 [[[[[["aa"]]]]],[[[[["q q"]]]]],[[[[["elo"]]]]],[[[[["bob"]]]]]]),
	"  and third array okay" );

    Inline::SLang::sl_array2perl(3);
    ( $ret1, $ret2 ) = array_scalar();
    is( ref($ret1), "PDL", 'mixed types: returned a piddle' );
    ok( all($ret1 == double(-3,0,42.1)), '             mixed types: array okay' );
    is( ref($ret2), "", "  2nd element is a scalar" );
    is( $ret2, "aa", "  - and it's value is okay" );

    ($ret1,$ret2,$ret3) = array_multi();
    isa_ok( $ret1, "PDL" );
    isa_ok( $ret2, 'Array_Type' );
    isa_ok( $ret3, 'Array_Type' );

    ok( all($ret1 == long([3,4,-2],[3,9,0])), "  array 1 okay" );

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
    isa_ok( $ret2->get(1)->{baz}, 'PDL' );
    ok( all($ret2->get(1)->{baz} == long(1,2,-4)), "    second struct okay" );
    ##print Dumper($ret3), "\n";
    isa_ok( $ret3, "Array_Type" );
    ( $dims, $ndims, $atype ) = $ret3->array_info();
    ok( $ndims == 6 && eq_array( $dims, [4,1,1,1,1,1] ),
	"  3rd element is an array [6D] with 4x1x1x1x1x1 elements" );
    is( "$atype", "String_Type", "  and datatype String_Type" );
    ok( eq_array($ret3->toPerl,
		 [[[[[["aa"]]]]],[[[[["q q"]]]]],[[[[["elo"]]]]],[[[[["bob"]]]]]]),
	"  and values are okay" );
    Inline::SLang::sl_array2perl(2);

} # SKIP

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

% 'any' numeric type
define array_types(in) {
  eval( "$1=typecast([20]," + in + "_Type);");
  return $1;
}

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


