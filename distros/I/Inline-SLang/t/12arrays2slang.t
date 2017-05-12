#
# test conversion of Perl arrays to S-Lang
#
# many of these tests shouldn't be direct equality
# since it's floating point
#

use strict;

use Test::More tests => 136;

# we implicitly test support for !types here
use Inline 'SLang' => Config => EXPORT => [ qw( sl_array !types ) ];
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

my ( $ret1, $ret2, $ret3, $ret4, @ret );

## test Array_Type object
$ret1 = Array_Type->new( "Int_Type", [3] );
ok( defined $ret1, "Array_Type->new returned something" );
isa_ok( $ret1, "Inline::SLang::_Type" );
isa_ok( $ret1, "Array_Type" );

ok( !$ret1->is_struct_type, "And it's not a struct!" );

$ret2 = $ret1->typeof();
isa_ok( $ret2, "DataType_Type" );
is( "$ret2", "Array_Type", "typeof() returned Array_Type" );

$ret2 = $ret1->_typeof();
isa_ok( $ret2, "DataType_Type" );
is( "$ret2", "Integer_Type", "_typeof() returned Integer_Type" );

( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( ref($ret2), "ARRAY", "array_info() returns dim array as a Perl array ref" );
is( $ret3, 1, "  and reports ndims=1" );
is( $$ret2[0], 3, "  and nelem=3" );
isa_ok( $ret4, "DataType_Type" );
is( "$ret4", "Integer_Type", "  and the type is Integer_Type" );

# check that changing $ret2 doesn't change the object
$$ret2[0] = 23;
( $ret3 ) = $ret1->array_info();
is( $$ret3[0], 3, "dim array returned by array_info() is a copy of internal structure" );

ok( !defined $ret1->get(0) &&
    !defined $ret1->get(1) &&
    !defined $ret1->get(2), "elem0,1,2 = undef" );
is( $ret1->set(1,23), 23, "set(1,23) returned 23" );
ok( $ret1->get(1) == 23 && !defined $ret1->get(0) && !defined $ret1->get(2),
    "  and it set elem 1, leaving 0,2 alone" );
$ret1->set(0,1);
$ret1->set(2,-5);

# set() uses the same code so we don't need to test that too
ok( $ret1->get(-3) == 1 && $ret1->get(-2) == 23 && $ret1->get(-1) == -5,
    "Can use get() with negative indices" );
$ret1->set(-1, -10);

# check get/set when sent invalid arguments
eval { $ret1->get(5); };
like( $@, qr/^Error: coord #0 of get\(\) call \(val=5\) lies outside valid range of -3:2/,
	"Can not access invalid element (>=nelem)" );
eval { $ret1->get(-4); };
like( $@, qr/^Error: coord #0 of get\(\) call \(val=-4\) lies outside valid range of -3:2/,
	"Can not access invalid element (<-nelem)" );
eval { $ret1->get(1,2,3); };
like( $@, qr/^Error: get\(\) called with 3 coordinates but array dimensionality is 1/,
	"Can not access invalid element (3-dimensional coordinate)" );

# can we send this to S-Lang?
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,Integer_Type(),1,3), 1,
    "  and it seems to have the correct info" );
ok( check_array1d($ret1), "  and the right values" );

# note: $ret2 actually points to the storage area used by the obect,
#  so if you change it the object changes but without knowing about it
#  - so changing the array size is BAD
#
$ret2 = $ret1->toPerl();
is( ref($ret2), "ARRAY", "toPerl() returned an array reference" );
ok( eq_array( $ret2, [1,23,-10] ), "  with the correct values" );
$$ret2[1] = 4;
ok( $ret1->get(0) == 1 && $ret1->get(1) == 4 && $ret1->get(2) == -10,
    "  and can change the data stored in the object [scary]" ); 

# check persistence of $foo->toPerl return value after object is deleted
undef $ret1;
#print "Does array reference exist beyond object destruction: ", 
#   Dumper($ret2), "\n";
ok( ref($ret2) eq "ARRAY" && eq_array( $ret2, [1,4,-10] ),
    "  and it persists past the destruction of the object" );

## Now a 2D array

$ret1 = Array_Type->new( "Float_Type", [2,3] );
isa_ok( $ret1, "Array_Type" );

( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( $ret3, 2, "2D array is 2D" );
ok( eq_array( $ret2, [2,3] ), "  and is 2x3" );
is( "$ret4", "Float_Type", "  and the type is Float_Type" );

$ret1->set(0,0,0); $ret1->set(1,0,10);
$ret1->set(0,1,1); $ret1->set(1,1,11);
$ret1->set(0,2,2); $ret1->set(1,2,12);
ok( $ret1->get(0,2) == 2 && $ret1->get(1,2) == 12, "Some simple sets/gets work" );

# check get/set when sent invalid arguments
eval { $ret1->get(0,5); };
like( $@, qr/^Error: coord #1 of get\(\) call \(val=5\) lies outside valid range of -3:2/,
	"Can not access invalid element (>=nelem)" );
eval { $ret1->get(-4,1); };
like( $@, qr/^Error: coord #0 of get\(\) call \(val=-4\) lies outside valid range of -2:1/,
	"Can not access invalid element (<-nelem)" );
eval { $ret1->get(5); };
like( $@, qr/^Error: get\(\) called with 1 coordinates but array dimensionality is 2/,
	"Can not access invalid element (1-dimensional coordinate)" );

# can we send this to S-Lang?
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,Float_Type(),2,2,3), 1,
    "  [2D] and it seems to have the correct info" );
ok( check_array2d($ret1), "  [2D] and the right values" );

## Now a 0D array

$ret1 = Array_Type->new( "String_Type", [] );
isa_ok( $ret1, "Array_Type" );

( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( $ret3, 0, "0D array is 0D" );
is( $#$ret2, -1, "  and has no size" );
is( "$ret4", "String_Type", "  and the type is String_Type" );

# check get/set when sent invalid arguments
eval { $ret1->get(0); };
like( $@, qr/^Error: get\(\) called with 1 coordinates but array dimensionality is 0/,
	"Can not access any element (since there isn't one)" );

# can we send this to S-Lang?
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,String_Type(),0), 1,
    "  [OD] and it seems to have the correct info" );

## Now a 3D array

$ret1 = Array_Type->new( "Short_Type", [1,3,2] );
isa_ok( $ret1, "Array_Type" );
( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( $ret3, 3, "3D array is 3D" );
ok( eq_array( $ret2, [1,3,2] ), "  and is 1x3x2" );
is( "$ret4", "Short_Type", "  and the type is Short_Type" );

$ret1->set(0,0,0,1); $ret1->set(0,0,1,2);
$ret1->set(0,1,0,10); $ret1->set(0,1,1,11);
$ret1->set(0,2,0,20); $ret1->set(0,2,1,21);
ok( $ret1->get(0,1,0) == 10 && $ret1->get(0,2,1) == 21, "Some simple sets/gets work" );

# can we send this to S-Lang?
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,Short_Type(),3,1,3,2), 1,
    "  [3D] and it seems to have the correct info" );
ok( check_array3d($ret1), "  [3D] and the right values" );

## 4D array - 1 elem along each dimension

$ret1 = Array_Type->new( "Double_Type", [1,1,1,1] );
isa_ok( $ret1, "Array_Type" );
( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( $ret3, 4, "4D array is 4D" );
ok( eq_array( $ret2, [1,1,1,1] ), "  and is 1x1x1x1" );
is( "$ret4", "Double_Type", "  and the type is Double_Type" );

$ret1->set(0,0,0,0,-23.2);
ok( $ret1->get(0,0,0,0) == -23.2, "Some simple sets/gets work" );

# can we send this to S-Lang?
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,Short_Type(),4,1,1,1,1), 1,
    "  [4D] and it seems to have the correct info" );
ok( check_array4d($ret1), "  [4D] and the right values" );

## see if we trash the stack
$ret2 = Array_Type->new( "DataType_Type", [2] );
# note: could probably - with current internals - get away with
#  sending in strings, but not sure I want to rely on this behaviour
$ret2->set(0,Complex_Type());
$ret2->set(1,UShort_Type());
ok( isa_array($ret2), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret2,DataType_Type(),1,2), 1,
    "  [datatype array] and it seems to have the correct info" );
ok( check_array1d_dt($ret2), "  [datatype array] and the right values" );

$ret1 = Struct_Type();
$ret3 = Assoc_Type();
ok( check_multi($ret1,$ret2,$ret3), "Stack seems okay" );

# as an array reference -- ie not an Array_Type object
#
# 1) all integers
$ret1 = [ -9, 4, 23 ];
ok( isa_array($ret1), "Can convert an array ref to a S-Lang array: Int_Type 1D" );
is( check_array($ret1,Integer_Type(),1,3), 1,
    "  and it seems to have the correct info" );
ok( check_arrayref_int1d($ret1), "  and the right values" );

# 2) all floats
$ret1 = [ -9.0, 4.0, 23.0 ];
ok( isa_array($ret1), "Can convert an array ref to a S-Lang array: Double_Type 1D" );
is( check_array($ret1,Double_Type(),1,3), 1,
    "  and it seems to have the correct info" );
ok( check_arrayref_dbl1d($ret1), "  and the right values" );

# 3) all strings
$ret1 = [ "-9.0", "4.0", "23.0" ];
ok( isa_array($ret1), "Can convert an array ref to a S-Lang array: String_Type 1D" );
is( check_array($ret1,String_Type(),1,3), 1,
    "  and it seems to have the correct info" );
ok( check_arrayref_str1d($ret1), "  and the right values" );

# 3) all complex number
$ret1 = [ Math::Complex->make(4,-2.4), Math::Complex->make(-2.4,4) ];
ok( isa_array($ret1), "Can convert an array ref to a S-Lang array: Complex_Type 1D" );
is( check_array($ret1,Complex_Type(),1,2), 1,
    "  and it seems to have the correct info" );
ok( check_arrayref_cpl1d($ret1), "  and the right values" );

# 4) 2D integers (2x2)
$ret1 = [ [ 0, 1 ], [4, 3 ] ];
ok( isa_array($ret1), "Can convert an array ref to a S-Lang array: Int_Type 2D" );
is( check_array($ret1,Integer_Type(),2,2,2), 1,
    "  and it seems to have the correct info" );
ok( check_arrayref_int2d($ret1), "  and the right values" );

# 5) 2D floats (2x3)
$ret1 = [ [-4.0,73], [ 0, 1 ], [4, 3 ] ];
ok( isa_array($ret1), "Can convert an array ref to a S-Lang array: Double_Type 2D" );
is( check_array($ret1,Double_Type(),2,3,2), 1,
    "  and it seems to have the correct info" );
ok( check_arrayref_dbl2d($ret1), "  and the right values" );

# 6) 6D int's (1x1x1x1x1x1)
$ret1 = [ [ [ [ [ [ 24 ] ] ] ] ] ];
ok( isa_array($ret1), "Can convert an array ref to a S-Lang array: Int_Type 6D" );
is( check_array($ret1,Integer_Type(),6,1,1,1,1,1,1), 1,
    "  and it seems to have the correct info" );
ok( check_arrayref_int6d($ret1), "  and the right values" );

# TODO doesn't seem to be understood properly by my test alpha
# machine running perl5.6.0 and some set of Test modules
#

=begin SOMEWAYOFF

TODO: {
	todo_skip "need clever type-checking of array refs", 3;

	$ret1 = [-9,"foo",23.0,Math::Complex->new(4,-3),Struct_Type()];
	ok( isa_array($ret1), "Can convert an array ref to a S-Lang array" );
	print "Array reference: ", Dumper($ret1), "\n";
	is( check_array($ret1,Any_Type(),1,5), 1,
	    "  and it seems to have the correct info" );
	ok( check_arrayref_any1d($ret1), "  and the right values" );
}

=end SOMEWAYOFF

=cut

# stack checks when sent array references
# - note: use simple arrays only for now
$ret1 = Inline::SLang::sl_array( [1.1,2.2,-43.2], [3], "Double_Type" );
$ret2 = [ "a string", "another one", "fooble" ];
$ret3 = [ [ 0, 1 ], [4, 3 ] ];
ok( check_multiref($ret1,$ret2,$ret3), "Stack seems okay with array references" );

# check Array_Type constructor being sent actual data
#
my $aref = [ [-49.0], [23.2], [1.0e47] ];
$ret1 = Array_Type->new( "Double_Type", [3,1], $aref );
isa_ok( $ret1, "Array_Type" );
( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( $ret3, 2, "2D array is 2D" );
ok( eq_array( $ret2, [3,1] ), "  and is 3x1" );
is( "$ret4", "Double_Type", "  and the type is Double_Type" );

ok( $ret1->get(0,0) == -49.0 &&
    $ret1->get(1,0) == 23.2 &&
    $ret1->get(2,0) == 1.0e47,
    "Some simple gets work" );

# can we send this to S-Lang?
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,Double_Type(),2,3,1), 1,
    "  [2D] and it seems to have the correct info" );
ok( check_array2d_b($ret1), "  [2D] and the right values" );

### check the sl_array() constructor
# [it's just a wrapper around the Array_Type constructor]
#
# basically the same test but with different values sent to the
# function
#
print "--- Checking Inline::SLang::sl_array\n";
$ret1 = undef;
$ret1 = Inline::SLang::sl_array( $aref, [3,1], "Double_Type" );
isa_ok( $ret1, "Array_Type" );
( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( $ret3, 2, "2D array is 2D" );
ok( eq_array( $ret2, [3,1] ), "  and is 3x1" );
is( "$ret4", "Double_Type", "  and the type is Double_Type" );
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,Double_Type(),2,3,1), 1,
    "  [2D] and it seems to have the correct info" );
ok( check_array2d_b($ret1), "  [2D] and the right values" );

print "--- Checking sl_array (ie can we export it to main)\n";
$ret1 = undef;
$ret1 = sl_array( $aref, [3,1], "Double_Type" );
isa_ok( $ret1, "Array_Type" );
( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( $ret3, 2, "2D array is 2D" );
ok( eq_array( $ret2, [3,1] ), "  and is 3x1" );
is( "$ret4", "Double_Type", "  and the type is Double_Type" );
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,Double_Type(),2,3,1), 1,
    "  [2D] and it seems to have the correct info" );
ok( check_array2d_b($ret1), "  [2D] and the right values" );

print "--- Checking sl_array - can it guess array dims\n";
$ret1 = undef;
$ret1 = sl_array( $aref, "Double_Type" );
isa_ok( $ret1, "Array_Type" );
( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( $ret3, 2, "2D array is 2D" );
ok( eq_array( $ret2, [3,1] ), "  and is 3x1" );
is( "$ret4", "Double_Type", "  and the type is Double_Type" );
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,Double_Type(),2,3,1), 1,
    "  [2D] and it seems to have the correct info" );
ok( check_array2d_b($ret1), "  [2D] and the right values" );

print "--- Checking sl_array - can it guess array type\n";
$ret1 = undef;
$ret1 = sl_array( $aref, [3,1] );
isa_ok( $ret1, "Array_Type" );
( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( $ret3, 2, "2D array is 2D" );
ok( eq_array( $ret2, [3,1] ), "  and is 3x1" );
is( "$ret4", "Double_Type", "  and the type is Double_Type" );
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,Double_Type(),2,3,1), 1,
    "  [2D] and it seems to have the correct info" );
ok( check_array2d_b($ret1), "  [2D] and the right values" );

print "--- Checking sl_array - can it guess everything\n";
$ret1 = undef;
$ret1 = sl_array( $aref );
isa_ok( $ret1, "Array_Type" );
( $ret2, $ret3, $ret4 ) = $ret1->array_info();
is( $ret3, 2, "2D array is 2D" );
ok( eq_array( $ret2, [3,1] ), "  and is 3x1" );
is( "$ret4", "Double_Type", "  and the type is Double_Type" );
ok( isa_array($ret1), "Can convert Array_Type to a S-Lang array" );
is( check_array($ret1,Double_Type(),2,3,1), 1,
    "  [2D] and it seems to have the correct info" );
ok( check_array2d_b($ret1), "  [2D] and the right values" );


# and now some random checks
is( sumup_nelems( [0], ["a", "b"], [3.4, 5.6, 9.4, 55] ),
    7, "able to add up 1D elements" );
is( sumup_nelems( [0],
                  sl_array( [["a","b"],["cc","d"]], [2,2], "String_Type" ),
                  [3.4, 5.6, 9.4, 55] ),
    9, "able to add up 1D + 2D elements [sl_array full]" );
is( sumup_nelems( [0],
                  sl_array( [["a","b"],["cc","d"]], [2,2] ),
                  [3.4, 5.6, 9.4, 55] ),
    9, "able to add up 1D + 2D elements [sl_array no type]" );
is( sumup_nelems( [0],
                  sl_array( [["a","b"],["cc","d"]] ),
                  [3.4, 5.6, 9.4, 55] ),
    9, "able to add up 1D + 2D elements [sl_array no type/dims]" );
is( sumup_nelems( [0], [ ["a", "b"], ["cc", "d"] ], [3.4, 5.6, 9.4, 55] ),
    9, "able to add up 1D + 2D elements [array ref]" );

__END__
__SLang__

define debug (x) { }
define debug (x) { vmessage( "@@@ dbg: %S", x ); }

%
% As of version 0.26 of Inline::SLang we guarantee that
% sum is part of the S-Lang tun-time library
%
define all(x) { return sum(typecast(x,Int_Type)!=0) == length(x); }
define any(x) { return sum(typecast(x,Int_Type)!=0) != 0; }

%% Convert perl to S-Lang

define isa_array(a) { return typeof(a) == Array_Type; }

define check_array() {
  variable a, itype, ndims, size;
  _stk_reverse(_NARGS);
  ( ndims, itype, a ) = ();
  variable asize, andims, atype;
  ( asize, andims, atype ) = array_info(a);

  if ( andims != ndims ) return 0;
  if ( atype != itype ) return 0;

  _stk_reverse(_NARGS-3);
  size = __pop_args(_NARGS-3);
  variable i;
  _for( 0, ndims-1, 1 ) {
    i = ();
    if ( size[i].value != asize[i] ) return 0;
  }
  return 1;
}

define check_array1d(a) { return all(a == [1,23,-10]); }
define check_array1d_dt(a) { return all(a == [Complex_Type,UShort_Type]); }

define check_array2d(a) {
  variable out = Float_Type [2,3];
  out[0,0] = 0.0; out[1,0] = 10.0;
  out[0,1] = 1.0; out[1,1] = 11.0;
  out[0,2] = 2.0; out[1,2] = 12.0;
  return all( a == out );
}
define check_array2d_b(a) {
  variable out = Double_Type [3,1];
  out[0,0] = -49.0;
  out[1,0] = 23.2;
  out[2,0] = 1.0e47;
  return all( a == out );
}

define check_array3d(a) {
  variable out = Short_Type [1,3,2];
  out[0,0,*] = [1,2];
  out[0,1,*] = [10,11];
  out[0,2,*] = [20,21];
  return all( a == out );
}
define check_array4d(a) { return a[0,0,0,0] == -23.2; }

define check_arrayref_int1d(x) { return all( x == [-9,4,23] ); }
define check_arrayref_dbl1d(x) { return all( x == [-9.0,4.0,23.0] ); }
define check_arrayref_str1d(x) { return all( x == ["-9.0","4.0","23.0"] ); }
define check_arrayref_cpl1d(x) { return all( x == [4-2.4i,-2.4+4i] ); }

define check_arrayref_int2d(x) {
  variable match = Int_Type [2,2];
  match[0,*] = [0,1];
  match[1,*] = [4,3];
  return all( x == match );
}

define check_arrayref_dbl2d(x) {
  variable match = Double_Type [3,2];
  match[0,*] = [-4.0,73.0];
  match[1,*] = [0.0,1.0];
  match[2,*] = [4.0,3.0];
  return all( x == match );
}

define check_arrayref_int6d(x) {
  variable match = Int_Type [1,1,1,1,1,1];
  match[0,0,0,0,0,0] = 24;
  return all( x == match );
}

% to compare any_type things we have to dereference the values
%
define _comp_any (a,b) { return @a == @b; }
define check_arrayref_any1d(a) { 
  variable x = Any_Type [5];
  x[0] = -9;
  x[1] = "foo";
  x[2] = 23.0;
  x[3] = 4-3i;
  x[4] = Struct_Type;
  return all( array_map( Char_Type, &_comp_any, a, x ) );
}

define check_multi(x,y,z) {
  if ( orelse 
       { typeof(x) != DataType_Type }
       { x != Struct_Type }
     ) return 0;
  if ( orelse 
       { typeof(z) != DataType_Type }
       { z != Assoc_Type }
     ) return 0;
  % swapped logic
  if ( andelse 
       { isa_array(y) }
       { check_array1d_dt(y) }
     ) return 1;
  return 0;
}

define check_multiref(x,y,z) {
  if ( orelse 
       { typeof(x)  != Array_Type }
       { _typeof(x) != Double_Type }
     ) return 0;
  if ( orelse 
       { typeof(y)  != Array_Type }
       { _typeof(y) != String_Type }
     ) return 0;
  if ( orelse 
       { typeof(z)  != Array_Type }
       { _typeof(z) != Integer_Type }
     ) return 0;
  if ( any( x != [1.1,2.2,-43.2] ) ) return 0;
  if ( any( y != ["a string", "another one", "fooble"] ) ) return 0;

  variable dims, ndims;
  ( dims, ndims, ) = array_info( z );
  if ( orelse
       { ndims != 2 }
       { any( dims != [2,2] ) }
     ) return 0;
  variable zz = Integer_Type [2,2];
  zz[0,*] = [0,1];
  zz[1,*] = [4,3];
  if ( any( z != zz ) ) return 0;

  return 1;
}

define add2 (a) { return a+2; }

define sumup_nelems () {
  variable sum = 0;
  foreach ( __pop_args(_NARGS) ) {
    variable arg = ();
    sum += length(arg.value);
  }
  return sum;
}

