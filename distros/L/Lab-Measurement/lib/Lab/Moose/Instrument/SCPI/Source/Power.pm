package Lab::Moose::Instrument::SCPI::Source::Power;
#ABSTRACT: Role for the SCPI SOURce:POWer subsystem
$Lab::Moose::Instrument::SCPI::Source::Power::VERSION = '3.682';
use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;


cache source_power_level_immediate_amplitude =>
    ( getter => 'source_power_level_immediate_amplitude_query' );

sub source_power_level_immediate_amplitude_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_source_power_level_immediate_amplitude(
        $self->query( command => "SOUR${channel}:POW?", %args ) );
}

sub source_power_level_immediate_amplitude {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Num' }
    );
    $self->write(
        command => sprintf( "SOUR%s:POW %.17g", $channel, $value ),
        %args
    );
    $self->cached_source_power_level_immediate_amplitude($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Source::Power - Role for the SCPI SOURce:POWer subsystem

=head1 VERSION

version 3.682

=head1 METHODS

=head2 source_power_level_immediate_amplitude_query

=head2 source_power_level_immediate_amplitude

 $self->source_power_level_immediate_amplitude(value => -20);

Query/Set the signal amplitude, which will be set without waiting for further
commands (like e.g. triggers).

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
