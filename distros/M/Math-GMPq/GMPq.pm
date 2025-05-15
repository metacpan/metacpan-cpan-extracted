    package Math::GMPq;
    use strict;
    use warnings;
    use Math::GMPq::Random;
    use Math::GMPq::V;
    require Exporter;
    *import = \&Exporter::import;
    require DynaLoader;

    use constant _UOK_T         => 1;
    use constant _IOK_T         => 2;
    use constant _NOK_T         => 3;
    use constant _POK_T         => 4;
    use constant _MATH_MPFR_T   => 5;
    use constant _MATH_GMPf_T   => 6;
    use constant _MATH_GMPq_T   => 7;
    use constant _MATH_GMPz_T   => 8;
    use constant _MATH_GMP_T    => 9;
    use constant _MATH_MPC_T    => 10;
    use constant GMPQ_PV_NV_BUG => Math::GMPq::Random::_has_pv_nv_bug();
    use constant GMPQ_WIN32_FMT_BUG => Math::GMPq::V::_buggy();

use subs qw( __GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL
             __GNU_MP_RELEASE __GMP_CC __GMP_CFLAGS GMP_LIMB_BITS GMP_NAIL_BITS);

use overload
    '++'   => \&overload_inc,
    '--'   => \&overload_dec,
    '+'    => \&overload_add,
    '-'    => \&overload_sub,
    '*'    => \&overload_mul,
    '/'    => \&overload_div,
    '**'   => \&overload_pow,
    '+='   => \&overload_add_eq,
    '-='   => \&overload_sub_eq,
    '*='   => \&overload_mul_eq,
    '/='   => \&overload_div_eq,
    '%'    => \&overload_fmod,
    '%='   => \&overload_fmod_eq,
    '**='  => \&overload_pow_eq,
    '""'   => \&overload_string,
    '0+'   => \&overload_num,
    '>'    => \&overload_gt,
    '>='   => \&overload_gte,
    '<'    => \&overload_lt,
    '<='   => \&overload_lte,
    '<=>'  => \&overload_spaceship,
    '=='   => \&overload_equiv,
    '!='   => \&overload_not_equiv,
    '!'    => \&overload_not,
    '='    => \&overload_copy,
    'int'  => \&overload_int,
    '&'    => \&overload_and,
    '|'    => \&overload_ior,
    '^'    => \&overload_xor,
    '~'    => \&overload_com,
    '>>'   => \&overload_rshift,
    '<<'   => \&overload_lshift,
    '>>='  => \&overload_rshift_eq,
    '<<='  => \&overload_lshift_eq,
    'abs'  => \&overload_abs;


    my @untagged = qw(
__GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL
__GNU_MP_RELEASE __GMP_CC __GMP_CFLAGS
IOK_flag NOK_flag POK_flag
    );

my @tagged = qw(
GMPQ_PV_NV_BUG GMPQ_WIN32_FMT_BUG
mpfr2mpq
Rmpq_abs Rmpq_add Rmpq_canonicalize Rmpq_clear Rmpq_cmp Rmpq_cmp_si Rmpq_cmp_ui
Rmpq_and Rmpq_ior Rmpq_xor Rmpq_com
Rmpq_cmp_z Rmpq_add_z Rmpq_sub_z Rmpq_z_sub Rmpq_mul_z Rmpq_div_z Rmpq_z_div
Rmpq_pow_ui
Rmpq_create_noval Rmpq_denref Rmpq_div Rmpq_div_2exp Rmpq_equal
Rmpq_fprintf
Rmpq_get_d
Rmpq_get_den Rmpq_get_num Rmpq_get_str Rmpq_init Rmpq_init_nobless Rmpq_inp_str
Rmpq_inv Rmpq_mul Rmpq_mul_2exp Rmpq_neg Rmpq_numref Rmpq_out_str Rmpq_printf
Rmpq_set Rmpq_set_d Rmpq_set_den Rmpq_set_f Rmpq_set_num Rmpq_set_si Rmpq_set_str
Rmpq_set_NV Rmpq_get_NV Rmpq_cmp_NV
Rmpq_set_IV Rmpq_cmp_IV
Rmpq_set_ui Rmpq_set_z Rmpq_sgn
Rmpq_sprintf Rmpq_snprintf
Rmpq_sub Rmpq_swap
Rmpq_integer_p
TRmpq_out_str TRmpq_inp_str
qgmp_randseed qgmp_randseed_ui qgmp_randclear
qgmp_randinit_default qgmp_randinit_mt qgmp_randinit_lc_2exp qgmp_randinit_lc_2exp_size
qgmp_randinit_set qgmp_randinit_default_nobless qgmp_randinit_mt_nobless
qgmp_randinit_lc_2exp_nobless qgmp_randinit_lc_2exp_size_nobless qgmp_randinit_set_nobless
qgmp_urandomb_ui qgmp_urandomm_ui
    );

    @Math::GMPq::EXPORT_OK = (@untagged, @tagged);
    our $VERSION = '0.66';
    #$VERSION = eval $VERSION;

    Math::GMPq->DynaLoader::bootstrap($VERSION);

    %Math::GMPq::EXPORT_TAGS =(mpq => \@tagged);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

sub new {

    # This function caters for 2 possibilities:
    # 1) that 'new' has been called OOP style - in which
    #    case there will be a maximum of 3 args
    # 2) that 'new' has been called as a function - in
    #    which case there will be a maximum of 2 args.
    # If there are no args, then we just want to return an
    # initialized Math::GMPq
    if(!@_) {return Rmpq_init()}

    if(@_ > 3) {die "Too many arguments supplied to new()"}

    # If 'new' has been called OOP style, the first arg is the string
    # "Math::GMPq" which we don't need - so let's remove it. However,
    # if the first arg is a Math::GMPq object (which is a possibility),
    # then we'll get a fatal error when we check it for equivalence to
    # the string "Math::GMPq". So we first need to check that it's not
    # an object - which we'll do by using the ref() function:
    if(!ref($_[0]) && Math::GMPq::_SvPOK($_[0]) && $_[0] eq "Math::GMPq") {
      shift;
      if(!@_) {return Rmpq_init()}
      }

    # @_ can now contain a maximum of 2 args - the value, and iff the value is
    # a string, (optionally) the base of the numeric string.
    if(@_ > 2) {die "Too many arguments supplied to new() - expected no more than two"}

    my ($arg1, $type, $base);

    # $_[0] is the value, $_[1] (if supplied) is the base of the number
    # in the string $[_0].
    $arg1 = shift;
    $base = 0;

    $type = _itsa($arg1);
    if(!$type) {die "Inappropriate argument supplied to new()"}

    my $ret = Rmpq_init();

    # Create a Math::GMPq object that has $arg1 as its value.
    # Die if there are any additional args (unless $type == _POK_T)
    if($type == _UOK_T || $type == _IOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      _Rmpq_set_str($ret, $arg1, 10);
      return $ret;
    }

    if($type == _NOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      Rmpq_set_NV($ret, $arg1);
      return $ret;
    }

#    if($type == _POK_T) {
#      if(@_ > 1) {die "Too many arguments supplied to new() - expected no more than two"}
#      $base = shift if @_;
#      if(($base < 2 && $base != 0) || $base > 62) {die "Invalid value for base"}
#      if( ($base == 0 || $base == 10) && _looks_like_number($arg1) ) {
#        # Added in 0.58:
#        # Convert (eg) a string such as '20.14e-1' into
#        # an acceptable input arg of '2014/1000'.
#        $arg1 = _reformatted($arg1);
#      }
#      _Rmpq_set_str($ret, $arg1, $base);
#      Rmpq_canonicalize($ret);
#      return $ret;
#    }

    if($type == _POK_T) {
      if(@_ > 1) {die "Too many arguments supplied to new() - expected no more than two"}
      $base = shift if @_;
#      if(($base < 2 && $base != 0) || $base > 62) {die "Invalid value for base"}
#      if( ($base == 0 || $base == 10) && _looks_like_number($arg1) ) {
#        # Added in 0.58:
#        # Convert (eg) a string such as '20.14e-1' into
#        # an acceptable input arg of '2014/1000'.
#        $arg1 = _reformatted($arg1);
#      }
      Rmpq_set_str($ret, $arg1, $base);

      return $ret;
    }


    if($type == _MATH_GMPz_T || $type == _MATH_GMP_T) { # Math::GMPz or Math::GMP object
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      Rmpq_set_z($ret, $arg1);
      return $ret;
    }

    if($type == _MATH_MPFR_T) {
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      Math::MPFR::Rmpfr_get_q($ret, $arg1);
      return $ret;
    }

    if($type == _MATH_GMPq_T) { # Math::GMPq object
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      Rmpq_set($ret, $arg1);
      return $ret;
    }
}

sub Rmpq_out_str {
    if(@_ == 2) {
       die "Inappropriate 1st arg supplied to Rmpq_out_str" if _itsa($_[0]) != _MATH_GMPq_T;
       return _Rmpq_out_str($_[0], $_[1]);
    }
    if(@_ == 3) {
      if(_itsa($_[0]) == _MATH_GMPq_T) {return _Rmpq_out_strS($_[0], $_[1], $_[2])}
      die "Incorrect args supplied to Rmpq_out_str" if _itsa($_[1]) != _MATH_GMPq_T;
      return _Rmpq_out_strP($_[0], $_[1], $_[2]);
    }
    if(@_ == 4) {
      die "Inappropriate 2nd arg supplied to Rmpq_out_str" if _itsa($_[1]) != _MATH_GMPq_T;
      return _Rmpq_out_strPS($_[0], $_[1], $_[2], $_[3]);
    }
    die "Wrong number of arguments supplied to Rmpq_out_str()";
}

sub TRmpq_out_str {
    if(@_ == 3) {
      die "Inappropriate 3rd arg supplied to TRmpq_out_str" if _itsa($_[2]) != _MATH_GMPq_T;
      return _TRmpq_out_str($_[0], $_[1], $_[2]);
    }
    if(@_ == 4) {
      if(_itsa($_[2]) == _MATH_GMPq_T) {return _TRmpq_out_strS($_[0], $_[1], $_[2], $_[3])}
      die "Incorrect args supplied to TRmpq_out_str" if _itsa($_[3]) != _MATH_GMPq_T;
      return _TRmpq_out_strP($_[0], $_[1], $_[2], $_[3]);
    }
    if(@_ == 5) {
      die "Inappropriate 4th arg supplied to TRmpq_out_str" if _itsa($_[3]) != _MATH_GMPq_T;
      return _TRmpq_out_strPS($_[0], $_[1], $_[2], $_[3], $_[4]);
    }
    die "Wrong number of arguments supplied to TRmpq_out_str()";
}

sub _rewrite {
    my $len = length($_[0]);
    my @split = ();
    my @ret = ();
    for(my $i = 0; $i < $len - 1; $i++) {
       if(substr($_[0], $i, 1) eq '%') {
         if(substr($_[0], $i + 1, 1) eq '%') { $i++ }
         else { push(@split, $i) }
         }
       }

    push(@split, $len);
    shift(@split);

    my $start = 0;

    for(@split) {
       push(@ret, substr($_[0], $start, $_ - $start));
       $start = $_;
       }

    return @ret;
}

sub Rmpq_printf {
    local $| = 1;
    push @_, 0 if @_ == 1; # add a dummy second argument
    die "Rmpz_printf must pass 2 arguments: format string, and variable" if @_ != 2;
    wrap_gmp_printf(@_);
}

sub Rmpq_fprintf {
    push @_, 0 if @_ == 2; # add a dummy third argument
    die "Rmpq_fprintf must pass 3 arguments: filehandle, format string, and variable" if @_ != 3;
    wrap_gmp_fprintf(@_);
}

sub Rmpq_sprintf {
    my $len;

    if(@_ == 3) {      # optional arg wasn't provided
      $len = wrap_gmp_sprintf($_[0], $_[1], 0, $_[2]);  # Set missing arg to 0
    }
    else {
      die "Rmpq_sprintf must pass 4 arguments: buffer, format string, variable, buflen" if @_ != 4;
      $len = wrap_gmp_sprintf(@_);
    }

    return $len;
}

sub Rmpq_snprintf {
    my $len;

    if(@_ == 4) {      # optional arg wasn't provided
      $len = wrap_gmp_snprintf($_[0], $_[1], $_[2], 0, $_[3]);  # Set missing arg to 0
    }
    else {
      die "Rmpq_snprintf must pass 5 arguments: buffer, bytes written, format string, variable and buflen" if @_ != 5;
      $len = wrap_gmp_snprintf(@_);
    }

    return $len;
}

sub Rmpq_set_str { # $str, $base
  my ($ret, $str, $base, $exp) = (shift, shift, shift);
  my $str_orig = "$str";
  my $base_to_pass = abs($base);
  die "Invalid value for base ($base)"
    if($base_to_pass == 1 || $base_to_pass > 62);

  # GMP's mpq_aer_str() won't allow a leading '+'.
  $str =~ s/^\+//;
  $str =~ s/\/\+/\//;

  # If $str =~ /\// then the 2 values on either
  # side of the '/' must be integers. Otherwise
  # the assignment should abort with "illegal
  # characters errors.
  if($str =~ /\// || ( !$base && _represents_allowable_integer($str))) {
    _Rmpq_set_str($ret, $str, $base_to_pass);
    Rmpq_canonicalize($ret);
    return;
  }

  my $prefix = '';
  $prefix = '-' if $str =~ s/^\-//;

  if($base == 0) {
    if($str =~ s/^0x//i) {
      #return '0' if $str eq '';
      my($s, $exp) = split /p/i, $str;

      # Remove any radix point, and
      # adjust $exp accordingly.
      my @temp = split /\./, $s;
      {
        no warnings 'uninitialized';
        $exp -= length($temp[1]) * 4;
      }
      $s =~ s/\.//;

      _Rmpq_set_str($ret, $prefix . $s, 16);
      if($exp < 0) {
        Rmpq_div_2exp($ret, $ret, -$exp);
        return;
      }

      Rmpq_mul_2exp($ret, $ret, $exp);
      return;
    }
    elsif($str =~ s/^0b//i) {
      #return '0' if $str eq '';
      my($s, $exp) = split /p/i, $str;

      # Remove any radix point, and
      # adjust $exp accordingly.
      my @temp = split /\./, $s;
      {
        no warnings 'uninitialized';
        $exp -= length($temp[1]);
      }
      $s =~ s/\.//;

      _Rmpq_set_str($ret, $prefix . $s, 2);
      if($exp < 0) {
        Rmpq_div_2exp($ret, $ret, -$exp);
        return;
      }

      Rmpq_mul_2exp($ret, $ret, $exp);
      return;
    }
    elsif($str =~ s/^0o//i) {
      my($s, $exp) = split /p/i, $str;

      # Remove any radix point, and
      # adjust $exp accordingly.
      my @temp = split /\./, $s;
      {
        no warnings 'uninitialized';
        $exp -= length($temp[1]) * 3;
      }
      $s =~ s/\.//;
      _Rmpq_set_str($ret, $prefix . $s, 8);
      if($exp < 0) {
        Rmpq_div_2exp($ret, $ret, -$exp);
        return;
      }

      Rmpq_mul_2exp($ret, $ret, $exp);
      return;
    }
    else {
      $base_to_pass = 10;
    }
  }

  if($base_to_pass <= 15) { $str =~ s/e/@/i }
    $str =~ s/@\+/@/; # GMP's mpq_set_str() won't allow a leading '+'.
  unless($str =~ /[^a-zA-Z0-9]/) {
    _Rmpq_set_str($ret, $prefix . $str, $base_to_pass);
    # Rmpq_canonicalize($ret); # not needed - value is an integer
    return;
  }

  ($str, $exp) = split /@/, $str;

  my $den = Rmpq_init();
  $str =~ s/^0+//g;
  my($s1, $s2) = split /\./, $str;
  $s2 = '' unless defined $s2; # Avoid uninitialized warning at next 2 lines

  _Rmpq_set_str($ret, $prefix . $s1 . $s2, $base_to_pass);
  _Rmpq_set_str($den, '1' . ('0' x length($s2)), $base_to_pass);
  Rmpq_div($ret, $ret, $den);
  return unless $exp;

  # Deal with the exponent:
  # $exp is to be treated as a base 10 value
  # whevever $base is negative. Otherwise it
  # needs to be treated as a base $base value
  # and we need to convert the given $base
  # exponent to it's base 10 equivalent value.

  my($q_modifier, $exp_adj) = (Rmpq_init());
  if($base < 0 || $base == 10) {
    $exp_adj = $exp + 0;
  }
  else {
    $exp_adj = _to_base($exp, $base_to_pass);
  }

  _Rmpq_set_str($q_modifier, '1' . ('0') x abs($exp_adj), $base_to_pass);

  if($exp > 0) {
    Rmpq_mul($ret, $ret, $q_modifier);
    return;
  }

  Rmpq_div($ret, $ret, $q_modifier);
  return;
}

sub Rmpq_set_str_prev {
  if( _itsa($_[1]) == 4 && _looks_like_number($_[1]) && ($_[2] == 0 || $_[2] == 10) ) {
    _Rmpq_set_str($_[0], _reformatted($_[1]), $_[2]);
  }
  else { _Rmpq_set_str($_[0], $_[1], $_[2]) }
}

sub overload_add {
  if( _itsa($_[1]) == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    _overload_add($_[0], $q, $_[2]);
  }
  else {
    _overload_add($_[0], $_[1], $_[2]);
  }
}

sub overload_add_eq {
  if( _itsa($_[1]) == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    _overload_add_eq($_[0], $q, $_[2]);
  }
  else {
    _overload_add_eq($_[0], $_[1], $_[2]);
  }
}

sub overload_mul {
  if( _itsa($_[1]) == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    _overload_mul($_[0], $q, $_[2]);
  }
  else {
    _overload_mul($_[0], $_[1], $_[2]);
  }
}

sub overload_mul_eq {
  if( _itsa($_[1]) == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    _overload_mul_eq($_[0], $q, $_[2]);
  }
  else {
    _overload_mul_eq($_[0], $_[1], $_[2]);
  }
}

sub overload_sub {
  if( _itsa($_[1]) == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    # _overload_sub() doesn't check $_[2] if both args are
    # Math::GMPq objects - so we perform the check here.
    if($_[2]) { _overload_sub($q, $_[0], 0) }
    else { _overload_sub($_[0], $q, 0) }
  }
  else {
    _overload_sub($_[0], $_[1], $_[2]);
  }
}

sub overload_sub_eq {
  if( _itsa($_[1]) == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    # _overload_sub_eq() doesn't check $_[2] if both args are
    # Math::GMPq objects - so we perform the check here.
    if($_[2]) { _overload_sub_eq($q, $_[0], 0) }
    else { _overload_sub_eq($_[0], $q, 0) }
  }
  else {
    _overload_sub_eq($_[0], $_[1], $_[2]);
  }
}

sub overload_div {
  if( _itsa($_[1]) == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    # _overload_div() doesn't check $_[2] if both args are
    # Math::GMPq objects - so we perform the check here.
    if($_[2]) { _overload_div($q, $_[0], 0) }
    else { _overload_div($_[0], $q, 0) }
  }
  else {
    _overload_div($_[0], $_[1], $_[2]);
  }
}

sub overload_div_eq {
  if( _itsa($_[1]) == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    # _overload_div_eq() doesn't check $_[2] if both args are
    # Math::GMPq objects - so we perform the check here.
    if($_[2]) { _overload_div_eq($q, $_[0], 0) }
    else { _overload_div_eq($_[0], $q, 0) }
  }
  else {
    _overload_div_eq($_[0], $_[1], $_[2]);
  }
}

sub overload_pow {
  if( _itsa($_[1]) == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    _overload_pow($_[0], $q, $_[2]);
  }
  else {
    _overload_pow($_[0], $_[1], $_[2]);
  }
}

sub overload_pow_eq {
  if( _itsa($_[1]) == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    _overload_pow_eq($_[0], $q, $_[2]);
  }
  else {
    _overload_pow_eq($_[0], $_[1], $_[2]);
  }
}

##### overloaded comparisons #####

sub overload_gt {
  my $itsa = _itsa($_[1]);
  if( $itsa == 5 ) { # Math::MPFR object
    return 0 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_q($_[1], $_[0]) <  0;
    return 0;
  }

  if($itsa == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    # _overload_gt() doesn't check $_[2] if both args are
    # Math::GMPq objects - so we perform the check here.
    if($_[2]) { return _overload_gt($q, $_[0], 0) }
    else { return _overload_gt($_[0], $q, 0) }
  }
  return _overload_gt($_[0], $_[1], $_[2]);
}

sub overload_gte {
  my $itsa = _itsa($_[1]);
  if( $itsa == 5 ) { # Math::MPFR object
    return 0 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_q($_[1], $_[0]) <=  0;
    return 0;
  }

  if($itsa == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    # _overload_gte() doesn't check $_[2] if both args are
    # Math::GMPq objects - so we perform the check here.
    if($_[2]) { return _overload_gte($q, $_[0], 0) }
    else { return _overload_gte($_[0], $q, 0) }
  }
  return _overload_gte($_[0], $_[1], $_[2]);
}

sub overload_lt {
  my $itsa = _itsa($_[1]);
  if( $itsa == 5 ) { # Math::MPFR object
    return 0 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_q($_[1], $_[0]) >  0;
    return 0;
  }
  if($itsa == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    # _overload_lt() doesn't check $_[2] if both args are
    # Math::GMPq objects - so we perform the check here.
    if($_[2]) { return _overload_lt($q, $_[0], 0) }
    else { return _overload_lt($_[0], $q, 0) }
  }
  return _overload_lt($_[0], $_[1], $_[2]);
}

sub overload_lte {
  my $itsa = _itsa($_[1]);
  if( $itsa == 5 ) { # Math::MPFR object
    return 0 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_q($_[1], $_[0]) >=  0;
    return 0;
  }
  if($itsa == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    # _overload_lte() doesn't check $_[2] if both args are
    # Math::GMPq objects - so we perform the check here.
    if($_[2]) { return _overload_lte($q, $_[0], 0) }
    else { return _overload_lte($_[0], $q, 0) }
  }
  return _overload_lte($_[0], $_[1], $_[2]);
}

sub overload_spaceship {
  my $itsa = _itsa($_[1]);
  if( $itsa == 5 ) { # Math::MPFR object
    return undef if Math::MPFR::Rmpfr_nan_p($_[1]);
    return Math::MPFR::Rmpfr_cmp_q($_[1], $_[0]) * -1;
  }
  if($itsa == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    # _overload_spaceship() doesn't check $_[2] if both args are
    # Math::GMPq objects - so we perform the check here.
    if($_[2]) { return _overload_spaceship($q, $_[0], 0) }
    else { return _overload_spaceship($_[0], $q, 0) }
  }
  return _overload_spaceship($_[0], $_[1], $_[2]);
}

sub overload_equiv {
  my $itsa = _itsa($_[1]);
  if( $itsa == 5 ) { # Math::MPFR object
    return 0 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_q($_[1], $_[0]) ==  0;
    return 0;
  }
  if($itsa == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    return _overload_equiv($_[0], $q, $_[2]);
  }
  return _overload_equiv($_[0], $_[1], $_[2]);
}

sub overload_not_equiv {
  my $itsa = _itsa($_[1]);
  if( $itsa == 5 ) { # Math::MPFR object
    return 1 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_q($_[1], $_[0]) !=  0;
    return 0;
  }
  if($itsa == 4 ) {
    my $q = Math::GMPq->new($_[1], 0);
    return _overload_not_equiv($_[0], $q, $_[2]);
  }
  return _overload_not_equiv($_[0], $_[1], $_[2]);
}

#### end overloaded comparisons ####

sub overload_and {
  my $itsa = _itsa($_[1]);
  my $ret = Math::GMPq->new();
  if($itsa == 7) {
    Rmpq_and($ret, $_[0], $_[1]);
    return $ret;
  }
  my $arg1 = _to_mpq($itsa, $_[1], '&');
  return Rmpq_and($ret,$_[0], $arg1);
  return $ret;
}

sub overload_ior {
  my $itsa = _itsa($_[1]);
  my $ret = Math::GMPq->new();
  if($itsa == 7) {
    Rmpq_ior($ret, $_[0], $_[1]);
    return $ret;
  }
  my $arg1 = _to_mpq($itsa, $_[1], '|');
  return Rmpq_ior($ret,$_[0], $arg1);
  return $ret;
}

sub overload_xor {
  my $itsa = _itsa($_[1]);
  my $ret = Math::GMPq->new();
  if($itsa == 7) {
    Rmpq_xor($ret, $_[0], $_[1]);
    return $ret;
  }
  my $arg1 = _to_mpq($itsa, $_[1], '^');
  return Rmpq_xor($ret,$_[0], $arg1);
  return $ret;
}

sub overload_com {
  my $ret = Math::GMPq->new();
  Rmpq_com($ret, $_[0]);
  return $ret;
}

sub _to_mpq {
  my ($itsa, $arg, $op) = (shift, shift, shift);
  die "Bad argument given to '$op' overloading" unless $itsa;
  return Math::GMPq->new($arg) if $itsa <= 4;
  if($itsa == 8 || $itsa == 9) {
    my $ret = Math::GMPq->new();
    Rmpq_set_z($ret, $arg);
    return $ret;
  }
  die "Bad argument given to '$op' overloading";
}


sub overload_lshift {
  if($_[2] || !_looks_like_number($_[1])) {
    die "Math::GMPq: When overloading '<<', the argument that specifies the number of bits to be shifted must be a perl number";
  }
  return _overload_lshift(@_) if $_[1] >= 0;
  return _overload_rshift($_[0], -$_[1], $_[2]);
}

sub overload_lshift_eq {
  if($_[2] || !_looks_like_number($_[1])) {
    die "Math::GMPq: When overloading '<<=', the argument that specifies the number of bits to be shifted must be a perl number";
  }
  return _overload_lshift_eq(@_) if $_[1] >= 0;
  return _overload_rshift_eq($_[0], -$_[1], $_[2]);
}

sub overload_rshift {
  if($_[2] || !_looks_like_number($_[1])) {
    die "Math::GMPq: When overloading '>>', the argument that specifies the number of bits to be shifted must be a perl number";
  }
  return _overload_rshift(@_) if $_[1] >= 0;
  return _overload_lshift($_[0], -$_[1], $_[2]);
}

sub overload_rshift_eq {
  if($_[2] || !_looks_like_number($_[1])) {
    die "Math::GMPq: When overloading '>>=', the argument that specifies the number of bits to be shifted must be a perl number";
  }
  return _overload_rshift_eq(@_) if $_[1] >= 0;
  return _overload_lshift_eq($_[0], -$_[1], $_[2]);
}

sub overload_fmod {
  if(ref($_[1]) eq 'Math::MPFR') {
    return Math::MPFR::_overload_fmod(Math::MPFR->new($_[0]), $_[1], 0);
  }
  if(ref($_[1]) ne 'Math::GMPq') {
    return _overload_fmod($_[0], Math::GMPq->new($_[1]), 0) unless $_[2];
    return _overload_fmod(Math::GMPq->new($_[1]), $_[0], 0);
  }
  return _overload_fmod(@_);
}

sub overload_fmod_eq {
  if(ref($_[1]) eq 'Math::MPFR') {
    return Math::MPFR::_overload_fmod(Math::MPFR->new($_[0]), $_[1], 0);
  }
  if(ref($_[1]) ne 'Math::GMPq') {
    return _overload_fmod_eq($_[0], Math::GMPq->new($_[1]), 0) unless $_[2];
    return _overload_fmod_eq(Math::GMPq->new($_[1]), $_[0], 0);
  }
  return _overload_fmod_eq(@_);
}

sub mpfr2mpq {
  die "The argument provided to Math::GMPq::mpfr2mpq must be a Math::MPFR::object"
    unless ref($_[0]) eq 'Math::MPFR';
  Math::MPFR::Rmpfr_get_q( my $mpq_from_mpfr = Math::GMPq->new(), shift );
  return $mpq_from_mpfr;
}

sub _represents_allowable_integer {
  # Will be called only if base is zero.
  my $str = shift;
  if($str =~ s/^\-?0x//i) {
    return 0 if $str =~ /[^0-9a-fA-F]/;
    return 1;
  }
  if($str =~ s/^\-?0b//i) {
    return 0 if $str =~ /[^0-1]/;
    return 1;
  }
  if($str =~ s/^\-?0//i) {
    return 0 if $str =~ /[^0-7]/;
    return 1;
  }
  return 0;
}

sub __GNU_MP_VERSION            () {return ___GNU_MP_VERSION()}
sub __GNU_MP_VERSION_MINOR      () {return ___GNU_MP_VERSION_MINOR()}
sub __GNU_MP_VERSION_PATCHLEVEL () {return ___GNU_MP_VERSION_PATCHLEVEL()}
sub __GNU_MP_RELEASE            () {return ___GNU_MP_RELEASE()}
sub __GMP_CC                    () {return ___GMP_CC()}
sub __GMP_CFLAGS                () {return ___GMP_CFLAGS()}
sub GMP_LIMB_BITS               () {return _GMP_LIMB_BITS()}
sub GMP_NAIL_BITS               () {return _GMP_NAIL_BITS()}

*qgmp_randseed =                      \&Math::GMPq::Random::Rgmp_randseed;
*qgmp_randseed_ui =                   \&Math::GMPq::Random::Rgmp_randseed_ui;
*qgmp_randclear =                     \&Math::GMPq::Random::Rgmp_randclear;
*qgmp_randinit_default =              \&Math::GMPq::Random::Rgmp_randinit_default;
*qgmp_randinit_mt =                   \&Math::GMPq::Random::Rgmp_randinit_mt;
*qgmp_randinit_lc_2exp =              \&Math::GMPq::Random::Rgmp_randinit_lc_2exp;
*qgmp_randinit_lc_2exp_size =         \&Math::GMPq::Random::Rgmp_randinit_lc_2exp_size;
*qgmp_randinit_set =                  \&Math::GMPq::Random::Rgmp_randinit_set;
*qgmp_randinit_default_nobless =      \&Math::GMPq::Random::Rgmp_randinit_default_nobless;
*qgmp_randinit_mt_nobless =           \&Math::GMPq::Random::Rgmp_randinit_mt_nobless;
*qgmp_randinit_lc_2exp_nobless =      \&Math::GMPq::Random::Rgmp_randinit_lc_2exp_nobless;
*qgmp_randinit_lc_2exp_size_nobless = \&Math::GMPq::Random::Rgmp_randinit_lc_2exp_size_nobless;
*qgmp_randinit_set_nobless =          \&Math::GMPq::Random::Rgmp_randinit_set_nobless;
*qgmp_urandomb_ui =                   \&Math::GMPq::Random::Rgmp_urandomb_ui;
*qgmp_urandomm_ui =                   \&Math::GMPq::Random::Rgmp_urandomm_ui;

1;

__END__

