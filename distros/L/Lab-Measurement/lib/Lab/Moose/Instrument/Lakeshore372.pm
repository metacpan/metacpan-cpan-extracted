package Lab::Moose::Instrument::Lakeshore372;
$Lab::Moose::Instrument::Lakeshore372::VERSION = '3.810';
#ABSTRACT: Lakeshore Model 372 Temperature Controller

#
# TODO:
# TLIMIT, TLIMIT?
# HTR? RAMPST?, RDGPWR?, RDGST?, RDGSTL?
# MONITOR

use v5.20;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

#use POSIX qw/log10 ceil floor/;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common
);

has input_channel => (
    is      => 'ro',
    isa     => enum( [ 'A', 1 .. 16 ] ),
    default => 5,
);

has default_loop => (
    is      => 'ro',
    isa     => enum( [ 0, 1 ] ),
    default => 0,
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

my %channel_arg = ( channel => { isa => enum( [ 'A', 1 .. 16 ] ) } );
my %loop_arg    = ( loop    => { isa => enum( [ 0,   1 ] ), optional => 1 } );
my %output_arg  = ( output  => { isa => enum( [ 0,   1, 2 ] ) } );


sub get_T {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "KRDG? $channel", %args );
}

sub get_value {
    my $self = shift;
    return $self->get_T(@_);
}


sub get_sensor_units_reading {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "SRDG? $channel", %args );
}


sub get_quadrature_reading {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "QRDG? $channel", %args );
}


sub get_excitation_power_reading {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "RDGPWR? $channel", %args );

}


sub get_setpoint {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;
    return $self->query( command => "SETP? $loop", %args );
}

sub set_setpoint {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;

    # Device bug. The 340 cannot parse values with too many digits.
    $value = sprintf( "%.6G", $value );
    $self->write( command => "SETP $loop,$value", %args );
}


sub set_T {
    my $self = shift;
    $self->set_setpoint(@_);
}


sub set_heater_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %output_arg,
        value => { isa => enum( [ 0 .. 8 ] ) }
    );
    my $output = delete $args{output};
    $self->write( command => "RANGE $output, $value", %args );
}

sub get_heater_range {
    my ( $self, %args ) = validated_getter(
        \@_,
        %output_arg,
    );
    my $output = delete $args{output};
    return $self->query( command => "RANGE? $output", %args );
}


sub set_outmode {
    my ( $self, %args ) = validated_getter(
        \@_,
        %output_arg,
        mode => { isa => enum( [ 0 .. 6 ] ) },
        %channel_arg,
        powerup_enable => { isa => enum( [ 0, 1 ] ), default => 0 },
        polarity       => { isa => enum( [ 0, 1 ] ), default => 0 },
        filter         => { isa => enum( [ 0, 1 ] ), default => 0 },
        delay => { isa => enum( [ 1 .. 255 ] ) },
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my ( $output, $mode, $powerup_enable, $polarity, $filter, $delay )
        = delete @args{qw/output mode powerup_enable polarity filter delay/};
    $self->write(
        command =>
            "OUTMODE $output, $mode, $channel, $powerup_enable, $polarity, $filter, $delay",
        %args
    );
}

sub get_outmode {
    my ( $self, %args ) = validated_getter(
        \@_,
        %output_arg,
    );
    my $output = delete $args{output};
    my $rv     = $self->query( command => "OUTMODE? $output", %args );
    my @rv     = split /,/, $rv;
    return (
        mode     => $rv[0], channel => $rv[1], powerup_enable => $rv[2],
        polarity => $rv[3], filter  => $rv[4], delay          => $rv[5]
    );
}


sub set_input_curve {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %channel_arg,
        value => { isa => enum( [ 0 .. 59 ] ) },
    );
    my $channel = delete $args{channel} // $self->input_channel();
    $self->write( command => "INCRV $channel,$value", %args );
}

sub get_input_curve {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "INCRV? $channel", %args );
}


sub set_remote_mode {
    my ( $self, $value, %args )
        = validated_setter( \@_, value => { isa => enum( [ 0 .. 2 ] ) } );
    $self->write( command => "MODE $value", %args );
}

sub get_remote_mode {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "MODE?", %args );
}


sub set_pid {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
        P => { isa => 'Lab::Moose::PosNum' },
        I => { isa => 'Lab::Moose::PosNum' },
        D => { isa => 'Lab::Moose::PosNum' }
    );
    my ( $loop, $P, $I, $D ) = delete @args{qw/loop P I D/};
    $loop = $loop // $self->default_loop();
    $self->write(
        command => sprintf( "PID $loop, %.1f, %d, %d", $P, $I, $D ),
        %args
    );
}

sub get_pid {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;
    my $pid = $self->query( command => "PID? $loop", %args );
    my %pid;
    @pid{qw/P I D/} = split /,/, $pid;
    return %pid;
}


sub set_zone {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
        zone => { isa => enum( [ 1 .. 10 ] ) },
        top  => { isa => 'Lab::Moose::PosNum' },
        P    => { isa => 'Lab::Moose::PosNum' },
        I    => { isa => 'Lab::Moose::PosNum' },
        D    => { isa => 'Lab::Moose::PosNum' },
        mout => { isa => 'Lab::Moose::PosNum', default => 0 },
        range => { isa => enum( [ 0 .. 8 ] ) },
        rate => { isa => 'Lab::Moose::PosNum' },
        relay_1 => { isa => enum( [ 0, 1 ] ), default => 0 },
        relay_2 => { isa => enum( [ 0, 1 ] ), default => 0 },
    );
    my (
        $loop, $zone, $top, $P, $I, $D, $mout, $range, $rate, $relay_1,
        $relay_2
        )
        = delete @args{
        qw/loop zone top P I D mout range rate relay_1 relay_2/};
    $loop = $loop // $self->default_loop;

    # if ( defined $mout ) {
    #     $mout = sprintf( "%.1f", $mout );
    # }
    # else {
    #     $mout = ' ';
    # }

    $self->write(
        command => sprintf(
            "ZONE $loop, $zone, %.6G, %.1f, %.1f, %d, $mout, $range, %.1f, $relay_1, $relay_2",
            $top, $P, $I, $D
        ),
        %args
    );
}

sub get_zone {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
        zone => { isa => enum( [ 1 .. 10 ] ) }
    );
    my ( $loop, $zone ) = delete @args{qw/loop zone/};
    $loop = $loop // $self->default_loop;
    my $result = $self->query( command => "ZONE? $loop, $zone", %args );
    my %zone;
    @zone{qw/top P I D mout range rate relay_1 relay_2/} = split /,/, $result;
    return %zone;
}


sub set_filter {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
        on => { isa => enum( [ 0, 1 ] ) },
        settle_time => { isa => enum( [ 1 .. 200 ] ) },
        window      => { isa => enum( [ 1 .. 80 ] ) }
    );
    my ( $channel, $on, $settle_time, $window )
        = delete @args{qw/channel on settle_time window/};
    $channel = $channel // $self->input_channel();

    $self->write(
        command => "FILTER $channel,$on,$settle_time,$window",
        %args
    );
}

sub get_filter {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my $result = $self->query( command => "FILTER? $channel", %args );

    my %filter;
    @filter{qw/on settle_time window/} = split /,/, $result;
    return %filter;
}


sub set_freq {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %channel_arg,
        value => { isa => enum( [ 1 .. 5 ] ) },
    );
    my $channel = delete $args{channel} // $self->input_channel();
    $self->write( command => "FREQ $channel,$value", %args );
}

sub get_freq {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "FREQ? $channel", %args );
}


sub set_common_mode_reduction {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1 ] ) },
    );
    $self->write( command => "CMR $value", %args );
}

sub get_common_mode_reduction {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "CMR?", %args );
}


sub set_mout {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %output_arg,
        value => { isa => 'Num' }
    );
    my $output = delete $args{output};
    $self->write( command => "MOUT $output, $value", %args );
}

sub get_mout {
    my ( $self, %args ) = validated_getter(
        \@_,
        %output_arg,
    );
    my $output = delete $args{output};
    return $self->query( command => "MOUT? $output" );
}


sub set_inset {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
        enabled => { isa => enum( [ 0, 1 ] ) },
        dwell   => { isa => enum( [ 1 .. 200 ] ) },
        pause   => { isa => enum( [ 3 .. 200 ] ) },
        curve_number => { isa => enum( [ 0 .. 59 ] ) },
        tempco => { isa => enum( [ 1, 2 ] ) },
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my ( $enabled, $dwell, $pause, $curve_number, $tempco )
        = delete @args{qw/enabled dwell pause curve_number tempco/};
    $self->write(
        command =>
            "INSET $channel, $enabled, $dwell, $pause, $curve_number, $tempco",
        %args
    );
}

sub get_inset {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my $rv = $self->query( command => "INSET? $channel" );
    my %inset;
    @inset{qw/enabled dwell pause curve_number tempco/} = split /,/, $rv;
    return %inset;
}


sub set_intype {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
        mode => { isa => enum( [ 0, 1 ] ) },
        excitation => { isa => enum( [ 1 .. 22 ] ) },
        autorange  => { isa => enum( [ 0, 1, 2 ] ) },
        range      => { isa => enum( [ 1 .. 22 ] ) },
        cs_shunt   => { isa => enum( [ 0, 1 ] ), default => 0 },
        units      => { isa => enum( [ 1, 2 ] ), default => 1 },
    );

    my $channel = delete $args{channel} // $self->input_channel();
    my ( $mode, $excitation, $autorange, $range, $cs_shunt, $units )
        = delete @args{qw/mode excitation autorange range cs_shunt units/};
    $self->write(
        command =>
            "INTYPE $channel, $mode, $excitation, $autorange, $range, $cs_shunt, $units",
        %args
    );
}

sub get_intype {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my $rv = $self->query( command => "INTYPE? $channel", %args );
    my %intype;
    @intype{qw/mode excitation autorange range cs_shunt units/} = split /,/,
        $rv;
    return %intype;
}


sub curve_delete {
    my ( $self, %args ) = validated_getter(
        \@_,
        curve => { isa => enum( [ 21 .. 59 ] ) },
    );
    my $curve = delete $args{curve};
    $self->write( command => "CRVDEL $curve", %args );
}


sub set_curve_header {
    my ( $self, %args ) = validated_getter(
        \@_,
        curve => { isa => enum( [ 21 .. 59 ] ) },
        name  => { isa => 'Str' },
        SN    => { isa => 'Str' },
        format => { isa => enum( [ 3, 4, 7 ] ) },
        limit => { isa => 'Lab::Moose::PosNum' },
        coefficient => { isa => enum( [ 1, 2 ] ) }
    );
    my ( $curve, $name, $SN, $format, $limit, $coefficient )
        = delete @args{qw/curve name SN format limit coefficient/};
    $self->write(
        command =>
            "CRVHDR $curve, \"$name\", \"$SN\", $format, $limit, $coefficient",
        %args
    );
}

sub get_curve_header {
    my ( $self, %args ) = validated_getter(
        \@_,
        curve => { isa => enum( [ 1 .. 59 ] ) },
    );
    my $curve = delete $args{curve};
    my $rv = $self->query( command => "CRVHDR? $curve", %args );
    my %header;
    @header{qw/name SN format limit coefficient/} = split /,/,
        $rv;
    return %header;
}


sub set_curve_point {
    my ( $self, %args ) = validated_getter(
        \@_,
        curve => { isa => enum( [ 21 .. 59 ] ) },
        index => { isa => enum( [ 1 .. 200 ] ) },
        units => { isa => 'Num' },
        temp  => { isa => 'Num' },
        curvature => { isa => 'Num', default => 0 },
    );
    my ( $curve, $index, $units, $temp, $curvature )
        = delete @args{qw/curve index units temp curvature/};
    $self->write(
        command => "CRVPT $curve, $index, $units, $temp, $curvature", %args );
}

sub get_curve_point {
    my ( $self, %args ) = validated_getter(
        \@_,
        curve => { isa => enum( [ 1 .. 59 ] ) },
        index => { isa => enum( [ 1 .. 200 ] ) },
    );
    my $curve = delete $args{curve};
    my $index = delete $args{index};
    my $rv    = $self->query( command => "CRVPT? $curve, $index", %args );
    my %point;
    @point{qw/units temp curvature/} = split /,/,
        $rv;
    return %point;
}


sub set_input_name {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    $self->write( command => "INNAME $channel, $value", %args );
}

sub get_input_name {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
    );
    my $channel = delete $args{channel} // $self->input_channel();
    return $self->query( command => "INNAME? $channel", %args );
}


sub set_ramp {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
        rate => { isa => 'Lab::Moose::PosNum' },
        on   => { isa => enum( [ 0, 1 ] ) },
    );
    my $loop = delete $args{loop} // $self->default_loop;
    my $rate = delete $args{rate};
    my $on   = delete $args{on};
    $self->write( command => "RAMP $loop, $on, $rate", %args );
}

sub get_ramp {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
    );
    my $loop = delete $args{loop} // $self->default_loop;
    my $rv = $self->query( command => "RAMP? $loop", %args );
    my %ramp;
    @ramp{qw/on rate/} = split ',', $rv;
    return %ramp;
}


sub set_heater_setup {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
        resistance       => { isa => 'Lab::Moose::PosNum' },
        max_current      => { isa => enum( [ 0, 1, 2 ] ) },
        max_user_current => { isa => 'Lab::Moose::PosNum' },
        display => { isa => enum( [ 0, 1 ] ) },
    );
    my $loop = delete $args{loop} // $self->default_loop;
    my ( $resistance, $max_current, $max_user_current, $display )
        = delete @args{qw/resistance max_current max_user_current display/};
    $self->write(
        command =>
            "HTRSET $loop, $resistance, $max_current, $max_user_current, $display",
        %args
    );
}

sub get_heater_setup {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
    );
    my $loop = delete $args{loop} // $self->default_loop;
    my $rv = $self->query( command => "HTRSET? $loop", %args );
    my %htr;
    @htr{qw/resistance max_current max_user_current display/} = split ',',
        $rv;
    return %htr;
}


sub set_scanner {
    my ( $self, %args ) = validated_getter(
        \@_,
        %channel_arg,
        autoscan => { isa => enum( [ 0, 1 ] ) },
    );
    my $channel = delete $args{channel} // $self->input_channel();
    my $autoscan = delete $args{autoscan};
    $self->write( command => "SCAN $channel, $autoscan", %args );
}

sub get_scanner {
    my ( $self, %args ) = validated_getter( \@_ );
    my $rv = $self->query( command => "SCAN?", %args );
    my ( $channel, $autoscan ) = split ',', $rv;
    return ( channel => $channel, autoscan => $autoscan );
}


sub set_display_field {
    my ( $self, %args ) = validated_getter(
        \@_,
        field => { isa => enum( [ 1 .. 8 ] ) },
        input => { isa => enum( [ 0 .. 17 ] ) },
        units => { isa => enum( [ 1 .. 6 ] ) },
    );
    my ( $field, $input, $units ) = delete @args{qw/field input units/};
    $self->write( command => "DISPFLD $field, $input, $units", %args );
}

sub get_display_field {
    my ( $self, %args ) = validated_getter(
        \@_,
        field => { isa => enum( [ 1 .. 8 ] ) }
    );
    my $field = delete $args{field};
    my $rv = $self->query( command => "DISPFLD? $field", %args );
    my ( $input, $units ) = split ',', $rv;
    return ( input => $input, units => $units );
}


sub set_display {
    my ( $self, %args ) = validated_getter(
        \@_,
        mode       => { isa => enum( [ 0, 1, 2 ] ) },
        num_fields => { isa => enum( [ 0, 1, 2 ] ) },
        displayed_info => { isa => enum( [ 0 .. 3 ] ) }
    );
    my ( $mode, $num_fields, $displayed_info )
        = delete @args{qw/mode num_fields displayed_info/};
    $self->write(
        command => "DISPLAY $mode, $num_fields, $displayed_info",
        %args
    );
}

sub get_display {
    my ( $self, %args ) = validated_getter( \@_ );
    my $rv = $self->query( command => "DISPLAY?", %args );
    my ( $mode, $num_fields, $displayed_info ) = split ',', $rv;
    return (
        mode           => $mode, num_fields => $num_fields,
        displayed_info => $displayed_info
    );
}


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Lakeshore372 - Lakeshore Model 372 Temperature Controller

=head1 VERSION

version 3.810

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $lakeshore = instrument(
     type => 'Lakeshore372',
     connection_type => 'Socket',
     connection_options => {host => '192.168.3.24'},
     
     input_channel => '5', # set default input channel for all method calls
 );


 my $temp_5 = $lakeshore->get_T(channel => 5); # Get temperature for channel 5.
 my $resistance_5 = TODO

Example: Configure inputs

 # enable channels 1..3
 for my $channel (1..3) {
    $lakeshore->set_inset(
        channel => $channel,
        enabled => 1,
        dwell => 1,
        pause => 3,
        curve_number => 0, # no curve
        tempco => 1, # negative temp coeff
    );
 }
 # disable the other channels
 for my $channel ('A', 4..16) {
      $lakeshore->set_inset(
        channel => $channel,
        enabled => 0,
        dwell => 1,
        pause => 3,
        curve_number => 0, # no curve
        tempco => 1, # negative temp coeff
    );
 }
  
 # setup the enabled input channels 1,2,3 for 20μV voltage excitation:
 for my $channel (1..3) {
     $lakeshore->set_intype(
        channel => $channel,
        mode => 0,
        excitation => 3,
        # control input, ignored:
        autorange => 0,
        range => 1,
    );
 }

=head1 METHODS

=head2 get_T

 my $temp = $lakeshore->get_T(channel => $channel);

C<$channel> needs to be one of 'A', 1, ..., 16.

=head2 get_value

alias for C<get_T>.

=head2 get_sensor_units_reading

 my $reading = $lakeshore->get_sensor_units_reading(channel => $channel);

Get sensor units reading (in  ohm) of an input channel.

=head2 get_quadrature_reading

 my $imaginary_part = $lakeshore->get_quadrature_reading(
    channel => 1, # 1..16 (only measurement input)
 );

=head2 get_excitation_power_reading

 my $excitation_power = $lakeshore->get_excitation_power_reading(
     channel => 1, # 1..16 or A
 );

=head2 set_setpoint/get_setpoint

Set/get setpoint for loop 0 in whatever units the setpoint is using

 $lakeshore->set_setpoint(value => 10, loop => 0); 
 my $setpoint1 = $lakeshore->get_setpoint(loop => 0);

=head2 set_T

alias for C<set_setpoint>

=head2 set_heater_range/get_heater_range

 $lakeshore->set_heater_range(output => 0, value => 1);
 my $range = $lakeshore->get_heater_range(output => 0);

For output 0 (sample heater), value is one of 0 (off), 1, ..., 8.
For outputs 1 and 2, value is one of 0 and 1.

=head2 set_outmode/get_outmode

 $lakeshore->set_outmode(
  output => 0, # 0, 1, 2
  mode => 3, # 0, ..., 6
  channel => 5, # A, 1, ..., 16
  powerup_enable => 1, # (default: 0)
  polarity => 1, # (default: 0)
  filter => 1, # (default: 0)
  delay => 1, # 1,...,255
 );
 
 my $args = $lakeshore->get_outmode(output => 0);

=head2 set_input_curve/get_input_curve

 # Set channel 5 to use curve 25
 $lakeshore->set_input_curve(channel => 5, value => 25);
 my $curve = $lakeshore->get_input_curve(channel => 5);

=head2 set_remote_mode/get_remote_mode

 $lakeshore->set_remote_mode(value => 0);
 my $mode = $lakeshore->get_remote_mode();

Valid entries: 0 = local, 1 = remote, 2 = remote with local lockout.

=head2 set_pid/get_pid

 $lakeshore->set_pid(loop => 0, P => 1, I => 50, D => 50)
 my %PID = $lakeshore->get_pid(loop => 0);
 # %PID = (P => $P, I => $I, D => $D);

=head2 set_zone/get_zone

 $lakeshore->set_zone(
     loop => 0,
     zone => 1,
     top  => 10,
     P    => 25,
     I    => 10,
     D    => 20,
     mout => 0, # 0%
     range => 1,
     rate => 1.2, # 1.2 K / min
     relay_1 => 0,
     relay_2 => 0,
 );

 my %zone = $lakeshore->get_zone(loop => 0, zone => 1);

=head2 set_filter/get_filter

 $lakeshore->set_filter(
     channel => 5,
     on      => 1,
     settle_time => 1, # (1s..200s) 
     window => 2, # % 2 percent of full scale window (1% ... 80%)
 );

 my %filter = $lakeshore->get_filter(channel => 5);

=head2 set_freq/get_freq

 # Set input channel 0 (measurement input) excitation frequency to 9.8Hz
 $lakeshore->set_freq(channel => 0, value => 1);

 my $freq = $lakeshore->get_freq(channel => 0);

Allowed channels: 0 (measurement input), 'A' (control input).
Allowed values: 1 = 9.8 Hz, 2 = 13.7 Hz, 3 = 16.2 Hz, 4 = 11.6 Hz, 5 = 18.2 Hz.

=head2 set_common_mode_reduction/get_common_mode_reduction

 $lakeshore->set_common_mode_reduction(value => 1);
 my $cmr = $lakeshore->get_common_mode_reduction();

Allowed values: 0 and 1.

=head2 set_mout/get_mout

 $lakeshore->set_mout(output => 0, value => 10);
 my $mout = $lakeshore->get_mout(output => 0);

=head2 set_inset/get_inset

 $lakeshore->set_inset(
     channel => 1, # A, 1, ..., 16
     enabled => 1,
     dwell => 1,
     pause => 3,
     curve_number => 1,
     tempco => 1, # 1 or 2
 );

 my %inset = $lakeshore->get_inset(channel => 1);

=head2 set_intype/get_intype

 $lakeshore->set_intype(
     channel => 1, 
     mode => 0, # voltage excitation mode
     excitation => 3, # 20μV, only relevant for measurement input
     autorange => 0, # only relevant for control input
     range => 1, # only relevant for control input
     cs_shunt => 0, # default: 0
     units => 1, # Kelvin, default: 1

 my %intype = $lakeshore->get_intype(channel => 1);

=head2 curve_delete

 $lakeshore->curve_delete(curve => 21);

=head2 set_curve_header/get_curve_header

 $lakeshore->set_curve_header(
     curve       => 21,
     name        => "Germanium",
     SN          => "selfmade",
     format      => 4, # log Ohm / Kelvin
     limit       => 300,
     coefficient => 1,  # negative
 );
 
 my %header = $lakeshore->get_curve_header(curve => 21);

=head2 set_curve_point/get_curve_point

 $lakeshore->set_curve_point(
     curve => 21, # 21..59
     index => 1, # sets first point (1..200)
     units => 2, # R or log(R)
     temp => 0.012345,
     curvature => 0, # default: 0
 );

 my %point = $lakeshore->get_curve_point(curve => 21, point => 1);

=head2 set_input_name/get_input_name

 $lakeshore->set_input_name(channel => 1, value => 'RuOx_Sample');
 
 my $name = $lakeshore->get_input_name(channel => 1);

=head2 set_ramp/get_ramp

 $lakeshore->set_ramp(
     loop => 0,
     on => 1, # 0 or 1
     rate => 10e-3, # ramp rate in K/min
 );

 my %rate = $lakeshore->get_ramp(loop => 0);

=head2 set_heater_setup/get_heater_setup

 $lakeshore->set_heater_setup(
    loop => 0,
    resistance => 1500, # Ohms
    max_current => 0, # warm-up heater
    max_user_current => 0.1, # Amps
    display => 2, # Display power 
 );

 my %setup = $lakeshore->get_heater_setup(loop => 0);

=head2 set_scanner/get_scanner

 # Set scanner to channel 5 and start autoscanning
 $lakeshore->set_scanner(
    channel => 5,
    autoscan => 1,
 );
 
 my %scanner = $lakeshore->get_scanner();
 my $current_channel = $scanner{channel};

=head2 set_display_field/get_display_field

 $lakeshore->set_display_field(
    field => 1,
    input => 1,
    units => 1, # Kelvin
 );

 my %field = $lakeshore->get_display_field(field => 1);

=head2 set_display/get_display

 $lakeshore->set_display(
    mode => 2, # custom
    num_fields => 2, # 8 fields
    displayed_info => 1, # sample_heater
 );

 my %display = $lakeshore->get_display();

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt
            2020       Andreas K. Huettel, Simon Reinhardt
            2021-2022  Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
