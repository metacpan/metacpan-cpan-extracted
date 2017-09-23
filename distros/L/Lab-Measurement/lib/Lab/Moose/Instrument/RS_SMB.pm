package Lab::Moose::Instrument::RS_SMB;
#ABSTRACT: Rohde & Schwarz SMB Signal Generator
$Lab::Moose::Instrument::RS_SMB::VERSION = '3.600';
use 5.010;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use Carp;
use Lab::Moose::Instrument::Cache;
use namespace::autoclean;


extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Source::Power

);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}



cache source_frequency => ( getter => 'source_frequency_query' );

sub source_frequency_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_source_frequency(
        $self->query( command => "FREQ?" ) );
}

sub source_frequency {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    $self->write( command => sprintf( "FREQ %.17g", $value ) );
    $self->cached_source_frequency($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::RS_SMB - Rohde & Schwarz SMB Signal Generator

=head1 VERSION

version 3.600

=head1 SYNOPSIS

 # Set frequency to 2 GHz
 $smb->source_frequency(value => 2e9);
 
 # Query output power (in Dbm)
 my $power = $smb->source_power_level_immediate_amplitude_query();

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::SCPI::Source::Power>

=back

=head2 source_frequency_query

=head2 source_frequency

=head2 cached_source_frequency

Query and set the RF output frequency.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
