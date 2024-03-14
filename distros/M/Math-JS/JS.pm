# Checked against calculator at https://playcode.io/new
package Math::JS;
use strict;
use warnings;
use Config;

BEGIN {
  $::bool = 0;
  eval {require Math::Ryu;};
  if(!$@ && $Math::Ryu::VERSION >= 0.06) {
    $::bool = 1;
  }
};
use 5.030; # avoid buggy floating-point assignments

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
'!='   => \&oload_not_equiv,
'>'    => \&oload_gt,
'<'    => \&oload_lt,
'<=>'  => \&oload_spaceship,
'""'   => \&oload_stringify,
'&'    => \&oload_and,
'|'    => \&oload_ior,
'^'    => \&oload_xor,
'~'    => \&oload_not,
'<<'   => \&oload_lshift,
'>>'   => \&oload_rshift,
;

use constant MAX_ULONG =>  4294967295;
use constant MAX_SLONG =>  2147483647;
use constant MIN_ULONG =>  2147483648;  # 1<<31 (Lowest positive value that sets 32nd bit)
use constant MIN_SLONG => -2147483648;
use constant LOW_31BIT =>  1073741824;  # 1<<30 (Lowest 31 bit positive number)
use constant MAX_NUM   =>  9007199254740991;
use constant USE_RYU => $::bool; # set in BEGIN{} block
use constant IVSIZE    => $Config{ivsize};

our $VERSION = '0.05';

require Exporter;
*import = \&Exporter::import;
@Math::JS::EXPORT = ();
@Math::JS::EXPORT_OK = qw(urs);

require DynaLoader;
Math::JS->DynaLoader::bootstrap($VERSION);
sub dl_load_flags {0}

# The "type" of a Math::JS object's value will be either 'sint32', 'uint32'
# or 'number'. Roughly speaking, these types are (respectively) "unsigned
# 32-bit integer", "signed 32-bit integer" and "floating-point number".
# Hence, relying on the value returned by is_ok(), we have:
my %classify = (2 => 'uint32', 3 => 'sint32', 4 => 'number');

sub new {
  shift if(!ref($_[0]) && $_[0] eq "Math::JS"); # 'new' has been called as a method
  my $val = shift;
  my $ok = is_ok($val); # returns 1 for Math::JS object, 2 for a 32-bit UV,
                        # 3 for a 32-bit IV, 4 for an NV, and 0 (not ok) for anything else.
  die "Bad argument (or no argument) given to new" unless $ok;

  if($ok == 1) {
    # return a copy of the given Math::JS object
    my $ret = shift;
    return $ret;
  }

  my %h = ('val' => $val, 'type' => $classify{$ok});
  return bless(\%h, 'Math::JS');
}

########### + ##########
sub oload_add {
  die "Wrong number of arguments given to oload_add()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_add" unless $ok;

  my $ret1 = $_[0]->{val};

  return Math::JS->new($ret1 + $_[1]->{val})
    if $ok == 1;

  return Math::JS->new($ret1 + $_[1]);
}

########### * ##########
sub oload_mul {
  die "Wrong number of arguments given to oload_mul()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_mul" unless $ok;

  my $ret1 = $_[0]->{val};

  return Math::JS->new($ret1 * $_[1]->{val})
    if $ok == 1;

  return Math::JS->new($ret1 * $_[1]);
}

########### - ##########
sub oload_sub {
  die "Wrong number of arguments given to oload_sub()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_sub" unless $ok;

  my $third_arg = $_[2];

  my $ret0 = $_[0]->{val};

  if($ok == 1) {
    return Math::JS->new($ret0 - $_[1]->{val});
  }

  return Math::JS->new($_[1] - $ret0)
    if $third_arg;
  return Math::JS->new($ret0 - $_[1]);
}

########### / ##########
sub oload_div {
  die "Wrong number of arguments given to oload_div()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_div" unless $ok;

  my $third_arg = $_[2];
  my ($num, $den, $ret);

  if($ok == 1) {
    $num = $_[0]->{val};
    $den = $_[1]->{val};
  }
  elsif($third_arg) {
    $num = $_[1];
    $den = $_[0]->{val};
  }
  else {
    $num = $_[0]->{val};
    $den = $_[1];
  }

  if($den == 0) { $ret = $num < 0 ? _get_ninf() : _get_pinf() }
  else { $ret = $num / $den }
  return Math::JS->new($ret);
}

########### % ##########
sub oload_mod {
  die "Wrong number of arguments given to oload_mod()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_mod" unless $ok;

  my $third_arg = $_[2];
  my ($num, $den);

  if($ok == 1) {
    $num = $_[0]->{val};
    $den = $_[1]->{val};
  }
  elsif($third_arg) {
    $num = $_[1];
    $den = $_[0]->{val};
  }
  else {
    $num = $_[0]->{val};
    $den = $_[1];
  }

  return Math::JS->new(_get_nan())
    if(_infnan($num) || _isnan($den) || $den == 0);
  return Math::JS->new($num)
    if(_isinf($den) || $num == 0);
  return Math::JS->new(_fmod($num, $den));
}

########### ** ##########
sub oload_pow {
  die "Wrong number of arguments given to oload_pow()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_div" unless $ok;

  my $third_arg = $_[2];

  my $val0 = $_[0]->{val};

  if($ok == 1) {
    if($third_arg) {
      return Math::JS->new(_get_nan())
        if($_[1]->{val} < 0 && $val0 != int($val0));
      return Math::JS->new($_[1]->{val} ** $val0);
    }

    return Math::JS->new(_get_nan())
      if($val0 < 0 && $_[1]->{val} != int($_[1]->{val}));
    return Math::JS->new($val0 ** $_[1]->{val});
  }

  return Math::JS->new($_[1] ** $val0)
    if $third_arg;
  return Math::JS->new($val0 ** $_[1]);
}

########### & ##########
sub oload_and {
  die "Wrong number of arguments given to oload_and()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_and" unless $ok;

  my $val0 = $_[0]->{val};
  $val0 = reduce($val0)
    if $_[0]->{type} eq 'number';

  my $retval;

  if($ok == 1) {
    my $val1 = $_[1]->{val};
    $val1 = reduce($val1)
      if $_[1]->{type} eq 'number';

    $retval = ($val0 & 0xffffffff) & ($val1 & 0xffffffff);
    return Math::JS->new(unpack 'l', pack 'L', $retval);
  }

  my $val1 = $_[1];
  $val1 = reduce($val1)
    if $ok == 4;

  $retval = ($val0 & 0xffffffff) & ($val1 & 0xffffffff);
  return Math::JS->new(unpack 'l', pack 'L', $retval);
}

########### | ##########
sub oload_ior {
  die "Wrong number of arguments given to oload_ior()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_ior" unless $ok;

  my $val0 = $_[0]->{val};
  $val0 = reduce($val0)
    if $_[0]->{type} eq 'number';

  my $retval;

  if($ok == 1) {
    my $val1 = $_[1]->{val};
    $val1 = reduce($val1)
      if $_[1]->{type} eq 'number';

    $retval = ($val0 & 0xffffffff) | ($val1 & 0xffffffff);
    return Math::JS->new(unpack 'l', pack 'L', $retval);
  }

  my $val1 = $_[1];
  $val1 = reduce($val1)
    if $ok == 4;

  $retval = ($val0 & 0xffffffff) | ($val1 & 0xffffffff);
  return Math::JS->new(unpack 'l', pack 'L', $retval);
}

########### ^ ##########
sub oload_xor {
  die "Wrong number of arguments given to oload_xor()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_xor" unless $ok;

  my $val0 = $_[0]->{val};
  $val0 = reduce($val0)
    if $_[0]->{type} eq 'number';

  my $retval;

  if($ok == 1) {
    my $val1 = $_[1]->{val};
    $val1 = reduce($val1)
      if $_[1]->{type} eq 'number';

    $retval = ($val0 & 0xffffffff) ^ ($val1 & 0xffffffff);
    return Math::JS->new(unpack 'l', pack 'L', $retval);
  }

  my $val1 = $_[1];
  $val1 = reduce($val1)
    if $ok == 4;

  $retval = ($val0 & 0xffffffff) ^ ($val1 & 0xffffffff);
  return Math::JS->new(unpack 'l', pack 'L', $retval);
}

########### ~ ##########
sub oload_not {
  die "Wrong number of arguments given to oload_not()"
    if @_ > 3;

  my $val = $_[0]->{val};
  $val = reduce($val  )
    if $_[0]->{type} eq 'number';

  return Math::JS->new( MAX_ULONG - $val )
    if($val > MAX_SLONG);

  return Math::JS->new( -$val - 1);
}

########### ++ ##########
sub oload_inc {
  $_[0]->{val} += 1;
  # 'type' needs to be checked
  $_[0]->{type} = $classify{is_ok($_[0]->{val})};
}

########### -- ##########
sub oload_dec {
  $_[0]->{val} -= 1;
  # 'type' needs to be checked
  $_[0]->{type} = $classify{is_ok($_[0]->{val})};
}

########### "" ##########
sub oload_stringify {
  my $val = $_[0]->{val};
  # "l" is signed 32-bit integer; "L" is unsigned 32-bit integer.
  my $ret;
  if    ($_[0]->{type} eq 'sint32') { $ret = unpack("l", pack("L", $val)) }
  elsif ($_[0]->{type} eq 'uint32') { $ret = unpack("L", pack("L", $val)) }
  elsif (_isinf($val)) {
      $ret = $val > 0 ? 'Infinity' : '-Infinity';
  }
  elsif(_isnan($val)) {
     $ret = 'nan';
  }
  elsif ($val < 1e+21 && $val == int($val)) {
    $ret = sprintf "%.21g", $val;
  }
  else {
    if(USE_RYU) {
      $ret = Math::Ryu::fmtpy(Math::Ryu::d2s($val));
    }
    else {
      $ret = sprintf "%.17g", $val;
    }
 }
  return "$ret";
}

########### >= ##########
sub oload_gte {
  die "Wrong number of arguments given to oload_gte()"
    if @_ > 3;

  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);

  return 0 if !defined $cmp;
  return 1 if $cmp >= 0;
  return 0;
}

########### <= ##########
sub oload_lte {
  die "Wrong number of arguments given to oload_lte()"
    if @_ > 3;

  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);
  return 0 if !defined $cmp;
  return 1 if $cmp <= 0;
  return 0;
}

########### == ##########
sub oload_equiv {
  die "Wrong number of arguments given to oload_equiv()"
    if @_ > 3;

  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);

  return 0 if !defined $cmp;
  return 1 if $cmp == 0;
  return 0;
}

########### != ##########
sub oload_not_equiv {
  die "Wrong number of arguments given to oload_equiv()"
    if @_ > 3;

  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);

  return 1 if !defined($cmp);
  return 0 if $cmp == 0;
  return 1;
}

########### > ##########
sub oload_gt {
  die "Wrong number of arguments given to oload_gt()"
    if @_ > 3;

  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);

  return 0 if !defined $cmp;
  return 1 if $cmp > 0;
  return 0;
}

########### < ##########
sub oload_lt {
  die "Wrong number of arguments given to oload_lt()"
    if @_ > 3;

  my $cmp = oload_spaceship($_[0], $_[1], $_[2]);

  return 0 if !defined $cmp;
  return 1 if $cmp < 0;
  return 0;
}

########### <=> ##########
sub oload_spaceship {
  die "Wrong number of arguments given to oload_spaceship()"
    if @_ > 3;

  my $ok = is_ok($_[1]); # check that 2nd arg is suitable.
  die "Bad argument given to oload_spaceship" unless $ok;

  my $third_arg = $_[2];

  if($ok == 1) {

    if($third_arg) {
      return ($_[1]->{val} <=> $_[0]->{val});
    }
    return ($_[0]->{val} <=> $_[1]->{val});
  }

  my $second = $_[1];

  if($third_arg) {
     return ($second <=> $_[0]->{val});
  }
  return ($_[0]->{val} <=> $second);
}

########### << ##########
sub oload_lshift {
  die "Wrong number of arguments given to oload_lshift()"
    if @_ > 3;

  my $shift = abs(int $_[1]) % 32;
  $shift = 32 - $shift if ($_[1] < 0 && $shift);

  my $val = $_[0]->{val};
  $val = reduce($val)
    if $_[0]->{type} eq 'number';

  return Math::JS->new(unpack 'l', pack 'l', (($val & 0xffffffff) << $shift) );
}

########### >> ##########
sub oload_rshift {

  # From the javascript manual:
  # <quote>
  # Excess bits shifted off to the right are discarded, and copies of
  # the leftmost bit are shifted in from the left. This operation is
  # also called "sign-propagating right shift" or "arithmetic right
  # shift", because the sign of the resulting number is the same as
  # the sign of the first operand.
  # </quote>

  die "Wrong number of arguments given to oload_rshift()"
    if @_ > 3;

  my $shift = abs(int $_[1]) % 32;
  $shift = 32 - $shift if ($_[1] < 0 && $shift);
  my $type  = $_[0]->{type};

  my $val  = $_[0]->{val};

  if($type eq 'number') {
    $val = reduce($val);
    $type = $classify{is_ok($val)}; # Determine whether it reduced
                                    # to 'sint32' or 'uint32'.
  }

  if($type eq 'uint32' || ($type eq 'sint32' && $val < 0)) { # Highest order bit is set
    my $ior = 0xffffffff ^ ((1 << (32 - $shift)) - 1);
    my $val = unpack('l', pack 'L', $val) >> $shift;
    $val |= $ior;
    return Math::JS->new(unpack 'l', pack 'L', $val);
  }

  # Highest order bit is unset
  return Math::JS->new( ($val & 0xffffffff) >> ($_[1] % 32) );
}

########### >>> ##########
sub urs { # unsigned 32-bit right shift (JavaScript's '>>>' operator).
          # This function is not available via overloading, and is
          # exported only on request ie - use Math::JS qw(urs);

  die "Wrong number of arguments given to urs()"
    unless @_ == 2;

  # 1st argument must be a Math::JS object
  die "Bad first argument given to urs()"
    unless ref($_[0]) eq 'Math::JS';

  # 2nd arg must be a perl number (IV or NV);
  die "Bad second arg given to urs()"
   unless is_ok($_[1]) > 1;

  my $shift = abs(int $_[1]) % 32;
  $shift = 32 - $shift if ($_[1] < 0 && $shift);
  my $type  = $_[0]->{type};

  my $val  = $_[0]->{val};

  if($type eq 'number') {
    $val = reduce($val);
    # $val is either type 'uint3' or 'sint32' ... doesn't matter here.
  }

  $val = unpack('L', pack 'L', $val) >> $shift;
  return Math::JS->new($val);
}

###########################
###########################

sub reduce {
  # Reduce values that are greater than MAX_ULONG or
  # less than MIN_SLONG to their appropriate value
  # for use in bit manipulation operations, following
  # the procedure used by javascipt.

  my $mul = 1;
  my $big = shift;

  return 0 if _infnan($big);

  my $integer = int($big);
  return $integer
    if($integer <= MAX_ULONG && $integer >= MIN_SLONG);

  if($big < 0) {
    $mul = -1;
    $big = -$big;
  }
  my $max = shift;

  $big -= int($big / (2 ** 32)) * (2 ** 32);
  my $ret = unpack 'l', pack 'l', $big;
  return $ret * $mul;
}

sub is_ok {
  my $val = shift;
  my $ret = _is_ok($val);

  return $ret if $ret < 2;

  return 4 if $val != int($val); # Handles NaN
  return 4 if ($val > 4294967295 || $val < -2147483648); # Handles +Inf and -Inf
  return 2 if $val >= 2147483648;
  return 3; # This is the only remaining possibility
}

sub _infnan {
  my $val = shift;
  my $inf = 2 ** 1500;
  return 1 if ($val == $inf || $val == -$inf || $val != $val);
  return 0;
}

sub _isnan {
  my $val = shift;
  return 1 if $val != $val;
  return 0;
}

sub _isinf {
  my $val = shift;
  return 1 if abs($val) == 2 ** 1500;
  return 0;
}

sub _get_pinf { # Return Math::JS object with a value of +Inf
  return 2 ** 1500;
}

sub _get_ninf { # Return Math::JS object with a value of -Inf
  return -(2 ** 1500);
}

sub _get_nan {
  my $inf = 2 ** 1500;
  return ($inf / $inf);
}

1;

__END__

