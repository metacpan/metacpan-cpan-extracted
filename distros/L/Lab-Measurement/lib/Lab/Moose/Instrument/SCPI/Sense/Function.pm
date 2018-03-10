package Lab::Moose::Instrument::SCPI::Sense::Function;
$Lab::Moose::Instrument::SCPI::Sense::Function::VERSION = '3.622';
#ABSTRACT: Role for the SCPI SENSe:FUNCtion subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;


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

version 3.622

=head1 METHODS

=head2 sense_function_query

=head2 sense_function

Query/Set the function used by the instrument.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
