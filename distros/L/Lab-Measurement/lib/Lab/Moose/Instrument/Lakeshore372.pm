package Lab::Moose::Instrument::Lakeshore372;
$Lab::Moose::Instrument::Lakeshore372::VERSION = '3.791';
#ABSTRACT: Lakeshore Model 372 Temperature Controller

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
my %loop_arg = ( loop => { isa => enum( [ 0, 1, 2 ] ), optional => 1 } );


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
        %loop_arg,
        value => { isa => enum( [ 0 .. 8 ] ) }
    );
    my $loop = delete $args{loop} // $self->default_loop;
    $self->write( command => "RANGE $loop,$value", %args );
}

sub get_heater_range {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg
    );
    my $loop = delete $args{loop} // $self->default_loop;
    return $self->query( command => "RANGE? $loop", %args );
}


sub set_outmode {
    my ( $self, %args ) = validated_getter(
        \@_,
        %loop_arg,
        mode => { isa => enum( [ 0 .. 6 ] ) },
        %channel_arg,
        powerup_enable => { isa => enum( [ 0, 1 ] ), default => 0 },
        polarity       => { isa => enum( [ 0, 1 ] ) },
        filter         => { isa => enum( [ 0, 1 ] ), default => 0 },
        delay          => {},
    );
    my $channel = delete $args{channel} // $self->input_channel();

    my ( $loop, $units, $state, $powerup_enable )
        = delete @args{qw/loop units state powerup_enable/};
    $loop = $loop // $self->default_loop;
    $self->write( command => "CSET $loop, $channel, $units, $state,"
            . "$powerup_enable", %args );
}

sub get_outmode {
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


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Lakeshore372 - Lakeshore Model 372 Temperature Controller

=head1 VERSION

version 3.791

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

=head1 METHODS

=head2 get_T

my $temp = $lakeshore->get_T(channel => $channel);

 C<$channel> needs to be one of 'A', 1, ..., 16.

=head2 get_value

alias for C<get_T>.

=head2 get_sensor_units_reading

 my $reading = $lakeshore->get_sensor_units_reading(channel => $channel);

Get sensor units reading (in  ohm) of an input channel.

=head2 set_setpoint/get_setpoint

Set/get setpoint for loop 0 in whatever units the setpoint is using

 $lakeshore->set_setpoint(value => 10, loop => 0); 
 my $setpoint1 = $lakeshore->get_setpoint(loop => 0);

=head2 set_T

alias for C<set_setpoint>

=head2 set_heater_range/get_heater_range

 $lakeshore->set_heater_range(loop => 0, value => 1);
 my $range = $lakeshore->get_heater_range(loop => 0);

For loop 0 (sample heater), value is one of 0 (off), 1, ..., 8.
For loops 1 and 2, value is one of 0 and 1.

=head2 set_outmode/get_outmode

 $lakeshore->set_outmode(
  loop => 0, # 0, 1, 2
  mode => 3, # 0, ..., 6
  channel => 5, # A, 1, ..., 16
  powerup_enable => 0, # 0, 1
  polarity => 1, # 0, 1
  filter => 0, # 0, 1
  delay => 0, # 1,...,255
 );
 
 my $args = $lakeshore->get_outmode(loop => 0);

=head2 set_input_curve/get_input_curve

 # Set channel 5 to use curve 25
 $lakeshore->set_input_curve(channel => 5, value => 25);
 my $curve = $lakeshore->get_input_curve(channel => 5);

=head2 set_remote_mode/get_remote_mode

 $lakeshore->set_remote_mode(value => 0);
 my $mode = $lakeshore->get_remote_mode();

Valid entries: 0 = local, 1 = remote, 2 = remote with local lockout.

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
     mout => 0, # 0%
     range => 1,
     rate => 1.2, # 1.2 K / min
     relay_1 => 0,
     relay_2 => 0,
 );

 my %zone = $lakeshore->get_zone(loop => 1, zone => 1);

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

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt
            2020       Andreas K. Huettel, Simon Reinhardt
            2021       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
