package Lab::Moose::Instrument::MCL1_540;
$Lab::Moose::Instrument::MCL1_540::VERSION = '3.810';
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
use LWP::Simple;


# TODO
# ====
# - how is ip address and port configured?
#   --> port 8002 is fixed
#   --> ip is required for init
# - type checks for write arguments - done
# - URL structure                   - done
# - names of outputs
# - which functions to implement?

has ip => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

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

    my $url = "http://$self->ip():8002/MCL/api?";
    return get( $url . "type=$type&id=$id&action=$action&path=$path" );
}

# WTF is das System mit dem Array?
sub get_L1_DC_0 {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[0]/"
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

sub get_L1_DC_10 {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/DC[10]/"
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

sub get_L1_R_10 {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/R[10]/"
    );
}

sub get_L1_Theta_10 {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path   => "/output_cluster/DataReadings/theta_(deg)[10]/"
    );
}

sub get_L1_Amplitude {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path =>
            "/output_cluster/GeneralReadings/Module_data[0]/Module/Amplitude_(Vrms)"
    );
}

sub get_L1_Output_Offset {
    my $self = shift;
    return $self->request(
        type   => "data",
        id     => "L1",
        action => "get",
        path =>
            "/output_cluster/GeneralReadings/Module_data[0]/Module/Output_offset_(V)"
    );
}

#     my $u_sample_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/DC[2]/"); 	 #entspricht V1 DC
#
#     my $u_AC_sample_B = get("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/X[2]/"); #ist das hier dann das u_x?
#     my $u_AC_sample_y_B = get("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/Y[2]/"); #ist das hier dann das u_y?
#
#     my $i_dc_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/DC[11]/");
#     my $i_AC_x_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/X[11]/");
#
#     my $i_AC_y_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/Y[11]/");
#
#     my $i_AC_R_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/R[11]/");
#     my $i_AC_Theta_B = get ("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/DataReadings/theta_(deg)[11]/");
#
#
#     my $u_osc_B = get("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/GeneralReadings/Module_data[1]/Module/Amplitude_(Vrms)");
#
#     my $output_offset_B = get("http://172.22.11.2:8002/MCL/api?type=data&id=L1&action=get&path=/output_cluster/GeneralReadings/Module_data[1]/Module/Output_offset_(V)");


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::MCL1_540 - Synctek MCL1-540 Lock-in Amplifier

=head1 VERSION

version 3.810

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

  Copyright 2022       Mia Schambeck, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
