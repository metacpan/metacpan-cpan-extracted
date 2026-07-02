use strict;
use warnings;
package Math::Float32;

use constant flt_EMIN     => -148;
use constant flt_EMAX     =>  128;
use constant flt_MANTBITS =>    24;


use overload
'+'  => \&oload_add,
'-'  => \&oload_sub,
'*'  => \&oload_mul,
'/'  => \&oload_div,
'%'  => \&oload_fmod,
'**' => \&oload_pow,

'=='  => \&oload_equiv,
'!='  => \&oload_not_equiv,
'>'   => \&oload_gt,
'>='  => \&oload_gte,
'<'   => \&oload_lt,
'<='  => \&oload_lte,
'<=>' => \&oload_spaceship,

'abs'  => \&oload_abs,
'""'   => \&oload_interp,
'sqrt' => \&_oload_sqrt,
'exp'  => \&_oload_exp,
'log'  => \&_oload_log,
'int'  => \&_oload_int,
'!'    => \&_oload_not,
'bool' => \&_oload_bool,
;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

our $VERSION = '0.03';
Math::Float32->DynaLoader::bootstrap($VERSION);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking



my @tagged = qw( flt_to_NV
                 is_flt_nan is_flt_inf is_flt_zero flt_set_nan flt_set_inf flt_set_zero
                 flt_signbit
                 flt_set
                 flt_nextabove flt_nextbelow
                 unpack_flt_hex pack_flt_hex
                 flt_EMIN flt_EMAX flt_MANTBITS
               );

@Math::Float32::EXPORT = ();
@Math::Float32::EXPORT_OK = @tagged;
%Math::Float32::EXPORT_TAGS = (all => \@tagged);


%Math::Float32::handler = (1 => sub {print "OK: 1\n"},
               2  => sub {return _fromIV(shift)},
               4  => sub {return _fromPV(shift)},
               3  => sub {return _fromNV(shift)},

               22 => sub {return _fromFloat32(shift)},
               );

$Math::Float32::flt_DENORM_MIN = Math::Float32->new(2) ** (flt_EMIN - 1);                  # 1.40129846e-45
$Math::Float32::flt_DENORM_MAX = Math::Float32->new(_get_denorm_max());                    # 1.17549421e-38
$Math::Float32::flt_NORM_MIN   = Math::Float32->new(2) ** (flt_EMIN + (flt_MANTBITS - 2)); # 1.17549435e-38
$Math::Float32::flt_NORM_MAX   = Math::Float32->new(_get_norm_max());                      # 3.402823467e+38


# Skip signed zero tests in the test suite if C's strtof()
# does not handle '-0' correctly.
my $signed_zero_tester = Math::Float32->new('-0.0');
$Math::Float32::broken_signed_zero = "$signed_zero_tester" =~ /^\-/ ? 0 : 1;

sub new {
   shift if (@_ > 0 && !ref($_[0]) && _itsa($_[0]) == 4 && $_[0] eq "Math::Float32");
   if(!@_) { return _fromPV('NaN');}
   die "Too many args given to new()" if @_ > 1;
   my $itsa = _itsa($_[0]);
   if($itsa) {
     my $coderef = $Math::Float32::handler{$itsa};
     return $coderef->(bin2hex($_[0]))
       if($itsa == 4 && $_[0] =~ /^(\s+)?[\-\+]?0b/i);
     return $coderef->($_[0]);
   }
   die "Unrecognized 1st argument passed to new() function";
}

sub flt_set {
   die "flt_set expects to receive precisely 2 arguments" if @_ != 2;
   my $itsa = _itsa($_[1]);
   if($itsa == 22) { _flt_set(@_) }
   else {
     my $coderef = $Math::Float32::handler{$itsa};
     _flt_set( $_[0], $coderef->($_[1]));
   }
}

sub oload_add {
   my $itsa = _itsa($_[1]);
   return _oload_add(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_add($_[0], $coderef->(bin2hex($_[1])), 0)
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_add($_[0], $coderef->($_[1]), 0);
   }
   return Math::Bfloat16::oload_add($_[1], $_[0], $_[2]) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_add() function";
}

sub oload_mul {
   my $itsa = _itsa($_[1]);
   return _oload_mul(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_mul($_[0], $coderef->(bin2hex($_[1])), 0)
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_mul($_[0], $coderef->($_[1]), 0);
   }
   return Math::Bfloat16::oload_mul($_[1], $_[0], $_[2]) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_mul() function";
}

sub oload_sub {
   my $itsa = _itsa($_[1]);
   return _oload_sub(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_sub($_[0], $coderef->(bin2hex($_[1])), $_[2])
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_sub($_[0], $coderef->($_[1]), $_[2]);
   }
   return Math::Bfloat16::oload_sub($_[1], $_[0], 1) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_sub() function";
}

sub oload_div {
   my $itsa = _itsa($_[1]);
   return _oload_div(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_div($_[0], $coderef->(bin2hex($_[1])), $_[2])
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_div($_[0], $coderef->($_[1]), $_[2]);
   }
   return Math::Bfloat16::oload_div($_[1], $_[0], 1) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_div() function";
}

sub oload_fmod {
   my $itsa = _itsa($_[1]);
   return _oload_fmod(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_fmod($_[0], $coderef->(bin2hex($_[1])), $_[2])
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_fmod($_[0], $coderef->($_[1]), $_[2]);
   }
   return Math::Bfloat16::oload_fmod($_[1], $_[0], 1) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_fmod() function";
}

sub oload_pow {
   my $itsa = _itsa($_[1]);
   return _oload_pow(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_pow($_[0], $coderef->(bin2hex($_[1])), $_[2])
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_pow($_[0], $coderef->($_[1]), $_[2]);
   }
   return Math::Bfloat16::oload_pow($_[1], $_[0], 1) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_pow() function";
}

sub oload_abs {
  return $_[0] * -1 if $_[0] < 0;
  return $_[0];
}

sub oload_equiv {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_equiv($_[0], $coderef->(bin2hex($_[1])), 0)
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_equiv($_[0], $coderef->($_[1]), 0);
   }
   return Math::Bfloat16::oload_equiv($_[1], $_[0], 0) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_equiv() function";
}

sub oload_not_equiv {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_not_equiv($_[0], $coderef->(bin2hex($_[1])), 0)
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_not_equiv($_[0], $coderef->($_[1]), 0);
   }
   return Math::Bfloat16::oload_not_equiv($_[1], $_[0], 0) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_not_equiv() function";
}

sub oload_gt {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_gt($_[0], $coderef->(bin2hex($_[1])), $_[2])
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_gt($_[0], $coderef->($_[1]), $_[2]);
   }
   return Math::Bfloat16::oload_lt($_[1], $_[0], 0) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_gt() function";
}

sub oload_gte {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_gte($_[0], $coderef->(bin2hex($_[1])), $_[2])
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_gte($_[0], $coderef->($_[1]), $_[2]);
   }
   return Math::Bfloat16::oload_lte($_[1], $_[0], 0) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_gte() function";
}

sub oload_lt {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_lt($_[0], $coderef->(bin2hex($_[1])), $_[2])
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_lt($_[0], $coderef->($_[1]), $_[2]);
   }
   return Math::Bfloat16::oload_gt($_[1], $_[0], 0) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_lt() function";
}

sub oload_lte {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_lte($_[0], $coderef->(bin2hex($_[1])), $_[2])
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_lte($_[0], $coderef->($_[1]), $_[2]);
   }
   return Math::Bfloat16::oload_gte($_[1], $_[0], 0) if $itsa == 20;
   die "Unrecognized 2nd argument passed to oload_lte() function";
}

sub oload_spaceship {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_spaceship($_[0], $coderef->(bin2hex($_[1])), $_[2])
       if($itsa == 4 && $_[1] =~ /^(\s+)?[\-\+]?0b/i);
     return _oload_spaceship($_[0], $coderef->($_[1]), $_[2]);
   }
   if($itsa == 20) {
     my $ret = Math::Bfloat16::oload_spaceship($_[1], $_[0], 0);
     return undef if !defined($ret);
     return $ret * -1;
   }
   die "Unrecognized 2nd argument passed to oload_spaceship() function";
}

sub oload_interp {
   return sprintf("%.9g", flt_to_NV($_[0]));
}

sub is_flt_zero {
    if($_[0] == 0) {
      return -1 if flt_signbit($_[0]);
      return 1;
    }
    return 0;
}

sub flt_signbit {
  return 1 if hex(substr(unpack_flt_hex($_[0]), 0, 1)) >= 8;
  return 0;
}

sub unpack_flt_hex {
  my @ret = _unpack_flt_hex($_[0]);
  return join('', @ret);
}

sub pack_flt_hex {
  my $arg = shift;
  my $is_neg = '';
  die "Invalid argument ($arg) given to pack_flt_hex"
    if(length($arg) != 8 || $arg =~ /[^0-9a-fA-F]/);

  my $binstr = unpack 'B32', pack 'H8', $arg;
  $is_neg = '-' if substr($binstr, 0, 1) eq '1';
  my $power = oct('0b' .substr($binstr,1, 8)) - 127;
  my $prefix = '1';
  if($power < -126) { # Subnormal
    $power = -126;
    $prefix = '0';
  }

  # Unfortunately, C's strtof function (which is used by
  # Math::Float32::new() does not accommodate binary strings,
  # so we have to convert the binary string to its hex
  # equivalent before passing it to new().
  $power -= 23;
  my $hexstring = '0x' . lc(unpack 'H6', pack('B24', $prefix . substr($binstr,9, 23)));
  return Math::Float32->new($is_neg . $hexstring . "p$power");
}

sub bin2hex {
  my $arg = shift; # It is assumed that $arg =~ /^(\s+)?[\-\+]?0b/i
  $arg =~ s/^\s+//;
  die "Illegal character(s) in arg ($arg) passed to bin2hex"
    if $arg =~ /[^0-9peb\.\-\+]/i;
  my($is_neg, $point_index) = ('');
  $is_neg = '-' if $arg =~ /^\-/;

  $arg =~ s/^[\-\+]?0b//i;

  # Remove all leading zeroes, but retain a leading
  # '0' if (and only if) it is succeeded by a '.'.
  substr($arg, 0, 1, '') while $arg =~ /^0[^\.]/;

  $arg =~ s/e/p/i;
  my @args = split /p/i, $arg;

  { # Start no warnings 'uninitialized'

    no warnings 'uninitialized'; # $args[0] might be uninitialized
    # Remove trailing zeroes from beyond the
    # radix point and remove a trailing '.' (if present)
    $args[0] =~ s/0+$// if $args[0] =~ /\./;
    $args[0] =~ s/\.$//;

    $args[1] //= 0;
    $point_index = index($args[0], '.');
    if ($args[0] =~ s/^0\.//) {
      $args[1]--;
      while($args[0] =~ /^0/) {
         substr($args[0], 0, 1, '');
         $args[1]--;
      }
    }
    return $is_neg . '0x0p0' if $args[0] !~ /1/;

  } # End no warnings 'uninitialized'

  $args[0] =~ s/\.//;

  my $pad = length($args[0]) % 4;
  if($pad) {
    $pad = 4 - $pad;
    $args[0] .= '0' x $pad;
    $args[1] -= $pad if $point_index < 0; # The string did not contain a radix point
  }

  my $B_quantity = length($args[0]);
  my $H_quantity = $B_quantity / 4;

  # It may well be that the case (ie "lower" or "upper") makes no difference.
  # Out of caution, I'll specify lower case and use the (matching) '0x' prefix.
  my $mantissa = lc(unpack "H$H_quantity", pack "B$B_quantity", $args[0]);

  return $is_neg . '0x' . $mantissa . "p$args[1]" if $point_index < 0;
  my $exponent = $point_index - $B_quantity + $args[1];
  return $is_neg . '0x' . $mantissa . "p$exponent";
}

sub _get_norm_max {
  my $ret = 0;
  for my $p(1 .. flt_MANTBITS) { $ret += 2 ** (flt_EMAX - $p) }
  return $ret;
}

sub _get_denorm_max {
  my $ret = 0;
  my $max = -(flt_EMIN - 1);
  my $min = $max - (flt_MANTBITS - 2);
  for my $p($min .. $max) { $ret += 2 ** -$p }
  return $ret;
}

1;

__END__
