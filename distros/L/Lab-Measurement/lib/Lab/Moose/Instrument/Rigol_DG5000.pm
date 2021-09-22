package Lab::Moose::Instrument::Rigol_DG5000;
$Lab::Moose::Instrument::Rigol_DG5000::VERSION = '3.772';
#ABSTRACT: Rigol DG5000 series Function/Arbitrary Waveform Generator

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw/enum/;
use List::Util qw/sum/;
use List::MoreUtils qw/minmax/;
use Math::Round;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter validated_getter validated_setter/;
use Lab::Moose::Instrument::Cache;
use Carp 'croak';
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

has instrument_nselect => (
    is      => 'ro',
    isa     => 'Int',
    default => 1
);

has function => (
    is      => 'ro',
    isa     => enum([qw/SIN SQU RAMP PULSE NOISE USER DC SINC EXPR EXPF CARD GAUS HAV LOR ARBPULSE DUA/]),
    default => 'SIN'
);

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x1ab1, pid => 0x0640 };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
    $self->source_function_shape(channel => $self->instrument_nselect, value => $self->function);
    if ($self->function eq 'PULSE'){
      $self->write(command => ":SOURce".$self->instrument_nselect.":PULSe:TRANsition:LEADing 0.0000000025");
      $self->write(command => ":SOURce".$self->instrument_nselect.":PULSe:TRANsition:TRAiling 0.0000000025");
    }
    $self->set_level_low(channel => $self->instrument_nselect, value => 0);
    $self->output_on(channel => $self->instrument_nselect);
}

sub get_default_channel {
  my $self = shift;
  return $self->instrument_nselect;
}


#
# MY FUNCTIONS
#


sub gen_arb_step {
  my ( $self, $channel, %args ) = validated_channel_getter(
      \@_,
      sequence => { isa => 'ArrayRef' },
      bdelay => { isa => 'Num' , default => 0},
      bcycles => { isa => 'Num', default => 1}
  );
  my ($sequence, $bdelay, $bcycles )
      = delete @args{qw/sequence bdelay bcycles/};
  my @data = @$sequence; # Dereference the input data

  # If number of input data points is uneven croak
  if (@data % 2 != 0) {croak "Please enter an even number of arguments with
    the layout <amplitude1[V]>,<length1[s]>,<amplitude2[V]>,<length2[s]>,...";};

  # Split input data into the time lengths and amplitude values...
  my @times = @data[ grep { $_ % 2 == 1 } 0..@data-1 ];
  my @amps = @data[grep { $_ % 2 == 0 } 0..@data-1 ];
  # ...and compute the period lentgth as well as the min and max amplitude
  my $period = sum @times;
  my ($minamp, $maxamp) = minmax @amps;

  # now apply everything to the Rigol: Frequency = 1/T, amplitude and offset
  # are computed, so that the whole waveform lies within that amplitude range
  $self->source_apply_arb(channel => $channel, freq => 1/$period, amp => 2*abs($maxamp)+2*abs($minamp), offset => $maxamp+$minamp, phase => 0.0);
  $self->arb_mode(channel => $channel, value => 'INTernal');
  $self->trace_data_points_interpolate(value => 'OFF');

  # Convert all amplitudes into values from 0 to 16383 (14Bit) and generate
  # 16384 data points in total
  my $input = "";
  my $counter;

  # go through each amp (or time) value
  foreach (0..@amps-1){
    # Compute what length in units of the resolution (16384) each step has
    my $c = round(16383*$times[$_]/$period);
    $counter += $c; # Count them all up
    # On the last iteration check, if there are really 16384 data points,
    # there might be less because of rounding. Add the remaining at the end if
    # necessary
    if ($_ == @amps-1 && $counter != 16384) {$c += 16384-$counter};
    # Lastly append the according amplitude value (in 14Bit resolution) to the
    # whole string
    $input = $input.(",".round(16383*$amps[$_]/(1.5*$maxamp-0.5*$minamp))) x $c;
  };
  # Finally download everything to the volatile memory
  $self->trace_data_points(value => 16384);
  $self->trace_data_dac(value => $input);

  # WIP: If a burst delay and number of cycles is given, enable burst mode
  my $off =  0;
  if ($bdelay > 0){
    $self->source_burst_mode(channel => $channel, value => 'TRIG');
    $self->source_burst_tdelay(channel => $channel, value => $bdelay);
    $self->source_burst_ncycles(channel => $channel, value => $bcycles);
    $self->source_burst_state(channel => $channel, value => 'ON');

    $self->trace_data_value(point => 0, data => 0);
    $self->trace_data_value(point => 16383, data => 0);
    $off = $amps[0];
  };
}


sub arb_mode {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/INT INTernal PLAY/] ) }
    );

    $self->write( command => ":SOURCE${channel}:FUNCtion:ARB:MODE $value", %args );
}


sub play_coefficient {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );
    if ($value < 0 or $value > 268435456){
      croak "The the frequency division coefficient must be between 0 and 268435456";
    };

    $self->write( command => ":SOURCE${channel}:FUNCtion:ARB:SAMPLE $value", %args );
}


sub phase_align {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_, );

    $self->write( command => ":SOURce${channel}:PHASe:INITiate", %args );
}


sub output_on {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    $self->write(command => ":OUTPut${channel}:STATe ON");
}

sub output_off {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    $self->write(command => ":OUTPut${channel}:STATe OFF");
}


sub set_pulsewidth {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' },
        constant_delay => { isa => 'Bool', default => 0}
    );
    my $constant_delay = delete $args{'constant_delay'};
    if ($constant_delay){
      my $delay = $self->get_pulsedelay();
      $self->set_period(channel => $channel, value => $delay+$value);
    }

    $self->write( command => ":SOURce${channel}:PULSe:WIDTh $value", %args );
}

sub get_pulsewidth {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->query( command => ":SOURce${channel}:PULSe:WIDTh?", %args );
}


sub set_pulsedelay {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' },
        constant_width => { isa => 'Bool', default => 0}
    );
    my $constant_width = delete $args{'constant_width'};
    if ($constant_width){
      my $width = $self->get_pulsewidth();
      $self->set_period(channel => $channel, value => $width+$value);
    }

    $self->write( command => ":SOURce${channel}:PULSe:DELay $value", %args );
}

sub get_pulsedelay {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->query( command => ":SOURce${channel}:PULSe:DELay?", %args );
}


sub set_period {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write( command => ":SOURce${channel}:PERiod $value", %args );
}

sub get_period{
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->query( command => ":SOURce${channel}:PERiod?", %args );
}


sub set_frq {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write( command => ":SOURce${channel}:FREQuency $value", %args );
}

sub get_frq{
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->query( command => ":SOURce${channel}:FREQuency?", %args );
}


sub set_voltage {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write( command => ":SOURce${channel}:VOLTage:AMPLitude $value", %args );
}

sub get_voltage{
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->query( command => ":SOURce${channel}:VOLTage:AMPLitude?", %args );
}


sub set_level {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write( command => ":SOURce${channel}:VOLTage:HIGH $value", %args );
}

sub get_level{
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->query( command => ":SOURce${channel}:VOLTage:HIGH?", %args );
}


sub set_level_low {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write( command => ":SOURce${channel}:VOLTage:LOW $value", %args );
}

sub get_level_low{
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->query( command => ":SOURce${channel}:VOLTage:LOW?", %args );
}


sub set_offset {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write( command => ":SOURce${channel}:AMPLitude:OFFSet $value", %args );
}

sub get_offset{
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->query( command => ":SOURce${channel}:AMPLitude:OFFSet?", %args );
}

#
# SOURCE APPLY
#



sub source_apply_ramp {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        freq   => { isa => 'Num' },
        amp    => { isa => 'Num' },
        offset => { isa => 'Num' },
        phase  => { isa => 'Num' },
    );

    my ( $freq, $amp, $offset, $phase )
        = delete @args{qw/freq amp offset phase/};

    $self->write(
        command => "SOURCE${channel}:APPLY:RAMP $freq,$amp,$offset,$phase",
        %args
    );
}


sub source_apply_pulse {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        freq   => { isa => 'Num' },
        amp    => { isa => 'Num' },
        offset => { isa => 'Num' },
        delay  => { isa => 'Num' },
    );

    my ( $freq, $amp, $offset, $delay )
        = delete @args{qw/freq amp offset delay/};

    $self->write(
        command => "SOURCE${channel}:APPLY:PULSE $freq,$amp,$offset,$delay",
        %args
    );
}


sub source_apply_sinusoid {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        freq   => { isa => 'Num' },
        amp    => { isa => 'Num' },
        offset => { isa => 'Num' },
        phase  => { isa => 'Num' },
    );

    my ( $freq, $amp, $offset, $phase )
        = delete @args{qw/freq amp offset phase/};

    $self->write(
        command => "SOURCE${channel}:APPLY:SINUSOID $freq,$amp,$offset,$phase",
        %args
    );
}


sub source_apply_square {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        freq   => { isa => 'Num' },
        amp    => { isa => 'Num' },
        offset => { isa => 'Num' },
        phase  => { isa => 'Num' },
    );

    my ( $freq, $amp, $offset, $phase )
        = delete @args{qw/freq amp offset phase/};

    $self->write(
        command => "SOURCE${channel}:APPLY:SQUare $freq,$amp,$offset,$phase",
        %args
    );
}


sub source_apply_arb {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        freq   => { isa => 'Num' },
        amp    => { isa => 'Num' },
        offset => { isa => 'Num' },
        phase  => { isa => 'Num' },
    );

    my ( $freq, $amp, $offset, $phase )
        = delete @args{qw/freq amp offset phase/};

    $self->write(
        command => "SOURCE${channel}:APPLY:USER $freq,$amp,$offset,$phase",
        %args
    );
}

#
# SOURCE BURST
#


sub source_burst_mode {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/TRIG GAT INF/] ) }
    );

    $self->write( command => "SOURCE${channel}:BURST:MODE $value", %args );
}

sub source_burst_mode_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query( command => "SOURCE${channel}:BURST:MODE?", %args );
}


sub source_burst_ncycles {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosInt' }
    );

    $self->write( command => "SOURCE${channel}:BURST:NCYCLES $value", %args );
}

sub source_burst_ncycles_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:BURST:NCYCLES?",
        %args
    );
}


sub source_burst_state {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) }
    );

    $self->write( command => "SOURCE${channel}:BURST:STATE $value", %args );
}

sub source_burst_state_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query( command => "SOURCE${channel}:BURST:STATE?", %args );
}


sub source_burst_tdelay {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );

    $self->write( command => "SOURCE${channel}:BURST:TDELAY $value", %args );
}

sub source_burst_tdelay_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query( command => "SOURCE${channel}:BURST:TDELAY?", %args );
}


sub source_burst_trigger {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    $self->write(
        command => "SOURCE${channel}:BURST:TRIGGER:IMMEDIATE",
        %args
    );
}


sub source_burst_trigger_slope {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/POS NEG/] ) }
    );

    $self->write(
        command => "SOURCE${channel}:BURST:TRIGGER:SLOPE $value",
        %args
    );
}

sub source_burst_trigger_slope_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:BURST:TRIGGER:SLOPE?",
        %args
    );
}


sub source_burst_trigger_trigout {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/OFF POS NEG/] ) }
    );

    $self->write(
        command => "SOURCE${channel}:BURST:TRIGGER:TRIGOUT $value",
        %args
    );
}

sub source_burst_trigger_trigout_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:BURST:TRIGGER:TRIGOUT?",
        %args
    );
}


sub source_burst_trigger_source {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => enum( [qw/INT EXT/] ) }
    );

    $self->write(
        command => "SOURCE${channel}:BURST:TRIGGER:SOURCE $value",
        %args
    );
}

sub source_burst_trigger_source_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:BURST:TRIGGER:SOURCE?",
        %args
    );
}


sub source_burst_period {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );

    $self->write( command => "SOURCE${channel}:BURST:INTERNAL:PERIOD $value", %args );
}

#
# SOURCE FUNCTION
#


sub source_function_shape {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => {
            isa => enum(
                [
                    qw/SIN SQU RAMP PULSE NOISE USER DC SINC EXPR EXPF CARD GAUS HAV LOR ARBPULSE DUA/
                ]
            )
        }
    );

    $self->write(
        command => "SOURCE${channel}:FUNCTION:SHAPE $value",
        %args
    );
}

sub source_function_shape_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:FUNCTION:SHAPE?",
        %args
    );
}


sub source_function_ramp_symmetry {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );

    $self->write(
        command => "SOURCE${channel}:FUNCTION:RAMP:SYMMETRY $value",
        %args
    );
}

sub source_function_ramp_symmetry_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query(
        command => "SOURCE${channel}:FUNCTION:RAMP:SYMMETRY?", %args );
}

#
# SOURCE PERIOD
#


sub source_period_fixed {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );

    $self->write( command => "SOURCE${channel}:PERIOD:FIXED $value", %args );
}

sub source_period_fixed_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );
    return $self->query( command => "SOURCE${channel}:PERIOD:FIXED?", %args );
}

#
# TRACE
#


sub trace_data_data {
    my ( $self, %args ) = validated_getter(
        \@_,
        data => { isa => 'ArrayRef[Num]' }
    );

    my $data = delete $args{data};
    my @data = @{$data};
    if ( @data < 1 ) {
        croak("empty data argument");
    }

    $data = join( ',', @data );

    $self->write( command => "TRACE:DATA:DATA VOLATILE,$data", %args );
}


sub trace_data_value {
    my ( $self, %args ) = validated_getter(
        \@_,
        point => { isa => 'Lab::Moose::PosInt' },
        data  => { isa => 'Num' }
    );
    my $point = delete $args{point};
    my $data  = delete $args{data};

    $self->write(
        command => "TRACE:DATA:VALUE VOLATILE,$point,$data",
        %args
    );
}

sub trace_data_value_query {
    my ( $self, %args ) = validated_getter(
        \@_,
        point => { isa => 'Lab::Moose::PosInt' },
    );
    my $point = delete $args{point};

    return $self->query(
        command => "TRACE:DATA:VALUE? VOLATILE,$point",
        %args
    );
}


sub trace_data_points {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosInt' }
    );

    if ( $value < 2 ) {
        croak("The minimum number of inital data points is 2");
    }

    $self->write( command => "TRACE:DATA:POINTS VOLATILE,$value", %args );
}

sub trace_data_points_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "TRACE:DATA:POINTS? VOLATILE", %args );
}


sub trace_data_points_interpolate {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/LIN SINC OFF/] ) },
    );
    $self->write( command => "TRACE:DATA:POINTS:INTERPOLATE $value", %args );
}

sub trace_data_points_interpolate_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "TRACE:DATA:POINTS:INTERPOLATE?", %args );
}


sub trace_data_dac {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Str' }
    );
    if (substr($value, 0, 1) eq ','){
      $self->write( command => "TRACE:DATA:DAC VOLATILE$value", %args );
    } else {
      $self->write( command => "TRACE:DATA:DAC VOLATILE,$value", %args );
    }
}

with qw(
    Lab::Moose::Instrument::Common
);

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Rigol_DG5000 - Rigol DG5000 series Function/Arbitrary Waveform Generator

=head1 VERSION

version 3.772

=head1 SYNOPSIS

 use Lab::Moose;

 my $rigol = instrument(
    type => 'Rigol_DG5000',
    connection_type => 'USB', # For NT-VISA use 'VISA::USB'
    instrument_nselect => 2,
    function => 'PULSE'
    );

All C<source_*> commands accept a C<channel> argument, which can be 1 or 2. On
initalization an argument instrument_nselect can be passed to specify a default
channel, though if instrument_nselect is not passed the default channel is 1:

 $rigol->source_function_shape(value => 'SIN'); # Channel 1
 $rigol->source_function_shape(value => 'SQU', channel => 2); # Channel 2

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=head2 gen_arb_step

 $rigol->gen_arb_step(channel => 1, sequence => [
   0.2,  0.00002,
   0.5,  0.0001,
   0.35, 0.0001
   ], bdelay => 0, bcycles => 1
 );

Generate an arbitrary voltage step function. With C<sequence> an array referrence is
passed to the function, containing data pairs of an amplitude and time value.
The example above repeatedly outputs a constant 200mV for 20µs, 500mV for
100µs and 350mV for 100µs.

WORK IN PROGRESS: With C<bdelay> and C<bcycles> a delay between a specified
amount of cycles is enabled using the Rigols burst mode.

C<bdelay> = 0 by default disabling burst mode.

=head2 arb_mode

 $rigol->arb_mode(value => 'INTernal');

Allowed values: C<INT, INTernal, PLAY>. In normal or internal mode he output
frequency ranges from 1 μHz to 50 MHz, and the sample rate is fixed at 1G Sa/s,
while the number of points is 16Mpts. Play mode is used once the number of points
of the arbitrary waveform to be output is greater than 16 Mpts, ranging up to
128Mpts. See the Rigols user manual page 3-4 and following for more information.

=head2 play_coefficient

 $rigol->play_coefficient(value => 10);

When using the arbitrary waveform in play mode, a frequency division coefficient
N can be used to reduce the sample rate fs via the relations
=item fs = 1G/2^N, When N≤2
=item fs = 1G/((N-2)*8), When N>2
The range of N is from 0 to 268435456 (2^28)

See the Rigols user manual page 3-4 and following for more information.

=head2 phase_align

 $rigol->phase_align();

Phase-align the two output channels, only available if the output function is
either Sine, Square, Ramp or Arbitrary.

=head2 output_on/output_off

 $rigol->output_on(channel => 1);
 $rigol->output_off(channel => 2);

Turn output channels on or off.

=head2 set_pulsewidth/get_pulsewidth

 $rigol->set_pulsewidth(channel => 1, value => 0.0000001, constant_delay => 1);

When the output functon is PULSE these subroutines set/get the pulses width.
This reduces the pulse delay however, since the pulse period stays the same.
An optional parameter C<constant_delay> can be passed to adapt the waveform period
and keep the delay constant.

=head2 set_pulsedelay/get_pulsedelay

 $rigol->set_pulsedelay(channel => 1, value => 0.0000003, constant_width => 1);

When the output functon is PULSE these subroutines set/get the pulses width.
This reduces the pulse delay however, since the pulse period stays the same.
As with the delay an optional parameter C<constant_width> can be passed to adapt
the waveform period and keep the width constant.

=head2 set_period/get_period

 $rigol->set_pulsedelay(channel => 1, value => 0.00000045);

Set/query the current waveforms period.

=head2 set_frq/get_frq

 $rigol->set_frq(channel => 1, value => 10000000);

Set/query the current waveforms frequency in Hz. This subroutine is used in
frequency sweeps.

=head2 set_voltage/get_voltage

 $rigol->set_voltage(channel => 1, value => 1);

Set/query the current waveforms peak-to-peak amplitude in volts.

=head2 set_level/get_level

 $rigol->set_level(channel => 1, value => 1);

Set/query the current waveforms maximum amplitude amplitude in volts. This
subroutine is used in voltage sweeps.

=head2 set_level_low/get_level_low

 $rigol->set_level_low(channel => 1, value => 1);

Set/query the current waveforms minimum amplitude amplitude in volts.

=head2 set_offset/get_offset

 $rigol->set_offset(channel => 1, value => 0.5);

Set/query the current waveforms dc offset in volts.

=head2 source_apply_ramp/source_apply_sinusoid/source_apply_square/source_apply_arb

 $rigol->source_apply_ramp(
     freq => ...,
     amp => ...,
     offset => ...,
     phase => ...
 );

Apply a ramp, sine, square function or arbitrary waveform with the given parameters,

=over

=item * freq = frequency in Hz
=item * amp = amplitude in Volts
=item * offset = DC offset in Volts
=item * phase = phase in degrees (0 to 360)

=back

=head2 source_apply_pulse

 $rigol->source_apply_ramp(
     freq => ...,
     amp => ...,
     offset => ...,
     delay => ...
 );

Apply a pulse function with the given parameters,

=over

=item * freq = frequency in Hz
=item * amp = amplitude in Volts
=item * offset = DC offset in Volts
=item * delay = pulse delay in seconds

=back

=head2 source_apply_sinusoid

 $rigol->source_apply_sinusoid(freq => 50000000, amp => 1, offset => 0, phase => 0);

=head2 source_apply_square

 $rigol->source_apply_square(freq => 50000000, amp => 1, offset => 0, phase => 0);

=head2 source_apply_arb

 $rigol->source_apply_arb(freq => 50000000, amp => 1, offset => 0, phase => 0);

=head2 source_burst_mode/source_burst_mode_query

 $rigol->source_burst_mode(value => 'TRIG');
 say $rigol->source_burst_mode_query();

Allowed values: C<TRIG, GAT, INF>.
For more information see the Rigols user manual page 7-3.

=head2 source_burst_ncycles/source_burst_ncycles_query

 $rigol->source_burst_ncycles(value => 1);
 say $rigol->source_burst_ncycles_query();

Output a specified amount of full wave cycles, with a delay between them.
See source_burst_tdelay/source_burst_tdelay_query for more information.

=head2 source_burst_state/source_burst_state_query

 $rigol->source_burst_state(value => 'ON');
 say $rigol_source_burst_state_query();

Allowed values: C<ON, OFF>
Turns the burst mode on or off.

=head2 source_burst_tdelay/source_burst_tdelay_query

 $rigol->source_burst_tdelay(value => 1e-3);
 say $rigol->source_burst_tdelay_query();

Specify/query the delay between bursts in seconds.

=head2 source_burst_trigger

 $rigol->source_burst_trigger();

Trigger a burst via program.

=head2 source_burst_trigger_slope/source_burst_trigger_slope_query

 $rigol->source_burst_trigger_slope(value => 'POS');
 say $rigol->source_burst_trigger_slope_query();

Allowed values: C<POS, NEG>.
In Gated mode, the generator will output burst at specified polarity of the
gated signal received from the [ExtTrig] connector at the rear panel.

=head2 source_burst_trigger_trigout/source_burst_trigger_trigout_query

 $rigol->source_burst_trigger_trigout(value => 'POS');
 $rigol->source_burst_trigger_trigout_query();

Allowed values: C<POS, NEG, OFF>.
In Burst mode, when “Internal” or “Manual” trigger source is selected, the generator
will output a TTL compatible signal with specified polarity from the [ExtTrig] connector
at the rear panel.
For more information see the Rigols user manual page 7-7.

=head2 source_burst_trigger_source/source_burst_trigger_source_query

 $rigol->source_burst_trigger_source(value => 'INT');
 $rigol->source_burst_trigger_source_query();

Allowed values: C<INT, EXT>.
Specify whether the trigger signal for a burst is controlled internally or
externally via the [ExtTrig] connector.
For more information see the Rigols user manual page 7-6.

=head2 source_burst_period

 $rigol->source_burst_period(value => 0.00001);

Defined as the time from the beginning of the N cycle burst to the beginning of
the next burst. Only for N cycle burst in internal trigger mode.

=head2 source_function_shape/source_function_shape_query

 $rigol->source_function_shape(value => 'SIN');
 say $rigol->source_function_shape_query();

Allowed values: C<SIN, SQU, RAMP, PULSE, NOISE, USER, DC, SINC, EXPR, EXPF, CARD, GAUS, HAV, LOR, ARBPULSE, DUA>.

=head2 source_function_ramp_symmetry/source_function_ramp_symmetry_query

 $rigol->source_function_ramp_symmetry(value => 100);
 say $rigol->source_function_ramp_symmetry_query();

=head2 source_period_fixed/source_period_fixed_query

 $rigol->source_period_fixed(value => 1e-3);
 say $rigol->source_period_fixed_query();

=head2 trace_data_data

 my $values = [-0.6,-0.5,-0.4,-0.3,-0.2,-0.1,0,0.1,0.2,0.3,0.4,0.5,0.6];
 $rigol->trace_data_data(data => $values);

=head2 trace_data_value, trace_data_value_query

 $rigol->trace_data_value(point => 2, data => 8192);

Modify the second point to the decimal number 8192.

 $rigol->trace_data_value_query(point => 2);

=head2 trace_data_points, trace_data_points_query

 $rigol->trace_data_points(value => 3);
 say $rigol->trace_data_points_query();

=head2 trace_data_points_interpolate, trace_data_points_interpolate_query

 $rigol->trace_data_points_interpolate(value => 'LIN');
 say $rigol->trace_data_points_interpolate_query();

Allowed values: C<LIN, SINC, OFF>.

=head2 trace_data_points_interpolate, trace_data_points_interpolate_query

 $rigol->trace_data_dac(value => '16383,8192,0,0,8192,8192,6345,0');

Input a string of comma-seperated integers ranging from 0 to 16383 (14Bit). If
there are less than 16384 data points given, the Rigol will automatically
interpolate.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2020       Simon Reinhardt
            2021       Fabian Weinelt, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
