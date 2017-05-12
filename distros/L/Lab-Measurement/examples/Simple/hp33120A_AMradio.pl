#!/usr/bin/perl
use Lab::Instrument::HP33120A;

#
# set up AM radio transmission of a heartbeat
# tested with an actual radio, and it was disappointing, but
# it does show how to use the HP33120A.
#
# usage: hp33120A_AMradio.pl [CarrierFrequency] [heartbeat_rate]
#

my $F = shift;

if ($F =~ /(\-h|help)/i) {
    print "$0: [CarrierFrequency] [heartbeat_rate]\n";
    print "The carrier frequency is specified in Hz, and can\n";
    print "be a number or a string. The heartbeat_rate is in 'beats\n";
    print "per minute', and is a simple number.\n";
    print "The signal starts with heartbeat/2 rate and low amplitude\n";
    print "then increases in amplitude and heartbeat over 100sec\n";
    print "\n";
    print "Defaults: 1.00MHz and 100bpm\n";
    print "Don't blame me if someone hears this on a radio and freaks out,\n";
    print "but I'd like to hear about it.\n";

    exit(0);
}

$F = '1.00MHz' unless defined $F;

my $bpm = shift;
$bpm = 100 unless defined $bpm;
die("bad heartbeat rate") if $bpm <= 0;


my $g = new Lab::Instrument::HP33120A (
    connection_type => 'LinuxGPIB',
    gpib_address => 10,
    );

die("no connection") unless defined $g;

$g->set_shape("SINE");
$g->set_frequency($F);
$g->set_amplitude('MIN');  # quiet until all set up
$g->set_user_waveform('CARDIAC');


$g->set_modulation('AM');
$g->set_am_depth('MIN');  # start low volume, then increase
$g->set_am_shape('USER'); 
$g->set_am_frequency($bpm*60/2);	

# let the wild rumpus begin

$g->set_amplitude('MAX');
for (my $j=0; $j < 100; $j++) {
    $g->set_am_frequency($bpm*60*(1+3*$j/100)/2);
    $g->set_am_depth($j);
    sleep(1);
}
$g->set_am_shape('NOISE');   # go to white noise after cardiac arrest
sleep(5);
$g->reset();
