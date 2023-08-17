package Lab::Instrument::AH2700A;
#ABSTRACT: Andeen-Hagerling AH2700A ultra-precision capacitance bridge
$Lab::Instrument::AH2700A::VERSION = '3.881';
use v5.20;

use strict;
use Time::HiRes qw (usleep);
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => [ 'VISA_GPIB', 'GPIB', 'DEBUG', 'DUMMY' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
        timeout      => 2,
        termchar     => "\n"
    },

    device_settings => {

    },

    device_cache => {
        aver => undef,
        frq  => undef,
        bias => undef
    },

    device_cache_order => [],

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub _device_init {

}

sub set_frq {
    my $self = shift;

    # read from cache or from device?
    my ( $frq, $tail ) = $self->_check_args( \@_, ['frq'] );

    if ( $frq < 50 or $frq > 20000 ) {
        Lab::Exception::CorruptParameter->throw(
            error => "bad frequency-parameter!\n" );
    }
    else {
        $self->write( sprintf( "FREQ %d", $frq ), $tail );
    }

}

sub get_frq {
    my $self = shift;

    my $result = $self->query( sprintf("SH FR") );

    $result =~ /(\D+)(\d+\.\d+)(\D+)/;

    return $2;

}

sub set_aver {
    my $self = shift;

    # read from cache or from device?
    my ( $aver, $tail ) = $self->_check_args( \@_, ['aver'] );

    if ( $aver < 0 or $aver > 15 ) {
        Lab::Exception::CorruptParameter->throw(
            error => "bad average-parameter!\n" );
    }
    else {
        $self->write( sprintf( "AV %d", $aver ), $tail );
    }
}

sub get_aver {
    my $self = shift;

    my $result = $self->query( sprintf("SH AV") );

    $result =~ /(\D+)(\D+\=)(\d+)/;

    return $3;

}

sub set_bias {
    my $self = shift;

    # read from cache or from device?
    my ( $bias, $tail ) = $self->_check_args( \@_, ['bias'] );

    if ( $bias eq "OFF" or $bias eq "IHIGH" or $bias eq "ILOW" ) {
        $self->write( sprintf( "BI %s", $bias ), $tail );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            error => "bad bias-parameter!\n" );
    }

}

sub get_bias {
    my $self = shift;

    my $result = $self->query( sprintf("SH BI") );

    $result =~ /(\D+\s)(\D+)/;

    return $2;

}

sub set_bright {
    my $self = shift;

    # read from cache or from device?
    my ( $bright1, $bright2, $tail )
        = $self->_check_args( \@_, [ 'bright1', 'bright2' ] );

    if (
        (
               $bright1 ne 'ALL'
            or $bright1 ne 'C'
            or $bright1 ne 'LOS'
            or $bright1 ne 'OT'
        )
        and ( $bright2 < 0 or $bright2 > 9 )
        ) {
        Lab::Exception::CorruptParameter->throw(
            error => "bad brightness-parameter!\n" );
    }
    if ( $bright1 eq 'ALL' ) {
        $self->write( sprintf( "BR %s %d", $bright1, $bright2 ), $tail );
    }
    if ( $bright1 eq 'C' ) {
        $self->write( sprintf( "BR %s %d", $bright1, $bright2 ), $tail );
    }
    if ( $bright1 eq 'LOS' ) {
        $self->write( sprintf( "BR %s %d", $bright1, $bright2 ), $tail );
    }
    if ( $bright1 eq 'OT' ) {
        $self->write( sprintf( "BR %s %d", $bright1, $bright2 ), $tail );
    }

}

sub get_bright {
    my $self = shift;

    my $result = $self->query( sprintf("SH BR") );

    $result =~ /(\D+\s)(\D\=\d\s\D\=\d\s\D\=\d)/;

    return $2;

}

sub set_cable {
    my $self = shift;

    # read from cache or from device?
    my ( $cab1, $cab2, $tail )
        = $self->_check_args( \@_, [ 'cab1', 'cab2' ] );

    if ( not $cab1 =~ m/L|RES|I|C/ ) {
        Lab::Exception::CorruptParameter->throw(
            error => "bad cable-parameter!\n" );
    }
    else {
        $self->write( sprintf( "CAB %s %d", $cab1, $cab2 ), $tail );
    }

}

sub get_cable {
    my $self = shift;

    my $result = $self->write( sprintf("SH CAB") );

    my @results;

    for ( my $i = 0; $i < 4; $i++ ) {
        my $result = $self->read();
        push( @results, $result );
    }

    print " @results ";

    return @results;

}

# set number of measurements for continuous-mode
sub set_cont {
    my $self = shift;

    # read from cache or from device?
    my ( $cont, $tail ) = $self->_check_args( \@_, ['cont'] );

    if ( $cont > 10 ) {
        Lab::Exception::CorruptParameter->throw(
            error => "number of measurements higher than 10!\n" );
    }
    else {
        $self->write( sprintf( "CO TO %d", $cont ), $tail );
    }
}

# get number of measurements for continuous-mode
sub get_cont {
    my $self = shift;

    my $result = $self->query( sprintf("SH CO TO") );

    $result =~ /(\D+)(\D+\=)(\d+)/;

    return $result;

}

# start continuous-mode
sub cont {
    my $self = shift;

    $self->write("CO");

}

sub get_single {
    my $self = shift;

    # read from cache or from device?
    my ($tail) = $self->_check_args( \@_ );

    my $average = $self->get_aver( { read_mode => "cache" } );
    my $frequency = $self->get_frq( { read_mode => "cache" } );

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

    if ( not defined $tail->{timeout} ) {
        $tail->{timeout} = 100;
    }

    my $result = $self->request( sprintf("SI"), $tail );
    my $values;
    while ( $result =~ /([A-Z])=\s(\d+\.\d+)/g ) {
        $values->{$1} = $2;
    }
    $values->{E} = 00;
    if ( $result =~ /^(\d+)/ and $result != /00/ ) {
        $values->{E} = $1;
        print new Lab::Exception::Warning(
                  error => "Error in get_single. Errorcode = "
                . $values->{E}
                . "\n" );
    }

    if ( wantarray() ) {
        return (
            $values->{C} * 1e-12,
            $values->{L} * 1e-9,
            $values->{V}, $values->{S}, $values->{E}
        );
    }
    else {
        return $values->{C} * 1e-12;
    }

}

sub get_value {
    my $self = shift;

    return $self->get_single(@_);
}

sub set_wait {
    my $self = shift;

    # read from cache or from device?
    my ( $wait, $tail ) = $self->_check_args( \@_, ['wait'] );

    $self->write( sprintf( "WAIT DELAY %d", $wait ), $tail );

}

sub reset {
    my $self = shift;

    $self->write("*RST");

}

# fetch-function
sub get_last {
    my $self = shift;

    $self->write("FE");

}

# controls which fields are sent to GPIB port
sub set_field {
    my $self = shift;

    # read from cache or from device?
    my ( $fi1, $fi2, $fi3, $fi4, $fi5, $fi6, $tail ) = $self->_check_args(
        \@_,
        [ 'fi1', 'fi2', 'fi3', 'fi4', 'fi5', 'fi6' ]
    );

    $self->write(
        sprintf(
            "FIELD %s,%s,%d,%d,%s,%s", $fi1, $fi2, $fi3, $fi4, $fi5, $fi6
        ),
        $tail
    );

}

sub get_field {
    my $self = shift;

    $self->write("SH FI");

}

sub set_gpib {
    my $self = shift;

    # read from cache or from device?
    my ( $gp1, $gp2, $gp3, $gp4, $gp5, $tail )
        = $self->_check_args( \@_, [ 'gp1', 'gp2', 'gp3', 'gp4', 'gp5' ] );

    $self->write(
        sprintf( "GP %d,%d,%s,%s,%s", $gp1, $gp2, $gp3, $gp4, $gp5 ),
        $tail
    );

}

sub get_gpib {
    my $self = shift;

    $self->write("SH GP");

}

# stops remote mode (switches to local mode)
sub go_to_local {
    my $self = shift;

    $self->write("LOC");

}

sub set_date {
    my $self = shift;

    # read from cache or from device?
    my ( $yr, $mo, $day, $tail )
        = $self->_check_args( \@_, [ 'yr', 'mo', 'day' ] );

    $self->write( sprintf( "STO %d,%d,%d", $yr, $mo, $day ), $tail );

}

sub get_date {
    my $self = shift;

    $self->write("SH DATE");

}

sub set_time {
    my $self = shift;

    # read from cache or from device?
    my ( $hr, $min, $sec, $tail )
        = $self->_check_args( \@_, [ 'hr', 'min', 'sec' ] );

    $self->write( sprintf( "STO %d,%d,%d", $hr, $min, $sec ), $tail );

}

sub get_time {
    my $self = shift;

    $self->write("SH TIME");

}

sub set_units {
    my $self = shift;

    # read from cache or from device?
    my ( $units, $tail ) = $self->_check_args( \@_, ['units'] );

    if ( not $units =~ m/NS|DS|KO|GO|JP/ ) {
        Lab::Exception::CorruptParameter->throw(
            error => "bad units-parameter!\n" );
    }
    else {
        $self->write( sprintf( "UN %s", $units ), $tail );
    }

}

sub set_volt {
    my $self = shift;

    # read from cache or from device?
    my ( $volt, $tail ) = $self->_check_args( \@_, ['volt'] );

    $self->write( sprintf( "V %2.2f", $volt ), $tail );

}

sub get_volt {
    my $self = shift;

    my $result = $self->query( sprintf("SH V") );

    $result =~ /(\D+)(\d+\.\d+)(\D+)/;

    return $2;

}

#sub sample_select {}	# only  in conjunction with the sample switch port

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::AH2700A - Andeen-Hagerling AH2700A ultra-precision capacitance bridge

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Christian Butschkow
            2016       Andreas K. Huettel, Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
