# -*-perl-*-
#
# test conversion of piddles to S-Lang
#
# many of these tests shouldn't be direct equality
# since it's floating point
#

use strict;

# we implicitly test support for !types here
use Inline 'SLang' => Config => EXPORT => [ qw( sl_array !types ) ];
use Inline 'SLang';

use constant NTESTS => 35;
use Test::More tests => NTESTS;

SKIP: {
    skip 'PDL support is not available', NTESTS
      unless Inline::SLang::sl_have_pdl();

    eval "use PDL;";

    ##use Data::Dumper;

    ## Tests

    # Can we send simple 1D arrays to S-Lang?
    # (the actual value stored is not checked for in these tests)
    #
    my $val = [20];
    my $dim = [1];
    ok( isa_array(byte($val),$dim,UChar_Type()),    "Can convert byte to a 1D S-Lang array" );
    ok( isa_array(short($val),$dim,Short_Type()),   "Can convert short to a 1D S-Lang array" );
    ok( isa_array(ushort($val),$dim,UShort_Type()), "Can convert ushort to a 1D S-Lang array" );
    ok( isa_array(long($val),$dim,Int_Type()),      "Can convert long to a 1D S-Lang array" );
    ok( isa_array(float($val),$dim,Float_Type()),   "Can convert float to a 1D S-Lang array" );
    ok( isa_array(double($val),$dim,Double_Type()), "Can convert double to 1D a S-Lang array" );

    # Can we send simple 6D arrays to S-Lang?
    # - can't do 7D since there's a problem with 7D arrays in v1.4.9 of S-Lang
    #
    $val = [[[[[[20]]]]]];
    $dim = [1,1,1,1,1,1];
    ok( isa_array(byte($val),$dim,UChar_Type()),    "Can convert byte to a 6D S-Lang array" );
    ok( isa_array(short($val),$dim,Short_Type()),   "Can convert short to a 6D S-Lang array" );
    ok( isa_array(ushort($val),$dim,UShort_Type()), "Can convert ushort to a 6D S-Lang array" );
    ok( isa_array(long($val),$dim,Int_Type()),      "Can convert long to a 6D S-Lang array" );
    ok( isa_array(float($val),$dim,Float_Type()),   "Can convert float to a 6D S-Lang array" );
    ok( isa_array(double($val),$dim,Double_Type()), "Can convert double to a 6D S-Lang array" );

    # Check that 1D data is converted correctly
    #
    $val = byte(1,2,3,128,255,256);
    ok( check_byte1d($val), "1D byte vals okay" );
    $val = sequence( short(), 5 ) - 2;
    ok( check_short1d($val), "1D short vals okay" );
    # too lazy to find out what the max value of a short is
    $val = ushort(2,1,0,1,2);
    ok( check_ushort1d($val), "1D ushort vals okay" );
    $val = long(-3,-16,0,1,2);
    ok( check_long1d($val), "1D long vals okay" );
    $val = (sequence(float(),10)-5)/2.0;
    ok( check_float1d($val), "1D float vals okay" );
    $val = (sequence(float(),10)-5)/2.0;
    ok( check_float1d($val), "1D float vals okay" );
    $val = (sequence(10)-5)/2.0;
    ok( check_dble1d($val), "1D double vals okay" );

    # and now 2D arrays
    #
    $val = cat( byte(1,2,3), byte(128,255,256) );
    ok( check_byte2d($val), "2D byte vals okay" );
    $val = ones(short(),4,2)->xvals;
    ok( check_short2d($val), "2D short vals okay" );
    $val = sequence(2,4);
    ok( check_dble2d($val), "2D double vals okay" );

    # and now 3D arrays
    #
    $val = sequence( byte(), 2, 4, 3 );
    ok( check_3d($val,UChar_Type()), "3D byte vals okay" );
    $val = sequence( ushort(), 2, 4, 3 );
    ok( check_3d($val,UShort_Type()), "3D ushort vals okay" );
    $val = sequence( short(), 2, 4, 3 );
    ok( check_3d($val,Short_Type()), "3D short vals okay" );
    $val = sequence( long(), 2, 4, 3 );
    ok( check_3d($val,Int_Type()), "3D int vals okay" );
    $val = sequence( float(), 2, 4, 3 );
    ok( check_3d($val,Float_Type()), "3D float vals okay" );
    $val = sequence( double(), 2, 4, 3 );
    ok( check_3d($val,Double_Type()), "3D double vals okay" );

    # try some 'fancy' stuff
    # - use a slice (without NiceSlice syntax as too painful to eval strings)
    # - try contiguous and non-contiguous slices (not that it is important
    #   for the current code, it may be if we improve it later on)
    #
    $val = sequence( short(), 15 ) - 7;
    ok( check_short1d($val->slice('5:9')), "1D short vals okay [slice]" );
    $val = (sequence(20)-10)/2.0;
    ok( check_dble1d($val->slice('5:14')), "1D double vals okay [slice]" );

    $val = short( -3, -2, 0, 1, 2, -1 );
    my $i = long( 1, 5, 2, 3, 4 );
    ok( check_short1d($val->index($i)), "1D short vals okay [index]" );

    # send a piddle to S-Lang, get it back, and sent it to S-Lang
    #
    $val = reshape( sequence(12) % 4 == 1, 3, 4 );
    my $val2 = return2sender( $val );
    ok( all( $val == $val2 ), "2D return from S-Lang is okay" );
    ok( 1 == get_nsent(), "  - rather pointless check 1" );
    $val = return2sender( $val2 );
    ok( all( $val2 == $val ), "  - rather pointless check 2" );
    ok( 2 == get_nsent(), "  - rather pointless check 3" );

} # SKIP

__END__
__SLang__

%
% As of version 0.26 of Inline::SLang we guarantee that
% sum is part of the S-Lang run-time library
%
% we label these functions as private to avoid them being exported
% to Perl, where they would conflict with the all() and any()
% routines from PDL [resulting in a warning message printed to
% the screen]
%
private define all(x) { return sum(typecast(x,Int_Type)!=0) == length(x); }
private define any(x) { return sum(typecast(x,Int_Type)!=0) != 0; }

define isa_array(a,dims,type) {
    if (
	andelse
	{ typeof(a) == Array_Type }
	{ _typeof(a) == type }
       ) {
	variable adims;
	( adims, , ) = array_info(a);
	return all( adims == dims );
    }
    return 0;
}

private variable nsent = 0;
define return2sender(in) { nsent++; return in; }
define get_nsent() { return nsent; }

define check_byte1d(in) {
  if ( _typeof(in) != UChar_Type ) return 0;
  variable out = typecast( [1,2,3,128,255,0], UChar_Type );
  return all( in == out );
}

define check_short1d(in) {
  if ( _typeof(in) != Short_Type ) return 0;
  variable out = typecast( [-2,-1,0,1,2], Short_Type );
  return all( in == out );
}

define check_ushort1d(in) {
  if ( _typeof(in) != UShort_Type ) return 0;
  variable out = typecast( [2,1,0,1,2], UShort_Type );
  return all( in == out );
}

define check_long1d(in) {
  if ( _typeof(in) != Integer_Type ) return 0;
  variable out = typecast( [-3,-16,0,1,2], Integer_Type );
  return all( in == out );
}

define check_float1d(in) {
  if ( _typeof(in) != Float_Type ) return 0;
  variable out = typecast( [-5:4]/2.0, Float_Type );
  return all( in == out );
}

define check_dble1d(in) {
  if ( _typeof(in) != Double_Type ) return 0;
  variable out = typecast( [-5:4]/2.0, Double_Type );
  return all( in == out );
}

define check_byte2d(in) {
  if ( _typeof(in) != UChar_Type ) return 0;
  variable out = UChar_Type [2,3];
  out[0,*] = [1,2,3];
  out[1,*] = [128,255,0];
  return all( in == out );
}

define check_short2d(in) {
  if ( _typeof(in) != Short_Type ) return 0;
  variable out = Short_Type [2,4];
  out[0,*] = [0,1,2,3];
  out[1,*] = out[0,*];
  return all( in == out );
}

define check_dble2d(in) {
  if ( _typeof(in) != Double_Type ) return 0;
  variable out = typecast([0:7],Double_Type);
  reshape(out,[4,2]);
  return all( in == out );
}

define check_3d(in,type) {
  if ( _typeof(in) != type ) return 0;
  variable out = typecast( [0:23], type );
  reshape( out, [3,4,2] );
  return all( in == out );
}

%% end
