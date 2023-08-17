package Lab::Instrument::MG369xB;
#ABSTRACT: Anritsu MG369xB series signal generator
$Lab::Instrument::MG369xB::VERSION = '3.881';
use v5.20;

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

# Programming manual:
# http://www.anritsu.com/en-GB/Downloads/Manuals/Programming-Manual/DWL2029.aspx

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => ['GPIB'],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
    },

    device_settings => {},

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);
    return $self;
}

sub id {
    my $self = shift;
    return $self->query('*IDN?');
}

sub reset {
    my $self = shift;
    $self->write('RST');
}

sub set_frq {
    my $self = shift;

    my ( $freq, $tail ) = $self->_check_args( \@_, ['value'] );

    $freq /= 1000000;
    $self->write("F0 $freq MH ACW");
}

sub set_power {
    my $self = shift;

    my ( $power, $tail ) = $self->_check_args( \@_, ['value'] );

    $self->write("L0 $power DM");
}

sub get_frq {
    my $self = shift;
    my $frq  = $self->query("OF0");
    return $frq * 1000000;
}

sub get_power {
    my $self  = shift;
    my $power = $self->query("OL0");
    return $power;
}

sub power_on {
    my $self = shift;
    $self->write('RF 1');
}

sub power_off {
    my $self = shift;
    $self->write('RF 0');
}

# SYZ + UP produce distorted signal
sub sweep_single_step {
    my $self = shift;
    my $onoff = (shift) ? "1" : "0";
    $self->write("DU $onoff");
}

sub sweep_trigger_manual {
    my $self = shift;

    # RSS = reset sweep
    $self->write("MNT RSS");
}

# Note: You have to set trigger type
sub init_sweep_linear {
    my $self      = shift;
    my $start     = shift;
    my $stop      = shift;
    my $step_size = shift;

    if ( !defined($stop) ) {

        # Assume $start is a Sweep object
        $step_size = $start->{step_size};
        $stop      = $start->{stop};
        $start     = $start->{start};
    }

    $self->sweep_single_step(1);

    my $next_sweep_start = undef;

    my $nr_of_steps = int( ( $stop - $start ) / ($step_size) );

    my $current_sweep_stop = $start + $step_size * $nr_of_steps;
    print "$nr_of_steps\n";

    if ( $nr_of_steps > 10000 ) {
        $nr_of_steps        = 10000;
        $current_sweep_stop = $start + $step_size * 10000;
        $next_sweep_start   = $current_sweep_stop + $step_size;
    }

    print
        "$nr_of_steps $next_sweep_start $start $step_size $current_sweep_stop\n";
    $self->{next_sweep_start} = $next_sweep_start;
    $self->{stop}             = $stop;
    $self->{step_size}        = $step_size;
    $self->{step_nr}          = 0;                   # Nr of TSS calls
    $self->{nr_of_steps}      = $nr_of_steps;

    $start              /= 1e6;
    $current_sweep_stop /= 1e6;
    $step_size          /= 1e6;

    # SSP = linear step sweep
    # SP0 = equally spaced steps
    # RSS = Reset śweep
    my $cmd
        = "F1 $start MH F2 $current_sweep_stop MH SNS $nr_of_steps SPS SP0 SF1 SSP RSS";
    print "Sending $cmd\n";
    $self->write($cmd);
    sleep(1);
}

sub sweep_next_step {
    my $self = shift;
    if ( $self->{step_nr} >= $self->{nr_of_steps} ) {
        if ( defined( $self->{next_sweep_start} ) ) {
            $self->init_sweep_linear(
                $self->{next_sweep_start},
                $self->{stop}, $self->{step_size}
            );
        }
        else {
            # Output last point
            my $stop = $self->{stop};
            $self->write("CF1 $stop");
            usleep(200000);
        }
    }
    else {
        $self->write("TSS");
        $self->{step_nr}++;
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::MG369xB - Anritsu MG369xB series signal generator

=head1 VERSION

version 3.881

=head1 CAVEATS/BUGS

IMPORTANT: Only works for B series devices. MG369xA use SCPI commands and are 
supported by HP83732A driver.

=head1 SEE ALSO

=over 4

=item * Lab::Instrument

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Hermann Kraus
            2013-2014  Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
