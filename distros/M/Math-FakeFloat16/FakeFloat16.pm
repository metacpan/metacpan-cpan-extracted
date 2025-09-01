use strict;
use warnings;
package Math::FakeFloat16;
use Math::MPFR qw(:mpfr);

use constant f16_EMIN     => -23;
use constant f16_EMAX     =>  16;
use constant f16_MANTBITS =>  11;
use constant MPFR_PREC_MIN => Math::MPFR::MPFR_PREC_MIN;


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

'sqrt' => \&oload_sqrt,
'exp'  => \&oload_exp,
'log'  => \&oload_log,
'int'  => \&oload_int,
'!'    => \&oload_not,
'bool' => \&oload_bool,
;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

$Math::FakeFloat16::VERSION = '0.01';
Math::FakeFloat16->DynaLoader::bootstrap($Math::FakeFloat16::VERSION);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking


my @tagged = qw( is_f16_nan is_f16_inf is_f16_zero f16_set_nan f16_set_inf f16_set_zero
                 f16_set
                 f16_nextabove f16_nextbelow
                 unpack_f16_hex
                 f16_EMIN f16_EMAX f16_MANTBITS
                 f16_to_NV f16_to_MPFR f16_to_PV
               );

@Math::FakeFloat16::EXPORT = ();
@Math::FakeFloat16::EXPORT_OK = @tagged;
%Math::FakeFloat16::EXPORT_TAGS = (all => \@tagged);


%Math::FakeFloat16::handler = (1 => sub {print "OK: 1\n"},
               2  => sub {return _fromIV(shift)},
               4  => sub {return _fromPV(shift)},
               3  => sub {return _fromNV(shift)},
               5  => sub {return _fromMPFR(shift)},
               6  => sub {return _fromGMPf(shift)},
               7  => sub {return _fromGMPq(shift)},

               31 => sub {return _fromFloat16(shift)},
               );

$Math::FakeFloat16::f16_DENORM_MIN = Math::FakeFloat16->new(2) ** (f16_EMIN - 1);                  # 5.9605e-8
$Math::FakeFloat16::f16_DENORM_MAX = Math::FakeFloat16->new(_get_denorm_max());                    # 6.0976e-5
$Math::FakeFloat16::f16_NORM_MIN   = Math::FakeFloat16->new(2) ** (f16_EMIN + (f16_MANTBITS - 2)); # 6.1035e-5
$Math::FakeFloat16::f16_NORM_MAX   = Math::FakeFloat16->new(_get_norm_max());                      # 6.5504e4

sub new {
   shift if (@_ > 0 && !ref($_[0]) && _itsa($_[0]) == 4 && $_[0] eq "Math::FakeFloat16");
   if(!@_) {
     my $ret = Rmpfr_init2(f16_MANTBITS);
     return bless(\$ret);
   }
   die "Too many args given to new()" if @_ > 1;
   my $itsa = _itsa($_[0]);
   if($itsa) {
     return _fromIV($_[0]) if($itsa == 2);
     return _fromFloat16($_[0]) if ($itsa == 31);
     my $ret = subnormalize_generic($_[0], f16_EMIN, f16_EMAX, f16_MANTBITS);
     return bless(\$ret);
   #  my $coderef = $Math::FakeFloat16::handler{$itsa};
   #  return $coderef->($_[0]);
    }
   die "Unrecognized 1st argument passed to new() function";
}

sub _fromPV {
  my $pv = shift;
  my $ret = subnormalize_generic($pv, f16_EMIN, f16_EMAX, f16_MANTBITS);
  return bless(\$ret);
}

sub _fromIV {
  my $iv = shift;
  my $ret = Rmpfr_init2(f16_MANTBITS);
  Rmpfr_set_IV($ret, $iv, MPFR_RNDN);
  # Make appropriate correction if abs($ret) > 65504
  if   ($ret >  65504) { Rmpfr_set_inf($ret, 1)  }
  elsif($ret < -65504) { Rmpfr_set_inf($ret, -1) }
  return bless(\$ret);
}

sub _fromNV {
  my $nv = shift;
  my $ret = subnormalize_generic($nv, f16_EMIN, f16_EMAX, f16_MANTBITS);
  return bless(\$ret);
}

sub _fromMPFR {
  my $mpfr = shift;
  my $ret = subnormalize_generic($mpfr, f16_EMIN, f16_EMAX, f16_MANTBITS);
  return bless(\$ret);
}

sub _fromGMPf {
  my $mpf = shift;
  my $ret = subnormalize_generic($mpf, f16_EMIN, f16_EMAX, f16_MANTBITS);
  return bless(\$ret);
}

sub _fromGMPq {
  my $mpq = shift;
  my $ret = subnormalize_generic($mpq, f16_EMIN, f16_EMAX, f16_MANTBITS);
  return bless(\$ret);
}

sub _fromFloat16 { # ie from Math::FakeFloat16 object
  my $f16 = shift;
  my $ret = Rmpfr_init2(f16_MANTBITS);
  my $inex = Rmpfr_set($ret, $$f16, MPFR_RNDN);
  die "Error in assignment" if $inex;
  return bless(\$ret);
}

sub f16_to_NV {
  # For compatibility with Math::Float16
  return Rmpfr_get_NV(${$_[0]}, MPFR_RNDN);
}

sub f16_to_MPFR {
  # For compatibility with Math::Float16
  my $ret = Rmpfr_init2(11);
  Rmpfr_set($ret, ${$_[0]}, MPFR_RNDN);
  return $ret;
}

sub is_f16_nan {
  return 1 if Rmpfr_nan_p(${$_[0]});
  return 0;
}

sub is_f16_inf {
  if( Rmpfr_inf_p(${$_[0]}) ) {
    return 1 if ${$_[0]} > 0;
    return -1;
  }
  return 0;
}

sub is_f16_zero {
  if ( Rmpfr_zero_p(${$_[0]}) ) {
    return -1 if Rmpfr_signbit( ${$_[0]} );
    return 1;
  }
  return 0;
}

sub f16_set_nan {
  Rmpfr_set_nan(${$_[0]});
}

sub f16_set_inf {
    Rmpfr_set_inf(${$_[0]}, $_[1]);
}

sub f16_set_zero {
    Rmpfr_set_zero(${$_[0]}, $_[1]);
}

sub f16_set {
   die "f16_set expects to receive precisely 2 arguments" if @_ != 2;
   my $coderef = $Math::FakeFloat16::handler{_itsa($_[1])};
   my $arg = $coderef->($_[1]);
   my ($emin_orig, $emax_orig) = (Rmpfr_get_emin(), Rmpfr_get_emax());
   SET_EMIN_EMAX(f16_EMIN, f16_EMAX);
   my $inex = Rmpfr_set(${$_[0]}, $$arg, MPFR_RNDN);
   Rmpfr_subnormalize(${$_[0]}, $inex, MPFR_RNDN);
   RESET_EMIN_EMAX($emin_orig, $emax_orig);
}

sub oload_add {
   my $ret = Rmpfr_init2(f16_MANTBITS);
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_add() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   my ($emin_orig, $emax_orig) = (Rmpfr_get_emin(), Rmpfr_get_emax());
   SET_EMIN_EMAX(f16_EMIN, f16_EMAX);
   my $inex = Rmpfr_add($ret, ${$_[0]}, $$arg, MPFR_RNDN);
   Rmpfr_subnormalize($ret, $inex, MPFR_RNDN);
   RESET_EMIN_EMAX($emin_orig, $emax_orig);
   return bless(\$ret);
}

sub oload_mul {
   my $ret = Rmpfr_init2(f16_MANTBITS);
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_mul() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   my ($emin_orig, $emax_orig) = (Rmpfr_get_emin(), Rmpfr_get_emax());
   SET_EMIN_EMAX(f16_EMIN, f16_EMAX);
   my $inex = Rmpfr_mul($ret, ${$_[0]}, $$arg, MPFR_RNDN);
   Rmpfr_subnormalize($ret, $inex, MPFR_RNDN);
   RESET_EMIN_EMAX($emin_orig, $emax_orig);
   return bless(\$ret);
}

sub oload_sub {
   my $ret = Rmpfr_init2(f16_MANTBITS);
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_sub() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   my ($emin_orig, $emax_orig) = (Rmpfr_get_emin(), Rmpfr_get_emax());
   SET_EMIN_EMAX(f16_EMIN, f16_EMAX);
   my $inex;
   if($_[2]) { $inex = Rmpfr_sub($ret, $$arg, ${$_[0]}, MPFR_RNDN) }
   else      { $inex = Rmpfr_sub($ret, ${$_[0]}, $$arg, MPFR_RNDN) }
   Rmpfr_subnormalize($ret, $inex, MPFR_RNDN);
   RESET_EMIN_EMAX($emin_orig, $emax_orig);
   return bless(\$ret);
}

sub oload_div {
   my $ret = Rmpfr_init2(f16_MANTBITS);
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_div() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   my ($emin_orig, $emax_orig) = (Rmpfr_get_emin(), Rmpfr_get_emax());
   SET_EMIN_EMAX(f16_EMIN, f16_EMAX);
   my $inex;
   if($_[2]) { $inex = Rmpfr_div($ret, $$arg, ${$_[0]}, MPFR_RNDN) }
   else      { $inex = Rmpfr_div($ret, ${$_[0]}, $$arg, MPFR_RNDN) }
   Rmpfr_subnormalize($ret, $inex, MPFR_RNDN);
   RESET_EMIN_EMAX($emin_orig, $emax_orig);
   return bless(\$ret);
}

sub oload_pow {
   my $ret = Rmpfr_init2(f16_MANTBITS);
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_pow() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   my ($emin_orig, $emax_orig) = (Rmpfr_get_emin(), Rmpfr_get_emax());
   SET_EMIN_EMAX(f16_EMIN, f16_EMAX);
   my $inex;
   if($_[2]) { $inex = Rmpfr_pow($ret, $$arg, ${$_[0]}, MPFR_RNDN) }
   else      { $inex = Rmpfr_pow($ret, ${$_[0]}, $$arg, MPFR_RNDN) }
   Rmpfr_subnormalize($ret, $inex, MPFR_RNDN);
   RESET_EMIN_EMAX($emin_orig, $emax_orig);
   return bless(\$ret);
}

sub oload_fmod {
   my $ret = Rmpfr_init2(f16_MANTBITS);
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_fmod() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   my ($emin_orig, $emax_orig) = (Rmpfr_get_emin(), Rmpfr_get_emax());
   SET_EMIN_EMAX(f16_EMIN, f16_EMAX);
   my $inex;
   if($_[2]) { $inex = Rmpfr_fmod($ret, $$arg, ${$_[0]}, MPFR_RNDN) }
   else      { $inex = Rmpfr_fmod($ret, ${$_[0]}, $$arg, MPFR_RNDN) }
   Rmpfr_subnormalize($ret, $inex, MPFR_RNDN);
   RESET_EMIN_EMAX($emin_orig, $emax_orig);
   return bless(\$ret);
}

sub oload_sqrt {
   my $ret = Rmpfr_init2(f16_MANTBITS);
   my ($emin_orig, $emax_orig) = (Rmpfr_get_emin(), Rmpfr_get_emax());
   SET_EMIN_EMAX(f16_EMIN, f16_EMAX);
   my $inex = Rmpfr_sqrt($ret, ${$_[0]}, MPFR_RNDN);
   Rmpfr_subnormalize($ret, $inex, MPFR_RNDN);
   RESET_EMIN_EMAX($emin_orig, $emax_orig);
   return bless(\$ret);
}

sub oload_log {
   my $ret = Rmpfr_init2(f16_MANTBITS);
   my ($emin_orig, $emax_orig) = (Rmpfr_get_emin(), Rmpfr_get_emax());
   SET_EMIN_EMAX(f16_EMIN, f16_EMAX);
   my $inex = Rmpfr_log($ret, ${$_[0]}, MPFR_RNDN);
   Rmpfr_subnormalize($ret, $inex, MPFR_RNDN);
   RESET_EMIN_EMAX($emin_orig, $emax_orig);
   return bless(\$ret);
}

sub oload_exp {
   my $ret = Rmpfr_init2(f16_MANTBITS);
   my ($emin_orig, $emax_orig) = (Rmpfr_get_emin(), Rmpfr_get_emax());
   SET_EMIN_EMAX(f16_EMIN, f16_EMAX);
   my $inex = Rmpfr_exp($ret, ${$_[0]}, MPFR_RNDN);
   Rmpfr_subnormalize($ret, $inex, MPFR_RNDN);
   RESET_EMIN_EMAX($emin_orig, $emax_orig);
   return bless(\$ret);
}

sub oload_int {
   my $ret = Rmpfr_init2(f16_MANTBITS);
   Rmpfr_trunc($ret, ${$_[0]});
   return bless(\$ret);
}

sub oload_abs {
  return $_[0] * -1 if $_[0] < 0;
  return $_[0];
}

sub oload_not {
  return 1 if( Rmpfr_nan_p(${$_[0]}) || Rmpfr_zero_p(${$_[0]}) );
  return 0;
}

sub oload_bool {
  return 0 if( Rmpfr_nan_p(${$_[0]}) || Rmpfr_zero_p(${$_[0]}) );
  return 1;
}

sub oload_equiv {
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_equiv() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   return 0 if( Rmpfr_nan_p(${$_[0]}) || Rmpfr_nan_p($$arg) );
   return 0 if Rmpfr_cmp(${$_[0]}, $$arg);
   return 1;
}

sub oload_not_equiv {
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_not_equiv() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   return 1 if( Rmpfr_nan_p(${$_[0]}) || Rmpfr_nan_p($$arg) );
   return 1 if Rmpfr_cmp(${$_[0]}, $$arg);
   return 0;
}

sub oload_gt {
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_gt() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   return 0 if( Rmpfr_nan_p(${$_[0]}) || Rmpfr_nan_p($$arg) );
   if($_[2]) {
     return 1 if Rmpfr_cmp($$arg, ${$_[0]}) > 0;
     return 0;
   }
   return 1 if Rmpfr_cmp(${$_[0]}, $$arg) > 0;
   return 0;
}

sub oload_gte {
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_gte() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   return 0 if( Rmpfr_nan_p(${$_[0]}) || Rmpfr_nan_p($$arg) );
   if($_[2]) {
     return 1 if Rmpfr_cmp($$arg, ${$_[0]}) >= 0;
     return 0;
   }
   return 1 if Rmpfr_cmp(${$_[0]}, $$arg) >= 0;
   return 0;
}

sub oload_lt {
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_lt() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   return 0 if( Rmpfr_nan_p(${$_[0]}) || Rmpfr_nan_p($$arg) );
   if($_[2]) {
     return 1 if Rmpfr_cmp($$arg, ${$_[0]}) < 0;
     return 0;
   }
   return 1 if Rmpfr_cmp(${$_[0]}, $$arg) < 0;
   return 0;
}

sub oload_lte {
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_lte() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   return 0 if( Rmpfr_nan_p(${$_[0]}) || Rmpfr_nan_p($$arg) );
   if($_[2]) {
     return 1 if Rmpfr_cmp($$arg, ${$_[0]}) <= 0;
     return 0;
   }
   return 1 if Rmpfr_cmp(${$_[0]}, $$arg) <= 0;
   return 0;
}


sub oload_spaceship {
   my $itsa = _itsa($_[1]);
   my $coderef = $Math::FakeFloat16::handler{$itsa};
   die "Unrecognized 2nd argument passed to oload_spaceship() function"
     if ($itsa != 31 && ($itsa < 2 || $itsa > 4));
   my $arg = $coderef->($_[1]);
   return undef if(Rmpfr_nan_p(${$_[0]}) || Rmpfr_nan_p($$arg));
   my $ret = Rmpfr_cmp(${$_[0]}, $$arg);
   $ret = 1 if $ret > 0;
   $ret = -1 if $ret < 0;
   $ret *= -1 if $_[2];
   return $ret;
}

sub oload_interp {
   my $ret = Math::MPFR::Rmpfr_get_str(${$_[0]}, 10, 0, MPFR_RNDN);
   $ret =~ s/\@//g;
   return $ret;
}

sub f16_nextabove {
  #if(Rmpfr_zero_p(${$_[0]})) {
  #  f16_set($_[0], $Math::FakeFloat16::f16_DENORM_MIN);
  #}
  if($_[0] == $Math::FakeFloat16::f16_NORM_MAX) {
    Rmpfr_set_inf(${$_[0]}, 1);
  }
  elsif(is_f16_inf($_[0]) == -1) {
    f16_set($_[0], -$Math::FakeFloat16::f16_NORM_MAX);
  }
  elsif($_[0] < $Math::FakeFloat16::f16_NORM_MIN && $_[0] >= -$Math::FakeFloat16::f16_NORM_MIN ) {
    $_[0] += $Math::FakeFloat16::f16_DENORM_MIN;
    f16_set_zero($_[0], -1) if is_f16_zero($_[0]);
  }
  else {
    Rmpfr_nextabove(${$_[0]});
  }
}

sub f16_nextbelow {
  #if(Rmpfr_zero_p(${$_[0]})) {
  #  f16_set($_[0], -$Math::FakeFloat16::f16_DENORM_MIN);
  #}
  if($_[0] == -$Math::FakeFloat16::f16_NORM_MAX) {
    Rmpfr_set_inf(${$_[0]}, -1);
  }
  elsif(is_f16_inf( $_[0] ) == 1) {
    f16_set($_[0], $Math::FakeFloat16::f16_NORM_MAX);
  }
  elsif($_[0] <= $Math::FakeFloat16::f16_NORM_MIN && $_[0] > -$Math::FakeFloat16::f16_NORM_MIN ) {
   $_[0] -= $Math::FakeFloat16::f16_DENORM_MIN;
  }
  else {
    Rmpfr_nextbelow( ${$_[0]} );
  }
}

sub unpack_f16_hex {
  if(MPFR_PREC_MIN > 1) {
    warn " The unpack_f16_hex() function is disabled because the mpfr library\n",
         " against which Math::MPFR was built does not support a precision of 1.\n";

    die  " Please rebuild Math::MPFR against a modern mpfr library (v4.2.0 or later)\n";
  }

  die "Math::FakeFloat16::unpack_f16_hex() accepts only a Math::FakeFloat16 object as its argument"
    unless ref($_[0]) eq "Math::FakeFloat16";
  return _unpack_irregular($_[0]) unless Rmpfr_regular_p(${$_[0]});

  # This sub will have already returned
  # if $_[0] is Inf, NaN or Zero.

  if(Rmpfr_get_exp(${$_[0]}) < -12) { # ${$_[0]} < 1.2207e-4
    my $prefix = '0';
    my $count = int( (23 + Rmpfr_get_exp(${$_[0]})) / 4 ) + 1;
    my @res = Rmpfr_deref2(${$_[0]}, 16, $count, MPFR_RNDN);
    $prefix ='8' if $res[0] =~ s/\-//;
    $res[0] = '0' . $res[0] while length($res[0]) < 3;
    return $prefix . uc($res[0]);
  }

  my $signbit = '0';
  my @res = Rmpfr_deref2(${$_[0]}, 2, 11, MPFR_RNDD);
  $signbit ='1' if $res[0] =~ s/\-//;
  my $exp = $res[1] + 14; # 14 == 15 - 1;
  my $expstr = sprintf "%b", $exp;
  $expstr = '0' . $expstr while length($expstr) < 5;
  my $manstr = substr($res[0], -10, 10);
  my $to_pack = $signbit . $expstr . $manstr;
  return uc(unpack "H4", pack("B16", $to_pack));
}

sub _unpack_irregular {
  my $ret;
  my $is_type = is_f16_nan($_[0]);
  return 'FE00' if $is_type;

  $is_type = is_f16_inf($_[0]);
  if($is_type) {
    $ret = '7C00';
    $ret = 'FC00' if $is_type == -1;
    return $ret
  }

  $is_type = is_f16_zero($_[0]);
  if($is_type) {
    $ret = '0000';
    $ret = '8000' if $is_type == -1;
    return $ret
  }

  die "Unrecognized type passed to _unpack_irregular()";
}

sub _get_norm_max {
  my $ret = 0;
  for my $p(1 .. f16_MANTBITS) { $ret += 2 ** (f16_EMAX - $p) }
  return $ret;
}

sub _get_denorm_max {
  my $ret = 0;
  my $max = -(f16_EMIN - 1);
  my $min = $max - (f16_MANTBITS - 2);
  for my $p($min .. $max) { $ret += 2 ** -$p }
  return $ret;
}

############################
############################

sub SET_EMIN_EMAX {
  Rmpfr_set_emin($_[0]);
  Rmpfr_set_emax($_[1]);
}

sub RESET_EMIN_EMAX {
  Rmpfr_set_emin($_[0]);
  Rmpfr_set_emax($_[1]);
}
1;

__END__
