package Lab::Moose::Instrument::RS_SMB;

use 5.010;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use Carp;
use Lab::Moose::Instrument::Cache;
use namespace::autoclean;

our $VERSION = '3.542';

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

=head1 NAME

Lab::Moose::Instrument::RS_SMB - Rohde & Schwarz SMB Signal Generator

=head1 SYNOPSIS

 # Set frequency to 2 GHz
 $smb->source_frequency(value => 2e9);
 
 # Query output power (in Dbm)
 my $power = $smb->source_power_level_immediate_amplitude_query();
 
=cut

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::SCPI::Source::Power>

=back

=head2 source_frequency_query

=head2 source_frequency

=head2 cached_source_frequency

Query and set the RF output frequency.
    
=cut

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
