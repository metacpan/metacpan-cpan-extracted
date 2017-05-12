package Math::Trig::Units;

require Exporter;
use Carp;

use vars qw( @ISA @EXPORT_OK $VERSION $UNITS $ZERO $pi $inf );
$VERSION = '0.03';
@ISA=qw(Exporter);
@EXPORT_OK=qw(
    dsin    asin
    dcos    acos
    tan     atan
    sec     asec
    csc     acsc
    cot     acot
    sinh    asinh
    cosh    acosh
    tanh    atanh
    sech    asech
    csch    acsch
    coth    acoth
    deg_to_rad  rad_to_deg
    grad_to_rad rad_to_grad
    deg_to_grad grad_to_deg
    units
    );

BEGIN { $pi    = atan2(1,1)*4;
        $inf   = exp(1000000);
        $UNITS = 'radians';
      }

sub deg_to_rad  { my $x=$_[0]; ($x/180) * $pi }
sub rad_to_deg  { my $x=$_[0]; ($x/$pi) * 180 }
sub grad_to_rad { my $x=$_[0]; ($x/200) * $pi }
sub rad_to_grad { my $x=$_[0]; ($x/$pi) * 200 }
sub deg_to_grad { my $x=$_[0]; $x/0.9 }
sub grad_to_deg { my $x=$_[0]; $x*0.9 }

sub units_to_rad {
  return $UNITS =~ /gradian/i  ? grad_to_rad($_[0]) :
         $UNITS =~ /radian/i ? $_[0] :
         deg_to_rad($_[0]);
}

sub rad_to_units {
  return $UNITS =~ /gradian/i  ? rad_to_grad($_[0]) :
         $UNITS =~ /radian/i   ? $_[0] :
         rad_to_deg($_[0]);
}

sub units {
   $UNITS = $_[0] if $_[0];
    confess( "Don't know how to do $_[0] units!") unless $UNITS =~ m/degree|gradian|radian/i;
  return $UNITS;
}

sub dsin { my $x=$_[0];  $x=units_to_rad($x); return  sin($x) }

sub dcos { my $x=$_[0];  $x=units_to_rad($x); return cos($x) }

sub tan { my $x=$_[0]; $x=units_to_rad($x); return cos($x)==0 ? $inf : sin($x)/cos($x) }

sub sec { my $x=$_[0]; $x=units_to_rad($x); return cos($x)==0 ? $inf : 1/cos($x) }

sub csc { my $x=$_[0]; $x=units_to_rad($x); return sin($x)==0 ? $inf : 1/sin($x) }

sub cot { my $x=$_[0]; $x=units_to_rad($x); return sin($x)==0 ? $inf : cos($x)/sin($x) }

sub asin { my $x=$_[0]; return ($x<-1 or $x>1) ? undef : rad_to_units( atan2($x,sqrt(1-$x*$x)) ); }

sub acos { my $x=$_[0]; return ($x<-1 or $x>1) ? undef : rad_to_units( atan2(sqrt(1-$x*$x),$x) ); }

sub atan {
  return ($_[0]==0) ? 0 :
         ($_[0]>0)  ? rad_to_units( atan2(sqrt(1+$_[0]*$_[0]),sqrt(1+1/($_[0]*$_[0]))) ) :
         rad_to_units($pi) - rad_to_units( atan2(sqrt(1+$_[0]*$_[0]),sqrt(1+1/($_[0]*$_[0]))) );
}

sub asec { return ( $_[0]==0 or ($_[0]>-1 and $_[0]<1) ) ? undef : acos(1/$_[0]); }

sub acsc { return ( $_[0]==0 or ($_[0]>-1 and $_[0]<1) ) ? undef : asin(1/$_[0]); }

sub acot { return ($_[0]==0) ? rad_to_units($pi/2) : atan(1/$_[0]) }

sub sinh { my $x=$_[0]; $x=units_to_rad($x); return (exp($x)-exp(-$x))/2; }

sub cosh { my $x=$_[0]; $x=units_to_rad($x); return (exp($x)+exp(-$x))/2; }

sub tanh {
    my($ep,$em) = (exp(units_to_rad($_[0])),exp(-units_to_rad($_[0])));
  return ($ep==$inf) ? 1  :
         ($em==$inf) ? -1 : ($ep-$em)/($ep+$em);
}

sub sech { my $x=$_[0]; $x=units_to_rad($x); return 2/(exp($x)+exp(-$x)); }

sub csch { my $x=$_[0]; $x=units_to_rad($x); return ($x==0) ? $inf : 2/(exp($x)-exp(-$x)); }

sub coth {
    my $x=units_to_rad($_[0]);
    my($ep,$em) = (exp($x),exp(-$x));
  return ($x==0) ? $inf :
         ($ep == $inf) ? 1 :
         ($em == $inf) ? -1 : (exp($x)+exp(-$x))/(exp($x)-exp(-$x));
}

sub asinh { return rad_to_units(log($_[0]+sqrt(1+$_[0]*$_[0]))); }

sub acosh { return ($_[0]<1) ? $inf : asinh(sqrt($_[0]*$_[0]-1)); }  # Returns positive value only!

sub atanh { return ( $_[0]<=-1 or $_[0]>=1) ? $inf : asinh($_[0]/sqrt(1-$_[0]*$_[0])); }

sub asech { return ( $_[0]<=0 or $_[0]>1 ) ? $inf : asinh(sqrt(1-$_[0]*$_[0])/$_[0]); }  # Returns positive value only!

sub acsch { return ( $_[0]==0 ) ? $inf : asinh(1/$_[0]); }

sub acoth {
  return ($_[0]>=-1 and $_[0]<=1) ? $inf :
         ($_[0]<-1) ? -asinh(1/sqrt($_[0]*$_[0]-1)) :
         asinh(1/sqrt($_[0]*$_[0]-1));
}

1;

__END__

=head1 NAME

    Math::Trig::Units - Inverse and hyperbolic trigonemetric Functions
                         in degrees, radians or gradians.

=head1 SYNOPSIS

    use Math::Trig::Units qw(dsin  dcos  tan   sec   csc   cot
                             asin  acos  atan  asec  acsc  acot
                             sinh  cosh  tanh  sech  csch  coth
                             asinh acosh atanh asech acsch acoth
                             deg_to_rad  rad_to_deg
                             grad_to_rad rad_to_grad
                             deg_to_grad grad_to_deg
                             units );
    $v = dsin($x);
    $v = dcos($x);
    $v = tan($x);
    $v = sec($x);
    $v = csc($x);
    $v = cot($x);
    $v = asin($x);
    $v = acos($x);
    $v = atan($x);
    $v = asec($x);
    $v = acsc($x);
    $v = acot($x);
    $v = sinh($x);
    $v = cosh($x);
    $v = tanh($x);
    $v = sech($x);
    $v = csch($x);
    $v = coth($x);
    $v = asinh($x);
    $v = acosh($x);
    $v = atanh($x);
    $v = asech($x);
    $v = acsch($x);
    $v = acoth($x);
    $degrees  = rad_to_deg($radians);
    $radians  = deg_to_rad($degrees);
    $degrees  = grad_to_deg($gradians);
    $gradians = deg_to_grad($degrees);
    $radians  = grad_to_rad($gradians);
    $gradians = rad_to_grad($radians);

    # set radians instead of degrees (default)
    Math::Trig::Units::units('radians');
    # set gradians as units
    Math::Trig::Units::units('gradians');
    # set degrees as units
    Math::Trig::Units::units('degrees');
    # return current unit setting
    $units = Math::Trig::Units::units();

=head1 DESCRIPTION

This module exports the missing inverse and hyperbolic trigonometric
functions of real numbers.  The inverse functions return values
cooresponding to the principal values.  Specifying an argument outside
of the domain of the function where an illegal divion by zero would occur
will cause infinity to be returned. Infinity is Perl's version of this.

This module implements the functions in radians by default. You set the
units via the units sub:

    # set radians as units (default)
    Math::Trig::Units::units('radians');
    # set gradians as units
    Math::Trig::Units::units('gradians');
    # set degrees as units
    Math::Trig::Units::units('degrees');
    # return current unit setting
    $units = Math::Trig::Units::units();

To avoid redefining the internal sin() and cos() functions this module
calls the functions dsin() and dcos().

=head3 units( [UNITS] )

Set or get the units. Options are 'radians', 'degrees', 'gradians' and are
case insensitive. When called without an argument this function returns the
current units setting. Alternatively you can call the subclasses:

    Math::Trig::Degree
    Math::Trig::Radian
    Math::Trig::Gradian

=head3 dsin

returns sin of real argument.

=head3 dcos

returns cos of real argument.

=head3 tan

returns tangent of real argument.

=head3 sec

returns secant of real argument.

=head3 csc

returns cosecant of real argument.

=head3 cot

returns cotangent of real argument.

=head3 asin

returns inverse sine of real argument.

=head3 acos

returns inverse cosine of real argument.

=head3 atan

returns inverse tangent of real argument.

=head3 asec

returns inverse secant of real argument.

=head3 acsc

returns inverse cosecant of real argument.

=head3 acot

returns inverse cotangent of real argument.

=head3 sinh

returns hyperbolic sine of real argument.

=head3 cosh

returns hyperbolic cosine of real argument.

=head3 tanh

returns hyperbolic tangent of real argument.

=head3 sech

returns hyperbolic secant of real argument.

=head3 csch

returns hyperbolic cosecant of real argument.

=head3 coth

returns hyperbolic cotangent of real argument.

=head3 asinh

returns inverse hyperbolic sine of real argument.

=head3 acosh

returns inverse hyperbolic cosine of real argument.

(positive value only)

=head3 atanh

returns inverse hyperbolic tangent of real argument.

=head3 asech

returns inverse hyperbolic secant of real argument.

(positive value only)

=head3 acsch

returns inverse hyperbolic cosecant of real argument.

=head3 acoth

returns inverse hyperbolic cotangent of real argument.

=head1 HISTORY

Modification of Math::Trig by request from stefan_k.

=head1 BUGS

All known ones have been fixed (see changes). Let me know if you find one.

=head1 AUTHOR

Initial Version John A.R. Williams <J.A.R.Williams@aston.ac.uk>
Bug fixes and many additonal functions Jason Smith <smithj4@rpi.edu>
This version James Freeman <james.freeman@id3.org.uk>

=cut




