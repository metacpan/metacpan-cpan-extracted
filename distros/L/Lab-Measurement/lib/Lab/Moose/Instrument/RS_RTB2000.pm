package Lab::Moose::Instrument::RS_RTB2000;
$Lab::Moose::Instrument::RS_RTB2000::VERSION = '3.901';
#ABSTRACT: Rohde & Schwarz RTB 2000 oscilloscope (work in progress)

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

# around default_connection_options => sub {
#     my $orig     = shift;
#     my $self     = shift;
#     my $options  = $self->$orig();
#     my $usb_opts = { vid => 0x0957, pid => 0x2b07 };
#     $options->{USB} = $usb_opts;
#     $options->{'VISA::USB'} = $usb_opts;
#     return $options;
# };

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
    Lab::Moose::Instrument::SCPIBlock
);

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::RS_RTB2000 - Rohde & Schwarz RTB 2000 oscilloscope (work in progress)

=head1 VERSION

version 3.901

=head1 SYNOPSIS

 use Lab::Moose;
 my $rtb = instrument(
    type => 'RS_RTB2000',
    connection_type => '...',
    connection_options => {...}
 );

 $rtb->write(command => 'CHAN:TYPE HRES'); # set high-resolution mode
 $rtb->write(command => 'ACQ:POIN 10000'); # record 10k points per waveform
 $rtb->write(command => 'ACQ:TYPE AVER');
 $rtb->write(command => 'ACQ:AVER:COUN 100'); # average over 100 waveforms


 # vertical setup 
 $rtb->write(command => 'CHAN1:RANG 10'); # set 0 to 10V range
 $rtb->write(command => 'CHAN1:POS -5');
 $rtb->write(command => 'CHAN1:COUP DCLimit');
 $rtb->write(command => 'CHAN1:BAND B20'); # 20MHz Bandwith
   


 
 # horizontal setup 

 # set measurement time of 1ms, i.e. 1/12 ms per division
 $rtb->write(command => 'TIM:RANG 1e-3');
 $rtb->write(command => 'TIM:REF 50'); # reference point in the middle
 # set trigger position at start of measurement time
 $rtb->write(command => 'TIM:POS 0.5e-3');

 $rtb->write(command => 'FORM REAL');
 $rtb->write(command => 'FORM:BORD LSBF'); # little-endian data format
 
 # trigger 

 $rtb->write(command => 'TRIG:A:MODE NORM');
 $rtb->write(command => 'TRIG:A:SOUR CH1');
 $rtb->write(command => 'TRIG:A:TYPE EDGE');
 $rtb->write(command => 'TRIG:A:EDGE:SLOP NEG');
 $rtb->write(command => 'TRIG:A:LEV1 10e-3');
 $rtb->write(command => 'TRIG:A:EDGE:FILT:HFR ON'); # 5kHz filter 

 # output signal (option R&S RTB-B6)

 $rtb->write(command => 'WGEN:OUTP ON');
 $rtb->write(command => 'WGEN:FUNC RAMP');
 $rtb->write(command => 'WGEN:FUNC:RAMP:POL POS');
 $rtb->write(command => 'WGEN:VOLT 5');
 $rtb->write(command => 'WGEN:VOLT:OFFS 2.5');
 $rtb->write(command => 'WGEN:FREQ 100');

 # burst setup
 $rtb->write(command => 'WGEN:BURS ON');
 $rtb->write(command => 'WGEN:BURS:NCYC 50'); # 50 ramps
 $rtb->write(command => 'WGEN:BURS:TRIG SING');
 
 # record single measurement

 $rtb->write(command => 'ACQ:AVER:RESET'); # reset average calculation
 $rtb->write(command => 'SING');
 $rtb->write(command => 'WGEN:BURS:TRIG:SING'); # start output signal
 $rtb->query(command => '*OPC?'); # wait until acquisiton is complete

 # transfer data
 
 my $header = $rtb->query(command => 'CHAN1:DATA:HEAD?');
 my ($x_start, $x_stop, $samples, $vals_per_sample) = split(',', $header);
 my $data = $rtb->query(command => 'CHAN:DATA?', read_length => '...');
 # returns binary data #520000>??[>??[>??[>??[>??[>??...

 my @points = $rtb->block_to_array($data, precision => 'single');

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=item L<Lab::Moose::Instrument::SCPIBlock>

=back

=head2

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2022       Andreas K. Huettel, Erik Fabrizzi, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
