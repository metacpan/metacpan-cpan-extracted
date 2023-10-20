package Lab::Instrument::TemperatureDiode::SI420;
#ABSTRACT: SI420 (???)
$Lab::Instrument::TemperatureDiode::SI420::VERSION = '3.899';
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
    my $self = shift;

    my $value = shift;
    my $y;
    my $x1;
    my $x2;

    if ( $value <= 1.1014 ) {    # approximieren durch polynom
        $value
            = ( -234.66 * $value**5.0 )
            + ( 548.92 * $value**4.0 )
            - ( 509.23 * $value**3.0 )
            + ( 201.73 * $value**2.0 )
            - ( 453.87 * $value**1.0 )
            + 537.83;
        return $value;
    }
    elsif ( $value > 1.7191 ) {
        $value = 0;
        return 0;
    }    # keine Aussage möglich
    elsif ( $value > 1.7086 ) { $y = 1;  $x1 = 1.7086; $x2 = 1.7191; }
    elsif ( $value > 1.6852 ) { $y = 2;  $x1 = 1.6852; $x2 = 1.7086; }
    elsif ( $value > 1.6530 ) { $y = 3;  $x1 = 1.6530; $x2 = 1.6852; }
    elsif ( $value > 1.6124 ) { $y = 4;  $x1 = 1.6124; $x2 = 1.6530; }
    elsif ( $value > 1.5659 ) { $y = 5;  $x1 = 1.5659; $x2 = 1.6124; }
    elsif ( $value > 1.5179 ) { $y = 6;  $x1 = 1.5179; $x2 = 1.5659; }
    elsif ( $value > 1.4723 ) { $y = 7;  $x1 = 1.4723; $x2 = 1.5179; }
    elsif ( $value > 1.4309 ) { $y = 8;  $x1 = 1.4309; $x2 = 1.4723; }
    elsif ( $value > 1.3956 ) { $y = 9;  $x1 = 1.3956; $x2 = 1.4309; }
    elsif ( $value > 1.3656 ) { $y = 10; $x1 = 1.3656; $x2 = 1.3956; }
    elsif ( $value > 1.3385 ) { $y = 11; $x1 = 1.3385; $x2 = 1.3656; }
    elsif ( $value > 1.3142 ) { $y = 12; $x1 = 1.3142; $x2 = 1.3385; }
    elsif ( $value > 1.2918 ) { $y = 13; $x1 = 1.2918; $x2 = 1.3142; }
    elsif ( $value > 1.2712 ) { $y = 14; $x1 = 1.2712; $x2 = 1.2918; }
    elsif ( $value > 1.2517 ) { $y = 15; $x1 = 1.2517; $x2 = 1.2712; }
    elsif ( $value > 1.2333 ) { $y = 16; $x1 = 1.2333; $x2 = 1.2517; }
    elsif ( $value > 1.2151 ) { $y = 17; $x1 = 1.2151; $x2 = 1.2333; }
    elsif ( $value > 1.1963 ) { $y = 18; $x1 = 1.1963; $x2 = 1.2151; }
    elsif ( $value > 1.1759 ) { $y = 19; $x1 = 1.1759; $x2 = 1.1963; }
    elsif ( $value > 1.1524 ) { $y = 20; $x1 = 1.1524; $x2 = 1.1759; }
    elsif ( $value > 1.1293 ) { $y = 21; $x1 = 1.1293; $x2 = 1.1524; }
    elsif ( $value > 1.1192 ) { $y = 22; $x1 = 1.1192; $x2 = 1.1293; }
    elsif ( $value > 1.1146 ) { $y = 23; $x1 = 1.1146; $x2 = 1.1192; }
    elsif ( $value > 1.1114 ) { $y = 24; $x1 = 1.1114; $x2 = 1.1146; }
    elsif ( $value > 1.1090 ) { $y = 25; $x1 = 1.1090; $x2 = 1.1114; }
    elsif ( $value > 1.1069 ) { $y = 26; $x1 = 1.1069; $x2 = 1.1090; }
    elsif ( $value > 1.1049 ) { $y = 27; $x1 = 1.1049; $x2 = 1.1069; }
    elsif ( $value > 1.1031 ) { $y = 28; $x1 = 1.1031; $x2 = 1.1049; }
    elsif ( $value > 1.1014 ) { $y = 29; $x1 = 1.1014; $x2 = 1.1031; }

    $value = $y + ( $x2 - $value ) / ( $x2 - $x1 );

    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::TemperatureDiode::SI420 - SI420 (???) (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Andreas K. Huettel, Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
