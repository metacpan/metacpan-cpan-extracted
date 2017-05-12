#!/usr/bin/perl

# Jeff Mock
# 1859 Scott St.
# San Francisco, CA 94115
#
# jeff@mock.com
# (c) 1999

#
# Test program demonstrating simple UI to control an HP3631A
# power supply.  This works on both NT and Linux, with remote
# or local connections to the power supply, and using either
# the serial for GPIB interfaces on the power supply.
#
# A listbox selects one of the three outputs of the power supply
# and two sliders let you control the voltage and current limits
# for the selected channel.  Program should initialize with
# current settings for the power supply.
#
# This is just a demo, it doesn't exercise all of the power 
# supply parameters and it doesn't do any real error checking.
# An exercise to the reader to support other features of the
# power supply.
#

use Tk;
use GPIB::hpe3631a;

$debug = 0;                     
$device = "HPE3631A";
$curr = 'P6V';                  # Initial setting of list box
$slv_val = 0;                   # Value of voltage slider
$slc_val = 0;                   # Value of current slider
$ch_output = 0;                 # Check box for output enable

%setting = (
    # Positive 6v supply
    P6V_MAXV   =>  6.18,        # Maximum voltage limit
    P6V_MAXC   =>  5.15,        # Maximum current limit
    P6V_MAXVS  =>  2.0,         # tickinterval for voltage slider
    P6V_MAXCS  =>  2.0,         # tickintercal for current slider
    P6V_MV     =>  0.0,         # Measured voltage
    P6V_MC     =>  0.0,         # Measure current
    P6V_VRES   =>  0.001,       # Resolution for voltage slider
    P6V_LV     =>  0.0,         # Last voltage sent to instrument
    P6V_LC     =>  0.0,         # Last current send to instrument

    # Positive 25v supply
    P25V_MAXV  =>  25.75,
    P25V_MAXC  =>  1.03,
    P25V_MAXVS =>  10.0,
    P25V_MAXCS =>  0.5,
    P25V_MV    =>  0.0,
    P25V_MC    =>  0.0,
    P25V_VRES  =>  0.01, 
    P25V_LV    =>  0.0,
    P25V_LC    =>  0.0,
    
    # Negative 25v supply
    N25V_MAXV  =>  -25.75,
    N25V_MAXC  =>  1.03,
    N25V_MAXVS =>  10.0,
    N25V_MAXCS =>  0.5,
    N25V_MV    =>  0.0,
    N25V_MC    =>  0.0,
    N25V_VRES  =>  0.01, 
    N25V_LV    =>  0.0,
    N25V_LC    =>  0.0,
);

# Sub for changes to listbox selecting output to control
sub output_sel {
    $curr = $lb->get($lb->curselection);
    print "Setting display for $curr output\n" if $debug;
    $g->ibwrt("INST $curr");        # set instrument display to 
                                    # selected listbox item

    $slv->configure(        
        -state         => 'normal', 
        -to            => $setting{$curr . "_MAXV"},
        -tickinterval  => $setting{$curr . "_MAXVS"},
        -resolution    => $setting{$curr . "_VRES"},
    );
    $slc->configure(    
        -state         => 'normal', 
        -to            => $setting{$curr . "_MAXC"},
        -tickinterval  => $setting{$curr . "_MAXCS"},
    );
    $slv->set($setting{$curr . "_LV"});
    $slc->set($setting{$curr . "_LC"});
}

# Sub for changes to either current for voltage slider
sub slider_change {
    return if $ignore;
    return if $slv_val == $setting{$curr . "_LV"} && 
              $slc_val == $setting{$curr . "_LC"};

    $setting{$curr . "_LV"} = $slv_val;
    $setting{$curr . "_LC"} = $slc_val;

    print "Sending: $curr gets V=$slv_val, C=$slc_val\n" if $debug;
    $g->set($curr, $slv_val, $slc_val);
}

# Sub for clicking output control check box
sub output_check {
    $g->output($ch_output);
}

#
# Program starts here
#

# Open the power supply
$g = GPIB::hpe3631a->new($device);

# Create a window
$mw = MainWindow->new();
$mw->title("HPE3631A Control Panel");

# Create a listbox
$lb = $mw->Listbox(
    -selectmode         => "single",
    -height             => 3,
);
$lb->insert('end', "P6V", "P25V", "N25V");
$lb->bind('<Button-1>', \&output_sel);
$lb->pack;

# Create a slider for voltage
$slv = $mw->Scale( 
    -command            => \&slider_change,
    -from               => 0,
    -to                 => 25.0,
    -tickinterval       => 25.0,
    -length             => 200,
    -sliderlength       => 15,
    -resolution         => 0.001,
    -orient             => 'horizontal',
    -variable           => \$slv_val,
    -label              => "Voltage Limit (Volts)",
);
$slv->pack;
            
# Create a slider for current
$slc = $mw->Scale( 
    -command            => \&slider_change,
    -from               => 0,
    -to                 => 1.0,
    -tickinterval       => 1.0,
    -length             => 200,
    -sliderlength       => 15,
    -resolution         => 0.001,
    -orient             => 'horizontal',
    -variable           => \$slc_val, 
    -label              => "Current Limit (Amps)",
);
$slc->pack;

# Create a checkbox for output control
$check_on = $mw->Checkbutton(
    -text               => "Outputs ON",
    -command            => \&output_check,
    -variable           => \$ch_output,
);
$check_on->pack;

# Initialize state with instrument state
$lb->selectionSet(0);
for $op ("P6V", "P25V", "N25V") {
    ($v, $c) = $g->get($op);
    $setting{$op . "_LV"} = $v;
    $setting{$op . "_LC"} = $c;
    $g->set($op, $v, $c);
}
$ch_output = $g->output;

# Set initial UI parameters
output_sel();

# Tk takes care of everything else
MainLoop;
