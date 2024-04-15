package Math::Int113;
use strict;
use warnings;
use Config;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

$Math::Int113::VERSION = '0.05';
Math::Int113->DynaLoader::bootstrap($Math::Int113::VERSION);
sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

use constant IVSIZE_IS_8  => $Config{ivsize} == 8 ? 1 : 0;

# hint: 49 == 113 - 64; 17 == 113 - 96
# NOT_MASK is utilised only in sub oload_not()
use constant NOT_MASK     => IVSIZE_IS_8 ? (2 ** 49) - 1 : (2 ** 17) - 1;

use overload
'+'    => \&oload_add,
'-'    => \&oload_sub,
'*'    => \&oload_mul,
'/'    => \&oload_div,
'%'    => \&oload_mod,
'**'   => \&oload_pow,
'++'   => \&oload_inc,
'--'   => \&oload_dec,
'>='   => \&oload_gte,
'<='   => \&oload_lte,
'=='   => \&oload_equiv,
'>'    => \&oload_gt,
'<'    => \&oload_lt,
'<=>'  => \&oload_spaceship,
'""'   => \&oload_stringify,
'&'    => \&oload_and,
'|'    => \&oload_or,
'^'    => \&oload_xor,
'~'    => \&oload_not,
'>>'   => \&oload_rshift,
'<<'   => \&oload_lshift,
;

##############################################
my @tagged = qw(
    coverage divmod
    );

@Math::Int113::EXPORT = ();
@Math::Int113::EXPORT_OK = @tagged;

%Math::Int113::EXPORT_TAGS = (all => \@tagged);
#############################################

$Math::Int113::MAX_OBJ = Math::Int113->new(1.0384593717069655257060992658440191e34);

if($Config{nvtype} ne '__float128') {
   if($Config{nvtype} ne 'long double' &&
      $Config{longdblkind} != 1        &&
      $Config{longdblkind} != 2) {
      die "Bailing out: NV must be either IEEE 754 long double or __float128";
  }
}

sub new {
  shift if(!ref($_[0]) && $_[0] eq "Math::Int113"); # 'new' has been called as a method

  if(ref($_[0]) eq "Math::Int113") {
    # return a copy of the given Math::Int113 object
    my $ret = shift;
    return $ret;
  }

  my $v = shift;
    if(overflows($v)) {
    my($package, $filename, $line) = caller;
    warn "overflow in package $package, file $filename, at line $line\n";
    die "Arg (", sprintf("%.36g", $v), "), given to new(), overflows 113 bits";
    }
  my %h = ('val' => int($v));
  return bless(\%h, 'Math::Int113');
}

sub overflows {
  # This is a private sub. No need to check initialization in here.
  no warnings 'uninitialized';
  my $v = shift;
  return 1 if $v != $v; # NaN
  return 1
    if($v >=  1.0384593717069655257060992658440192e34 ||
       $v <= -1.0384593717069655257060992658440192e34);
  return 0;
}

sub oload_add {
  my($_1, $_2) = (shift, shift);
  if(ref($_2) eq 'Math::Int113') { return Math::Int113->new($_1->{val} + $_2->{val}) }

  die "Overflow in arg (", sprintf("%.36g", $_2), ") given to overloaded addition"
    if overflows(int($_2));

  return Math::Int113->new($_1->{val} + int($_2));
}

sub oload_mul {
  my($_1, $_2) = (shift, shift);
  if(ref($_2) eq 'Math::Int113') { return Math::Int113->new($_1->{val} * $_2->{val}) }

  die "Overflow in arg (", sprintf("%.36g", $_2), ") given to overloaded multiplication"
    if overflows(int($_2));

  return Math::Int113->new($_1->{val} * int($_2));
}

sub oload_sub {
  my($_1, $_2, $_3) = (shift, shift, shift);
  if(ref($_2) eq 'Math::Int113') {
    return Math::Int113->new($_2->{val} - $_1->{val})
      if $_3;
    return Math::Int113->new($_1->{val} - $_2->{val})
  }

  die "Overflow in arg (", sprintf("%.36g", $_2), ") given to overloaded subtraction"
    if overflows(int($_2));

  return Math::Int113->new(int(int($_2) - $_1->{val}))
    if $_3;
  return Math::Int113->new(int($_1->{val} - int($_2)));
}

sub oload_div {
  my($_1, $_2, $_3) = (shift, shift, shift);
  if(ref($_2) eq 'Math::Int113') {
    return Math::Int113->new(int($_2->{val} / $_1->{val}))
      if $_3;
    return Math::Int113->new(int($_1->{val} / $_2->{val}))
  }

  die "Overflow in arg (", sprintf("%.36g", $_2), ") given to overloaded division"
    if overflows(int($_2));

  return Math::Int113->new(int(int($_2) / $_1->{val}))
    if $_3;
  return Math::Int113->new(int($_1->{val} / int($_2)));
}

sub oload_mod {
  my($_1, $_2, $_3) = (shift, shift, shift);
  if(ref($_2) eq 'Math::Int113') {
    return Math::Int113->new($_2->{val} % $_1->{val})
      if $_3;
    return Math::Int113->new($_1->{val} % $_2->{val})
  }

  die "Overflow in arg (", sprintf("%.36g", $_2), ") given to overloaded modulus"
    if overflows(int($_2));

  return Math::Int113->new(int($_2) % $_1->{val})
    if $_3;
  return Math::Int113->new($_1->{val} % int($_2));
}

sub divmod {
  my ($_1, $_2) = (shift, shift);
  # Convert given args to Math::Int113 objects (if they are not already).
  $_1 = Math::Int113->new($_1) unless ref $_1 eq 'Math::Int113';
  $_2 = Math::Int113->new($_2) unless ref $_2 eq 'Math::Int113';
  # Return the result as a list of 2 Math::Int113 objects.
  return ( $_1 / $_2,
           $_1 % $_2 );
}

sub oload_pow {
  my($_1, $_2, $_3) = (shift, shift, shift);
  if(ref($_2) eq 'Math::Int113') {
    return Math::Int113->new(int($_2->{val} ** $_1->{val}))
      if $_3;
    return Math::Int113->new(int($_1->{val} ** $_2->{val}))
  }

  die "Overflow in arg (", sprintf("%.36g", $_2), ") given to overloaded division"
    if overflows(int($_2));
  # If $_2 is a fractional value, it remains unaltered.
  return Math::Int113->new($_2 ** $_1->{val})
    if $_3;
  return Math::Int113->new($_1->{val} ** $_2);
}

###################################
sub oload_gte {
  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);
  return 1 if $cmp >= 0;
  return 0;
}

sub oload_lte {
  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);
  return 1 if $cmp <= 0;
  return 0;
}

sub oload_equiv {
  return 1 if(oload_spaceship($_[0], $_[1], $_[2]) == 0);
  return 0;
}

sub oload_gt {
  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);
  return 1 if $cmp > 0;
  return 0;
}

sub oload_lt {
  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);
  return 1 if $cmp < 0;
  return 0;
}
###################################

sub oload_spaceship {
  my($_1, $_2, $_3) = (shift, shift, shift);

  if(ref($_2) eq 'Math::Int113') {
    if($_3) {
      return $_2->{val} <=> $_1->{val};
    }
    return $_1->{val} <=> $_2->{val};
  }

  if($_3) {
    return int($_2) <=> $_1->{val};
  }

  return $_1->{val} <=> int($_2);
}

sub oload_inc {
  die "$_[0] overflows '++'"
    unless $_[0] < 1.0384593717069655257060992658440192e34 ;
  ($_[0]->{val})++;
}

sub oload_dec {
  die "$_[0] overflows '--'"
    unless $_[0] > -1.0384593717069655257060992658440192e34 ;
  ($_[0]->{val})--;
}

sub oload_stringify {
  my $self = shift;
  return sprintf("%.36g", $self->{val});
}

sub oload_rshift {
  my($_1, $_2, $switch);

  # If $_1 is negative, we set $_1 = ~(abs($_1)) + 1
  # If $_2 is negative, we return oload_lshift($_1, abs($_2))

  if($_[2]) {
    ($_2, $_1, $switch) = (shift, shift, 1);    # $_1 is NOT a Math::Int113 object
  }
  else {
    ($_1, $_2, $switch) = (shift, shift, 0);    # $_1 IS a Math::Int113 object
  }

  $_1 = Math::Int113->new($_1) if $switch;

  # If $_1 is negative, we set $_1 = ~(abs($_1)) + 1
  # If $_2 is negative, we return oload_lshift($_1, abs($_2))

  $_1 = ~(-$_1) + 1              if $_1 < 0; # 2s-complement
  return oload_lshift($_1, -$_2) if $_2 < 0;
  return Math::Int113->new(0)    if $_2 >= 113;

  if(ref($_2) eq 'Math::Int113') {
    return $_1 / (2 ** ($_2->{val}));
  }

  return $_1 / (2 ** int($_2));
}

sub oload_lshift {
  my($_1, $_2, $switch);

  if($_[2]) {
    ($_2, $_1, $switch) = (shift, shift, 1);    # $_1 is NOT a Math::Int113 object
  }
  else {
    ($_1, $_2, $switch) = (shift, shift, 0);    # $_1 IS a Math::Int113 object
  }

  $_1 = Math::Int113->new($_1) if $switch;

  # If $_1 is negative, we set $_1 = ~(abs($_1)) + 1
  # If $_2 is negative, we return oload_rshift($_1, abs($_2))

  $_1 = ~(-$_1) + 1              if $_1 < 0; # 2s-complement
  return oload_rshift($_1, -$_2) if $_2 < 0;
  return Math::Int113->new(0)    if $_2 >= 113;

  # Avoid overflow:
  #my $t0 = $Math::Int113::MAX_OBJ >> $_2;
  #my $t1 = $_1 & $t0;
  #$_1 = $t1;
  $_1 = $_1 & ($Math::Int113::MAX_OBJ >> $_2);

  if(ref($_2) eq 'Math::Int113') {
    return $_1 * (2 ** ($_2->{val}));
  }

  return $_1 *  (2 ** int($_2));
}

sub oload_and {

  my($_1, $_2) = (shift, shift);

  $_1 = ~(-$_1) + 1 if $_1 < 0; # 2s-complement
  if($_2 < 0) {
    if(ref($_2) eq 'Math::Int113') { $_2 = ~(-$_2) + 1 } # 2s-complement
    else { $_2 = ~(Math::Int113->new(-$_2)) + 1 }        # 2s-complement
  }

  if(IVSIZE_IS_8) {
    my($hi_1, $lo_1) = hi_lo($_1);
    my($hi_2, $lo_2) = hi_lo($_2);

    my $hi = $hi_1->{val} & $hi_2->{val};
    $hi *= 2 ** 64;

    my $lo = $lo_1->{val} & $lo_2->{val};

    return Math::Int113->new($hi + $lo);
  }
  else {

    my($hi_1, $m1_1, $m2_1, $lo_1) = hi_lo($_1);
    my($hi_2, $m1_2, $m2_2, $lo_2) = hi_lo($_2);

    my $hi = $hi_1->{val} & $hi_2->{val};
    $hi *= 2 ** 96;

    my $m1 = $m1_1->{val} & $m1_2->{val};
    $m1 *= 2 ** 64;

    my $m2 = $m2_1->{val} & $m2_2->{val};
    $m2 *= 2 ** 32;

    my $lo = $lo_1->{val} & $lo_2->{val};

    return Math::Int113->new($hi + $m1 + $m2 + $lo);
  }
}

sub oload_or {

  my($_1, $_2) = (shift, shift);

  $_1 = ~(-$_1) + 1 if $_1 < 0; # 2s-complement
  if($_2 < 0) {
    if(ref($_2) eq 'Math::Int113') { $_2 = ~(-$_2) + 1 } # 2s-complement
    else { $_2 = ~(Math::Int113->new(-$_2)) + 1 }        # 2s-complement
  }

  if(IVSIZE_IS_8) {

    my($hi_1, $lo_1) = hi_lo($_1);
    my($hi_2, $lo_2) = hi_lo($_2);

    my $hi = $hi_1->{val} | $hi_2->{val};
    $hi *= 2 ** 64;

    my $lo = $lo_1->{val} | $lo_2->{val};

    return Math::Int113->new($hi + $lo);
  }
  else {

    my($hi_1, $m1_1, $m2_1, $lo_1) = hi_lo($_1);
    my($hi_2, $m1_2, $m2_2, $lo_2) = hi_lo($_2);

    my $hi = $hi_1->{val} | $hi_2->{val};
    $hi *= 2 ** 96;

    my $m1 = $m1_1->{val} | $m1_2->{val};
    $m1 *= 2 ** 64;

    my $m2 = $m2_1->{val} | $m2_2->{val};
    $m2 *= 2 ** 32;

    my $lo = $lo_1->{val} | $lo_2->{val};

    return Math::Int113->new($hi + $m1 + $m2 + $lo);
  }
}

sub oload_xor {

  my($_1, $_2) = (shift, shift);

  $_1 = ~(-$_1) + 1 if $_1 < 0; # 2s-complement
  if($_2 < 0) {
    if(ref($_2) eq 'Math::Int113') { $_2 = ~(-$_2) + 1 } # 2s-complement
    else { $_2 = ~(Math::Int113->new(-$_2)) + 1 }        # 2s-complement
  }

  if(IVSIZE_IS_8) {

    my($hi_1, $lo_1) = hi_lo($_1);
    my($hi_2, $lo_2) = hi_lo($_2);

    my $hi = $hi_1->{val} ^ $hi_2->{val};
    $hi *= 2 ** 64;

    my $lo = $lo_1->{val} ^ $lo_2->{val};

    return Math::Int113->new($hi + $lo);
  }
  else {

    my($hi_1, $m1_1, $m2_1, $lo_1) = hi_lo($_1);
    my($hi_2, $m1_2, $m2_2, $lo_2) = hi_lo($_2);

    my $hi = $hi_1->{val} ^ $hi_2->{val};
    $hi *= 2 ** 96;

    my $m1 = $m1_1->{val} ^ $m1_2->{val};
    $m1 *= 2 ** 64;

    my $m2 = $m2_1->{val} ^ $m2_2->{val};
    $m2 *= 2 ** 32;

    my $lo = $lo_1->{val} ^ $lo_2->{val};

    return Math::Int113->new($hi + $m1 + $m2 + $lo);
  }
}

sub oload_not {

  my($_1) = (shift);

  $_1 = ~(-$_1) + 1 if $_1 < 0; # 2s-complement

  if(IVSIZE_IS_8) {

    my($hi_1, $lo_1) = hi_lo($_1);

    my $mask = (2 ** 49) - 1;
    my $hi = ~($hi_1->{val});
    $hi &= NOT_MASK; # NOT_MASK == (2 ** 49) - 1
    $hi *= 2 ** 64;

    my $lo = ~($lo_1->{val});

    return Math::Int113->new($hi + $lo);
  }
  else {

    my($hi_1, $m1_1, $m2_1, $lo_1) = hi_lo($_1);

    my $hi = ~($hi_1->{val});
    $hi &= NOT_MASK; # NOT_MASK == (2 ** 17) - 1
    $hi *= 2 ** 96;

    my $m1 = ~($m1_1->{val});
    $m1 *= 2 **64;

    my $m2 = ~($m2_1->{val});
    $m2 *= 2 **32;

    my $lo = ~($lo_1->{val});

    return Math::Int113->new($hi + $m1 + $m2 + $lo);
  }
}

sub hi_lo {
  # Altered, as of Math-Int113-0.04, to avoid overloaded operations.

  my $de_obj;
  if(ref($_[0]) eq 'Math::Int 113') {
    $de_obj = $_[0]->{val};
  }
  else {
    $de_obj = int(shift);
    # Because $de_obj is not derived from a Math::Int113 object we
    # must check that its value doesn't overflow a Math::Int113 object.
    die "Overflow in arg (", sprintf("%.36g", $de_obj), ") given to sub hi_lo"
      if overflows($de_obj);
  }

  if(IVSIZE_IS_8) {
    my($hi, $lo);
    $hi = int($de_obj / (2 ** 64));
    my $intermediate = $hi * (2 ** 64);
    $lo = $de_obj - $intermediate;
    return(Math::Int113->new($hi), Math::Int113->new($lo));
  }
  else {
    # We use $lo as a variable to hold
    # various intermediate values. At the
    # end it holds the value of the 32
    # least significant bits.
    my($hi, $m1, $m2, $lo);

    $hi = int($de_obj / (2 ** 96));
    $lo = $de_obj - ($hi * (2 ** 96));
    $m1 = int($lo / (2 ** 64));

    $lo -= $m1 * (2 ** 64);
    $m2 = int($lo / (2 ** 32));

    $lo -= $m2 * (2 ** 32);
    return (Math::Int113->new($hi), Math::Int113->new($m1),
            Math::Int113->new($m2), Math::Int113->new($lo));
  }
}

sub coverage {
  my($iv_bits, $nv_prec, $max_prec) = (shift, shift, shift);
  return ( (2**$iv_bits)-1, 0 ) if $iv_bits >= $max_prec;

  my $integer_max = (2**$max_prec) - 1;
  $max_prec--;

  my $rep = (2**$iv_bits) - 1; # All values in 1..(2**$iv_bits)-1 are
                               # representable - though this might not be
                               # so for the range -((2**$iv_bits)-1..-1.

  for my $v($iv_bits..$max_prec) { $rep += (2 ** _min($v,$nv_prec)) }
  my $unrep = $integer_max - $rep;
  return ( sprintf("%.36g", $rep), sprintf("%.36g", $unrep) );
}

sub _min {
  my($v1, $v2) = (shift, shift);
  return $v1 if $v1 <= $v2;
  return $v2;
}

1;

__END__

Saving this OK version of sub hi_lo:

sub hi_lo {

  my $obj;
  if(ref($_[0]) eq 'Math::Int 113') {
    $obj = shift;
  }
  else {
    $obj = Math::Int113->new(shift);
  }

  if(IVSIZE_IS_8) {
    my($hi, $lo);
 #  ORIG
 #   $hi = $obj >> 64;
 #   my $intermediate = $hi << 64;
 #   $lo = $obj - $intermediate;
 #   return ($hi, $lo);
 #  REPLACEMENT - avoid operator overloading
    $hi = int($obj->{val} / (2 ** 64));
    my $intermediate = $hi * (2 ** 64);
    $lo = $obj->{val} - $intermediate;
    return(Math::Int113->new($hi), Math::Int113->new($lo));
  }
  else {
    # We use $lo as a variable to hold
    # various intermediate values. At the
    # end it holds the value of the 32
    # least significant bits.
    my($hi, $m1, $m2, $lo);
 #  ORIG
 #   $hi = $obj >> 96;
 #   $lo = $obj - ($hi << 96);
 #   $m1 = $lo >> 64;
 #
 #   $lo -= $m1 << 64;
 #   $m2 = $lo >> 32;
 #
 #   $lo -= $m2 << 32;
 #  REPLACEMENT - avoid operator overloading
    $hi = int($obj->{val} / (2 ** 96));
    $lo = $obj->{val} - ($hi * (2 ** 96));
    $m1 = int($lo / (2 ** 64));

    $lo -= $m1 * (2 ** 64);
    $m2 = int($lo / (2 ** 32));

    $lo -= $m2 * (2 ** 32);
    return (Math::Int113->new($hi), Math::Int113->new($m1),
            Math::Int113->new($m2), Math::Int113->new($lo));
  }
}

