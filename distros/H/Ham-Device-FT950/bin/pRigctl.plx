#!/usr/bin/perl -w
use strict;
use Switch;
use Ham::Device::FT950;
our $VERSION = '0.02';

#Commands (may not be available for this rig):
#F: set_freq        (Frequency)          f: get_freq        ()
#M: set_mode        (Mode,Passband)      m: get_mode        ()
#I: set_split_freq  (Tx frequency)       i: get_split_freq  ()
#X: set_split_mode  (Mode,Passband)      x: get_split_mode  ()
#S: set_split_vfo   (Split mode,TxVFO)   s: get_split_vfo   ()
#N: set_ts          (Tuning step)        n: get_ts          ()
#L: set_level       (Level,Value)        l: get_level       (Level)
#U: set_func        (Func,Func status)   u: get_func        (Func)
#P: set_parm        (Parm,Value)         p: get_parm        (Parm)
#G: vfo_op          (Mem/VFO op)         g: scan            (Scan fct,Channel)
#A: set_trn         (Transceive)         a: get_trn         ()
#R: set_rptr_shift  (Rptr shift)         r: get_rptr_shift  ()
#O: set_rptr_offs   (Rptr offset)        o: get_rptr_offs   ()
#C: set_ctcss_tone  (CTCSS tone)         c: get_ctcss_tone  ()
#D: set_dcs_code    (DCS code)   d: get_dcs_code    ()
#V: set_vfo         (VFO)        v: get_vfo         ()
#T: set_ptt         (PTT)        t: get_ptt         ()
#E: set_mem         (Memory#)    e: get_mem         ()
#H: set_channel     (Channel)    h: get_channel     (Channel)
#B: set_bank        (Bank)       _: get_info        ()
#J: set_rit         (RIT)        j: get_rit         ()
#Z: set_xit         (XIT)        z: get_xit         ()
#Y: set_ant         (Antenna)    y: get_ant         ()
#?: set_powerstat   (Status)     ?: get_powerstat   ()
#*: reset           (Reset)      2: power2mW        ()
#w: send_cmd        (Cmd)        1: dump_caps       ()
#b: send_morse      (Morse)

my $ft950 = new Ham::Device::FT950(
            baudrate    => 9600,
            databits    => 8,
            #configFile  => "radio.ini",
            portname    => "/dev/ttyUSB0",
            handshake   => "rts",
            read_char_time  => 0,
            read_const_time => 20,
            user_msg   => "OFF",
            lockfile    => 1
            
);

#print "Portname is now " . $ft950->portname . "\n";
#print "Baudrate is now " . $ft950->baudrate . "\n";
#print "Databits is now " . $ft950->databits . "\n";
#print "Config file is now " . $ft950->configFile . "\n";
#print "Handshake is now " . $ft950->handshake . "\n";
#print "pRigCtl: Freq is " . $freq . "\n";


print "pRigctl.pl: test program for FT950.pm \n";
while () {
    my $input;
    printHeader();
    print "pRigctl(f,m,v,s,F,M,V,q,?): ";
    chomp($input = <STDIN>);
        if ($input eq '?')  {
            help();
        } elsif ($input eq "q" || $input eq "Q") {
        $ft950->DESTROY;
        exit;
        }
    print "Input is: $input\n";    
    switcher($input);
   }
sub switcher {
    my $data = shift;
    switch($data) {
        case "f"    {print $ft950->getFreq('b')." Mhz \n"}
        case "F"    {print setfreq() }
        case "m"    {print $ft950->getMode('a') . "\n"}
        case "v"    {print "VFO ".$ft950->getActVfo()."\n"}
        case "s"    {print "S-meter is ".$ft950->readSMeter(). "\n"}
        case "b"    {print "Busy light is " . $ft950->statBSY() . "\n" }
        case "T"    {print "Setting MOX with result of " . $ft950->setMOX('1') . "\n" }
        case "t"    {print "Unsetting MOX with result of " . $ft950->setMOX('0') . "\n" }
        case "sm"   {print "status of MOX is " . $ft950->setMOX('2') . "\n" }
        case "VO"   {print "Setting MOX with result of " . $ft950->setVOX('1') . "\n" }
        case "vo"   {print "Unsetting MOX with result of " . $ft950->setVOX('0') . "\n" }
        case "sv"   {print "Status of MOX is " . $ft950->setVOX('2') . "\n" }
        case "st"   {print "Tx status of tranmitter is " . $ft950->statTX() . "\n"; }
        case "sf"   {print "Fast step mode status is " . $ft950->statFastStep() . "\n";}
        case "Sf"   {print "Setting Fast Step Mode " . $ft950->setFastStep(1) . "\n"; }
        case "uSf"  {print "Unsetting Fast Step Mode " . $ft950->setFastStep(0) . "\n"; }
        case "wo"   {print "Writing rig optons to file " . $ft950->writeOpt("FT950Settings.txt") . "\n"; }
        case "vs"   {print "Swapping VFO's " . $ft950->swapVfo() . "\n"; }
        case "M"    {print setmode() }
        case "V"    {print setvfo() }
        #case "B"    {bandSelect('00') }
        #case "?"    {help()}
        #else        {print "Error, undefined option!\n"}
    }
}
sub help {
print "V vfoSelect       (Sets VFO A or B)    v getActiveVfo (Not implmented yet)\n";    
print "F set_freq        (Frequency)          f get_freq\n";
print "M set_mode        (Mode)               m get_mode\n";
print "V set_vfo         (VFO)                v get_vfo\n";
}

sub printHeader {
    my $format;
    print "\n";
    print "Portname        Baudrate    Databits    Freq        Mode \n";
    $format = sprintf("%12s  %6d        %1d           %2.6f    %s\n",$ft950->portname, $ft950->baudrate, $ft950->databits, $ft950->getFreq("A"), $ft950->getMode());
    print $format;
}
sub setfreq {
    my $input;
        while () {
            print "Enter Freq in Mhz: ";
            chomp($input = <STDIN>);
            print "Input was $input \n";
                unless ($input) { last; }                                  
            $ft950->setFreq("A",$input);
            last;
        }     
}
sub setmode {
    my $input;
        while () {
            print "LSB,USB,CW,FM,AM,FSK,CW-R,PKT-L,FSK-R,PKT-FM,FM-N,PKT-U,AM-N \n";
            print "Enter Mode: ";
            chomp($input = <STDIN>);
            print "Input was $input \n";
                unless ($input) { last; }                                  
            $ft950->setMode($input);
            last;
        }         
}
sub setvfo {
    my $input;
        while () {
            print "Enter VFO: ";
            chomp($input = <STDIN>);
            print "Input was $input \n";
                unless ($input) { last; }                                  
            $ft950->vfoSelect($input);
            last;
        }
}
#$ft950->DESTROY;  #closePort();