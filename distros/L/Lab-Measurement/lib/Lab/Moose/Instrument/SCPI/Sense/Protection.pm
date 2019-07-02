package Lab::Moose::Instrument::SCPI::Sense::Protection;
$Lab::Moose::Instrument::SCPI::Sense::Protection::VERSION = '3.682';
#ABSTRACT: Role for the SCPI SENSe:$function:Protection subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;

use namespace::autoclean;


requires 'cached_sense_function';

cache sense_protection => ( getter => 'sense_protection_query' );

sub sense_protection_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $func = $self->cached_sense_function();

    return $self->cached_sense_protection(
        $self->query( command => "SENS:$func:PROT?", %args ) );
}

sub sense_protection {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' },
    );

    my $func = $self->cached_sense_function();

    $self->write( command => "SENS:$func:PROT $value", %args );

    $self->cached_sense_protection($value);
}


sub sense_protection_tripped_query {
    my ( $self, %args ) = validated_getter( \@_ );
    my $func = $self->cached_sense_function();
    return $self->query( command => "SENS:$func:PROT:TRIP?" );
}


cache sense_protection_rsynchronize =>
    ( getter => 'sense_protection_rsynchronize_query' );

sub sense_protection_rsynchronize_query {
    my ( $self, %args ) = validated_getter( \@_ );
    my $func = $self->cached_sense_function();
    return $self->cached_sense_protection_rsynchronize(
        $self->query( command => "SENS:$func:PROT:RSYN?", %args ) );
}

sub sense_protection_rsynchronize {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Bool' }
    );
    my $func = $self->cached_sense_function();
    $self->write( command => "SENS:$func:PROT:RSYN $value" );
    $self->cached_sense_protection_rsynchronize($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Protection - Role for the SCPI SENSe:$function:Protection subsystem

=head1 VERSION

version 3.682

=head1 METHODS

=head2 sense_protection_query

=head2 sense_protection

 $self->sense_protection(value => 1e-6);

Query/Set the measurement protection limit

=head2 sense_protection_tripped_query

 my $tripped = $self->sense_protection_tripped_query();

Return '1' if source is in compliance, and '0' if source is not in compliance.

=head2 sense_protection_rsynchronize_query/sense_protection_rsynchronize

Get/Set measure and compliance range synchronization.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
