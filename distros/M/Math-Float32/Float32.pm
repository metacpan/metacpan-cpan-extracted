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

our $VERSION = '0.01';
Math::Float32->DynaLoader::bootstrap($VERSION);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking



my @tagged = qw( flt_to_NV flt_to_MPFR
                 is_flt_nan is_flt_inf is_flt_zero flt_set_nan flt_set_inf flt_set_zero
                 flt_signbit
                 flt_set
                 flt_nextabove flt_nextbelow
                 unpack_flt_hex
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

$Math::Float32::flt_DENORM_MIN = Math::Float32->new(2) ** (flt_EMIN - 1);                  # 1.401298464e-45
$Math::Float32::flt_DENORM_MAX = Math::Float32->new(_get_denorm_max());                    # 1.175494211e-38
$Math::Float32::flt_NORM_MIN   = Math::Float32->new(2) ** (flt_EMIN + (flt_MANTBITS - 2)); # 1.175494351e-38
$Math::Float32::flt_NORM_MAX   = Math::Float32->new(_get_norm_max());                      # 3.402823466e+38

sub new {
   shift if (@_ > 0 && !ref($_[0]) && _itsa($_[0]) == 4 && $_[0] eq "Math::Float32");
   if(!@_) { return _fromPV('NaN');}
   die "Too many args given to new()" if @_ > 1;
   my $itsa = _itsa($_[0]);
   if($itsa) {
     my $coderef = $Math::Float32::handler{$itsa};
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
     return _oload_add($_[0], $coderef->($_[1]), 0);
   }
   die "Unrecognized 2nd argument passed to oload_add() function";
}

sub oload_mul {
   my $itsa = _itsa($_[1]);
   return _oload_mul(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_mul($_[0], $coderef->($_[1]), 0);
   }
   die "Unrecognized 2nd argument passed to oload_mul() function";
}

sub oload_sub {
   my $itsa = _itsa($_[1]);
   return _oload_sub(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_sub($_[0], $coderef->($_[1]), $_[2]);
   }
   die "Unrecognized 2nd argument passed to oload_sub() function";
}

sub oload_div {
   my $itsa = _itsa($_[1]);
   return _oload_div(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_div($_[0], $coderef->($_[1]), $_[2]);
   }
   die "Unrecognized 2nd argument passed to oload_div() function";
}

sub oload_fmod {
   my $itsa = _itsa($_[1]);
   return _oload_fmod(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_fmod($_[0], $coderef->($_[1]), $_[2]);
   }
   die "Unrecognized 2nd argument passed to oload_fmod() function";
}

sub oload_pow {
   my $itsa = _itsa($_[1]);
   return _oload_pow(@_) if $itsa == 22;
   if($itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_pow($_[0], $coderef->($_[1]), $_[2]);
   }
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
     return _oload_equiv($_[0], $coderef->($_[1]), 0);
   }
   die "Unrecognized 2nd argument passed to oload_equiv() function";
}

sub oload_not_equiv {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_not_equiv($_[0], $coderef->($_[1]), 0);
   }
   die "Unrecognized 2nd argument passed to oload_not_equiv() function";
}

sub oload_gt {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_gt($_[0], $coderef->($_[1]), $_[2]);
   }
   die "Unrecognized 2nd argument passed to oload_gt() function";
}

sub oload_gte {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_gte($_[0], $coderef->($_[1]), $_[2]);
   }
   die "Unrecognized 2nd argument passed to oload_gte() function";
}

sub oload_lt {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_lt($_[0], $coderef->($_[1]), $_[2]);
   }
   die "Unrecognized 2nd argument passed to oload_lt() function";
}

sub oload_lte {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_lte($_[0], $coderef->($_[1]), $_[2]);
   }
   die "Unrecognized 2nd argument passed to oload_lte() function";
}

sub oload_spaceship {
   my $itsa = _itsa($_[1]);
   if($itsa == 22 || $itsa < 5) {
     my $coderef = $Math::Float32::handler{$itsa};
     return _oload_spaceship($_[0], $coderef->($_[1]), $_[2]);
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

sub flt_nextabove {
  if(is_flt_zero($_[0])) {
    flt_set($_[0], $Math::Float32::flt_DENORM_MIN);
  }
  elsif($_[0] < $Math::Float32::flt_NORM_MIN && $_[0] >= -$Math::Float32::flt_NORM_MIN ) {
    $_[0] += $Math::Float32::flt_DENORM_MIN;
    flt_set_zero($_[0], -1) if is_flt_zero($_[0]);
  }
  else {
    _flt_nextabove($_[0]);
  }
}

sub flt_nextbelow {
  if(is_flt_zero($_[0])) {
    flt_set($_[0], -$Math::Float32::flt_DENORM_MIN);
  }
  elsif($_[0] <= $Math::Float32::flt_NORM_MIN && $_[0] > -$Math::Float32::flt_NORM_MIN ) {
    $_[0] -= $Math::Float32::flt_DENORM_MIN;
  }
  else {
    _flt_nextbelow($_[0]);
  }
}

sub unpack_flt_hex {
  my @ret = _unpack_flt_hex($_[0]);
  return join('', @ret);
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
