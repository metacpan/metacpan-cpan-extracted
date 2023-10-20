package Lab::Instrument::TemperatureDiode::RO600;
#ABSTRACT: RO600 (????)
$Lab::Instrument::TemperatureDiode::RO600::VERSION = '3.899';
use v5.20;

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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::TemperatureDiode::RO600 - RO600 (????) (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
