package Lab::Moose::Instrument::SCPI::Sense::Impedance;
$Lab::Moose::Instrument::SCPI::Sense::Impedance::VERSION = '3.682';
#ABSTRACT: Role for the HP/Agilent/Keysight SCPI SENSe:$function:IMPedance subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use Moose::Util::TypeConstraints 'enum';
use Carp;
use namespace::autoclean;


requires 'cached_sense_function';

cache sense_impedance_auto => ( getter => 'sense_impedance_auto_query' );

sub sense_impedance_auto_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $func = $self->cached_sense_function();
    if ( $func ne 'VOLT' ) {
        croak "query impedance with function $func";
    }
    return $self->cached_sense_impedance_auto(
        $self->query( command => "SENS:$func:IMP:AUTO?", %args ) );
}

sub sense_impedance_auto {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1 ] ) },
    );

    my $func = $self->cached_sense_function();
    if ( $func ne 'VOLT' ) {
        croak "query impedance with function $func";
    }
    $self->write( command => "SENS:$func:IMP:AUTO $value", %args );

    $self->cached_sense_impedance_auto($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Impedance - Role for the HP/Agilent/Keysight SCPI SENSe:$function:IMPedance subsystem

=head1 VERSION

version 3.682

=head1 METHODS

=head2 sense_impedance_auto_query

=head2 sense_impedance_auto

 $self->sense_impedance_auto(value => 1);

Query/Set input impedance mode. Allowed values: '0' or '1'.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
