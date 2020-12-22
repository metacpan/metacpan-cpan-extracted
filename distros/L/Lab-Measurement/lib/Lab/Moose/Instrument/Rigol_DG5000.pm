package Lab::Moose::Instrument::Rigol_DG5000;
$Lab::Moose::Instrument::Rigol_DG5000::VERSION = '3.731';
#ABSTRACT: Rigol DG5000 series Function/Arbitrary Waveform Generator

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw/enum/;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter validated_getter validated_setter/;
use Lab::Moose::Instrument::Cache;
use Carp 'croak';
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

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
}

sub get_default_channel {
    return '';
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

version 3.731

=head1 SYNOPSIS

 use Lab::Moose;

 my $tbs = instrument(
    type => 'Rigol_DG5000',
    connection_type => 'USB' # For NT-VISA use 'VISA::USB'
    );

All C<source_*> commands accept a C<channel> argument, which can be 1 (default) or 2:

 $rigol->source_function_shape(value => 'SIN'); # Channel 1
 $rigol->source_function_shape(value => 'SQU', channel => 2); # Channel 2

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=head2 source_apply_ramp

 $rigol->source_apply_ramp(
     freq => ...,
     amp => ...,
     offset => ....,
     phase => ...
 );

=head2 source_burst_mode/source_burst_mode_query

 $rigol->source_burst_mode(value => 'TRIG');
 say $rigol->source_burst_mode_query();

Allowed values: C<TRIG, GAT, INF>.

=head2 source_burst_ncycles/source_burst_ncycles_query

 $rigol->source_burst_ncycles(value => 1);
 say $rigol->source_burst_ncycles_query();

=head2 source_burst_state/source_burst_state_query

 $rigol->source_burst_state(value => 'ON');
 say $rigol_source_burst_state_query();

Allowed values: C<ON, OFF>

=head2 source_burst_tdelay/source_burst_tdelay_query

 $rigol->source_burst_tdelay(value => 1e-3);
 say $rigol->source_burst_tdelay_query();

=head2 source_burst_trigger

 $rigol->source_burst_trigger();

=head2 source_burst_trigger_slope/source_burst_trigger_slope_query

 $rigol->source_burst_trigger_slope(value => 'POS');
 say $rigol->source_burst_trigger_slope_query();

Allowed values: C<POS, NEG>.

=head2 source_burst_trigger_trigout/source_burst_trigger_trigout_query

 $rigol->source_burst_trigger_trigout(value => 'POS');
 $rigol->source_burst_trigger_trigout_query();

Allowed values: C<POS, NEG, OFF>.

=head2 source_burst_trigger_source/source_burst_trigger_source_query

 $rigol->source_burst_trigger_source(value => 'INT');
 $rigol->source_burst_trigger_source_query();

Allowed values: C<INT, EXT>.

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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by the Lab::Measurement team; in detail:

  Copyright 2020       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
