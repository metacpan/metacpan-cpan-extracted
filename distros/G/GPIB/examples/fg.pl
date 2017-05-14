#!/usr/bin/perl

# Jeff Mock
# 1859 Scott St.
# San Francisco, CA 94115
#
# jeff@mock.com
# (c) 1999

#
# Here is Tk + GPIB example for controlling a small set of 
# features in an HP33120A function generator.  This 
# examples runs on both NT and Linux.  It works with 
# local or remote connections using either the serial
# port or GPIB port on the instrument.
#
# This script puts up a listbox for selecting a 
# waveform and two sliders for controlling the 
# frequency and amplitude of the signal.
#

use Tk;
use GPIB::hp33120a;

$debug = 0;                     
$device = "HP33120A";

# Change waveform shape
sub shape_sel {
    $g->shape($lb->get($lb->curselection));
}

# Open the function generator
$g = GPIB::hp33120a->new($device);

# Create a window
$mw = MainWindow->new();
$mw->title("HP33120A Control Panel");

# Create a listbox for waveform
$lb = $mw->Listbox(
    -selectmode         => "single",
    -height             => 4,
);
$lb->insert('end', "SQU", "SIN", "TRI", "RAMP");
$lb->bind('<Button-1>', \&shape_sel);
$lb->pack;

# Create a slider for frequency
$mw->Scale( 
    -command            => sub { $g->freq( $slf_val*1000.0); },
    -from               => 50.0,
    -to                 => 100.0,
    -tickinterval       => 20.0,
    -length             => 200,
    -sliderlength       => 15,
    -resolution         => 0.01,
    -orient             => 'horizontal',
    -variable           => \$slf_val,
    -label              => "Frequency (kHz)",
)->pack;
            
# Create a slider for amplitude
$mw->Scale( 
    -command            => sub { $g->amplitude( $sla_val); },
    -from               => 1.0,
    -to                 => 2.0,
    -tickinterval       => 0.5,
    -length             => 200,
    -sliderlength       => 15,
    -resolution         => 0.01,
    -orient             => 'horizontal',
    -variable           => \$sla_val,
    -label              => "Amplitude (Volts)",
)->pack;
            
# Initialize state
$g->offset(0.0);
$lb->selectionSet(0);
$sla_val = 1.5;
$slf_val = 50.0;
shape_sel();

# Tk takes care of everything else
MainLoop;

