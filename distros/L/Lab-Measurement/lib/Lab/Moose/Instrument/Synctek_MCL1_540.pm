package Lab::Moose::Instrument::Synctek_MCL1_540;
$Lab::Moose::Instrument::Synctek_MCL1_540::VERSION = '3.840';
#ABSTRACT: Synctek MCL1-540 Lock-in Amplifier

use v5.20;

use strict;
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter
    validated_setter
    validated_no_param_setter
    setter_params
    /;
use Carp;
use namespace::autoclean;
use Time::HiRes qw/time usleep/;

extends 'Lab::Moose::Instrument';


# TODO
# ====
# - how is ip address and port configured?
#   --> port 8002 is fixed
#   --> ip is required for init
# - type checks for write arguments - done
# - URL structure                   - done
# - names of outputs
# - which functions to implement?


# default connection options:
around default_connection_options => sub {
	my $orig = shift;
	my $self = shift;
	my $options = $self->$orig();

	$options->{WWW}{port} = 8002;
	return $options;
};


# html escape sequences
sub request {
    my ( $self, %args ) = validated_getter(
        \@_,
        type   => { isa => enum( [qw/config data/] ) },
        id     => { isa => 'Str' },
        action => { isa => enum( [qw/get set/] ) },
        path   => { isa => 'Str' },
    );
    my $type   = delete $args{'type'};
    my $id     = delete $args{'id'};
    my $action = delete $args{'action'};
    my $path   = delete $args{'path'};
    return query( command =>
		"/MCL/api?type=$type&id=$id&action=$action&path=$path" 
	);
}

# Configuration dump and write todo

# WTF is das System mit dem Array?
sub get_A_V1_DC {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[0]/"
    );
}

sub get_A_V2_DC {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[1]/"
    );
}

sub get_B_V1_DC {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[2]/"
    );
}

sub get_B_V2_DC {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[3]/"
    );
}

sub get_C_V1_DC {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[4]/"
    );
}

sub get_C_V2_DC {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[5]/"
    );
}

sub get_D_V1_DC {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[6]/"
    );
}

sub get_D_V2_DC {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[7]/"
    );
}

sub get_E_V1_DC {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[8]/"
    );
}

sub get_E_V2_DC {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[9]/"
    );
}

sub get_AI {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[10]/"
    );
}

sub get_BI {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[11]/"
    );
}

sub get_CI {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[12]/"
    );
}

sub get_DI {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[13]/"
    );
}

sub get_EI {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[14]/"
    );
}

sub get_L1_X_0 {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/X[0]/"
    );
}

sub get_L1_Y_0 {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/Y[0]/"
    );
}

sub get_L1_X_10 {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/X[10]/"
    );
}

sub get_L1_Y_10 {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/Y[10]/"
    );
}

sub get_L1_frq {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path =>
            "/output_cluster/GeneralReadings/Lock-in_f_(Hz)"
    );
}

sub set_L1_frq {
    my $self = shift;
    return $self->request(
        type   => "config",
        id     => "Freq_1",
        action => "set",
        path =>
            "/FrequencyCtrl/Frequency_(Hz)&value=..."
    );
}

sub get_Offset_1 {
    my $self = shift;
    return $self->request(
        type   => "config",
        id     => "Offset_1",
        action => "get",
        path =>
            "/OffsetCtrl/Offset_(V)"
    );
}

sub set_Offset_1 {
    my $self = shift;
    return $self->request(
        type   => "config",
        id     => "Offset_1",
        action => "set",
        path =>
            "/OffsetCtrl/Offset_(V)&value=..."
    );
}

sub get_Amplitude_1 {
    my $self = shift;
    return $self->request(
        type   => "config",
        id     => "Amplitude_1",
        action => "get",
        path =>
            "/AmplitudeCtrl/Amplitude:Amplitude"
    );
}

sub set_Amplitude_1 {
    my $self = shift;
    return $self->request(
        type   => "config",
        id     => "Amplitude_1",
        action => "set",
        path =>
            "/AmplitudeCtrl/Amplitude:Amplitude&value=..."
    );
}

sub get_time_constant_1 {
    my $self = shift;
    return $self->request(
        type   => "config",
        id     => "Lockin_L1",
        action => "get",
        path =>
            "/LockinCtrl/Time_constant_(s)"
    );
}

sub set_time_constant_1 {
    my $self = shift;
    return $self->request(
        type   => "config",
        id     => "Lockin_L1",
        action => "set",
        path =>
            "/LockinCtrl/Time_constant_(s)&value=..."
    );
}



__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Synctek_MCL1_540 - Synctek MCL1-540 Lock-in Amplifier

=head1 VERSION

version 3.840

=head1 SYNOPSIS

 use Lab::Moose;

 my $lockin = instrument(...);

TODO

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item TODO

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2022       Jonas Schambeck, Mia Schambeck, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
