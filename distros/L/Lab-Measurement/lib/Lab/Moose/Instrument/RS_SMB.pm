package Lab::Moose::Instrument::RS_SMB;
$Lab::Moose::Instrument::RS_SMB::VERSION = '3.613';
#ABSTRACT: Rohde & Schwarz SMB Signal Generator

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
    Lab::Moose::Instrument::SCPI::Output::State
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

    my $min_freq = 9e3;
    if ( $value < $min_freq ) {
        croak "value smaller than minimal frequency $min_freq";
    }

    $self->write( command => sprintf( "FREQ %.17g", $value ) );
    $self->cached_source_frequency($value);
}


sub set_power {
    my $self = shift;
    return $self->source_power_level_immediate_amplitude(@_);
}

sub get_power {
    my $self = shift;
    return $self->source_power_level_immediate_amplitude_query(@_);
}

sub cached_power {
    my $self = shift;
    return $self->cached_source_power_level_immediate_amplitude(@_);
}


sub cached_frq {
    my $self = shift;
    return $self->cached_source_frequency(@_);
}

#
# Aliases for Lab::XPRESS::Sweep API
#

sub set_frq {
    my $self = shift;
    return $self->source_frequency(@_);
}

sub get_frq {
    my $self = shift;
    return $self->source_frequency_query();
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::RS_SMB - Rohde & Schwarz SMB Signal Generator

=head1 VERSION

version 3.613

=head1 SYNOPSIS

 my $smb = instrument(
    type => 'RS_SMB',
    connection_type => 'VXI11',
    connection_options => {host => '192.168.3.26'},
    );
    
 # Set frequency to 2 GHz
 $smb->set_frq(value => 2e9);

 # Get frequency from device cache
 my $frq = $smb->cached_frq();
 
 # Set power to -10 dBm
 $smb->set_power(value => -10);

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::SCPI::Source::Power>

=item L<Lab::Moose::Instrument::SCPI::Output::State>

=back

=head2 get_power/set_power

 $smb->set_power(value => -10);
 $power = $smb->get_power(); # or $smb->cached_power();

Get set output power (dBm);

=head2 get_frq/set_frq

 $smb->set_frq(value => 1e6); # 1MHz
 $frq = $smb->get_frq(); # or $smb->cached_frq();

Get/Set output frequency (Hz).

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
