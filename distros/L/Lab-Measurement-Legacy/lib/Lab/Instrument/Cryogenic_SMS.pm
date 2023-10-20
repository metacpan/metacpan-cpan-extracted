package Lab::Instrument::Cryogenic_SMS;
#ABSTRACT: Cryogenic SMS magnet power supply
$Lab::Instrument::Cryogenic_SMS::VERSION = '3.899';
use v5.20;

use strict;
use Lab::Instrument;

our @ISA = ('Lab::Instrument');

# does not use any magnet supply specific code yet

our %fields = (
    supported_connections => [ 'GPIB', 'VISA' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
    },

    #	device_settings => {
    #	    use_persistentmode          => 0,
    #	    can_reverse                 => 0,
    #	    can_use_negative_current    => 0,
    #	},
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);
    print "Cryogenic SMS magnet supply code is experimental.\n";
    return $self;
}

sub ramp_to_mid {
    my $self = shift;
    $self->write("RAMP MID\n");
    my $status = $self->status();
    while ( $status =~ /HOLDING/ )
    {    # takes care that command is finally executed
        $status = $self->status();

        $status =~ /MID SETTING: (.*) AMPS/;
        my $mid = $1;
        $status =~ /OUTPUT: (.*) AMPS/;
        my $out = $1;

        last if $mid == $out;    # breaks if we have already reached target

        $self->write("RAMP MID\n");
        print "power supply not responding, send command again\n";
        sleep(1);
    }

    while ( $status =~ /RAMPING/ ) {
        $status = $self->status();
        sleep(1);
    }

    $status =~ /MID SETTING: (.*) AMPS/;
    my $mid = $1;
    $status =~ /OUTPUT: (.*) AMPS/;
    my $out = $1;

    return 0 if $mid == $out;
    return 1;
}

sub ramp_to_zero {
    my $self = shift;
    $self->write("RAMP ZERO\n");
    my $status = $self->status();
    while ( $status =~ /HOLDING/ )
    {    # takes care that command is finally executed
        $status = $self->status();

        $status =~ /OUTPUT: (.*) AMPS/;
        my $out = $1;

        last if $out == 0;    # breaks if we have already reached target

        $self->write("RAMP ZERO\n");
        print "power supply not responding, send command again\n";
        sleep(1);
    }

    while ( $status =~ /RAMPING/ ) {
        $status = $self->status();
        sleep(1);
    }

    $status = $self->status();
    $status =~ /OUTPUT: (.*) AMPS/;
    my $out = $1;
    if ( $out == 0 ) {
        return 0;
    }
    return 1;
}

sub ramp_to_max {
    my $self = shift;
    $self->write("RAMP MAX\n");
    my $status = $self->status();
    while ( $status =~ /HOLDING/ )
    {    # takes care that command is finally executed
        $status = $self->status();

        $status =~ /MAX SETTING: (.*) AMPS/;
        my $max = $1;
        $status =~ /OUTPUT: (.*) AMPS/;
        my $out = $1;

        last if $max == $out;    # breaks if we have already reached target

        $self->write("RAMP MID\n");
        print "power supply not responding, send command again\n";
        sleep(1);
    }

    while ( $status =~ /RAMPING/ ) {
        $status = $self->status();
        sleep(1);
    }

    $status =~ /MAX SETTING: (.*) AMPS/;
    my $max = $1;
    $status =~ /OUTPUT: (.*) AMPS/;
    my $out = $1;

    return 0 if $max == $out;
    return 1;
}

sub heater_on {
    my $self = shift;
    $self->write("HEATER ON\n");

    my $status = $self->status();
    while ( $status =~ /HEATER STATUS: OFF/ )
    {    # takes care that command is finally executed
        sleep(1);
        $self->write("HEATER ON\n");
        print "power supply not responding, send command again\n";
        sleep(1);
        $status = $self->status();
    }
    sleep(10);
    return 0;
}

sub heater_off {
    my $self = shift;
    $self->write("HEATER OFF\n");

    my $status = $self->status();
    while ( $status =~ /HEATER STATUS: ON/ )
    {    # takes care that command is finally executed
        sleep(1);
        print "power supply not responding, send command again\n";
        $self->write("HEATER OFF\n");
        sleep(1);
        $status = $self->status();
    }
    sleep(10);
    return 0;
}

sub status {
    my $self = shift;
    my $result = $self->query( command => "U\n", read_length => 1000 );
    for ( my $i = 1; $i <= 20; $i++ ) {
        $result .= $self->query( command => "U\n", read_length => 1000 );

    }
    return $result;
}

sub read_messages {
    my $self = shift;
    my $result = $self->read( read_length => 1000 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::Cryogenic_SMS - Cryogenic SMS magnet power supply (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
