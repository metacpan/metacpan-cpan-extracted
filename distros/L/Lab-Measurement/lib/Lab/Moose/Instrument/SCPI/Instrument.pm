package Lab::Moose::Instrument::SCPI::Instrument;
$Lab::Moose::Instrument::SCPI::Instrument::VERSION = '3.682';
#ABSTRACT: Role for SCPI INSTrument subsystem.

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;


cache instrument_nselect => ( getter => 'instrument_nselect_query' );

sub instrument_nselect_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_instrument_nselect(
        $self->query( command => 'INST:NSEL?', %args ) );
}

sub instrument_nselect {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    $self->write( command => "INST:NSEL $value", %args );

    return $self->cached_instrument_nselect($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Instrument - Role for SCPI INSTrument subsystem.

=head1 VERSION

version 3.682

=head1 METHODS

=head2 instrument_nselect_query

=head2 instrument_nselect

Query/Set instrument channel for multi-channel instruments.

=head2

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
