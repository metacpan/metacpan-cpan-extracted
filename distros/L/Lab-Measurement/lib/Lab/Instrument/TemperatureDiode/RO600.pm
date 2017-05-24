package Lab::Instrument::TemperatureDiode::SI420;
our $VERSION = '3.543';

use strict;
use Math::Complex;
use Lab::Instrument::TemperatureDiode;

our @ISA = ("Lab::Instrument::TemperatureDiode");

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub convert2Kelvin {
    my $value = shift;

    if ( $value < 1725.8 and $value >= 1100.75 )
    {    # approximieren durch polynom
        $value = (-0.3199412263 + 5.7488447e-8 * ( $value**2 ) * log($value)
                - 8.840903e-11 * $value**3 )**(-1);
    }
    elsif ( $value >= 1725.82 and $value <= 29072.86 ) {
        $value = (-0.771272244 + 0.00010067892 * $value * log($value)
                - 1.071888e-9 * ( $value**2 ) * log($value) )**(-1);
    }
    else {
        warn "no valid TEMPERATURE VALUE.";
        return -1;
    }

    return $value;
}
