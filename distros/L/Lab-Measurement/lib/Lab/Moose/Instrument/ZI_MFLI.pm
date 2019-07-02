package Lab::Moose::Instrument::ZI_MFLI;
$Lab::Moose::Instrument::ZI_MFLI::VERSION = '3.682';
#ABSTRACT: Zurich Instruments MFLI Lock-in Amplifier

use 5.010;
use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

use Lab::Moose::Instrument 'validated_setter';
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
    my $self = shift;
    return $self->cached_frequency(
        $self->get_value(
            path => $self->device() . "/oscs/0/freq",
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
        value => { isa => 'Num' },
    );

    return $self->cached_frequency(
        $self->sync_set_value(
            path  => $self->device() . "/oscs/0/freq", type => 'D',
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
    return $self->cached_voltage_sens(
        $self->get_value(
            path => $self->device() . "/sigins/0/range",
            type => 'D'
        )
    );
}


sub set_voltage_sens {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    return $self->cached_voltage_sens(
        $self->sync_set_value(
            path  => $self->device() . "/sigins/0/range",
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


cache amplitude => ( getter => 'get_amplitude' );

sub get_amplitude {
    my $self = shift;
    return $self->cached_amplitude(
        $self->get_value(
            path => $self->device() . "/sigouts/0/amplitudes/1",
            type => 'D'
        )
    );
}


sub set_amplitude {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    return $self->cached_amplitude(
        $self->sync_set_value(
            path  => $self->device() . "/sigouts/0/amplitudes/1",
            type  => 'D',
            value => $value
        )
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

#
# Demodulators
#


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

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $mfli = instrument(
     type => 'ZI_MFLI',
     connection_type => 'Zhinst',
     connection_options => {
         host => '132.188.12.13',
         port => 8004,
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

 my $freq = $mfli->get_frequency();

Get oscillator frequency.

=head2 get_frq

Alias for L</get_frequency>.

=head2 set_frequency

 $mfli->set_frequency(value => 10000);

Set oscillator frequency.

=head2 set_frq

Alias for L</set_frequency>.

=head2 get_voltage_sens

 my $sens = $mfli->get_voltage_sens();

Get sensitivity (range) of voltage input.

=head2 set_voltage_sens

 $mfli->set_voltage_sens(value => 1);

Set sensitivity (range) of voltage input.

=head2 get_current_sens

 my $sens = $mfli->get_current_sens();

Get sensitivity (range) of current input.

=head2 set_current_sens

 $mfli->set_current_sens(value => 100e-6);

Set sensitivity (range) of current input.

=head2 get_amplitude

 my $amplitude = $mfli->get_amplitude();

Get amplitude of voltage output.

=head2 set_amplitude

 $mfli->set_amplitude(value => 300e-3);

Set amplitude of voltage output.

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

=head2 get_xy

 my $xy_0 = $mfli->get_xy(demod => 0);
 my $xy_1 = $mfli->get_xy(demod => 1);
 
 printf("x: %g, y: %g\n", $xy_0->{x}, $xy_0->{y});

Get demodulator X and Y output measurement values.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Andreas K. Huettel, Simon Reinhardt
            2019       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
