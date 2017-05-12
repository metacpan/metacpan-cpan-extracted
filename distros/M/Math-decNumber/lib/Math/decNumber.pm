package Math::decNumber;
#
# Copyright (c) 2014 Jean-Louis Morel <jl_morel@bribes.org>
#
# Version 0.01
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#

use 5.006000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Round modes
use constant ROUND_CEILING    => 0;   # round towards +infinity
use constant ROUND_UP         => 1;   # round away from 0
use constant ROUND_HALF_UP    => 2;   # 0.5 rounds up
use constant ROUND_HALF_EVEN  => 3;   # 0.5 rounds to nearest even
use constant ROUND_HALF_DOWN  => 4;   # 0.5 rounds down
use constant ROUND_DOWN       => 5;   # round towards 0 (truncate)
use constant ROUND_FLOOR      => 6;   # round towards -infinity
use constant ROUND_05UP       => 7;   # Round away from zero if the last digit
                                      # is 0 or 5, otherwise towards zero.

# Trap-enabler and Status flags
use constant DEC_Conversion_syntax    =>  0x00000001;
use constant DEC_Division_by_zero     =>  0x00000002;
use constant DEC_Division_impossible  =>  0x00000004;
use constant DEC_Division_undefined   =>  0x00000008;
use constant DEC_Insufficient_storage =>  0x00000010; 
use constant DEC_Inexact              =>  0x00000020;
use constant DEC_Invalid_context      =>  0x00000040;
use constant DEC_Invalid_operation    =>  0x00000080;
use constant DEC_Lost_digits          =>  0x00000100;
use constant DEC_Overflow             =>  0x00000200;
use constant DEC_Clamped              =>  0x00000400;
use constant DEC_Rounded              =>  0x00000800;
use constant DEC_Subnormal            =>  0x00001000;
use constant DEC_Underflow            =>  0x00002000;

# flags which cause a result to become qNaN
use constant DEC_NaNs         =>  DEC_Conversion_syntax |  
                                  DEC_Division_impossible |   
                                  DEC_Division_undefined |    
                                  DEC_Insufficient_storage |  
                                  DEC_Invalid_context |       
                                  DEC_Invalid_operation;

# flags which are normally errors (result is qNaN, infinite, or 0)
use constant DEC_Errors       =>  DEC_Division_by_zero |                 
                                  DEC_NaNs |
                                  DEC_Overflow |
                                  DEC_Underflow;

# flags which are normally for information only (finite results)
use constant DEC_Information  =>  DEC_Clamped |
                                  DEC_Rounded |
                                  DEC_Inexact |
                                  DEC_Lost_digits;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::decNumber ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
'all' => [ qw(
ROUND_CEILING ROUND_UP ROUND_HALF_UP ROUND_HALF_EVEN ROUND_HALF_DOWN
ROUND_DOWN ROUND_FLOOR ROUND_05UP ROUND_MAX
DEC_Conversion_syntax DEC_Division_by_zero DEC_Division_impossible
DEC_Division_undefined DEC_Insufficient_storage DEC_Inexact
DEC_Invalid_context DEC_Invalid_operation DEC_Lost_digits
DEC_Overflow constant DEC_Clamped DEC_Rounded
DEC_Subnormal DEC_Underflow
DEC_NaNs DEC_Errors DEC_Information

ToIntegralValue FMA NextToward Divide Xor Or Max DivideInteger
ToEngString SquareRoot Exp Min ToString FromString Add Multiply Abs
CompareSignal Shift RemainderNear ScaleB NextPlus LogB
CompareTotalMag Subtract Invert Log10 NextMinus Plus
Quantize Compare Power ToIntegralExact And SameQuantum
Rescale Remainder CompareTotal Ln Minus MaxMag MinMag	d_
Class ClassToString Reduce Rotate Trim Radix Copy CopyNegate
CopySign CopyAbs Version

ContextClearStatus ContextGetStatus ContextStatusToString
ContextSetStatus ContextSetStatusQuiet ContextSetStatusFromString
ContextSetStatusFromStringQuiet ContextSaveStatus
ContextTestStatus ContextTestSavedStatus ContextRestoreStatus
ContextZeroStatus
ContextRounding ContextPrecision ContextMaxExponent
ContextMinExponent ContextTraps ContextClamp ContextExtended

IsNormal IsSubnormal IsCanonical IsFinite IsInfinite IsNaN
IsNegative IsQNaN IsSNaN IsSpecial IsZero
 ) ],
'ROUND_' => [ qw(
ROUND_CEILING ROUND_UP ROUND_HALF_UP ROUND_HALF_EVEN ROUND_HALF_DOWN
ROUND_DOWN ROUND_FLOOR ROUND_05UP
) ],
'DEC_' => [ qw(
DEC_Conversion_syntax DEC_Division_by_zero DEC_Division_impossible
DEC_Division_undefined DEC_Insufficient_storage DEC_Inexact
DEC_Invalid_context DEC_Invalid_operation DEC_Lost_digits
DEC_Overflow DEC_Clamped DEC_Rounded
DEC_Subnormal DEC_Underflow
DEC_NaNs DEC_Errors DEC_Information
) ],

);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Math::decNumber', $VERSION);

sub _d_ {
	return $_[0] if (ref($_[0]) eq 'decNumberPtr');
	my $s = shift;
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;
	return Math::decNumber::FromString($s);
}

sub d_ {
  return _d_($_[0]) if 1 == @_;
  return map _d_($_), @_;
}

sub ContextStatusToString {
  return _ContextStatusToString() unless wantarray;
  my @r;
  my $status = ContextGetStatus();
  push @r,'Conversion syntax' if ( $status & DEC_Conversion_syntax );
  push @r,'Division by zero' if ( $status & DEC_Division_by_zero );
  push @r,'Division impossible' if ( $status & DEC_Division_impossible );
  push @r,'Division undefined' if ( $status & DEC_Division_undefined );
  push @r,'Insufficient storage' if ( $status & DEC_Insufficient_storage );
  push @r,'Inexact' if ( $status & DEC_Inexact );
  push @r,'Invalid context' if ( $status & DEC_Invalid_context );
  push @r,'Invalid operation' if ( $status & DEC_Invalid_operation );
  push @r,'Lost digits' if ( $status & DEC_Lost_digits );   
  push @r,'Overflow' if ( $status & DEC_Overflow );
  push @r,'Clamped' if ( $status & DEC_Clamped );
  push @r,'Rounded' if ( $status & DEC_Rounded );
  push @r,'Subnormal' if ( $status & DEC_Subnormal );
  push @r,'Underflow' if ( $status & DEC_Underflow );
  return @r;
}

sub ClassToString {
  my $a = shift;
  $a = Class($a) if ref $a eq 'decNumberPtr';
  return _ClassToString($a);
}

package decNumberPtr;

sub as_string{
	return Math::decNumber::ToString($_[0]);
}

sub _add { # +
	my ($u, $v) = @_;
	$v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
	return Math::decNumber::Add( $u, $v );
}

sub _sub { # -
	my ($u, $v, $mut) = @_;
  $v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
  return $mut? Math::decNumber::Subtract( $v, $u )
             : Math::decNumber::Subtract( $u, $v );
}

sub _mul { # *
	my ($u, $v) = @_;
	$v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
	return Math::decNumber::Multiply( $u, $v );
}

sub _div { # /
	my ($u, $v, $mut) = @_;
  $v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
  return $mut? Math::decNumber::Divide( $v, $u )
             : Math::decNumber::Divide( $u, $v );
}

sub _abs {
	return Math::decNumber::Abs($_[0]);
}

sub _sqrt {
	return Math::decNumber::SquareRoot($_[0]);
}

sub _equiv {   # ==
  my ($u, $v) = @_;
  $v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
  return !Math::decNumber::Compare( $u, $v );
}

sub _diff {    # !=
   my ($u, $v) = @_;
  $v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
  return Math::decNumber::Compare( $u, $v );
}

sub _comp {    # <=>
  my ($u, $v, $mut) = @_;
  $v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
  return $mut? Math::decNumber::Compare( $v, $u )
             : Math::decNumber::Compare( $u, $v );
}

sub _copy {
  return Math::decNumber::Copy($_[0]);
}

sub _copyneg {
  return Math::decNumber::CopyNegate($_[0]);
}

sub _power {
	my ($u, $v, $mut) = @_;
  $v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
  return $mut? Math::decNumber::Power( $v, $u )
             : Math::decNumber::Power( $u, $v );
}

sub _log {
  return Math::decNumber::Ln($_[0]);
}

sub _exp {
  return Math::decNumber::Exp($_[0]);
}

sub _mod {  # %
  my ($u, $v, $mut) = @_;
  $v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
  return $mut? Math::decNumber::Remainder( $v, $u )
             : Math::decNumber::Remainder( $u, $v );
}

sub _inv { # ~
  return Math::decNumber::Invert($_[0]);
}

sub _and { # and
	my ($u, $v) = @_;
	$v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
	return Math::decNumber::And( $u, $v );
}

sub _or { # or
	my ($u, $v) = @_;
	$v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
	return Math::decNumber::Or( $u, $v );
}

sub _xor { # xor
	my ($u, $v) = @_;
	$v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
	return Math::decNumber::Xor( $u, $v );
}

sub _lshift { # shift
	my ($u, $v) = @_;
	$v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
	return Math::decNumber::Shift( $u, $v );
}

sub _rshift { # rotate
	my ($u, $v) = @_;
	$v = Math::decNumber::FromString($v) unless ref $v eq 'decNumberPtr';
	return Math::decNumber::Shift( $u, -$v );
}

sub _increment {  # ++
  Math::decNumber::_increment( $_[0] )
}

sub _decrement {  # --
  Math::decNumber::_decrement( $_[0] )
}

use overload
	'""'   => \&as_string,
	'+'    => \&_add,
	'-'    => \&_sub,
	'*'    => \&_mul,
	'/'    => \&_div,
	'abs'  => \&_abs,
	'sqrt' => \&_sqrt,
  '=='   => \&_equiv,
  '!='   => \&_diff,
  '='    => \&_copy,
  'neg'  => \&_copyneg,
  '**'   => \&_power,
  'log'  => \&_log,
  '<=>'  => \&_comp,
  'exp'  => \&_exp,
  '%'    => \&_mod,
  '~'    => \&_inv,
  '&'    => \&_and,
  '|'    => \&_or,
  '^'    => \&_xor,
  '<<'   => \&_lshift,
  '>>'   => \&_rshift,
  '++'   => \&_increment,
  '--'   => \&_decrement;

1;
