package Lab::Instrument::Lakeshore224;
#ABSTRACT: Lake Shore 224 temperature monitor
$Lab::Instrument::Lakeshore224::VERSION = '3.899';
use v5.20;

use strict;

use Lab::Instrument;
use Lab::MultiChannelInstrument;
use Carp;

our @ISA = ( "Lab::MultiChannelInstrument", "Lab::Instrument" );

our %fields = (
    supported_connections => [ 'VISA', 'VISA_GPIB', 'GPIB', 'DEBUG' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board      => 0,
        gpib_address    => 12,
        connection_type => 'VISA_GPIB',
        timeout         => 1,
    },

    device_settings => {
        channels => {
            ChA  => 'A',
            ChB  => 'B',
            ChC1 => 'C1',
            ChC2 => 'C2',
            ChC3 => 'C3',
            ChC4 => 'C4',
            ChC5 => 'C5',
            ChD1 => 'D1',
            ChD2 => 'D2',
            ChD3 => 'D3',
            ChD4 => 'D4',
            ChD5 => 'D5',
        },
        channel_default => 'ChA',
        channel         => undef
    },

    device_cache => { T => undef },

    device_cache_order => [],

    multichannel_shared_cache => [],

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub _device_init {
    my $self = shift;

}

sub get_tst {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    return $self->query( "*TST? ", $tail );
}

sub get_T {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    return $self->query( 'KRDG? ' . $self->{channel}, $tail );
}

sub get_R {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    return $self->query( "SRDG? " . $self->{channel}, $tail );
}

sub set_leds {
    my $self = shift;
    my ( $state, $tail ) = $self->_check_args( \@_, ['state'] );

    if ( defined $state and ( $state != 1 and $state != 0 ) ) {
        carp('State has to be 1 or 0');
        return;
    }

    $self->write( "LEDS " . $state, $tail );
}

sub get_leds {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    return $self->query( "LEDS?", $tail );
}

sub reset_minmax {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    $self->write("MNMXRST");

}

sub get_minmax {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    return $self->query( "MDAT?" . $self->{channel}, $tail );
}

sub get_T_Celsius {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    return $self->query( "CRDG? " . $self->{channel}, $tail );
}

sub get_filter {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    return $self->query( "FILTER?" . $self->{channel}, $tail );
}

sub set_filter {
    my $self = shift;
    my ( $on_off, $points, $window, $tail )
        = $self->_check_args( \@_, [ 'on_off', 'points', 'window' ] );

    if ( defined $on_off and ( $on_off != 1 and $on_off != 0 ) ) {
        carp('on_off has to be 1 or 0');
        return;
    }

    if ( defined $points and ( $points < 2 or $points > 64 ) ) {
        carp('Valid range for points is 2 to 64');
        return;
    }

    if ( defined $window and ( $window < 1 or $window > 10 ) ) {
        carp('Valid range for window is 1 to 10');
        return;
    }

    $self->write( "FILTER $self->{channel},$on_off,$points,$window", $tail );
}

sub get_mode {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    return $self->query( "MODE?", $tail );
}

sub set_mode {
    my $self = shift;
    my ( $state, $tail ) = $self->_check_args( \@_, ['state'] );

    if ( defined $state and ( $state < 1 or $state > 2 ) ) {
        carp(
            'State has to be 0 (local), 1 (remote) or 2 (remote with local lockout)'
        );
        return;
    }

    $self->write( "MODE " . $state, $tail );
}

sub get_lock {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    return $self->query( "LOCK?", $tail );
}

sub set_lock {
    my $self = shift;
    my ( $state, $tail ) = $self->_check_args( \@_, ['state'] );

    if ( defined $state and ( $state != 0 and $state != 1 ) ) {
        carp('State has to be 0 (unlocked) or 1 (locked)');
        return;
    }

    $self->write( "LOCK " . $state, $tail );
}

sub get_alarm {
    my $self = shift;
    my ( $state, $tail ) = $self->_check_args( \@_, ['state'] );

    return $self->query( "ALARM?" . $self->{channel}, $tail );
}

sub set_alarm {
    my $self = shift;
    my (
        $on_off,  $high_setpoint, $low_setpoint, $deadband, $latch_enable,
        $audible, $display,       $tail
        )
        = $self->_check_args(
        \@_,
        [
            'on_off',       'high_setpoint', 'low_setpoint', 'deadband',
            'latch_enable', 'audible',       'display'
        ]
        );

    if ( defined $on_off and ( $on_off != 1 and $on_off != 0 ) ) {
        carp('on_off has to be 1 or 0');
        return;
    }

    if ( defined $latch_enable
        and ( $latch_enable != 1 or $latch_enable != 0 ) ) {
        carp('latch_enable has to be 1 or 0');
        return;
    }

    if ( defined $audible and ( $audible != 1 and $audible != 0 ) ) {
        carp('audible has to be 1 or 0');
        return;
    }

    if ( defined $display and ( $display != 1 or $display != 0 ) ) {
        carp('display has to be 1 or 0');
        return;
    }

    $self->write(
        "ALARM $self->{channel}, $on_off, $high_setpoint, $low_setpoint, $deadband, $latch_enable, $audible, $display",
        $tail
    );
}

sub reset_alarm {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );

    $self->write( "ALMRST", $tail );
}

sub get_value {
    my $self = shift;
    return $self->get_T(@_);
}

1;

#----------Include features in measurment scripts-----------------------------------------------------------------------------------------------------------------------------------
# use Lab::Measurement::Legacy;

# my $lake=Instrument('Lakeshore224');

# my $t_sample=$lake->get_value();

# my $minmax = $lake->get_minmax();

# my $celsius = $lake->get_T_Celsius();

# $lake->reset_minmax;

# my $light = $lake->get_leds();

# $lake->set_leds(1);

# my $filter=$lake->get_filter();

# my $mode=$lake->get_mode();

# $lake->set_mode(2);    #State has to be 0 (local), 1 (remote) or 2 (remote with local lockout)

# my $lock = $lake ->get_lock();

# $lake->set_lock(0);

# my $alarm = $lake->get_alarm();

# $lake->reset_alarm();

# $lake->set_alarm({
# on_off => 0,					#0=off, 1=on
# high_setpoint => 296.906,
# low_setpoint => 290.00,
# deadband => 0,					#Sets the value that the source must change outside of an alarm condition to deactivate an unclatched alarm
# latch_enable => 1,				#Specifies wheter alarm remains active after alarm condition correction. 0=off, 1=on
# audible => 0,					#speaker will beep when alarm condition occurs: 0=off, 1=on
# display => 1,					#Alarm LED on front panel will blink when an alarm condition occurs: 0=off, 1=on
# });

# $lake->set_filter({
# on_off => 1,          #Specifies wheter the filter function is 0=Off or 1=On
# points => 2,		  #Specifies how many data points the filtering function uses. Valid range= 2 to 64
# window => 10,		  #Specifies what percent of full scale reading limits the filtering fuction. Valid range = 1 to 10 %
# });

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::Lakeshore224 - Lake Shore 224 temperature monitor (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2015       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
