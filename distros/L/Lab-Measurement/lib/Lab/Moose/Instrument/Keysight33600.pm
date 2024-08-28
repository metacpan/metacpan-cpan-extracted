package Lab::Moose::Instrument::Keysight33600;
$Lab::Moose::Instrument::Keysight33600::VERSION = '3.904';
#ABSTRACT: Keysight 33500/33600 series Function/Arbitrary Waveform Generator (work in progress)

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw/enum/;
use List::Util qw/sum/;
use List::MoreUtils qw/minmax/;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter validated_getter validated_setter/;
use Lab::Moose::Instrument::Cache;
use Carp 'croak';
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x0957, pid => 0x2b07 };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}


#
# MY FUNCTIONS
#


with qw(
    Lab::Moose::Instrument::Common
);

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Keysight33600 - Keysight 33500/33600 series Function/Arbitrary Waveform Generator (work in progress)

=head1 VERSION

version 3.904

=head1 SYNOPSIS

 use Lab::Moose;
 my $trueform = instrument(
    type => 'Keysight33600',
    connection_type => '...',
    connection_options => {...}
 );

 ### Setup waveform ###

 # Clear volatile memory
 $trueform->write(command => 'DATA:VOL:CLE');
 # write new waveform into volatile memory
 $trueform->write(command => 'DATA:ARB myarb, 0, 0, 0.1, ...,1, ...');
 # load the new waveform
 $trueform->write(command => 'SOUR:FUNC:ARB myarb');
 # set parameters
 $trueform->write(command => 'SOUR:VOLT 1'); # amplitude
 $trueform->write(command => 'FUNC:ARB:SRAT 100000'); # samples/points per second
 $trueform->write(command => 'FUNC:ARB:FILT STEP'); # interpolation type

 $trueform->write(command => 'OUTP:POL INV'); # invert output polarity 

 # Setup trigger input
 $trueform->write(command => 'BURS:MODE TRIG');
 $trueform->write(command => 'BURS:NCYC 1'); # one ramp per trigger
 $trueform->write(command => 'TRIG:SOUR BUS'}; # use *TRG command as trigger
 

 # Setup trigger output
 $trueform->write(command => 'OUTP:TRIG 1');
 $trueform->write(command => 'OUTP:TRIG:SLOP NEG');
 

 # Turn output on
 $trueform->write(command => 'OUTP ON');

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=head2

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by the Lab::Measurement team; in detail:

  Copyright 2022       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
