package Lab::Moose::Instrument::AH2700A;
$Lab::Moose::Instrument::AH2700A::VERSION = '3.820';
#ABSTRACT: Andeen-Hagerling AH2700A ultra-precision capacitance bridge

use v5.20;

use strict;
use Time::HiRes qw (usleep);
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter
    validated_setter
    validated_no_param_setter
    setter_params
/;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use Time::HiRes qw/time usleep/;
use Lab::Moose 'linspace';

extends 'Lab::Moose::Instrument';


sub BUILD {
    my $self = shift;
    # $self->get_id();
}


sub set_frq {
	my ( $self, $value, %args ) = validated_setter( \@_,
        value  => { isa => enum( [ ( 50..20000 ) ] ) },
    );

	$self->write( command => sprintf("FREQ %d", $value), %args ); 
}


sub get_frq {
    my $self = shift;

    my $result = $self->query( command => sprintf("SH FR") );

    $result =~ /(\D+)(\d+\.\d+)(\D+)/;

    return $2;
}


sub set_aver {
	my ( $self, $value, %args ) = validated_setter( \@_,
        value => { isa => enum( [ ( 0..15 ) ] ) },
    );

    $self->write( command => sprintf( "AV %d", $value ), %args );
}


sub get_aver {
    my $self = shift;

    my $result = $self->query( command => sprintf("SH AV") );

    $result =~ /(\D+)(\D+\=)(\d+)/;

    return $3;
}


sub set_bias {
	my ( $self, $value, %args ) = validated_setter( \@_,
        value => { isa => enum([qw/ OFF IHIGH ILOW /]) },
    );
    
    $self->write( command => sprintf( "BI %s", $value ), %args );
}


sub get_bias {
    my $self = shift;

    my $result = $self->query( command => sprintf("SH BI") );

    $result =~ /(\D+\s)(\D+)/;

    return $result;
}


sub set_cable {
	my ( $self, $cab1, $cab2, %args ) = validated_setter( \@_,
        cab1 => { isa => enum([qw/ L RES I C /]) },
        cab2 => { isa => 'Str' },
    );

    $self->write( command => sprintf( "CAB %s %d", $cab1, $cab2 ), %args );
}


sub get_cable {
    my $self = shift;

    my $result = $self->write( command => sprintf("SH CAB") );

    my @results;

    for ( my $i = 0; $i < 4; $i++ ) {
        my $result = $self->read();
        push( @results, $result );
    }

    print " @results ";

    return @results;
}

# used internally for get_value
sub get_single {
    my ( $self, %args ) = validated_getter( \@_,
    );

	# Implement cache; just use Lab::Moose::Instrument::Cache
	# and write cache id => (getter => 'get_id') for all get
	# functions?
    my $average  = $self->get_aver();
    my $frequency = $self->get_frq();

	# Rewrite with hash
    my $time_table_highf = {
        0  => [ 0.28,  80 ],
        1  => [ 0.29,  110 ],
        2  => [ 0.30,  150 ],
        3  => [ 0.33,  200 ],
        4  => [ 0.37,  260 ],
        5  => [ 0.44,  350 ],
        6  => [ 0.58,  520 ],
        7  => [ 3.2,   3200 ],
        8  => [ 4.8,   5200 ],
        9  => [ 7.2,   8800 ],
        10 => [ 12.0,  16000 ],
        11 => [ 20.0,  28000 ],
        12 => [ 36.0,  56000 ],
        13 => [ 68.0,  108000 ],
        14 => [ 140.0, 220000 ],
        15 => [ 280.0, 480000 ],
    };

    my $timeout = @{ $time_table_highf->{$average} }[0]
        + @{ $time_table_highf->{$average} }[1] / $frequency;

    if ( not exists($args{'timeout'}) ) {
        $args{'timeout'} = 100;
    }

    my $result = $self->query( command => sprintf("SI"), %args );
	#print "$result";
    # Rewrite with hash
	#if ($result eq "") { croak "AH2700A: Low to Ground\n"; }
	my $values;
    while ( $result =~ /([A-Z])=\s(\d+\.\d+)/g ) {
        $values->{$1} = $2;
    }
    $values->{E} = 00;
    # Didn't work in my last test
    #if ( $result =~ /^(\d+)/ and $result != /00/ ) {
    #    $values->{E} = $1;
    #}
	
    # TODO
    # S was always empty in my last test and caused the script
    # to crash, so i'll just document the first three values
    # for the moment.
    return (
        $values->{C} * 1e-12,
        $values->{L} * 1e-9,
        $values->{V}
        #,$values->{S}, $values->{E}
    );
}


sub get_value {
    my $self = shift;

    return $self->get_single(@_);
}

sub set_wait { my ( $self, $wait, %args ) = validated_setter( \@_, wait => { isa => 'Num' },
    );

    $self->write( command => sprintf( "WAIT DELAY %d", $wait ), %args );

}


# controls which fields are sent to GPIB port
sub set_field {
    my ( $self, %args ) = validated_getter( \@_,
		fi1 => { isa => 'Str' },
    	fi2 => { isa => 'Str' },
		fi3 => { isa => 'Num' },
		fi4 => { isa => 'Num' },
		fi5 => { isa => 'Str' },
		fi6 => { isa => 'Str' },
    );
	
	my $fi1 = delete $args{fi1};
	my $fi2 = delete $args{fi2};
	my $fi3 = delete $args{fi3};
	my $fi4 = delete $args{fi4};
	my $fi5 = delete $args{fi5};
	my $fi6 = delete $args{fi6};

    $self->write( command => 
        sprintf(
            "FIELD %s,%s,%d,%d,%s,%s", $fi1, $fi2, $fi3, $fi4, $fi5, $fi6
        ), %args
    );
}


sub set_volt {
    my ( $self, $value, %args ) = validated_setter( \@_,
        value => { isa => 'Num' },
    );

    $self->write( command => sprintf( "V %2.2f", $value ), %args );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::AH2700A - Andeen-Hagerling AH2700A ultra-precision capacitance bridge

=head1 VERSION

version 3.820

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $AH = instrument(
     type            => 'AH2700A',
     connection_type => 'VISA_GPIB',
     connection_options => {
         pad => 28,
     },
 );

=head1 METHODS

=head2 set_frq

 $AH->set_frq( value => (50..20000) );

 The frequency can be chosen between 50 Hz and 20 kHz.
 Since the AH2700A is a discrete frequency bridge it will select
 the nearest supported frequency when entering a value.

=head2 get_frq

 $AH->get_frq();

=head2 set_aver

 $AH->set_aver( value => (0..15) );

 Sets the approximate time used to make a measurement.
 This command sets the "average time exponent" controlling
 the measurement times for cold and warm-start measurements.

 The actual time taken can be calculated using the table from
 the manual on this function.

=head2 get_aver

 $AH->get_aver();

=head2 set_bias

 $AH->set_bias( value = (OFF / IHIGH / ILOW) );

 Controls the user-supplied DC bias voltage and selects the
 value of an internal resistor placed in series with this
 voltage.

 OFF:   Disabled
 ILOW:  100 megaohm resistor
 IHIGH: 1 megaohm resistor

=head2 get_bias

 $AH->get_bias();

=head2 set_cable

=head2 get_cable

=head2 get_value

 ($frequency, $capacity, $loss) = $AH->get_value();

 Causes the bridge to take a single measurement. 

=head2 set_wait

=head2 set_field

 $AH->set_field(fi1 => "OFF", fi2 => "OFF", fi3 => 9, fi4 => 9, fi5 => "ON", fi6 => "OFF");

 Controls the fields sent and the number of significant digits
 reported for capacitance and/or loss measurements.

 fi1: send the sample field ON/OFF
 fi2: send the frequency field ON/OFF
 fi3: send the capacitance field and control number of digits
      0..9
 fi4: send the loss field and control number of digits
      0..9
 fi5: send the voltage field ON/OFF
 fi6: send the error field ON/OFF

=head2 set_volt

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2013       Christian Butschkow
            2016       Andreas K. Huettel, Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel
            2022       Mia Schambeck


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
