package Lab::Moose::Instrument::SCPI::Sense::Function;
$Lab::Moose::Instrument::SCPI::Sense::Function::VERSION = '3.682';
#ABSTRACT: Role for the SCPI SENSe:FUNCtion subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

excludes 'Lab::Moose::Instrument::SCPI::Sense::Function::Concurrent';


# Cache used by multiple functions in sense subsystem
cache sense_function => ( getter => 'sense_function_query' );

sub sense_function_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    my $value = $self->query( command => "SENS${channel}:FUNC?", %args );
    $value =~ s/["']//g;
    return $self->cached_sense_function($value);
}

sub sense_function {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    $self->write( command => "SENS${channel}:FUNC '$value'", %args );
    return $self->cached_sense_function($value);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Function - Role for the SCPI SENSe:FUNCtion subsystem

=head1 VERSION

version 3.682

=head1 DESCRIPTION

This role is intended for instruments which support a single sense function.
The command for setting the function must be SENS:FUNC $function.
Instruments with concurrent sense shell use the Sense::Function:Concurrent
role. 

The set sense function is used by other SENSE: roles, like SENSE:NPLC. For
example,

 $source->sense_function(value => 'CURR');
 $source->sense_nplc(value => 10);

will set the integration time for current measurement to 10 power line cycles.

=head1 METHODS

=head2 sense_function_query

=head2 sense_function

Query/Enable the sense function used by the instrument

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
