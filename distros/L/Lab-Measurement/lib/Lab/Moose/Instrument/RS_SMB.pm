package Lab::Moose::Instrument::RS_SMB;
$Lab::Moose::Instrument::RS_SMB::VERSION = '3.682';
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

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x0aad, pid => 0x0054 };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

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
        $self->query( command => "FREQ?", %args ) );
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

    $self->write( command => sprintf( "FREQ %.17g", $value ), %args );
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

#
# Pulse/AM modulation stuff from old RSSMB100A driver; TODO: caching + docs
#

sub set_pulselength {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    $self->write( command => "PULM:WIDT $value s", %args );
}

sub get_pulselength {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "PULM:WIDT?", %args );
}

sub set_pulseperiod {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    $self->write( command => "PULM:PER $value s", %args );
}

sub get_pulseperiod {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "PULM:PER?", %args );
}

sub selftest {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "*TST?", %args );
}

sub display_on {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => "DISPlay ON", %args );
}

sub display_off {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => "DISPlay OFF", %args );
}

sub enable_external_am {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => "AM:DEPTh MAX",              %args );
    $self->write( command => "AM:SENSitivity 70PCT/VOLT", %args );
    $self->write( command => "AM:TYPE LINear",            %args );
    $self->write( command => "AM:STATe ON",               %args );
}

sub disable_external_am {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => "AM:STATe OFF", %args );
}

sub enable_internal_pulsemod {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => "PULM:SOUR INT",      %args );
    $self->write( command => "PULM:DOUB:STAT OFF", %args );
    $self->write( command => "PULM:MODE SING",     %args );
    $self->write( command => "PULM:STAT ON",       %args );
}

sub disable_internal_pulsemod {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => "PULM:STAT OFF", %args );
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::RS_SMB - Rohde & Schwarz SMB Signal Generator

=head1 VERSION

version 3.682

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

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Andreas K. Huettel, Simon Reinhardt
            2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
