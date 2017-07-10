package Lab::Moose::Instrument::ZI_MFLI;
$Lab::Moose::Instrument::ZI_MFLI::VERSION = '3.553';
use 5.010;
use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;


use Lab::Moose::Instrument 'validated_setter';
use constant {
    ZI_LIST_NODES_RECURSIVE => 1,
    ZI_LIST_NODES_ABSOLUTE  => 2,
};

extends 'Lab::Moose::Instrument::Zhinst';

=head1 NAME

Lab::Moose::Instrument::ZI_MFLI - Zurich Instruments MFLI Lock-in Amplifier.

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

=cut

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

=head1 METHODS

If the MFLI has the Impedance Analyzer option, calling some of the following
setter options might be without effect. E.g. if the B<Bandwith Control> option
of the Impedance Analyzer module is set, manipulating the time constant with
C<set_tc> will not work.

=head2 get_frequency

 my $freq = $mfli->get_frequency();

Get oscillator frequency.

=cut

sub get_frequency {
    my $self = shift;
    return $self->get_value(
        path => $self->device() . "/oscs/0/freq",
        type => 'D'
    );
}

=head2 set_frequency

 $mfli->set_frequency(value => 10000);

Set oscillator frequency.

=cut

sub set_frequency {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    return $self->sync_set_value(
        path  => $self->device() . "/oscs/0/freq", type => 'D',
        value => $value
    );
}

=head2 get_voltage_sens

 my $sens = $mfli->get_voltage_sens();

Get sensitivity (range) of voltage input.

=cut

sub get_voltage_sens {
    my $self = shift;
    return $self->get_value(
        path => $self->device() . "/sigins/0/range",
        type => 'D'
    );
}

=head2 set_voltage_sens

 $mfli->set_voltage_sens(value => 1);

Set sensitivity (range) of voltage input.

=cut

sub set_voltage_sens {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    return $self->sync_set_value(
        path  => $self->device() . "/sigins/0/range",
        type  => 'D',
        value => $value
    );
}

=head2 get_current_sens

 my $sens = $mfli->get_current_sens();

Get sensitivity (range) of current input.

=cut

sub get_current_sens {
    my $self = shift;
    return $self->get_value(
        path => $self->device() . "/currins/0/range",
        type => 'D'
    );
}

=head2 set_current_sens

 $mfli->set_current_sens(value => 100e-6);

Set sensitivity (range) of current input.

=cut

sub set_current_sens {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    return $self->sync_set_value(
        path  => $self->device() . "/currins/0/range",
        type  => 'D',
        value => $value
    );
}

=head2 get_amplitude

 my $amplitude = $mfli->get_amplitude();

Get amplitude of voltage output.

=cut

sub get_amplitude {
    my $self = shift;
    return $self->get_value(
        path => $self->device() . "/sigouts/0/amplitudes/1",
        type => 'D'
    );
}

=head2 set_amplitude

 $mfli->set_amplitude(value => 300e-3);

Set amplitude of voltage output.

=cut

sub set_amplitude {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    return $self->sync_set_value(
        path  => $self->device() . "/sigouts/0/amplitudes/1",
        type  => 'D',
        value => $value
    );
}

=head2 get_amplitude_range

 my $amplitude_range = $mfli->get_amplitude_range();

Get range of voltage output.

=cut

sub get_amplitude_range {
    my $self = shift;
    return $self->get_value(
        path => $self->device() . "/sigouts/0/range",
        type => 'D'
    );
}

=head2 set_amplitude_range

 $mfli->set_amplitude_range(value => 1);

Set amplitude of voltage output.

=cut

sub set_amplitude_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    return $self->sync_set_value(
        path  => $self->device() . "/sigouts/0/range",
        type  => 'D',
        value => $value
    );
}

#
# Demodulators
#

=head2 get_phase

 my $phase = $mfli->get_phase(demod => 0);

Get demodulator phase shift.

=cut

sub get_phase {
    my $self = shift;
    my ($demod) = validated_list(
        \@_,
        demod => { isa => 'Int' },
    );
    return $self->get_value(
        path => $self->device() . "/demods/$demod/phaseshift", type => 'D' );
}

=head2 set_phase

 $mfli->set_phase(demod => 0, value => 10);

Set demodulator phase.

=cut

sub set_phase {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
        demod => { isa => 'Int' },
    );
    my $demod = delete $args{demod};
    return $self->sync_set_value(
        path  => $self->device() . "/demods/$demod/phaseshift", type => 'D',
        value => $value
    );
}

=head2 get_tc

 my $tc = $mfli->get_tc(demod => 0);

Get demodulator time constant.

=cut

sub get_tc {
    my $self = shift;
    my ($demod) = validated_list(
        \@_,
        demod => { isa => 'Int' },
    );
    return $self->get_value(
        path => $self->device() . "/demods/$demod/timeconstant",
        type => 'D'
    );
}

=head2 set_tc

 $mfli->set_tc(demod => 0, value => 0.5);

Set demodulator time constant.

=cut

sub set_tc {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
        demod => { isa => 'Int' },
    );
    my $demod = delete $args{demod};
    return $self->sync_set_value(
        path  => $self->device() . "/demods/$demod/timeconstant", type => 'D',
        value => $value
    );
}

=head2 get_order

 my $order = $mfli->get_order(demod => 0);

Get demodulator filter order.

=cut

sub get_order {
    my $self = shift;
    my ($demod) = validated_list(
        \@_,
        demod => { isa => 'Int' },
    );
    return $self->get_value(
        path => $self->device() . "/demods/$demod/order",
        type => 'I'
    );
}

=head2 set_order

 $mfli->set_order(demod => 0, order => 4);

Set demodulator filter order.

=cut

sub set_order {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Int' },
        demod => { isa => 'Int' },
    );
    my $demod = delete $args{demod};
    return $self->sync_set_value(
        path  => $self->device() . "/demods/$demod/order", type => 'I',
        value => $value
    );
}

=head2 get_xy

 my $xy_0 = $mfli->get_xy(demod => 0);
 my $xy_1 = $mfli->get_xy(demod => 1);
 
 printf("x: %g, y: %g\n", $xy_0->{x}, $xy_0->{y});

Get demodulator X and Y output measurement values.

=cut

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
