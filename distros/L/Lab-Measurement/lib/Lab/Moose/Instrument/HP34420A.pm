package Lab::Moose::Instrument::HP34420A;
$Lab::Moose::Instrument::HP34420A::VERSION = '3.840';
#ABSTRACT: HP 34420A nanovolt meter.

use v5.20;

# So far only one channel. Could add support for two channels
# by using validated_channel_(setter/getter) in the SCPI/SENSE roles.

use Moose;
use Moose::Util::TypeConstraints 'enum';
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use Carp;
use Lab::Moose::Instrument::Cache;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common
    Lab::Moose::Instrument::SCPI::Sense::Function
    Lab::Moose::Instrument::SCPI::Sense::Range
    Lab::Moose::Instrument::SCPI::Sense::NPLC
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}



sub get_value {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => 'READ?', %args );
}


cache route_terminals => ( getter => 'route_terminals_query' );

sub route_terminals_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_route_terminals(
        $self->query( command => 'ROUT:TERM?', %args ) );
}

sub route_terminals {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/FRON FRON1 FRON2/] ) }
    );
    $self->write( command => "ROUT:TERM $value" );
    $self->cached_route_terminals($value);
}


cache input_filter_state => ( getter => 'input_filter_state_query' );

sub input_filter_state_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_input_filter_state(
        $self->query( command => 'INP:FILT:STAT?', %args ) );
}

sub input_filter_state {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0 .. 1 ] ) }
    );
    $self->write( command => "INP:FILT:STAT? $value", %args );
    return $self->cached_input_filter_state($value);
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::HP34420A - HP 34420A nanovolt meter.

=head1 VERSION

version 3.840

=head1 SYNOPSIS

 my $dmm = instrument(
    type => 'HP34420A',
    connection_type => 'LinuxGPIB',
    connection_options => {pad => 24},
    );

 # Set properties of channel1:
 $dmm->sense_range(value => 10);
 $dmm->sense_nplc(value => 2);  
  
 my $voltage = $dmm->get_value();

The C<SENSE> methods only support channel 1 so far.

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::SCPI::Sense::Function>

=item L<Lab::Moose::Instrument::SCPI::Sense::Range>

=item L<Lab::Moose::Instrument::SCPI::Sense::NPLC>

=back

=head2 get_value

 my $voltage = $dmm->get_value();

Perform voltage/current measurement.

=head2 route_terminals/route_terminals_query

 $dmm->route_terminals(value => 'FRON2');

Set/get used measurement channel. Allowed values: C<FRON[1], FRON2>.

=head2 input_filter_state/input_filter_state_query

 $dmm->input_filter_state(value => 0); # Filter OFF
 $dmm->input_filter_state(value => 1); # Filter ON

Enable/Disable input filter. Allowed values: C<0>, C<1>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt
            2020       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
