use strict;
use warnings;

use Test::More tests => 82;

use Math::decNumber qw(:all);

my $s = Version();
ok( $s eq 'decNumber 3.68' );

ok(1); # If we made it this far, we're ok.

$s = ContextGetStatus();
ok( $s == 0 );

# ====== Radix

ok( 10 == Radix() );

sub radix {  
  my $a = $_[0];
  $a *= 2.0 while( ($a + 1.0)-$a == $_[0] );  
  my $b = $_[0];
  $b += 1.0 while ( ($a +$b) - $a != $b );
  return $b;
}

ok( radix( d_ 1.0 ) == d_(10) );


# ====== ContextRounding

my $r = ContextRounding();
ok( $r == ROUND_HALF_EVEN );

ContextRounding(ROUND_HALF_UP);
$s = ContextRounding(ROUND_FLOOR);
ok( $s == ROUND_HALF_UP );

$s = ContextRounding($r);
ok( $s == ROUND_FLOOR );

foreach( ROUND_CEILING, ROUND_UP, ROUND_HALF_UP, ROUND_HALF_EVEN, ROUND_HALF_DOWN,
ROUND_DOWN, ROUND_FLOOR, ROUND_05UP ) {
  $s = ContextRounding($_);
  ok( $s == $r ),
  $r = $_;
}

# ====== ContextPrecision

sub precision {
  my $b = d_(10);
  my $i = 0;
  my $a = d_(0.1);;
  while ( ($a+0.1)-$a == d_(0.1) ) {
    $a = $b*$a;
    $i++;
  }
  return $i; 
}

my $p = ContextPrecision();
ok( $p == 34 );

ContextPrecision(100);
$s = ContextPrecision(60);
ok( $s == 100);
ok( 60 == precision() );
print precision(), "\n";

$s = ContextPrecision($p);
ok( $s == 60);
ok( 34 == precision() );

# ====== ContextMaxExponent

my $e = ContextMaxExponent();
ok( $e == 6144);

ContextMaxExponent(99);
$s = ContextMaxExponent(777);
ok( $s == 99 );

$s = ContextMaxExponent($e);
ok( $s == 777);

# ====== ContextMinExponent

$e = ContextMinExponent();
ok( $e == -6143);

ContextMaxExponent(-99);
$s = ContextMaxExponent(-777);
ok( $s == -99 );

$s = ContextMaxExponent($e);
ok( $s == -777);

# ====== ContextTraps

my $t = ContextTraps();
ok( $t == 0 );

ContextTraps(DEC_Conversion_syntax);
$s = ContextTraps(DEC_Division_by_zero);
ok( $s == DEC_Conversion_syntax);

$s = ContextTraps($t);
ok( $s == DEC_Division_by_zero);

# ====== ContextClamp

my $c = ContextClamp();
ok( $c == 0 );

ContextClamp(1);
$s = ContextClamp($c);
ok( $s == 1 );

ok( $c == ContextClamp($c) );

# ====== ContextExtended

ContextExtended(1);
ok( ContextExtended() == 1 );

# ====== ContextStatus*

ContextZeroStatus();
ContextSetStatus( DEC_Conversion_syntax );
ok( ContextStatusToString() eq 'Conversion syntax' );

ContextZeroStatus();
ContextSetStatus( DEC_Division_by_zero );
ok( ContextStatusToString() eq 'Division by zero' );

ContextZeroStatus();
ContextSetStatus( DEC_Division_impossible );
ok( ContextStatusToString() eq 'Division impossible' );

ContextZeroStatus();
ContextSetStatus( DEC_Division_undefined );
ok( ContextStatusToString() eq 'Division undefined' );

ContextZeroStatus();
ContextSetStatus( DEC_Insufficient_storage );
ok( ContextStatusToString() eq 'Insufficient storage' );

ContextZeroStatus();
ContextSetStatus( DEC_Inexact );
ok( ContextStatusToString() eq 'Inexact' );

ContextZeroStatus();
ContextSetStatus( DEC_Invalid_context );
ok( ContextStatusToString() eq 'Invalid context' );

ContextZeroStatus();
ContextSetStatus( DEC_Invalid_operation );
ok( ContextStatusToString() eq 'Invalid operation' );

ContextZeroStatus();
ContextSetStatus( DEC_Lost_digits );
ok( ContextStatusToString() eq 'Multiple status' );  # because DECSUBSET = 0

ContextZeroStatus();
ContextSetStatus( DEC_Overflow );
ok( ContextStatusToString() eq 'Overflow' );

ContextZeroStatus();
ContextSetStatus( DEC_Clamped );
ok( ContextStatusToString() eq 'Clamped' );

ContextZeroStatus();
ContextSetStatus( DEC_Rounded );
ok( ContextStatusToString() eq 'Rounded' );

ContextZeroStatus();
ContextSetStatus( DEC_Subnormal );
ok( ContextStatusToString() eq 'Subnormal' );

ContextZeroStatus();
ContextSetStatus( DEC_Underflow );
ok( ContextStatusToString() eq 'Underflow' );

ContextZeroStatus();
ContextSetStatusQuiet( DEC_Underflow );
ok( ContextStatusToString() eq 'Underflow' );

ContextZeroStatus();
ok( ContextStatusToString() eq 'No status' );

ContextZeroStatus();
ContextSetStatus( DEC_Underflow | DEC_Subnormal | DEC_Inexact );
ok( ContextStatusToString() eq 'Multiple status' );
my @r = ContextStatusToString();
ok( 3 == @r );
ok( $r[0] eq 'Inexact' );
ok( $r[1] eq 'Subnormal' );
ok( $r[2] eq 'Underflow' );

ContextClearStatus( DEC_Inexact );
@r = ContextStatusToString();
ok( 2 == @r );
ok( $r[0] eq 'Subnormal' );
ok( $r[1] eq 'Underflow' );

ContextSetStatusFromString( 'Division impossible' );
@r = ContextStatusToString();
ok( 3 == @r );
ok( $r[0] eq 'Division impossible' );
ok( $r[1] eq 'Subnormal' );
ok( $r[2] eq 'Underflow' );

ok( ContextTestStatus( DEC_Division_impossible ) );
ok( ContextTestStatus( DEC_Subnormal ) );
ok( ContextTestStatus( DEC_Underflow ) );
ok( ContextTestStatus( DEC_Division_impossible | DEC_Subnormal ) );
ok( ContextTestStatus( DEC_Division_impossible | DEC_Underflow ) );
ok( ContextTestStatus( DEC_Subnormal | DEC_Underflow ) );
ok( ContextTestStatus( DEC_Division_impossible | DEC_Subnormal | DEC_Underflow ) );
ok( ContextTestStatus( DEC_Division_impossible | DEC_Subnormal | DEC_Invalid_context ) );
ok( !ContextTestStatus( DEC_Invalid_context ) );

ContextSetStatusFromStringQuiet( 'Invalid operation' );
ok( ContextTestStatus( DEC_Invalid_operation ) );

$s = ContextSaveStatus( DEC_Subnormal | DEC_Invalid_context ) ;
ok( ContextTestSavedStatus( $s, DEC_Subnormal | DEC_Invalid_context ) );
ok( ContextTestSavedStatus( $s, DEC_Subnormal ) );
ok( !ContextTestSavedStatus( $s, DEC_Invalid_context ) );
ok( !ContextTestSavedStatus( $s, DEC_Underflow ) );

ContextZeroStatus();
ok( ContextStatusToString() eq 'No status' );
@r = ContextStatusToString();
ok( 0 == @r );

ContextRestoreStatus( $s, DEC_Subnormal | DEC_Invalid_context );
ok( ContextTestStatus( DEC_Subnormal ) );
ok( !ContextTestStatus( DEC_Invalid_context ) );
@r = ContextStatusToString();
ok( 1 == @r );
ok( $r[0] eq 'Subnormal' );

#====== End of tests







    








