package Lab::Moose::Instrument::Lakeshore340;
$Lab::Moose::Instrument::Lakeshore340::VERSION = '3.903';
#ABSTRACT: Lakeshore Model 340 Temperature Controller

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
    isa     => enum( [qw/A B C D/] ),
    default => 'A',
);

has default_loop => (
    is      => 'ro',
    isa     => enum( [ 1 .. 2 ] ),
    default => 1,
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

my %channel_arg
    = ( channel => { isa => enum( [qw/A B C D/] ), optional => 1 } );
my %loop_arg = ( loop => { isa => enum( [qw/1 2/] ), optional => 1 } );


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
        value => { isa => enum( [qw/0 1 2 3 4 5/] ) }
    );
    $self->write( command => "RANGE $value", %args );
}

sub get_heater_range {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "RANGE?", %args );
}


sub set_control_mode {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ ( 1 .. 6 ) ] ) },
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;
    return $self->write( command => "CMODE $loop,$value", %args );
}

sub get_control_mode {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;
    return $self->query( command => "CMODE? $loop", %args );
}


sub set_mout {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;
    return $self->write( command => "MOUT $loop,$value", %args );
}

sub get_mout {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;
    return $self->query( command => "MOUT? $loop", %args );
}


sub set_control_parameters {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
        %channel_arg,
        units          => { isa => enum( [qw/1 2 3/] ) },
        state          => { isa => enum( [qw/0 1/] ) },
        powerup_enable => { isa => enum( [qw/0 1/] ), default => 1 },
    );
    my $channel = delete $args{channel} // $self->input_channel();

    my ( $loop, $units, $state, $powerup_enable )
        = delete @args{qw/loop units state powerup_enable/};
    $loop = $loop // $self->default_loop;
    $self->write( command => "CSET $loop, $channel, $units, $state,"
            . "$powerup_enable", %args );
}

sub get_control_parameters {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop();
    my $rv = $self->query( command => "CSET? $loop", %args );
    my @rv = split /,/, $rv;
    return (
        channel        => $rv[0], units => $rv[1], state => $rv[2],
        powerup_enable => $rv[3]
    );
}


sub set_input_curve {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        %channel_arg,
        value => { isa => enum( [ 0 .. 60 ] ) },
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
    return $self->query( command => "INCRV $channel", %args );
}


sub set_remote_mode {
    my ( $self, $value, %args )
        = validated_setter( \@_, value => { isa => enum( [ 1 .. 3 ] ) } );
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
        command => sprintf( "PID $loop, %.1f, %.1f, %d", $P, $I, $D ),
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
        mout => { isa => 'Lab::Moose::PosNum', optional => 1 },
        range => { isa => enum( [ 0 .. 5 ] ) },
    );
    my ( $loop, $zone, $top, $P, $I, $D, $mout, $range )
        = delete @args{qw/loop zone top P I D mout range/};
    $loop = $loop // $self->default_loop;
    if ( defined $mout ) {
        $mout = sprintf( "%.1f", $mout );
    }
    else {
        $mout = ' ';
    }

    $self->write(
        command => sprintf(
            "ZONE $loop, $zone, %.6G, %.1f, %.1f, %d, $mout, $range", $top,
            $P, $I, $D
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
    @zone{qw/top P I D mout range/} = split /,/, $result;
    return %zone;
}


sub set_analog_out {
    my ( $self, %args ) = validated_getter(
        \@_,
        output         => { isa => enum( [ 1, 2 ] ) },
        bipolar_enable => { isa => enum( [ 0, 1 ] ), default => 0 },
        mode           => { isa => enum( [ 0, 1, 2, 3 ] ) },
        input => { isa => enum( [qw/A B C D/] ), default => '' },
        source => { isa => enum( [ 1, 2, 3, 4 ] ), default => '' },
        high_value   => { isa => 'Num', default => '' },
        low_value    => { isa => 'Num', default => '' },
        manual_value => { isa => 'Num', default => '' },
    );

    my (
        $output,    $bipolar_enable, $mode, $input, $source, $high_value,
        $low_value, $manual_value
        )
        = delete @args{
        qw/output bipolar_enable mode input source high_value low_value manual_value/
        };

    $self->write(
        command =>
            "ANALOG $output, $bipolar_enable, $mode, $input, $source, $high_value, $low_value, $manual_value",
        %args
    );

}

sub get_analog_out {
    my ( $self, %args ) = validated_getter(
        \@_,
        output => { isa => enum( [ 1, 2 ] ) },
    );

    my $output = delete $args{'output'};
    my $result = $self->query( command => "ANALOG? $output", %args );
    my %analog_out;
    @analog_out{
        qw/output bipolar_enable mode input source high_value low_value manual_value/
    } = split /,/, $result;
    return %analog_out;
}


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Lakeshore340 - Lakeshore Model 340 Temperature Controller

=head1 VERSION

version 3.903

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $lakeshore = instrument(
     type => 'Lakeshore340',
     connection_type => 'LinuxGPIB',
     connection_options => {pad => 22},
     
     input_channel => 'B', # set default input channel for all method calls
 );

 my $temp_B = $lakeshore->get_T(); # Get temp for input 'B' set as default in constructor.

 my $temp_A = $lakeshore->get_T(channel => 'A'); # Get temp for input 'A'.

=head1 METHODS

=head2 get_T

my $temp = $lakeshore->get_T(channel => $channel);

C<$channel> can be 'A' or 'B'. The default can be set in the constructor.

=head2 get_value

alias for C<get_T>.

=head2 get_sensor_units_reading

 my $reading = $lakeshore->get_sensor_units_reading(channel => $channel);

Get sensor units reading (like resistance) of an input channel.

=head2 set_setpoint/get_setpoint

Set/get setpoint for loop 1 in whatever units the setpoint is using

 $lakeshore->set_setpoint(value => 10, loop => 1); 
 my $setpoint1 = $lakeshore->get_setpoint(loop => 1);

=head2 set_T

alias for C<set_setpoint>

=head2 set_heater_range/get_heater_range

 $lakeshore->set_heater_range(value => 1);
 my $range = $lakeshore->get_heater_range();

Value is one of 0 (OFF),1,...,5 (MAX)

=head2 set_control_mode/get_control_mode

Specifies the control mode. Valid entries: 1 = Manual PID, 2 = Zone,
 3 = Open Loop 4 = AutoTune PID, 5 = AutoTune PI, 6 = AutoTune P.

 # Set loop 1 to manual PID
 $lakeshore->set_control_mode(value => 1, loop => 1);
 my $cmode = $lakeshore->get_control_mode(loop => 1);

=head2 set_mout/get_mout

 $lakeshore->set_mout(
    loop => 1,
    value => 22.45, # percent of range
 );
 my $mout = $lakeshore->get_mout(loop => 1);

Set/get manual output. Only works if output is configured for open
loop control.

=head2 set_control_parameters/get_control_parameters

 $lakeshore->set_control_parameters(
    loop => 1,
    input => 'A',
    units => 1, # 1 = Kelvin, 2 = Celsius, 3 = sensor units
    state => 1, # 0 = off, 1 = on
    powerup_enable => 1, # 0 = off, 1 = on, optional with default = off
 );
 my %args = $lakeshore->get_control_parameters(loop => 1);

=head2 set_input_curve/get_input_curve

 # Set channel 'B' to use curve 25
 $lakeshore->set_input_curve(channel => 'B', value => 25);
 my $curve = $lakeshore->get_input_curve(channel => 'B');

=head2 set_remote_mode/get_remote_mode

 $lakeshore->set_remote_mode(value => 1);
 my $mode = $lakeshore->get_remote_mode();

Valid entries: 1 = local, 2 = remote, 3 = remote with local lockout.

=head2 set_pid/get_pid

 $lakeshore->set_pid(loop => 1, P => 1, I => 50, D => 50)
 my %PID = $lakeshore->get_pid(loop => 1);
 # %PID = (P => $P, I => $I, D => $D);

=head2 set_zone/get_zone

 $lakeshore->set_zone(
     loop => 1,
     zone => 1,
     top  => 10,
     P    => 25,
     I    => 10,
     D    => 20,
     range => 1
 );

 my %zone = $lakeshore->get_zone(loop => 1, zone => 1);

=head2 set_analog_out/get_analog_out

 $lakeshore->set_analog_out
     output => 1,
     bipolar_enable => 1, # default: 0
     mode => 2, # 0 = off, 1 = input, 2 = manual, 3 = loop. Loop is only valid for output 2
     manual_value => -30, # -30 percent output (-3V)
 );

 my %analog_out = $lakeshore->get_analog_out();

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt
            2020       Andreas K. Huettel, Simon Reinhardt
            2021-2022  Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
