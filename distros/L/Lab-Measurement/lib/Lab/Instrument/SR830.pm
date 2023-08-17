package Lab::Instrument::SR830;
$Lab::Instrument::SR830::VERSION = '3.881';
#ABSTRACT: Stanford Research SR830 lock-in amplifier

use v5.20;

use strict;
use Lab::Instrument;
use Data::Dumper;
use Carp;
use Time::HiRes qw (usleep);

our @ISA = ("Lab::Instrument");

our %fields = ( supported_connections => [ 'GPIB', 'VISA_GPIB' ], );

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->empty_buffer();
    return $self;
}

#
# utility methods
#

sub empty_buffer {
    my $self = shift;
    my ($times) = $self->_check_args( \@_, ['times'] );
    if ($times) {
        for ( my $i = 0; $i < $times; $i++ ) {
            eval { $self->read( brutal => 1 ) };
        }
    }
    else {
        while ( $self->read( brutal => 1 ) ) {
            print "Cleaning buffer.";
        }
    }
}

sub set_frequency {
    my ( $self, $freq ) = @_;
    $self->write("FREQ $freq");
}

sub set_frq {
    my $self = shift;
    my ($freq) = $self->_check_args( \@_, ['value'] );
    $self->set_frequency($freq);
}

sub get_frequency {
    my $self = shift;
    my $freq = $self->query("FREQ?");
    chomp $freq;
    return $freq;    # frequency in Hz
}

sub get_frq {
    my $self = shift;
    my $freq = $self->get_frequency();
    return $freq;
}

sub set_amplitude {
    my $self = shift;
    my ($ampl) = $self->_check_args( \@_, ['value'] );
    $self->write("SLVL $ampl");
    my $realampl = $self->query("SLVL?");
    chomp $realampl;
    return $realampl;    # amplitude in V
}

sub get_amplitude {
    my $self = shift;
    my $ampl = $self->query("SLVL?");
    chomp $ampl;
    return $ampl;        # amplitude in V
}

sub set_sens {

    # set sensitivity to value equal to or greater than argument (in V), Range 2nV..1V
    my ( $self, $sens ) = @_;
    my $nr = 26;

    if    ( $sens < 2E-9 )  { $nr = 0; }
    elsif ( $sens <= 5E-9 ) { $nr = 1; }
    elsif ( $sens <= 1E-8 ) { $nr = 2; }
    elsif ( $sens <= 2E-8 ) { $nr = 3; }
    elsif ( $sens <= 5E-8 ) { $nr = 4; }
    elsif ( $sens <= 1E-7 ) { $nr = 5; }
    elsif ( $sens <= 2E-7 ) { $nr = 6; }
    elsif ( $sens <= 5E-7 ) { $nr = 7; }
    elsif ( $sens <= 1E-6 ) { $nr = 8; }
    elsif ( $sens <= 2E-6 ) { $nr = 9; }
    elsif ( $sens <= 5E-6 ) { $nr = 10; }
    elsif ( $sens <= 1E-5 ) { $nr = 11; }
    elsif ( $sens <= 2E-5 ) { $nr = 12; }
    elsif ( $sens <= 5E-5 ) { $nr = 13; }
    elsif ( $sens <= 1E-4 ) { $nr = 14; }
    elsif ( $sens <= 2E-4 ) { $nr = 15; }
    elsif ( $sens <= 5E-4 ) { $nr = 16; }
    elsif ( $sens <= 1E-3 ) { $nr = 17; }
    elsif ( $sens <= 2E-3 ) { $nr = 18; }
    elsif ( $sens <= 5E-3 ) { $nr = 19; }
    elsif ( $sens <= 1E-2 ) { $nr = 20; }
    elsif ( $sens <= 2E-2 ) { $nr = 21; }
    elsif ( $sens <= 5E-2 ) { $nr = 22; }
    elsif ( $sens <= 1E-1 ) { $nr = 23; }
    elsif ( $sens <= 2E-1 ) { $nr = 24; }
    elsif ( $sens <= 5E-1 ) { $nr = 25; }

    $self->write("SENS $nr");

    my $realsens = $self->query("SENS?");
    my @senses   = (
        "2e-9",   "5e-9",   "10e-9",  "20e-9",  "50e-9",  "100e-9",
        "200e-9", "500e-9", "1e-6",   "2e-6",   "5e-6",   "10e-6",
        "20e-6",  "50e-6",  "100e-6", "200e-6", "500e-6", "1e-3",
        "2e-3",   "5e-3",   "10e-3",  "20e-3",  "50e-3",  "100e-3",
        "200e-3", "500e-3", "1"
    );
    return $senses[$realsens];    # in V
}

sub get_sens {
    my @senses = (
        "2e-9",   "5e-9",   "10e-9",  "20e-9",  "50e-9",  "100e-9",
        "200e-9", "500e-9", "1e-6",   "2e-6",   "5e-6",   "10e-6",
        "20e-6",  "50e-6",  "100e-6", "200e-6", "500e-6", "1e-3",
        "2e-3",   "5e-3",   "10e-3",  "20e-3",  "50e-3",  "100e-3",
        "200e-3", "500e-3", "1"
    );
    my $self = shift;
    my $nr   = $self->query("SENS?");
    return $senses[$nr];    # in V
}

#
# Set sensitivity to 2x the current amplitude (or $minimum_sensitivity, if given)
# set_sens_auto( $minimum_sensitivity );
#
sub set_sens_auto {
    my $self    = shift;
    my $minsens = shift || 0;
    my $V       = get_amplitude();

    #print "V=$V\tminsens=$minsens\n";
    #my ($lix, $liy) = $self->read_xy();
    if ( abs($V) >= $minsens / 2 ) {
        $self->set_sens( abs( $V * 2. ) );
        my ( $lix, $liy ) = $self->get_xy();
    }
    else {
        $self->set_sens( abs($minsens) );
        my ( $lix, $liy ) = $self->get_xy();
    }
}

sub set_tc {

    # set time constant to value greater than or equal to argument given, value in s

    my ( $self, $tc ) = @_;
    my $nr = 19;

    if    ( $tc < 1E-5 )  { $nr = 0; }
    elsif ( $tc < 3E-5 )  { $nr = 1; }
    elsif ( $tc < 1E-4 )  { $nr = 2; }
    elsif ( $tc < 3E-4 )  { $nr = 3; }
    elsif ( $tc < 1E-3 )  { $nr = 4; }
    elsif ( $tc < 3E-3 )  { $nr = 5; }
    elsif ( $tc < 1E-2 )  { $nr = 6; }
    elsif ( $tc < 3E-2 )  { $nr = 7; }
    elsif ( $tc < 1E-1 )  { $nr = 8; }
    elsif ( $tc < 3E-1 )  { $nr = 9; }
    elsif ( $tc < 1 )     { $nr = 10; }
    elsif ( $tc < 3 )     { $nr = 11; }
    elsif ( $tc < 10 )    { $nr = 12; }
    elsif ( $tc < 30 )    { $nr = 13; }
    elsif ( $tc < 100 )   { $nr = 14; }
    elsif ( $tc < 300 )   { $nr = 15; }
    elsif ( $tc < 1000 )  { $nr = 16; }
    elsif ( $tc < 3000 )  { $nr = 17; }
    elsif ( $tc < 10000 ) { $nr = 18; }

    $self->write("OFLT $nr");

    my @tc = (
        "10e-6", "30e-6", "100e-6", "300e-6", "1e-3", "3e-3",
        "10e-3", "30e-3", "100e-3", "300e-3", "1",    "3",
        "10",    "30",    "100",    "300",    "1e3",  "3e3",
        "10e3",  "30e3"
    );
    my $realtc = $self->query("OFLT?");
    return $tc[$realtc];    # in sec

}

sub get_tc {
    my @tc = (
        "10e-6", "30e-6", "100e-6", "300e-6", "1e-3", "3e-3",
        "10e-3", "30e-3", "100e-3", "300e-3", "1",    "3",
        "10",    "30",    "100",    "300",    "1e3",  "3e3",
        "10e3",  "30e3"
    );

    my $self = shift;
    my $nr   = $self->query("OFLT?");
    return $tc[$nr];    # in sec
}

sub get_xy {

    # get value of X and Y channel (recorded simultaneously) as array
    my $self = shift;
    my $tmp  = $self->query("SNAP?1,2");
    chomp $tmp;
    my @arr = split( /,/, $tmp );
    return @arr;
}

sub get_rphi {

    # get value of amplitude and phase (recorded simultaneously) as array
    my $self = shift;
    my $tmp  = $self->query("SNAP?3,4");
    chomp $tmp;
    my @arr = split( /,/, $tmp );
    return @arr;
}

sub get_channels {

    # get value of channel1 and channel2 as array
    my $self = shift;

    $self->query("OUTR?1");
    $self->query("OUTR?2");
    my $x = $self->query("OUTR?1");
    my $y = $self->query("OUTR?2");
    chomp $x;
    chomp $y;
    my @arr = ( $x, $y );
    return @arr;
}

sub id {
    my $self = shift;
    return $self->query('*IDN?');
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::SR830 - Stanford Research SR830 lock-in amplifier

=head1 VERSION

version 3.881

=head1 SYNOPSIS

    use Lab::Instrument::SR830;
    
    my $sr=new Lab::Instrument::SR830(
       connection_type=>'LinuxGPIB',
       gpib_address=>12,
    );

    ($x,$y) = $sr->get_xy();
    ($r,$phi) = $sr->get_rphi();

=head1 DESCRIPTION

The Lab::Instrument::SR830 class implements an interface to the
Stanford Research SR830 Lock-In Amplifier.

=head1 CONSTRUCTOR

  $sr830=new Lab::Instrument::SR830($board,$gpib);

=head1 METHODS

=head2 get_xy

  ($x,$y)= $sr830->get_xy();

Reads channels x and y simultaneously; returns an array.

=head2 get_rphi

  ($r,$phi)= $sr830->get_rphi();

Reads amplitude and phase simultaneously; returns an array.

=head2 set_sens

  $string=$sr830->set_sens(1E-7);

Sets sensitivity (value given in V); possible values are:
2 nV, 5 nV, 10 nV, 20 nV, 50 nV, 100 nV, ..., 100 mV, 200 mV, 500 mV, 1V
If the argument is not in this list, the next higher value will be chosen.

Returns the value of the sensitivity that was actually set, as number in Volt.

=head2 get_sens

  $sens = $sr830->get_sens();

Returns the value of the sensitivity, as number in Volt.

=head2 set_tc

  $string=$sr830->set_tc(1E-3);

Sets time constant (value given in seconds); possible values are:
10 us, 30us, 100 us, 300 us, ..., 10000 s, 30000 s
If the argument is not in this list, the next higher value will be chosen.

Returns the value of the time constant that was actually set, as number in seconds.

=head2 get_tc

  $tc = $sr830->get_tc();

Returns the time constant, as number in seconds.

=head2 set_frequency

  $sr830->set_frequency(334);

Sets reference frequency; value given in Hz. Values between 0.001 Hz and 102 kHz can be set.

=head2 get_frequency

  $freq=$sr830->get_frequency();

Returns reference frequency in Hz.

=head2 set_amplitude

  $sr830->set_amplitude(0.005);

Sets output amplitude to the value given (in V); values between 4 mV and 5 V are possible.

=head2 get_amplitude

  $ampl=$sr830->get_amplitude();

Returns amplitude of the sine output in V.

=head2 id

  $id=$sr830->id();

Returns the instruments ID string.

=head1 CAVEATS/BUGS

command to change a property like amplitude or time constant might have to be executed twice to take effect

=head1 SEE ALSO

=over 4

=item Lab::Instrument

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2009       Andreas K. Huettel, Daniela Taubert
            2010       Andreas K. Huettel, Daniel Schroeer
            2011       Andreas K. Huettel, Florian Olbrich
            2013       Andreas K. Huettel
            2014       Alois Dirnaichner, Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
