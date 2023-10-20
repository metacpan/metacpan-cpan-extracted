package Lab::Instrument::Vectormagnet;
#ABSTRACT: ???
$Lab::Instrument::Vectormagnet::VERSION = '3.899';
use v5.20;

use strict;
use Time::HiRes qw/usleep/, qw/time/;
use Math::Trig;
use Lab::Instrument::IPS;
use Lab::XPRESS::hub;
use Lab::Generic;

our @ISA = ('Lab::Generic');

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    my @args  = @_;

    my $hub = new Lab::XPRESS::hub();

    # init the three IPS-instuments for the 3d-vector magnet:
    if ( $args[0] =~ /GPIB|gpib/ ) {
        my $gpib_board     = 0;
        my $gpib_address_x = 1;
        my $gpib_address_y = 2;
        my $gpib_address_z = 3;

        $self->{IPS_x} = new Lab::Instrument::IPS(
            {
                'connection_type' => 'VISA_GPIB',
                'gpib_address'    => $gpib_address_x
            }
        );
        $self->{IPS_y} = new Lab::Instrument::IPS(
            {
                'connection_type' => 'VISA_GPIB',
                'gpib_address'    => $gpib_address_y
            }
        );
        $self->{IPS_z} = new Lab::Instrument::IPS(
            {
                'connection_type' => 'VISA_GPIB',
                'gpib_address'    => $gpib_address_z
            }
        );
    }
    else {

        $self->{IPS_x} = new Lab::Instrument::IPS(
            {
                'connection' => $hub->Connection(
                    'VISA_RS232', { 'rs232_address' => 7 }
                )
            }
        );
        $self->{IPS_y} = new Lab::Instrument::IPS(
            {
                'connection' => $hub->Connection(
                    'VISA_RS232', { 'rs232_address' => 8 }
                )
            }
        );
        $self->{IPS_z} = new Lab::Instrument::IPS(
            {
                'connection' => $hub->Connection(
                    'VISA_RS232', { 'rs232_address' => 9 }
                )
            }
        );
    }

    # set limits:
    $self->{IPS_x}->{LIMITS} = {
        'magneticfield'          => 1,
        'field_intervall_limits' => [ 0, 1 ],
        'rate_intervall_limits'  => [ 0.6, 0.01 ]
    };
    $self->{IPS_y}->{LIMITS} = {
        'magneticfield'          => 1,
        'field_intervall_limits' => [ 0, 1 ],
        'rate_intervall_limits'  => [ 0.6, 0.01 ]
    };
    $self->{IPS_z}->{LIMITS} = {
        'magneticfield'          => 1,
        'field_intervall_limits' => [ 0, 1 ],
        'rate_intervall_limits'  => [ 0.6, 0.01 ]
    };

    # init magnets:
    $self->{IPS_x}->_init_magnet();
    $self->{IPS_y}->_init_magnet();
    $self->{IPS_z}->_init_magnet();

    # set ID:
    $self->{IPS_x}->{ID} = 'IPS_x';
    $self->{IPS_y}->{ID} = 'IPS_Y';
    $self->{IPS_z}->{ID} = 'IPS_Z';

    # set xy-plane as the initial sweeping plane:
    $self->{KAPPA}          = 0;
    $self->{RHO}            = 0;
    $self->{STARTING_SPEED} = 0.6;

    # register instrument:
    push( @{ ${Lab::Instrument::INSTRUMENTS} }, $self );
    return $self

}

sub create_header { }

sub get_config_data {
    my $self = shift;
    return $self;
}

sub abort {
    my $self = shift;

    $self->{IPS_x}->abort();
    $self->{IPS_y}->abort();
    $self->{IPS_z}->abort();

    return;

}

sub trg {
    my $self = shift;

    $self->{IPS_x}->trg();
    $self->{IPS_y}->trg();
    $self->{IPS_z}->trg();

    return;
}

sub active {

    # returns a value > 0 if MAGNET is SWEEPING. Else MAGNET is not sweeping.
    my $self = shift;

    my $active_x = $self->{IPS_x}->active();
    my $active_y = $self->{IPS_y}->active();
    my $active_z = $self->{IPS_z}->active();

    if ( $active_x or $active_y or $active_z ) {
        return 1;
    }
    else {
        return 0;
    }

}

sub wait {

    # waits while magnets are sweeping
    my $self    = shift;
    my $seconds = shift;
    my $min     = 0.5;

    my $time_0 = time();

    if ( not defined $seconds ) {
        while ( $self->active() ) {

            #wait ...
        }
        return 0;
    }
    else {
        while ( $self->active() ) {
            my $time_1 = time();
            if ( ( $time_1 - $time_0 ) > ( $seconds - $min ) ) {
                if ( ( $seconds - ( $time_1 - $time_0 ) ) < 0 ) {
                    last;
                }
                usleep( ( $seconds - ( $time_1 - $time_0 ) ) * 1e6 );
                last;
            }
        }
        return 0;
    }

}

sub get_value {
    my $self = shift;
    return $self->get_field(@_);
}

sub get_field {
    my $self = shift;
    my ( $mode, $tail ) = $self->_check_args( \@_, ['mode'] );
    my @field;

    if ( $tail->{read_mode} eq 'request' ) {
        $self->{IPS_x}->get_field( { read_mode => 'request' } );
        $self->{IPS_y}->get_field( { read_mode => 'request' } );
        $self->{IPS_z}->get_field( { read_mode => 'request' } );
    }

    my $x = $self->{IPS_x}->get_field();
    my $y = $self->{IPS_y}->get_field();
    my $z = $self->{IPS_z}->get_field();

    if ( not defined $mode ) {
        $mode = 's';
    }

    if ( $mode =~ /^(spherical|SPHERICAL|s|s)$/ ) {

        # returns BR, PHI, THETA:
        my ( $r, $phi, $theta ) = cartesian_to_spherical( $x, $y, $z );
        $phi   = ( $phi / pi ) * 180;
        $theta = ( $theta / pi ) * 180;
        $self->{value} = [ $r, $theta, $phi ];
    }
    elsif ( $mode =~ /^(cartesian|CARTESIAN|C|c)$/ ) {

        # returns X, Y, Z:
        $self->{value} = [ $x, $y, $z ];
    }
    elsif ( $mode =~ /^(all|ALL|A|a)$/ ) {

        # returns BR, PHI, THETA, X, Y, Z:
        my ( $r, $phi, $theta ) = cartesian_to_spherical( $x, $y, $z );
        $phi   = ( $phi * 180 ) / pi;
        $theta = ( $theta * 180 ) / pi;
        $r
            = ( ( $theta <= 90 ) and ( $phi > -90 and $phi <= 90 ) )
            ? $r
            : -$r;
        $self->{value} = [ $r, $theta, $phi, $x, $y, $z ];
    }

    if ( wantarray() ) {
        return @{ $self->{value} };
    }
    else {
        return $self->{value};
    }

}

sub change_plane {
    my $self           = shift;
    my $kappa          = shift;
    my $rho            = shift;
    my $starting_speed = shift;
    if ( defined $kappa ) {
        $self->{KAPPA} = $kappa;
    }
    if ( defined $rho ) {
        $self->{RHO} = $rho;
    }
    if ( defined $starting_speed ) {
        $self->{STARTING_SPEED} = $starting_speed;
    }
}

sub config_CIRC_sweep {
    my $self = shift;

    my ( $B_R, $phi_start, $phi_stop, $v_phi, $interval, $resolution )
        = $self->_check_args(
        \@_,
        [ 'b_r', 'phi_start', 'phi_stop', 'rate', 'interval', 'resolution' ]
        );

    if ( not defined $interval ) {
        $interval = 1;
    }
    if ( not defined $v_phi ) {
        $v_phi = 1;
    }
    if ( not defined $resolution ) {
        $resolution = ( $v_phi / 60 ) * 2 * $interval;
    }
    if ( not defined $phi_start ) {
        $phi_start = -180;
    }
    if ( not defined $phi_stop ) {
        $phi_stop = +180;
    }
    if ( not defined $B_R ) {
        die "B_R is mandatory value in sub config_CIRC_sweep\n";
    }

    my ( $x, $y, $z, $vx, $vy, $vz ) = $self->create_basic_trace(
        $B_R, $phi_start, $phi_stop, $v_phi,
        $resolution
    );
    my @x  = @$x;
    my @y  = @$y;
    my @z  = @$z;
    my @vx = @$vx;
    my @vy = @$vy;
    my @vz = @$vz;

    # my $l = @x;

    # use Lab::XPRESS::Data::XPRESS_DataFile;

    # my $file = new Lab::XPRESS::Data::XPRESS_DataFile('test.dat');
    # $file->add_column('X');
    # $file->add_column('Y');
    # $file->add_column('Z');
    # $file->add_column('VX');
    # $file->add_column('VY');
    # $file->add_column('VZ');

    # for (my $i = 0; $i < $l; $i++) {

    # $file->LOG({
    # 'X' => $x[$i],
    # 'Y' => $y[$i],
    # 'Z' => $z[$i],
    # 'VX' => $vx[$i],
    # 'VY' => $vy[$i],
    # 'VZ' => $vz[$i],
    # });
    # }

    # exit;

    my ( $x_c, $y_c, $z_c ) = $self->get_field('C');
    if ( ( $x_c, $y_c, $z_c ) != ( $x[0], $y[0], $z[0] ) ) {
        $self->config_DIR_sweep(
            $x[0], $y[0], $z[0], $self->{STARTING_SPEED},
            1,     'C'
        );
        print "Goto starting point...";
        $self->trg();
        $self->wait();
        print " done\n";
    }

    my @X = $self->{IPS_x}->config_sweep( \@x, \@vx, $interval );
    my @Y = $self->{IPS_y}->config_sweep( \@y, \@vy, $interval );
    my @Z = $self->{IPS_z}->config_sweep( \@z, \@vz, $interval );

    my @r;
    my @phi;
    my @theta;
    my @dphi;
    my $len_x = @X;
    my $len_y = @Y;
    my $len_z = @Z;
    my $len   = ( $len_x >= $len_y ) ? $len_x : $len_y;
    $len = ( $len >= $len_z ) ? $len : $len_z;

    for ( my $i = 0; $i < $len; $i++ ) {
        if ( ( my $len_x = @X ) >= $i ) {
            push( @X, $X[-1] );
        }
        if ( ( my $len_y = @Y ) >= $i ) {
            push( @Y, $Y[-1] );
        }
        if ( ( my $len_z = @Z ) >= $i ) {
            push( @Z, $Z[-1] );
        }
        ( $r[$i], $phi[$i], $theta[$i] )
            = cartesian_to_spherical( $X[$i], $Y[$i], $Z[$i] );
        $phi[$i]   = ( $phi[$i] * 180 ) / pi;
        $theta[$i] = ( $theta[$i] * 180 ) / pi;
        $dphi[$i]  = $phi[$i] - $phi[0];
    }

    return \@r, \@theta, \@phi, \@dphi, \@X, \@Y, \@Z;

}

sub config_DIR_sweep {
    my $self = shift;

    my ( $B_R, $theta, $phi, $rate, $interval, $mode ) = $self->_check_args(
        \@_,
        [ 'b_r', 'theta', 'phi', 'rate', 'interval', 'mode' ]
    );

    my ( $x_1, $y_1, $z_1 );

    if ( $mode =~ /^(cartesian|CARTESIAN|c|C)$/ ) {
        $x_1 = $B_R;
        $y_1 = $theta;
        $z_1 = $phi;
    }
    elsif ( not defined $mode or $mode =~ /^(spherical|SPHERICAL|s|S)$/ ) {
        $mode = 'spherical';
        $B_R  = abs($B_R);
        ( $x_1, $y_1, $z_1 ) = spherical_to_cartesian(
            $B_R, pi * $phi / 180,
            pi * $theta / 180
        );
    }
    else {
        die
            "Give mode for magnetic field sweep in Vectormagnet is not supported. \n";
    }

    if ( not defined $interval ) {
        $interval = 1;
    }

    if ( ( $x_1**2 + $y_1**2 + $z_1**2 ) > 1.01 ) {
        die
            "unexpected values in sub config_DIR_sweep. Magnetude of target magnetic field > 1 Tesla.";
    }

    if ( $rate <= 0 ) {
        die "unexpected value for RATE ($rate) in sub config_DIR_sweep.";
    }

    # get current magnetic field:
    my ( $x_0, $y_0, $z_0 ) = $self->get_field('C');

    #calculate sweep parameter:
    my $trace_length
        = ( ( $x_1 - $x_0 )**2 + ( $y_1 - $y_0 )**2 + ( $z_1 - $z_0 )**2 )
        **0.5;
    my $sweep_time = $trace_length / $rate;
    my $rate_x;
    my $rate_y;
    my $rate_z;

    if ( $sweep_time == 0 ) {
        $rate_x = 0.1;
        $rate_y = 0.1;
        $rate_z = 0.1;
    }
    else {
        $rate_x = abs( ( $x_1 - $x_0 ) / $sweep_time );
        $rate_y = abs( ( $y_1 - $y_0 ) / $sweep_time );
        $rate_z = abs( ( $z_1 - $z_0 ) / $sweep_time );
    }

    # config sweep:
    my @X = $self->{IPS_x}->config_sweep( $x_1, $rate_x, $interval );
    my @Y = $self->{IPS_y}->config_sweep( $y_1, $rate_y, $interval );
    my @Z = $self->{IPS_z}->config_sweep( $z_1, $rate_z, $interval );

    # calculate trace:
    my @r;
    my @phi;
    my @theta;
    my @dphi;
    my $len_x = @X;
    my $len_y = @Y;
    my $len_z = @Z;
    my $len   = ( $len_x >= $len_y ) ? $len_x : $len_y;
    $len = ( $len >= $len_z ) ? $len : $len_z;

    for ( my $i = 0; $i < $len; $i++ ) {
        if ( ( my $len_x = @X ) >= $i ) {
            push( @X, $X[-1] );
        }
        if ( ( my $len_y = @Y ) >= $i ) {
            push( @Y, $Y[-1] );
        }
        if ( ( my $len_z = @Z ) >= $i ) {
            push( @Z, $Z[-1] );
        }
        ( $r[$i], $phi[$i], $theta[$i] )
            = cartesian_to_spherical( $X[$i], $Y[$i], $Z[$i] );
        $phi[$i]   = ( $phi[$i] * 180 ) / pi;
        $theta[$i] = ( $theta[$i] * 180 ) / pi;
        $dphi[$i]  = $phi[$i] - $phi[0];
    }

    printf(
        "Vectormagnet: estimate total duration for sweep: %dm %ds\n",
        ( ( $len / 60 ) * $interval ),
        ( ( ( $len / 60 ) * $interval ) % 1 ) * 60
    );
    return \@r, \@theta, \@phi, \@dphi, \@X, \@Y, \@Z;

}

sub cartesian_to_spherical {
    my ( $x, $y, $z ) = @_;

    my $rho = sqrt( $x * $x + $y * $y + $z * $z );

    return ( $rho, atan2( $y, $x ), $rho ? acos_real( $z / $rho ) : 0 );
}

sub spherical_to_cartesian {
    my ( $rho, $theta, $phi ) = @_;

    return (
        $rho * cos($theta) * sin($phi),
        $rho * sin($theta) * sin($phi),
        $rho * cos($phi)
    );
}

sub acos_real {
    return 0  if $_[0] >= 1;
    return pi if $_[0] <= -1;
    return acos( $_[0] );
}

sub Trafo_RHO {
    my $self = shift;
    my $x    = shift;
    my $y    = shift;
    my $z    = shift;

    my $X = $x * cos( pi * $self->{RHO} / 180 )
        + $y * cos( pi * ( $self->{RHO} + 90 ) / 180 );
    my $Y = $x * cos( pi * ( $self->{RHO} - 90 ) / 180 )
        + $y * cos( pi * $self->{RHO} / 180 );
    my $Z = $z;

    return $X, $Y, $Z;

}

sub Trafo_KAPPA {
    my $self = shift;
    my $x    = shift;
    my $y    = shift;
    my $z    = shift;

    my $X = $x * cos( pi * $self->{KAPPA} / 180 )
        + $z * cos( pi * ( 90 - $self->{KAPPA} ) / 180 );
    my $Y = $y;
    my $Z = $x * cos( pi * ( $self->{KAPPA} - 90 ) / 180 )
        + $z * cos( -1 * pi * $self->{KAPPA} / 180 );

    return $X, $Y, $Z;

}

sub create_basic_trace {
    my $self       = shift;
    my $R          = shift;
    my $phi_start  = shift;
    my $phi_stop   = shift;
    my $v          = shift;
    my $resolution = shift;

    # resoltion:
    if (   not defined $resolution
        or not defined $v
        or not defined $phi_start
        or not defined $phi_stop
        or not defined $R ) {
        die
            "ERROR in sub 'create_basic_trace'. Some of the parameters are not defined.";
    }

    # calculate magnet sweep trace points:
    my @x;
    my @y;
    my @z;
    my $n = 0;
    print "PHI STOP" . $phi_stop . "\n";
    print "Res = " . $resolution . "\n";
    for ( my $i = $phi_start; $i < $phi_stop; $i += $resolution ) {

        $x[$n] = $R * cos( pi * ($i) / 180 );
        $y[$n] = $R * sin( pi * ($i) / 180 );
        $z[$n] = 0;

        #print $x[$n]."\t".$y[$n]."\t".$z[$n]."\n";
        ( $x[$n], $y[$n], $z[$n] )
            = $self->Trafo_KAPPA( $x[$n], $y[$n], $z[$n] );
        ( $x[$n], $y[$n], $z[$n] )
            = $self->Trafo_RHO( $x[$n], $y[$n], $z[$n] );
        $n++;
    }

    # Add Phi_stop (final value) to points array
    $x[$n] = $R * cos( pi * ($phi_stop) / 180 );
    $y[$n] = $R * sin( pi * ($phi_stop) / 180 );
    $z[$n] = 0;

    #print $x[$n]."\t".$y[$n]."\t".$z[$n]."\n";
    ( $x[$n], $y[$n], $z[$n] ) = $self->Trafo_KAPPA( $x[$n], $y[$n], $z[$n] );
    ( $x[$n], $y[$n], $z[$n] ) = $self->Trafo_RHO( $x[$n], $y[$n], $z[$n] );

    # calculate magnet sweep rate:
    my @vx;
    my @vy;
    my @vz;
    my $len = @x;
    for ( my $i = 0; $i < $len; $i++ ) {
        $vx[$i] = abs(
            (
                      $x[ ( $i == $len - 1 ) ? $i     : $i + 1 ]
                    - $x[ ( $i == $len - 1 ) ? $i - 1 : $i ]
            ) / ( ( $resolution / $v ) )
        );
        $vy[$i] = abs(
            (
                      $y[ ( $i == $len - 1 ) ? $i     : $i + 1 ]
                    - $y[ ( $i == $len - 1 ) ? $i - 1 : $i ]
            ) / ( ( $resolution / $v ) )
        );
        $vz[$i] = abs(
            (
                      $z[ ( $i == $len - 1 ) ? $i     : $i + 1 ]
                    - $z[ ( $i == $len - 1 ) ? $i - 1 : $i ]
            ) / ( ( $resolution / $v ) )
        );
    }

    #open LOG2, ">test2.dat";
    #my $len = @x;
    #for ( my $i =0; $i < $len; $i++)
    # {
    # print LOG2 $x[$i]."\t".$y[$i]."\t".$z[$i]."\t".$vx[$i]."\t".$vy[$i]."\t".$vz[$i]."\n";
    # }
    #close LOG2;

    return \@x, \@y, \@z, \@vx, \@vy, \@vz;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::Vectormagnet - ??? (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Christian Butschkow
            2014       Andreas K. Huettel
            2015       Christian Butschkow
            2016       Christian Butschkow, Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
