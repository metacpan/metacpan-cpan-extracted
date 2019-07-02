package Lab::Moose::Instrument::SCPI::Sense::Average;
#ABSTRACT: Role for the SCPI SENSe:AVERage subsystem
$Lab::Moose::Instrument::SCPI::Sense::Average::VERSION = '3.682';
use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

cache sense_average_state => ( getter => 'sense_average_state_query' );


sub sense_average_state_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_average_state(
        $self->query( command => "SENS${channel}:AVER?", %args ) );
}

sub sense_average_state {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write( command => "SENS${channel}:AVER $value", %args );
    return $self->cached_sense_average_state($value);
}


cache sense_average_count => (
    getter => 'sense_average_count_query',
    isa    => 'Int'
);

sub sense_average_count_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_average_count(
        $self->query( command => "SENS${channel}:AVER:COUN?", %args ) );
}

sub sense_average_count {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write( command => "SENS${channel}:AVER:COUN $value", %args );
    return $self->cached_sense_average_count($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Average - Role for the SCPI SENSe:AVERage subsystem

=head1 VERSION

version 3.682

=head1 METHODS

=head2 sense_average_state_query

=head2 sense_average_state

Query/Set whether averaging is turned on/off.

=head2 sense_average_count_query

=head2 sense_average_count

Query/Set the number of measurements used for an average.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
