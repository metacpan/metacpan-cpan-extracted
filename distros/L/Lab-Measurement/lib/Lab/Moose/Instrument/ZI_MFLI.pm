package Lab::Moose::Instrument::ZI_MFLI;
$Lab::Moose::Instrument::ZI_MFLI::VERSION = '3.903';
#ABSTRACT: Zurich Instruments MFLI Lock-in Amplifier

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use Moose::Util::TypeConstraints 'enum';
use Lab::Moose::Instrument qw/validated_setter validated_getter/;
use Lab::Moose::Instrument::Cache;
use constant {
    ZI_LIST_NODES_RECURSIVE => 1,
    ZI_LIST_NODES_ABSOLUTE  => 2,
};

extends 'Lab::Moose::Instrument::Zhinst';


# FIXME: warn/croak on AUTO freq, bw, ...

has num_demods => (
    is       => 'ro',
    isa      => 'Int',
    builder  => '_get_num_demods',
    lazy     => 1,
    init_arg => undef,
);

my %oscillator_arg
    = ( oscillator => { isa => 'Lab::Moose::PosInt', optional => 1 } );

my %sigin_arg = ( sigin => { isa => 'Lab::Moose::PosInt' } );

has oscillator => (
    is      => 'ro',
    isa     => 'Lab::Moose::PosInt',
    default => 0
);

sub _get_oscillator {
    my $self = shift;
    my %args = @_;
    my $osc  = delete $args{oscillator};
    if ( not defined $osc ) {
        $osc = $self->oscillator();
    }
    $osc;
}

sub _get_num_demods {
    my $self  = shift;
    my $nodes = $self->list_nodes(
        path => '/',
        mask => ZI_LIST_NODES_ABSOLUTE | ZI_LIST_NODES_RECURSIVE
    );

    my @demods = $nodes =~ m{^/dev\w+/demods/[0-9]+/}gmi;
    @demods = map {
        my $s = $_;
        $s =~ m{/([0-9]+)/$};
        $1;
    } @demods;
    my %hash = map { $_ => 1 } @demods;
    @demods = keys %hash;
    if ( @demods == 0 ) {
        croak "did not find any demods";
    }
    return ( @demods + 0 );
}


cache frequency => ( getter => 'get_frequency' );

sub get_frequency {
    my ( $self, %args ) = validated_hash(
        \@_,
        %oscillator_arg,
    );

    my $osc = $self->_get_oscillator(%args);

    return $self->cached_frequency(
        $self->get_value(
            path => $self->device() . "/oscs/$osc/freq",
            type => 'D'
        )
    );

}

sub get_frq {
    my $self = shift;
    return $self->get_frequency(@_);
}



sub set_frequency {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %oscillator_arg,
        value => { isa => 'Num' },
    );
    my $osc = $self->_get_oscillator(%args);
    return $self->cached_frequency(
        $self->sync_set_value(
            path  => $self->device() . "/oscs/$osc/freq", type => 'D',
            value => $value
        )
    );

}


sub set_frq {
    my $self = shift;
    return $self->set_frequency(@_);
}


cache voltage_sens => ( getter => 'voltage_sens' );

sub get_voltage_sens {
    my $self = shift;
    my ($sigin) = validated_list(
        \@_,
        %sigin_arg,
    );

    return $self->cached_voltage_sens(
        $self->get_value(
            path => $self->device() . "/sigins/$sigin/range",
            type => 'D'
        )
    );
}


sub set_voltage_sens {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
        %sigin_arg,
    );
    my $sigin = delete $args{sigin};
    return $self->cached_voltage_sens(
        $self->sync_set_value(
            path  => $self->device() . "/sigins/$sigin/range",
            type  => 'D',
            value => $value
        )
    );
}


# add methods for various "ON/OFF" properties of the inputs
for my $sigin_arg (qw/diff ac imp50 float autorange on/) {
    my $meta         = __PACKAGE__->meta();
    my $set_function = "set_sigin_$sigin_arg";
    my $get_function = "get_sigin_$sigin_arg";

    # create setter function
    $meta->add_method(
        $set_function => sub {
            my ( $self, $value, %args ) = validated_setter(
                \@_,
                value => { isa => enum( [ 0, 1 ] ) },
                %sigin_arg,
            );
            my $sigin = delete $args{sigin};
            return $self->sync_set_value(
                path  => $self->device() . "/sigins/$sigin/$sigin_arg",
                type  => 'I',
                value => $value
            );
        }
    );

    # create getter function
    $meta->add_method(
        $get_function => sub {
            my $self = shift;
            my ($sigin) = validated_list(
                \@_,
                %sigin_arg,
            );

            return $self->get_value(
                path => $self->device() . "/sigins/$sigin/$sigin_arg",
                type => 'I',
            );
        }
    );
}

sub set__sens {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
        %sigin_arg,
    );
    my $sigin = delete $args{sigin};
    return $self->cached_voltage_sens(
        $self->sync_set_value(
            path  => $self->device() . "/sigins/$sigin/range",
            type  => 'D',
            value => $value
        )
    );
}


cache current_sens => ( getter => 'get_current_sens' );

sub get_current_sens {
    my $self = shift;
    return $self->cached_current_sens(
        $self->get_value(
            path => $self->device() . "/currins/0/range",
            type => 'D'
        )
    );
}


sub set_current_sens {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    return $self->cached_current_sens(
        $self->sync_set_value(
            path  => $self->device() . "/currins/0/range",
            type  => 'D',
            value => $value
        )
    );
}

sub set_sigin_diff {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1 ] ) },
        %sigin_arg,
    );
    my $sigin = delete $args{sigin};

    return $self->sync_set_value(
        path  => $self->device() . "/sigins/$sigin/diff",
        type  => 'I',
        value => $value
    );
}


cache amplitude_range => ( getter => 'get_amplitude_range' );

sub get_amplitude_range {
    my $self = shift;
    return $self->cached_amplitude_range(
        $self->get_value(
            path => $self->device() . "/sigouts/0/range",
            type => 'D'
        )
    );
}


sub set_amplitude_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    return $self->cached_amplitude_range(
        $self->sync_set_value(
            path  => $self->device() . "/sigouts/0/range",
            type  => 'D',
            value => $value
        )
    );
}


sub set_output_status {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1 ] ) },
    );

    return $self->sync_set_value(
        path  => $self->device() . "/sigouts/0/on",
        type  => 'I',
        value => $value,
    );
}

cache offset_voltage => ( getter => 'get_offset_voltage' );


sub get_offset_voltage {
    my $self = shift;
    return $self->cached_offset_voltage(
        $self->get_value(
            path => $self->device() . "/sigouts/0/offset",
            type => 'D'
        )
    );
}


sub set_offset_voltage {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );
    return $self->cached_offset_voltage(
        $self->sync_set_value(
            path  => $self->device() . "/sigouts/0/offset",
            type  => 'D',
            value => $value
        )
    );
}


sub set_offset_status {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1 ] ) },
    );

    return $self->sync_set_value(
        path  => $self->device() . "/sigouts/0/add",
        type  => 'I',
        value => $value,
    );
}

#
# compatibility with XPRESS::Sweep::Voltage sweep
#

sub get_level {
    my $self = shift;
    return $self->get_offset_voltage();
}

sub sweep_to_level {
    my $self = shift;
    my ( $target, $time, $stepwidth ) = @_;
    $self->set_offset_voltage( value => $target );
}

sub config_sweep {
    croak "ZI_MFLI only supports step/list sweep with 'jump => 1'";
}

sub set_voltage {
    my $self  = shift;
    my $value = shift;
    $self->set_offset_voltage( value => $value );
}

my %adcselect_signals = (
    0   => 'sigin1',
    1   => 'currin1',
    2   => 'trigger1',
    3   => 'trigger2',
    4   => 'auxout1',
    5   => 'auxout2',
    6   => 'auxout3',
    7   => 'auxout4',
    8   => 'auxin1',
    9   => 'auxin2',
    174 => 'constant_input',
);
my %adcselect_signals_revers = reverse %adcselect_signals;
my @adcselect_signals        = values %adcselect_signals;

#
# Demodulators
#


sub set_input {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [@adcselect_signals] ) },
        demod => { isa => 'Int' },
    );

    $value = $adcselect_signals_revers{$value};
    my $demod = delete $args{demod};
    $self->sync_set_value(
        path => $self->device() . "/demods/$demod/adcselect",
        type => 'I', value => $value
    );
}

sub get_input {
    my $self = shift;
    my ($demod) = validated_list(
        \@_, demod => { isa => 'Int' },
    );
    my $v = $self->get_value(
        path => $self->device() . "/demods/$demod/adcselect",
        type => 'I'
    );
    return $adcselect_signals{$v};
}


cache phase => ( getter => 'get_phase', index_arg => 'demod' );

sub get_phase {
    my $self = shift;
    my ($demod) = validated_list(
        \@_,
        demod => { isa => 'Int' },
    );

    return $self->cached_phase(
        demod => $demod,
        value => $self->get_value(
            path => $self->device() . "/demods/$demod/phaseshift",
            type => 'D'
        )
    );
}


sub set_phase {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
        demod => { isa => 'Int' },
    );
    my $demod = delete $args{demod};
    return $self->cached_phase(
        demod => $demod,
        value => $self->sync_set_value(
            path => $self->device() . "/demods/$demod/phaseshift",
            type => 'D', value => $value
        )
    );
}


cache tc => ( getter => 'get_tc', index_arg => 'demod' );

sub get_tc {
    my $self = shift;
    my ($demod) = validated_list(
        \@_,
        demod => { isa => 'Int' },
    );
    return $self->cached_tc(
        demod => $demod,
        value => $self->get_value(
            path => $self->device() . "/demods/$demod/timeconstant",
            type => 'D'
        )
    );
}


sub set_tc {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
        demod => { isa => 'Int' },
    );
    my $demod = delete $args{demod};
    return $self->cached_tc(
        demod => $demod,
        value => $self->sync_set_value(
            path  => $self->device() . "/demods/$demod/timeconstant",
            type  => 'D',
            value => $value
        )
    );
}


cache order => ( getter => 'get_order', index_arg => 'demod' );

sub get_order {
    my $self = shift;
    my ($demod) = validated_list(
        \@_,
        demod => { isa => 'Int' },
    );
    return $self->cached_order(
        demod => $demod,
        value => $self->get_value(
            path => $self->device() . "/demods/$demod/order",
            type => 'I'
        )
    );
}


sub set_order {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Int' },
        demod => { isa => 'Int' },
    );
    my $demod = delete $args{demod};
    return $self->cached_order(
        demod => $demod,
        value => $self->sync_set_value(
            path  => $self->device() . "/demods/$demod/order", type => 'I',
            value => $value
        )
    );
}


cache amplitude => ( getter => 'get_amplitude' );

sub get_amplitude {
    my ( $self, %args ) = validated_getter(
        \@_,
        demod => { isa => 'Int' },
    );

    my $demod = delete $args{demod};
    return $self->cached_amplitude(
        $self->get_value(
            path => $self->device() . "/sigouts/0/amplitudes/$demod",
            type => 'D'
        )
    );
}


sub set_amplitude {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
        demod => { isa => 'Int' },
    );
    my $demod = delete $args{demod};
    return $self->cached_amplitude(
        $self->sync_set_value(
            path  => $self->device() . "/sigouts/0/amplitudes/$demod",
            type  => 'D',
            value => $value
        )
    );
}


sub get_amplitude_rms {
    my $self  = shift;
    my $value = $self->get_amplitude(@_);
    return $value / sqrt(2);
}

sub set_amplitude_rms {
    my $self = shift;
    my %args = @_;
    $args{value} *= sqrt(2);
    return $self->set_amplitude(%args);
}

#
# Output commands
#


sub get_xy {
    my $self = shift;
    my ($demod) = validated_list(
        \@_,
        demod => { isa => 'Int' },
    );
    my $demod_sample = $self->get_value(
        path => $self->device() . "/demods/$demod/sample",
        type => 'Demod'
    );

    return { x => $demod_sample->{x}, y => $demod_sample->{y} };
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::ZI_MFLI - Zurich Instruments MFLI Lock-in Amplifier

=head1 VERSION

version 3.903

=head1 SYNOPSIS

 use Lab::Moose;

 my $mfli = instrument(
     type => 'ZI_MFLI',
     connection_type => 'Zhinst',
     oscillator => 1, # 0 is default
     connection_options => {
         host => '132.188.12.13',
         port => 8004, # Note: The HF2LI uses port 8005.
     });

 $mfli->set_frequency(value => 10000);

 # Set time constants of first two demodulators to 0.5 sec:
 $mfli->set_tc(demod => 0, value => 0.5);
 $mfli->set_tc(demod => 1, value => 0.5);

 # Read out demodulators:
 my $xy_0 = $mfli->get_xy(demod => 0);
 my $xy_1 = $mfli->get_xy(demod => 1);
 say "x_0, y_0: ", $xy_0->{x}, ", ", $xy_0->{y};

=head1 METHODS

If the MFLI has the Impedance Analyzer option, calling some of the following
setter options might be without effect. E.g. if the B<Bandwith Control> option
of the Impedance Analyzer module is set, manipulating the time constant with
C<set_tc> will not work.

=head2 get_frequency

 # Get oscillator frequency of default oscillator.
 my $freq = $mfli->get_frequency();


 my $freq = $mfli->get_frequency(oscillator => ...);

=head2 get_frq

Alias for L</get_frequency>.

=head2 set_frequency

 $mfli->set_frequency(value => 10000);

Set oscillator frequency.

=head2 set_frq

Alias for L</set_frequency>.

=head2 get_voltage_sens

 my $sens = $mfli->get_voltage_sens(sigin => 0);

Get sensitivity (range) of voltage input.

=head2 set_voltage_sens

 $mfli->set_voltage_sens(value => 1, sigin => 0);

Set sensitivity (range) of voltage input.

=head2 set_sigin_diff, set_sigin_ac, set_sigin_imp50, set_sigin_float, set_sigin_autorange, set_sigin_on

These all take either C<0> or C<1> as value:

 $mfli->set_sigin_ac(sigin => 0, value => 0); # No AC coupling for first input
 $mfli->set_sigin_imp50(sigin => 0, value => 1); # Use 50 Ohm input impedance for first input

=head2 get_sigin_diff, get_sigin_ac, get_sigin_imp50, get_sigin_float, get_sigin_autorange, get_sigin_on

These all return either C<0> or C<1> as value:

 say $mfli->get_sigin_ac(sigin => 0); # Does the first input use AC coupling?
 $mfli->get_sigin_imp50(sigin => 0); # Is the impedance of the first input 50 Ohms?

=head2 get_current_sens

 my $sens = $mfli->get_current_sens();

Get sensitivity (range) of current input.

=head2 set_current_sens

 $mfli->set_current_sens(value => 100e-6);

Set sensitivity (range) of current input.

=head2 get_amplitude_range

 my $amplitude_range = $mfli->get_amplitude_range();

Get range of voltage output.

=head2 set_amplitude_range

 $mfli->set_amplitude_range(value => 1);

Set amplitude of voltage output.

=head2 set_output_status

 $mfli->set_output_status(value => 1); # Enable output
 $mfli->set_output_status(value => 0); # Disable output

=head2 get_offset_voltage

 my $offset = $mfli->get_offset_voltage();

Get DC offset.

=head2 set_offset_voltage

 $mfli->set_offset_voltage(value => 1e-3);

Set DC offset.

=head2 set_offset_status

 $mfli->set_offset_status(value => 1); # Enable offset voltage
 $mfli->set_offset_status(value => 0); # Disable offset voltage

=head2 set_input/get_input

 $mfli->set_input(demod => 0, value => 'CurrIn1');
 my $signal = $mfli->get_input(demod => 0);

Valid inputs:   currin1, trigger1, trigger2, auxout1, auxout2, auxout3, auxout4, auxin1, auxin2, constant_input

t

=head2 get_phase

 my $phase = $mfli->get_phase(demod => 0);

Get demodulator phase shift.

=head2 set_phase

 $mfli->set_phase(demod => 0, value => 10);

Set demodulator phase.

=head2 get_tc

 my $tc = $mfli->get_tc(demod => 0);

Get demodulator time constant.

=head2 set_tc

 $mfli->set_tc(demod => 0, value => 0.5);

Set demodulator time constant.

=head2 get_order

 my $order = $mfli->get_order(demod => 0);

Get demodulator filter order.

=head2 set_order

 $mfli->set_order(demod => 0, order => 4);

Set demodulator filter order.

=head2 get_amplitude

 # set amplitude for default oscillator
 my $amplitude = $mfli->get_amplitude(demod => ...);

Get peak amplitude of voltage output.

=head2 set_amplitude

 $mfli->set_amplitude(value => ..., demod => ...);

Set peak amplitude of voltage output.

=head2 get_amplitude_rms/set_amplitude_rms

Get/Set root mean square value of amplitude. These are wrappers around get_amplitude/set_amplitude and divide/multiply the peak amplitude with sqrt(2).

=head2 get_xy

 my $xy_0 = $mfli->get_xy(demod => 0);
 my $xy_1 = $mfli->get_xy(demod => 1);
 
 printf("x: %g, y: %g\n", $xy_0->{x}, $xy_0->{y});

Get demodulator X and Y output measurement values.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by the Lab::Measurement team; in detail:

  Copyright 2017       Andreas K. Huettel, Simon Reinhardt
            2019-2020  Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
